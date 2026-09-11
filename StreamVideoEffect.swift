import Foundation
import CoreImage
import CoreMedia
import HaishinKit
import UIKit

class StreamVideoEffect: VideoEffect {
    
    private let filter = CIFilter(name: "CISourceOverCompositing")
    private var overlayImage: CIImage?
    private var lastStateUpdate: Int64 = 0
    private let renderQueue = DispatchQueue(label: "com.volleypro.overlayRenderer")
    private var isRenderingOverlay = false
    
    var scoreboardView: ScoreboardOverlayView?
    var marqueeView: MarqueeOverlayView? = MarqueeOverlayView(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
    var currentState: RemoteMatchState? {
        didSet {
            if let state = currentState {
                triggerOverlayUpdate(state: state)
            }
        }
    }
    
    var stingerFrameCount = 0
    var isTransitioningToReplay = false
    var lastReplayState = false
    
    override func execute(_ image: CIImage, info: CMSampleBuffer?) -> CIImage {
        var outputImage = image
        
        let currentlyReplaying = ReplayManager.shared.isReplaying
        if currentlyReplaying != lastReplayState {
            isTransitioningToReplay = true
            stingerFrameCount = 15 // 0.25 sec @ 60fps
            lastReplayState = currentlyReplaying
        }
        
        if currentlyReplaying {
            if let replayFrame = ReplayManager.shared.getPlaybackFrame() {
                outputImage = replayFrame
            }
        }
        
        // Non applichiamo l'overlay sulla preview locale se non stiamo trasmettendo o registrando
        // In questo modo la vista locale usa solo il componente nativo ScoreboardOverlayView evitando doppi tabelloni
        let isPublishing = StreamManager.shared.isPublishing
        let isRecording = LocalVideoRecorder.shared.isRecordingState
        
        guard (isPublishing || isRecording), let overlay = overlayImage, let filter = filter else {
            return outputImage
        }
        
        filter.setValue(overlay, forKey: kCIInputImageKey)
        filter.setValue(outputImage, forKey: kCIInputBackgroundImageKey)
        
        let finalImage = filter.outputImage ?? outputImage
        
        if isRecording {
            if let sampleBuffer = info {
                let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                LocalVideoRecorder.shared.appendVideo(image: finalImage, time: time)
            }
        }
        
        if isTransitioningToReplay {
            stingerFrameCount -= 1
            if stingerFrameCount <= 0 { isTransitioningToReplay = false }
            let flash = CIImage(color: CIColor.white).cropped(to: finalImage.extent)
            let mixFilter = CIFilter(name: "CISourceOverCompositing")!
            mixFilter.setValue(flash, forKey: kCIInputImageKey)
            mixFilter.setValue(finalImage, forKey: kCIInputBackgroundImageKey)
            return mixFilter.outputImage ?? finalImage
        }
        return finalImage
    }
    
    func triggerOverlayUpdate(state: RemoteMatchState) {
        guard !isRenderingOverlay else { return }
        isRenderingOverlay = true
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.scoreboardView?.updateFromState(state)
            self.marqueeView?.updateMessage(state.scrollMessage, show: state.showScrollText)
            
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1.0
            format.opaque = false
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1920, height: 1080), format: format)
            
            let uiImage = renderer.image { context in
                if let sv = self.scoreboardView {
                    context.cgContext.saveGState()
                    let scale: CGFloat = 2.2
                    context.cgContext.translateBy(x: 50, y: 50)
                    context.cgContext.scaleBy(x: scale, y: scale)
                    sv.layer.render(in: context.cgContext)
                    context.cgContext.restoreGState()
                }
                
                if let mv = self.marqueeView {
                    mv.layer.render(in: context.cgContext)
                }
            }
            
            if let cgImage = uiImage.cgImage {
                let ciImage = CIImage(cgImage: cgImage)
                // CoreImage origin (0,0) is bottom-left, while CGImage is top-left.
                // Flip vertically by mapping y -> 1080 - y so that overlay is right-side up at top-left.
                let flipTransform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 1080)
                self.overlayImage = ciImage.transformed(by: flipTransform)
            }
            self.isRenderingOverlay = false
        }
    }
}

