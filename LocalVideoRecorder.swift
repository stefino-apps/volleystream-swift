import Foundation
import AVFoundation
import CoreImage
import UIKit

import Photos

class LocalVideoRecorder {
    static let shared = LocalVideoRecorder()
    
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    
    private var isRecording = false
    private var startTime: CMTime = .zero
    private var currentFileUrl: URL?
    
    func startRecording() {
        if isRecording { return }
        
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let timestamp = Int(Date().timeIntervalSince1970)
        let url = dir.appendingPathComponent("VolleyStream_Match_\(timestamp).mp4")
        self.currentFileUrl = url
        
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
        
        do {
            assetWriter = try AVAssetWriter(outputURL: url, fileType: .mp4)
            
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
            
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 2,
                AVSampleRateKey: 44100,
                AVEncoderBitRateKey: 128000
            ]
            audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            audioInput?.expectsMediaDataInRealTime = true
            
            if let audioInput = audioInput, assetWriter!.canAdd(audioInput) {
                assetWriter!.add(audioInput)
            }
            
            assetWriter?.startWriting()
            isRecording = true
            startTime = .zero
            print("LocalVideoRecorder: Registrazione avviata su \(url.path)")
            
        } catch {
            print("Errore avvio registrazione: \(error)")
        }
    }
    
    func stopRecording(completion: @escaping (URL?) -> Void) {
        guard isRecording, let url = currentFileUrl else {
            completion(nil)
            return
        }
        isRecording = false
        
        videoInput?.markAsFinished()
        audioInput?.markAsFinished()
        
        assetWriter?.finishWriting {
            DispatchQueue.main.async {
                PHPhotoLibrary.requestAuthorization { status in
                    if status == .authorized || status == .limited {
                        PHPhotoLibrary.shared().performChanges({
                            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                        }) { success, error in
                            print("Match salvato in galleria: \(success), error: \(String(describing: error))")
                        }
                    } else {
                        if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(url.path) {
                            UISaveVideoAtPathToSavedPhotosAlbum(url.path, nil, nil, nil)
                        }
                    }
                }
                completion(url)
            }
        }
    }
    
    private let ciContext = CIContext()
    var isRecordingState: Bool { return isRecording }
    
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
    
    func appendAudio(sampleBuffer: CMSampleBuffer) {
        guard isRecording, let audioInput = audioInput, audioInput.isReadyForMoreMediaData else { return }
        
        if startTime != .zero {
            audioInput.append(sampleBuffer)
        }
    }
}
