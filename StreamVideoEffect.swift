import Foundation
import CoreImage
import CoreMedia
import HaishinKit
import UIKit

class StreamVideoEffect: VideoEffect {
    
    private var overlayImage: CIImage?
    private let renderQueue = DispatchQueue(label: "com.volleypro.overlayRenderer", qos: .userInteractive)
    private var isRenderingOverlay = false
    private let lock = NSLock()
    
    var scoreboardView: ScoreboardOverlayView?
    var marqueeView: MarqueeOverlayView? = MarqueeOverlayView(frame: CGRect(x: 0, y: 0, width: 1920, height: 1080))
    var currentState: RemoteMatchState? {
        didSet {
            if let state = currentState {
                triggerOverlayUpdate(state: state)
            }
        }
    }
    
    private var cachedReplayBadgeCIImage: CIImage?
    
    private func getReplayBadgeCIImage() -> CIImage? {
        if let cached = cachedReplayBadgeCIImage {
            return cached
        }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1920, height: 1080), format: format)
        let uiImage = renderer.image { context in
            self.scoreboardView?.drawReplayBadge(ctx: context.cgContext, rect: CGRect(x: 0, y: 0, width: 1920, height: 1080))
        }
        if let cgImg = uiImage.cgImage {
            let ci = CIImage(cgImage: cgImg)
            self.cachedReplayBadgeCIImage = ci
            return ci
        }
        return nil
    }
    
    private func renderStingerCIImage(progress: Double, isOutro: Bool) -> CIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1920, height: 1080), format: format)
        let uiImage = renderer.image { context in
            self.scoreboardView?.drawReplayStingerTransition(ctx: context.cgContext, rect: CGRect(x: 0, y: 0, width: 1920, height: 1080), progress: progress, isOutro: isOutro)
        }
        if let cgImg = uiImage.cgImage {
            return CIImage(cgImage: cgImg)
        }
        return nil
    }
    
    override func execute(_ image: CIImage, info: CMSampleBuffer?) -> CIImage {
        // Registra frame nel buffer circolare per Replay e Highlights
        ReplayManager.shared.recordFrame(image)
        
        var outputImage = image
        
        let currentlyReplaying = ReplayManager.shared.isReplaying
        let isStinger = ReplayManager.shared.isStingerActive
        let isOutro = ReplayManager.shared.isOutroActive
        let stingerProgress = ReplayManager.shared.getStingerProgress()
        
        if currentlyReplaying {
            let showReplay = !(isOutro && stingerProgress >= 0.5)
            if showReplay, let replayFrame = ReplayManager.shared.getPlaybackFrame() {
                outputImage = replayFrame
            }
        }
        
        let isRecording = LocalVideoRecorder.shared.isRecordingState
        
        // Compositing overlay grafico nativo e velocissimo via GPU
        lock.lock()
        let currentOverlay = overlayImage
        lock.unlock()
        
        if let overlay = currentOverlay {
            outputImage = overlay.composited(over: outputImage)
        }
        
        // Disegna dinamici in tempo reale: Transizione Stinger TV e Scritta REPLAY Lampeggiante
        if isStinger {
            if let stingerImg = renderStingerCIImage(progress: stingerProgress, isOutro: isOutro) {
                outputImage = stingerImg.composited(over: outputImage)
            }
        } else if currentlyReplaying {
            let isBlinkingOn = ((Int(Date().timeIntervalSince1970 * 1000) % 700) < 480)
            if isBlinkingOn, let badgeImg = getReplayBadgeCIImage() {
                outputImage = badgeImg.composited(over: outputImage)
            }
        }
        
        if isRecording {
            if let sampleBuffer = info {
                let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                LocalVideoRecorder.shared.appendVideo(image: outputImage, time: time)
            }
        }
        
        return outputImage
    }
    
    func triggerOverlayUpdate(state: RemoteMatchState) {
        renderQueue.async { [weak self] in
            guard let self = self else { return }
            autoreleasepool {
                self.renderOverlayImage(state: state)
            }
        }
    }
    
    private func renderOverlayImage(state: RemoteMatchState) {
        DispatchQueue.main.sync { [weak self] in
            guard let self = self else { return }
            self.marqueeView?.updateMessage(state.scrollMessage, show: state.showScrollText)
        }
        
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
                
                // Disegna l'animazione TRIPLA (3 PUNTI) al centro dello schermo (1920x1080) per 3.5 secondi
                if sv.isBlinkingTriple {
                    let elapsed = Date().timeIntervalSince1970 - sv.tripleStartTime
                    if elapsed < 3.5 {
                        let show = ((Int(elapsed * 1000) % 600) < 400)
                        if show {
                            sv.drawTripleAlert(ctx: context.cgContext, rect: CGRect(x: 0, y: 0, width: 1920, height: 1080))
                        }
                    }
                }
            }
            
            // Watermark promozionale durante prova gratuita / versione free:
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
            let newCIImage = CIImage(cgImage: cgImage)
            lock.lock()
            self.overlayImage = newCIImage
            lock.unlock()
        }
    }
}

