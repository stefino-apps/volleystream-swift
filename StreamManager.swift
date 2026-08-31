import Foundation
import AVFoundation
import VideoToolbox
import HaishinKit

public class StreamManager: NSObject {
    public static let shared = StreamManager()
    
    public var rtmpConnection = RTMPConnection()
    public var rtmpStream: RTMPStream!
    private var streamKeyToPublish: String = ""
    
    // Effetto Video per Replay e Grafica
    let videoEffect = StreamVideoEffect()
    
    private override init() {
        super.init()
        setupStream()
    }
    
    public func setupStream() {
        rtmpStream = RTMPStream(connection: rtmpConnection)
        
        // Video Settings
        rtmpStream.videoSettings.videoSize = .init(width: 1920, height: 1080)
        rtmpStream.videoSettings.bitRate = 4000 * 1000 // 4 Mbps
        rtmpStream.videoSettings.profileLevel = kVTProfileLevel_H264_High_AutoLevel as String
        rtmpStream.videoSettings.maxKeyFrameIntervalDuration = 2
        
        // Audio Settings
        rtmpStream.audioSettings.bitRate = 128 * 1000
        
        // Capture & Camera Settings
        rtmpStream.frameRate = 60.0
        rtmpStream.sessionPreset = .hd1920x1080
        
        // Registra il Video Effect per sovrimpressione
        _ = rtmpStream.registerVideoEffect(videoEffect)
    }
    
    public func attachDevices() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .videoChat, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
        
        if let audio = AVCaptureDevice.default(for: .audio) {
            rtmpStream.attachAudio(audio) { unit, error in print("Audio error: \(error)") }
        }
        
        if let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            rtmpStream.attachCamera(camera) { unit, error in print("Camera error: \(error)") }
        }
    }
    
    // Metodo per collegare la preview video Metal
    public func attachCamera(to view: MTHKView) {
        view.attachStream(rtmpStream)
    }
    
    public func startStreaming(url: String, streamKey: String) {
        self.streamKeyToPublish = streamKey
        rtmpConnection.addEventListener(.rtmpStatus, selector: #selector(statusHandler), observer: self)
        rtmpConnection.connect(url)
    }
    
    @objc private func statusHandler(_ notification: Notification) {
        let e = Event.from(notification)
        guard let data: NSDictionary = e.data as? NSDictionary,
              let code: String = data["code"] as? String else {
            return
        }
        
        if code == RTMPConnection.Code.connectSuccess.rawValue {
            rtmpStream.publish(streamKeyToPublish)
        }
    }
    
    public func stopStreaming() {
        rtmpStream.close()
        rtmpConnection.close()
    }
}

