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
    private var cachedBannerUIImages: [UIImage] = []
    private var lastBannerCheckTime: TimeInterval = 0
    private var marqueeFont = UIFont.boldSystemFont(ofSize: 32)
    private var lastMarqueeMessage: String = ""
    private var cachedMarqueeWidth: CGFloat = 0
    
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
    
    // MARK: - Testo Scorrevole Dinamico in Tempo Reale
    private func getMarqueeStripCIImage(message: String) -> CIImage? {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        if trimmed != lastMarqueeMessage {
            lastMarqueeMessage = trimmed
            cachedMarqueeWidth = (trimmed as NSString).size(withAttributes: [.font: marqueeFont]).width
        }
        
        let totalDist = 1920.0 + cachedMarqueeWidth + 120.0
        let speed: Double = 140.0 // Velocità fluida broadcast in px/s
        let elapsed = CACurrentMediaTime()
        let offset = CGFloat(fmod(elapsed * speed, Double(totalDist)))
        let textX = 1920.0 - offset
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false
        let h: CGFloat = 64.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1920, height: h), format: format)
        let uiImage = renderer.image { context in
            let barRect = CGRect(x: 0, y: 0, width: 1920, height: h)
            
            // Sfondo barra elegante blu scuro con trasparenza
            UIColor(red: 10/255, green: 22/255, blue: 48/255, alpha: 0.92).setFill()
            context.cgContext.fill(barRect)
            
            // Bordo superiore neon azzurro
            let borderPath = UIBezierPath()
            borderPath.move(to: CGPoint(x: 0, y: 1))
            borderPath.addLine(to: CGPoint(x: 1920, y: 1))
            UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 0.95).setStroke()
            borderPath.lineWidth = 2.0
            borderPath.stroke()
            
            // Badge icona "LIVE" a sinistra fissa
            let tagRect = CGRect(x: 20, y: 14, width: 68, height: 36)
            let tagPath = UIBezierPath(roundedRect: tagRect, cornerRadius: 6)
            UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.95).setFill()
            tagPath.fill()
            let tagAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 15, weight: .black),
                .foregroundColor: UIColor.white
            ]
            "LIVE".draw(at: CGPoint(x: 32, y: 22), withAttributes: tagAttrs)
            
            // Testo scorrevole nitido in bianco
            let textAttrs: [NSAttributedString.Key: Any] = [
                .font: self.marqueeFont,
                .foregroundColor: UIColor.white
            ]
            (trimmed as NSString).draw(at: CGPoint(x: textX, y: 14), withAttributes: textAttrs)
        }
        if let cgImg = uiImage.cgImage {
            // CIImage origin is at bottom-left, so (0,0) with height 64 sits directly at the bottom of 1080p frame
            return CIImage(cgImage: cgImg)
        }
        return nil
    }
    
    // MARK: - Sponsor a Tutto Schermo (Tasto 'S')
    private func getFullScreenSponsorCIImage(state: RemoteMatchState) -> CIImage? {
        let idx = state.currentSponsorIdx
        let namesToTry = [
            "sponsor_\(idx + 1).png",
            "sponsorFull.png",
            "sponsor_1.png",
            "sponsor_2.png",
            "sponsor_3.png",
            "sponsor_4.png"
        ]
        var sponsorImg: UIImage?
        for name in namesToTry {
            if let data = AppPreferences.shared.loadImage(name: name), let img = UIImage(data: data) {
                sponsorImg = img
                break
            }
        }
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1920, height: 1080), format: format)
        let uiImage = renderer.image { context in
            // Sfondo broadcast
            UIColor(red: 10/255, green: 15/255, blue: 30/255, alpha: 1.0).setFill()
            context.cgContext.fill(CGRect(x: 0, y: 0, width: 1920, height: 1080))
            
            if let img = sponsorImg {
                let imgSize = img.size
                let aspect = min(1800.0 / imgSize.width, 960.0 / imgSize.height)
                let drawW = imgSize.width * aspect
                let drawH = imgSize.height * aspect
                let drawX = (1920.0 - drawW) / 2.0
                let drawY = (1080.0 - drawH) / 2.0
                img.draw(in: CGRect(x: drawX, y: drawY, width: drawW, height: drawH))
            } else {
                let cardRect = CGRect(x: 260, y: 190, width: 1400, height: 700)
                let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: 28)
                UIColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.95).setFill()
                cardPath.fill()
                UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 0.9).setStroke()
                cardPath.lineWidth = 3
                cardPath.stroke()
                
                let title = "PAUSA SPONSOR"
                let titleFont = UIFont.systemFont(ofSize: 56, weight: .black)
                let titleAttrs: [NSAttributedString.Key: Any] = [
                    .font: titleFont,
                    .foregroundColor: UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0)
                ]
                let tSize = (title as NSString).size(withAttributes: titleAttrs)
                (title as NSString).draw(at: CGPoint(x: (1920 - tSize.width) / 2, y: 440), withAttributes: titleAttrs)
                
                let sub = "LA DIRETTA RIPRENDERÀ A BREVE"
                let subFont = UIFont.systemFont(ofSize: 28, weight: .bold)
                let subAttrs: [NSAttributedString.Key: Any] = [
                    .font: subFont,
                    .foregroundColor: UIColor.white
                ]
                let sSize = (sub as NSString).size(withAttributes: subAttrs)
                (sub as NSString).draw(at: CGPoint(x: (1920 - sSize.width) / 2, y: 530), withAttributes: subAttrs)
            }
        }
        if let cgImg = uiImage.cgImage {
            return CIImage(cgImage: cgImg)
        }
        return nil
    }
    
    // MARK: - Sponsor a Rotazione in Alto a Destra
    private func reloadRotatingBannersIfNeeded() {
        let now = CACurrentMediaTime()
        guard now - lastBannerCheckTime > 5.0 else { return }
        lastBannerCheckTime = now
        
        var images: [UIImage] = []
        for i in 1...5 {
            if let data = AppPreferences.shared.loadImage(name: "banner_\(i).png"), let img = UIImage(data: data) {
                images.append(img)
            } else if let data = AppPreferences.shared.loadImage(name: "sponsorRotating_\(i - 1).png"), let img = UIImage(data: data) {
                images.append(img)
            }
        }
        self.cachedBannerUIImages = images
    }
    
    private func getRotatingBannerCIImage() -> CIImage? {
        reloadRotatingBannersIfNeeded()
        guard !cachedBannerUIImages.isEmpty else { return nil }
        
        let count = cachedBannerUIImages.count
        let index = Int(Date().timeIntervalSince1970 / 12.0) % count
        let banner = cachedBannerUIImages[index]
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false
        let boxW: CGFloat = 220.0
        let boxH: CGFloat = 60.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: boxW, height: boxH), format: format)
        let uiImage = renderer.image { context in
            let rect = CGRect(x: 0, y: 0, width: boxW, height: boxH)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 10)
            UIColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.90).setFill()
            path.fill()
            UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 0.8).setStroke()
            path.lineWidth = 1.5
            path.stroke()
            
            let bSize = banner.size
            let aspect = min((boxW - 16) / bSize.width, (boxH - 12) / bSize.height)
            let dw = bSize.width * aspect
            let dh = bSize.height * aspect
            let dx = (boxW - dw) / 2.0
            let dy = (boxH - dh) / 2.0
            banner.draw(in: CGRect(x: dx, y: dy, width: dw, height: dh))
        }
        if let cgImg = uiImage.cgImage {
            let ci = CIImage(cgImage: cgImg)
            let transform = CGAffineTransform(translationX: 1920.0 - 35.0 - boxW, y: 1080.0 - 35.0 - boxH)
            return ci.transformed(by: transform)
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
        
        // Verifica se è attivo lo sponsor a tutto schermo
        let isFullScreenSponsor = (currentState?.fullScreenSponsor == true) || (currentState?.showSponsor == true)
        if isFullScreenSponsor, let state = currentState, let sponsorCI = getFullScreenSponsorCIImage(state: state) {
            outputImage = sponsorCI.composited(over: outputImage)
        } else {
            // Compositing overlay grafico (tabellone TV)
            lock.lock()
            let currentOverlay = overlayImage
            lock.unlock()
            
            if let overlay = currentOverlay {
                outputImage = overlay.composited(over: outputImage)
            }
            
            // Sponsor rotanti in alto a destra
            if let bannerCI = getRotatingBannerCIImage() {
                outputImage = bannerCI.composited(over: outputImage)
            }
            
            // Testo scorrevole dinamico a 60fps in basso
            if let state = currentState, state.showScrollText, let marqueeCI = getMarqueeStripCIImage(message: state.scrollMessage) {
                outputImage = marqueeCI.composited(over: outputImage)
            }
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
        
        let isRecording = LocalVideoRecorder.shared.isRecordingState
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
                    let scale: CGFloat = 2.6
                    context.cgContext.translateBy(x: 35, y: 35)
                    context.cgContext.scaleBy(x: scale, y: scale)
                    sv.draw(CGRect(x: 0, y: 0, width: 228, height: 58))
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
        }
        
        if let cgImage = uiImage.cgImage {
            let newCIImage = CIImage(cgImage: cgImage)
            lock.lock()
            self.overlayImage = newCIImage
            lock.unlock()
        }
    }
}

