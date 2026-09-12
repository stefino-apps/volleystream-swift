import Foundation
import AVFoundation
import CoreImage
import UIKit
import Photos

class LocalVideoRecorder {
    static let shared = LocalVideoRecorder()
    
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var audioRecorder: AVAudioRecorder?
    
    private var isRecording = false
    private var startTime: CMTime = .zero
    private var currentVideoUrl: URL?
    private var currentAudioUrl: URL?
    private var finalOutputUrl: URL?
    
    private let ciContext = CIContext()
    var isRecordingState: Bool { return isRecording }
    
    func startRecording() {
        if isRecording { return }
        
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let timestamp = Int(Date().timeIntervalSince1970)
        let videoUrl = dir.appendingPathComponent("VolleyStream_TempVideo_\(timestamp).mp4")
        let audioUrl = dir.appendingPathComponent("VolleyStream_TempAudio_\(timestamp).m4a")
        let finalUrl = dir.appendingPathComponent("VolleyStream_Match_\(timestamp).mp4")
        
        self.currentVideoUrl = videoUrl
        self.currentAudioUrl = audioUrl
        self.finalOutputUrl = finalUrl
        
        // Pulizia eventuali file precedenti
        try? FileManager.default.removeItem(at: videoUrl)
        try? FileManager.default.removeItem(at: audioUrl)
        try? FileManager.default.removeItem(at: finalUrl)
        
        do {
            // 1. Setup Video Writer
            assetWriter = try AVAssetWriter(outputURL: videoUrl, fileType: .mp4)
            
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: 1920,
                AVVideoHeightKey: 1080
            ]
            videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            videoInput?.expectsMediaDataInRealTime = true
            
            let sourcePixelBufferAttributes: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
                kCVPixelBufferWidthKey as String: 1920,
                kCVPixelBufferHeightKey as String: 1080
            ]
            
            if let videoInput = videoInput {
                pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput, sourcePixelBufferAttributes: sourcePixelBufferAttributes)
                if assetWriter!.canAdd(videoInput) {
                    assetWriter!.add(videoInput)
                }
            }
            
            assetWriter?.startWriting()
            
            // 2. Setup Audio Recorder parallelo ad alta qualità
            let audioSettings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
                AVEncoderBitRateKey: 128000
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioUrl, settings: audioSettings)
            audioRecorder?.record()
            
            isRecording = true
            startTime = .zero
            print("LocalVideoRecorder: Registrazione Video & Audio avviata su \(videoUrl.path)")
            
        } catch {
            print("Errore avvio registrazione: \(error)")
        }
    }
    
    func appendVideo(image: CIImage, time: CMTime) {
        guard isRecording, let videoInput = videoInput, videoInput.isReadyForMoreMediaData else { return }
        
        if startTime == .zero {
            startTime = time
            assetWriter?.startSession(atSourceTime: time)
        }
        
        if let pool = pixelBufferAdaptor?.pixelBufferPool {
            var pixelBuffer: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBuffer)
            
            if let buffer = pixelBuffer {
                ciContext.render(image, to: buffer)
                pixelBufferAdaptor?.append(buffer, withPresentationTime: time)
            }
        }
    }
    
    func stopRecording(completion: @escaping (URL?) -> Void) {
        guard isRecording, let videoUrl = currentVideoUrl, let audioUrl = currentAudioUrl, let finalUrl = finalOutputUrl else {
            completion(nil)
            return
        }
        isRecording = false
        
        audioRecorder?.stop()
        videoInput?.markAsFinished()
        
        assetWriter?.finishWriting { [weak self] in
            guard let self = self else { return }
            
            self.mergeAudioAndVideo(videoUrl: videoUrl, audioUrl: audioUrl, outputUrl: finalUrl) { success in
                let targetUrl = success ? finalUrl : videoUrl
                
                DispatchQueue.main.async {
                    PHPhotoLibrary.requestAuthorization { status in
                        if status == .authorized || status == .limited {
                            PHPhotoLibrary.shared().performChanges({
                                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: targetUrl)
                            }) { saved, error in
                                print("Match salvato in galleria con audio: \(saved), error: \(String(describing: error))")
                                // Pulisce i file temporanei
                                try? FileManager.default.removeItem(at: videoUrl)
                                try? FileManager.default.removeItem(at: audioUrl)
                            }
                        } else {
                            if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(targetUrl.path) {
                                UISaveVideoAtPathToSavedPhotosAlbum(targetUrl.path, nil, nil, nil)
                            }
                        }
                    }
                    completion(targetUrl)
                }
            }
        }
    }
    
    private func mergeAudioAndVideo(videoUrl: URL, audioUrl: URL, outputUrl: URL, completion: @escaping (Bool) -> Void) {
        let composition = AVMutableComposition()
        let videoAsset = AVURLAsset(url: videoUrl)
        let audioAsset = AVURLAsset(url: audioUrl)
        
        guard let compVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            completion(false)
            return
        }
        
        let videoDuration = videoAsset.duration
        let videoTimeRange = CMTimeRange(start: .zero, duration: videoDuration)
        
        if let sourceVideoTrack = videoAsset.tracks(withMediaType: .video).first {
            try? compVideoTrack.insertTimeRange(videoTimeRange, of: sourceVideoTrack, at: .zero)
            compVideoTrack.preferredTransform = sourceVideoTrack.preferredTransform
        }
        
        if let sourceAudioTrack = audioAsset.tracks(withMediaType: .audio).first {
            if let compAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                let audioDuration = min(audioAsset.duration, videoDuration)
                let audioTimeRange = CMTimeRange(start: .zero, duration: audioDuration)
                try? compAudioTrack.insertTimeRange(audioTimeRange, of: sourceAudioTrack, at: .zero)
            }
        }
        
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            completion(false)
            return
        }
        
        exportSession.outputURL = outputUrl
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        exportSession.exportAsynchronously {
            completion(exportSession.status == .completed)
        }
    }
}
