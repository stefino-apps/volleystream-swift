import Foundation
import AVFoundation
import CoreImage
import UIKit

class LocalVideoRecorder {
    static let shared = LocalVideoRecorder()
    
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    
    private var isRecording = false
    private var startTime: CMTime = .zero
    
    private var outputUrl: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("VolleyStream_Match.mp4")
    }
    
    func startRecording() {
        if isRecording { return }
        
        let url = outputUrl
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
            
        } catch {
            print("Errore avvio registrazione: \(error)")
        }
    }
    
    func stopRecording(completion: @escaping (URL?) -> Void) {
        guard isRecording else { return }
        isRecording = false
        
        videoInput?.markAsFinished()
        audioInput?.markAsFinished()
        
        assetWriter?.finishWriting {
            DispatchQueue.main.async {
                if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(self.outputUrl.path) {
                    UISaveVideoAtPathToSavedPhotosAlbum(self.outputUrl.path, nil, nil, nil)
                }
                completion(self.outputUrl)
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
