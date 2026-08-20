import Foundation
import CoreImage
import CoreMedia

class ReplayManager {
    static let shared = ReplayManager()
    
    private var frameBuffer: [CIImage] = []
    private let maxFrames = 300 // 5 seconds at 60fps or 10 seconds at 30fps
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
            // Spesso è necessario clonare il CVPixelBuffer o applicare un filtro. 
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
}

