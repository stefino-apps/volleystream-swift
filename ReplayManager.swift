import Foundation
import CoreImage
import CoreMedia
import AVFoundation
import UIKit

class ReplayManager {
    static let shared = ReplayManager()
    
    static var isDeviceSupported: Bool {
        return true
    }
    
    private var frameBuffer: [CIImage] = []
    var replayDuration: Int = 5
    var replaySpeed: Double = 0.4 // Rallentatore Broadcast Fluido (40% velocità)
    private var maxFrames: Int { return replayDuration * 30 }
    private var isRecording = true
    private var isPlaying = false
    private var playbackFraction: Double = 0.0
    private var lastRecordedTime: TimeInterval = 0
    
    private let queue = DispatchQueue(label: "com.volleyscout.replayQueue", qos: .userInteractive)
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    
    private init() {}
    
    func recordFrame(_ image: CIImage) {
        guard isRecording else { return }
        
        let now = CACurrentMediaTime()
        // Limita il campionamento a max 30 fps per non sovraccaricare la GPU/CPU
        guard (now - lastRecordedTime) >= 0.032 else { return }
        lastRecordedTime = now
        
        let extent = image.extent
        guard extent.width > 0 && extent.height > 0 else { return }
        
        queue.async { [weak self] in
            guard let self = self, self.isRecording else { return }
            
            // Scala a 960x540 per il buffer circolare di replay (4x più veloce, -75% memoria GPU)
            let scaledImage = image.transformed(by: CGAffineTransform(scaleX: 0.5, y: 0.5))
            let scaledExtent = scaledImage.extent
            if let cgImg = self.ciContext.createCGImage(scaledImage, from: scaledExtent) {
                let detachedImage = CIImage(cgImage: cgImg).transformed(by: CGAffineTransform(scaleX: 2.0, y: 2.0))
                self.frameBuffer.append(detachedImage)
                
                if self.frameBuffer.count > self.maxFrames {
                    self.frameBuffer.removeFirst()
                }
            }
        }
    }
    
    func startPlayback() {
        queue.async {
            self.isRecording = false
            self.isPlaying = true
            self.playbackFraction = 0.0
        }
    }
    
    func stopPlayback() {
        queue.async {
            self.isPlaying = false
            self.isRecording = true
            self.playbackFraction = 0.0
        }
    }
    
    func getPlaybackFrame() -> CIImage? {
        var frame: CIImage?
        queue.sync {
            guard self.isPlaying, !self.frameBuffer.isEmpty else { return }
            
            let idx = min(Int(self.playbackFraction), self.frameBuffer.count - 1)
            frame = self.frameBuffer[idx]
            
            // Avanzamento a velocità rallentata (Slow Motion)
            self.playbackFraction += self.replaySpeed
            
            if Int(self.playbackFraction) >= self.frameBuffer.count {
                // Fine del replay
                self.isPlaying = false
                self.isRecording = true
                self.playbackFraction = 0.0
            }
        }
        return frame
    }
    
    var isReplaying: Bool {
        var playing = false
        queue.sync { playing = self.isPlaying }
        return playing
    }
    
    func saveHighlightClip(completion: @escaping (Bool, String?) -> Void) {
        queue.async {
            let framesToExport = self.frameBuffer
            guard !framesToExport.isEmpty else {
                DispatchQueue.main.async { completion(false, "Nessun frame registrato per l'highlight") }
                return
            }
            
            let tempDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            let timestamp = Int(Date().timeIntervalSince1970)
            let outputUrl = tempDir.appendingPathComponent("Highlight_\(timestamp).mp4")
            
            if FileManager.default.fileExists(atPath: outputUrl.path) {
                try? FileManager.default.removeItem(at: outputUrl)
            }
            
            do {
                let assetWriter = try AVAssetWriter(outputURL: outputUrl, fileType: .mp4)
                let videoSettings: [String: Any] = [
                    AVVideoCodecKey: AVVideoCodecType.h264,
                    AVVideoWidthKey: 1920,
                    AVVideoHeightKey: 1080
                ]
                let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
                videoInput.expectsMediaDataInRealTime = false
                
                let sourcePixelBufferAttributes: [String: Any] = [
                    kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
                    kCVPixelBufferWidthKey as String: 1920,
                    kCVPixelBufferHeightKey as String: 1080
                ]
                let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput, sourcePixelBufferAttributes: sourcePixelBufferAttributes)
                
                if assetWriter.canAdd(videoInput) {
                    assetWriter.add(videoInput)
                }
                
                assetWriter.startWriting()
                assetWriter.startSession(atSourceTime: .zero)
                
                let ciContext = CIContext()
                let fps: Int64 = 30
                var frameIndex: Int64 = 0
                
                for frame in framesToExport {
                    while !videoInput.isReadyForMoreMediaData {
                        Thread.sleep(forTimeInterval: 0.005)
                    }
                    
                    if let pool = adaptor.pixelBufferPool {
                        var pixelBuffer: CVPixelBuffer?
                        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBuffer)
                        if let buffer = pixelBuffer {
                            ciContext.render(frame, to: buffer)
                            let presentTime = CMTimeMake(value: frameIndex, timescale: Int32(fps))
                            adaptor.append(buffer, withPresentationTime: presentTime)
                            frameIndex += 1
                        }
                    }
                }
                
                videoInput.markAsFinished()
                assetWriter.finishWriting {
                    if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(outputUrl.path) {
                        UISaveVideoAtPathToSavedPhotosAlbum(outputUrl.path, nil, nil, nil)
                        DispatchQueue.main.async { completion(true, nil) }
                    } else {
                        DispatchQueue.main.async { completion(false, "Formato video non compatibile") }
                    }
                }
                
            } catch {
                DispatchQueue.main.async { completion(false, error.localizedDescription) }
            }
        }
    }
}

