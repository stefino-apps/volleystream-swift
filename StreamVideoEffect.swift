import Foundation
import CoreImage
import HaishinKit
import UIKit

class StreamVideoEffect: VideoEffect {
    
    private let filter = CIFilter(name: "CISourceOverCompositing")
    private var overlayImage: CIImage?
    private var lastStateUpdate: Int64 = 0
    
    // Riferimento per disegnare l HUD. Assicurarsi di impostare questo dall esterno.
    var scoreboardView: ScoreboardOverlayView?
    var currentState: RemoteMatchState?
    
    override func execute(_ image: CIImage, info: CMSampleBuffer?) -> CIImage {
        // 1. Registra o Riproduci Replay
        var outputImage = image
        
        if ReplayManager.shared.isReplaying {
            if let replayFrame = ReplayManager.shared.getPlaybackFrame() {
                outputImage = replayFrame
            } else {
                // Finito, riprende a registrare dalla cam
                ReplayManager.shared.recordFrame(image)
            }
        } else {
            ReplayManager.shared.recordFrame(image)
        }
        
        // 2. Aggiorna l'immagine dell'overlay se lo stato è cambiato
        if let state = currentState {
            if state.lastUpdate != lastStateUpdate {
                lastStateUpdate = state.lastUpdate
                updateOverlayImage()
            }
        } else if overlayImage == nil {
            // Primo render
            updateOverlayImage()
        }
        
        // 3. Applica l'overlay al frame video
        guard let overlay = overlayImage, let filter = filter else {
            return outputImage
        }
        
        filter.setValue(overlay, forKey: kCIInputImageKey)
        filter.setValue(outputImage, forKey: kCIInputBackgroundImageKey)
        
        return filter.outputImage ?? outputImage
    }
    
    private func updateOverlayImage() {
        guard let view = scoreboardView else { return }
        
        DispatchQueue.main.sync {
            if let state = self.currentState {
                view.updateFromState(state)
            }
            
            // Renderizza la view UIKit in una UIImage
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1.0
            format.opaque = false
            
            let renderer = UIGraphicsImageRenderer(bounds: view.bounds, format: format)
            let uiImage = renderer.image { context in
                view.layer.render(in: context.cgContext)
            }
            
            if let cgImage = uiImage.cgImage {
                // Sposta l'overlay nella posizione corretta. (CIImage ha l'origine in basso a sinistra)
                let ciImage = CIImage(cgImage: cgImage)
                let transform = CGAffineTransform(translationX: 50, y: 1080 - 50 - view.bounds.height) // Assumendo 1080p
                self.overlayImage = ciImage.transformed(by: transform)
            }
        }
    }
}

