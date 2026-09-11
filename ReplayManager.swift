import Foundation
import CoreImage
import CoreMedia

class ReplayManager {
    static let shared = ReplayManager()
    
    private var frameBuffer: [CIImage] = []
    var replayDuration: Int = 5
    var replaySpeed: Double = 0.5
    private var maxFrames: Int { return replayDuration * 60 }
    private var isRecording = true
    private var isPlaying = false
    private var playbackIndex = 0
    
    private let queue = DispatchQueue(label: "com.volleyscout.replayQueue")
    
    private init() {}
    
    func recordFrame(_ image: CIImage) {
        queue.async {
            guard self.isRecording else { return }
            
            // Per evitare che i buffer vengano sovrascritti dalla telecamera
            // forziamo un render contestuale se necessario, o ci fidiamo del CVPixelBuffer se gestito da AVFoundation.
            // Spesso e' necessario clonare il CVPixelBuffer o applicare un filtro. 
            // In questa demo salviamo il CIImage.
            self.frameBuffer.append(image)
            
            if self.frameBuffer.count > self.maxFrames {
                self.frameBuffer.removeFirst()
            }
        }
    }
    
    func startPlayback() {
        queue.async {
            self.isRecording = false
            self.isPlaying = true
            self.playbackIndex = 0
        }
    }
    
    func stopPlayback() {
        queue.async {
            self.isPlaying = false
            self.isRecording = true
        }
    }
    
    func getPlaybackFrame() -> CIImage? {
        var frame: CIImage?
        queue.sync {
            guard self.isPlaying, !self.frameBuffer.isEmpty else { return }
            
            frame = self.frameBuffer[self.playbackIndex]
            
            self.playbackIndex += 1
            if self.playbackIndex >= self.frameBuffer.count {
                // Fine del replay
                self.isPlaying = false
                self.isRecording = true
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

