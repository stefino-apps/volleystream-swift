import AVFoundation
import HaishinKit
import UIKit

class StreamManager {
    static let shared = StreamManager()
    
    private var rtmpConnection = RTMPConnection()
    private var rtmpStream: RTMPStream!
    
    // View dove la fotocamera viene mostrata
    var previewView: MTHKView?
    
    private init() {
        rtmpStream = RTMPStream(connection: rtmpConnection)
        
        // Configurazioni Audio/Video a 60 FPS
        rtmpStream.videoSettings = [
            .width: 1920,
            .height: 1080,
            .profileLevel: kVTProfileLevel_H264_High_AutoLevel,
            .maxKeyFrameIntervalDuration: 2,
            .bitrate: 4000 * 1000 // 4 Mbps
        ]
        
        rtmpStream.audioSettings = [
            .bitrate: 128 * 1000
        ]
        
        rtmpStream.captureSettings = [
            .fps: 60.0,
            .sessionPreset: AVCaptureSession.Preset.hd1920x1080,
            .continuousAutofocus: true,
            .continuousExposure: true
        ]
        
        // Listener per connessione
        rtmpConnection.addEventListener(.rtmpStatus, selector: #selector(rtmpStatusHandler), observer: self)
    }
    
    func attachCamera(to view: MTHKView) {
        self.previewView = view
        view.attachStream(rtmpStream)
        
        rtmpStream.attachAudio(AVCaptureDevice.default(for: .audio)) { error in
            print("Audio Attach Error: \(error)")
        }
        
        if let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            rtmpStream.attachCamera(camera) { error in
                print("Camera Attach Error: \(error)")
            }
        }
    }
    
    func startStreaming(url: String, streamKey: String) {
        rtmpConnection.connect(url)
        // Non appena si connette (rtmpStatusHandler = NetConnection.Connect.Success), chiameremo publish
        // In un'app completa, si gestisce l'evento in modo asincrono.
        
        // Qui lo simuliamo con un delay o lo mettiamo nell'handler.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.rtmpStream.publish(streamKey)
        }
    }
    
    func stopStreaming() {
        rtmpStream.close()
        rtmpConnection.close()
    }
    
    @objc private func rtmpStatusHandler(_ notification: Notification) {
        let e = Event.from(notification)
        guard let data: ASObject = e.data as? ASObject, let code: String = data["code"] as? String else {
            return
        }
        print("RTMP Status: \(code)")
    }
    
    // Funzione fondamentale: sovrapporre grafica
    // HaishinKit permette di registrare un view o CALayer da renderizzare sopra il video
    func registerOverlay(view: UIView) {
        // La registrazione dell'overlay avviene disegnando l'HUD.
        rtmpStream.registerEffect(videoEffect: VideoEffect()) // Placeholder per overlay personalizzato
        // Per inserire UIKit, si può usare il drawable custom di HaishinKit
    }
}
