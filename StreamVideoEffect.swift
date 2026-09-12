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
        
        let isRecording = LocalVideoRecorder.shared.isRecordingState
        
        if let overlay = overlayImage, let filter = filter {
            filter.setValue(overlay, forKey: kCIInputImageKey)
            filter.setValue(outputImage, forKey: kCIInputBackgroundImageKey)
            outputImage = filter.outputImage ?? outputImage
        }
        
        if isRecording {
            if let sampleBuffer = info {
                let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                LocalVideoRecorder.shared.appendVideo(image: outputImage, time: time)
            }
        }
        
        if isTransitioningToReplay {
            stingerFrameCount -= 1
            if stingerFrameCount <= 0 { isTransitioningToReplay = false }
            let flash = CIImage(color: CIColor.white).cropped(to: outputImage.extent)
            let mixFilter = CIFilter(name: "CISourceOverCompositing")!
            mixFilter.setValue(flash, forKey: kCIInputImageKey)
            mixFilter.setValue(outputImage, forKey: kCIInputBackgroundImageKey)
            return mixFilter.outputImage ?? outputImage
        }
        return outputImage
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
                        let scale: CGFloat = 2.8
                        context.cgContext.translateBy(x: 50, y: 45)
                        context.cgContext.scaleBy(x: scale, y: scale)
                        sv.draw(CGRect(x: 0, y: 0, width: 240, height: 58))
                    }
                    context.cgContext.restoreGState()
                    
                    // Disegna l'animazione Set Point / Match Point al centro dello schermo (1920x1080) per 4 secondi
                    if sv.isBlinkingAlert, let sp = sv.getSetPointInfo(state: state) {
                        let elapsed = Date().timeIntervalSince1970 - sv.alertStartTime
                        if elapsed < 4.0 {
                            let show = ((Int(elapsed * 1000) % 700) < 450)
                            if show {
                                sv.drawSpecialAlerts(ctx: context.cgContext, rect: CGRect(x: 0, y: 0, width: 1920, height: 1080), sp: sp, state: state)
                            }
                        }
                    }
                    
                    // Disegna l'animazione TIMEOUT al centro dello schermo (1920x1080) per 4 secondi
                    if sv.isBlinkingTimeout {
                        let elapsed = Date().timeIntervalSince1970 - sv.timeoutStartTime
                        if elapsed < 4.0 {
                            let show = ((Int(elapsed * 1000) % 700) < 450)
                            if show {
                                sv.drawTimeoutAlert(ctx: context.cgContext, rect: CGRect(x: 0, y: 0, width: 1920, height: 1080), teamName: sv.timeoutTeamName, state: state)
                            }
                        }
                    }
                }
                
                // Watermark promozionale durante prova gratuita / versione free:
                // Appare ogni 5 minuti (minuto % 5 == 0) e dura 1 minuto posizionato al CENTRO IN ALTO
                if !StoreKitManager.shared.isPremium {
                    let minute = Calendar.current.component(.minute, from: Date())
                    if minute % 5 == 0 {
                        let watermarkText = "VOLLEYSTREAM PRO"
                        let font = UIFont.systemFont(ofSize: 22, weight: .black)
                        
                        let pillW: CGFloat = 280.0
                        let pillH: CGFloat = 42.0
                        let pillX: CGFloat = (1920.0 - pillW) / 2.0
                        let pillY: CGFloat = 28.0
                        let pillRect = CGRect(x: pillX, y: pillY, width: pillW, height: pillH)
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
                        let textRect = CGRect(x: pillX + 2, y: pillY + 7, width: pillW - 4, height: 28)
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

