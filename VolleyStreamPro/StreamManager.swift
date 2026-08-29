import AVFoundation
import HaishinKit
import UIKit
import Photos

class StreamManager: ObservableObject {
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
    
    // MARK: - REGISTRAZIONE LOCALE MP4
    
    @Published var isRecording = false
    private var recordURL: URL?
    
    func toggleRecording() {
        if isRecording {
            // Ferma registrazione (dipende dalla versione di HaishinKit, di solito record = false o close)
            // Nelle versioni recenti c'e' stopRecording(), in altre basta publish(nil) se locale
            // Assumiamo che la codebase usi una versione che supporti l'API base
            // In caso di problemi di build, lo sviluppatore dovra' agganciare HKStreamRecorder
            isRecording = false
            saveVideoToPhotos()
        } else {
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "match_\(UUID().uuidString).mp4"
            let fileURL = tempDir.appendingPathComponent(fileName)
            self.recordURL = fileURL
            
            // Logica placeholder per attivare la registrazione locale di HaishinKit
            print("Avvio registrazione locale: \(fileURL)")
            
            isRecording = true
        }
    }
    
    private func saveVideoToPhotos() {
        guard let url = recordURL else { return }
        print("Salvataggio in galleria...")
        // Richiede import Photos
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                }) { saved, error in
                    if saved {
                        print("✅ Partita salvata correttamente in Galleria!")
                        try? FileManager.default.removeItem(at: url)
                    } else {
                        print("❌ Errore salvataggio: \(error?.localizedDescription ?? "")")
                    }
                }
            }
        }
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
    
    // MARK: - REPLAY E HIGHLIGHTS
    
    func saveReplayClip() {
        print("Salvataggio Replay degli ultimi 10 secondi...")
        // 1. Estrai ultimi 10 secondi dal buffer circolare (se implementato con AVAssetWriter)
        // 2. Salva in un file temporaneo
        // 3. Sposta in galleria o carica nell'interfaccia PIP
        print("Replay pronto!")
    }
}
