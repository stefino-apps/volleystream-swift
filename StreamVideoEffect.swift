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
        // Registra frame per Replay solo se abilitato nelle impostazioni e supportato dal dispositivo
        if AppPreferences.shared.isReplayEnabled && ReplayManager.isDeviceSupported {
            ReplayManager.shared.recordFrame(image)
        }
        
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
                    if state.isSetFinished || state.isMatchFinished {
                        sv.draw(CGRect(x: 0, y: 0, width: 1920, height: 1080))
                    } else {
                        let scale: CGFloat = 2.2
                        context.cgContext.translateBy(x: 50, y: 50)
                        context.cgContext.scaleBy(x: scale, y: scale)
                        sv.layer.render(in: context.cgContext)
                    }
                    context.cgContext.restoreGState()
                }
                
                // Watermark promozionale durante prova gratuita / versione free:
                // Appare ogni 5 minuti (minuto % 5 == 0) e dura 1 minuto in alto accanto al tabellone
                if !StoreKitManager.shared.isPremium {
                    let minute = Calendar.current.component(.minute, from: Date())
                    if minute % 5 == 0 {
                        let watermarkText = "VOLLEYSTREAM PRO"
                        let font = UIFont.systemFont(ofSize: 22, weight: .black)
                        
                        // Sfondo pillola semi-trasparente elegante
                        let pillRect = CGRect(x: 510, y: 56, width: 280, height: 42)
                        let pillPath = UIBezierPath(roundedRect: pillRect, cornerRadius: 8)
                        UIColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.85).setFill()
                        pillPath.fill()
                        UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 0.9).setStroke()
                        pillPath.lineWidth = 1.5
                        pillPath.stroke()
                        
                        let paragraph = NSMutableParagraphStyle()
                        paragraph.alignment = .center
                        let attrs: [NSAttributedString.Key: Any] = [
                            .font: font,
                            .foregroundColor: UIColor.white,
                            .paragraphStyle: paragraph
                        ]
                        let textRect = CGRect(x: 512, y: 64, width: 276, height: 28)
                        watermarkText.draw(in: textRect, withAttributes: attrs)
                    }
                }
                
                if let mv = self.marqueeView {
                    mv.layer.render(in: context.cgContext)
                }
            }
            
            if let cgImage = uiImage.cgImage {
                self.overlayImage = CIImage(cgImage: cgImage)
            }
            self.isRenderingOverlay = false
        }
    }
}

