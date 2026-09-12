import Foundation
import AVFoundation
import VideoToolbox
import HaishinKit

public class StreamManager: NSObject {
    public static let shared = StreamManager()
    
    public var rtmpConnection = RTMPConnection()
    public var rtmpStream: RTMPStream!
    private var streamKeyToPublish: String = ""
    public var currentCamera: AVCaptureDevice?
    public var isPublishing: Bool = false
    public var isStreaming: Bool {
        return isPublishing
    }
    
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
        rtmpStream.videoOrientation = .landscapeRight
        
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
            rtmpStream.attachAudio(audio) { _, error in
                if let error = error { print("Audio error: \(error.localizedDescription)") }
            }
        }
        
        if let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            self.currentCamera = camera
            rtmpStream.attachCamera(camera) { _, error in
                if let error = error { print("Camera error: \(error.localizedDescription)") }
            }
            rtmpStream.videoOrientation = .landscapeRight
        }
    }
    
    // Zoom Controls
    public func zoomIn() {
        guard let device = currentCamera else { return }
        do {
            try device.lockForConfiguration()
            let maxZoom: CGFloat = min(device.activeFormat.videoMaxZoomFactor, CGFloat(5.0))
            let newZoom: CGFloat = min(device.videoZoomFactor + CGFloat(0.5), maxZoom)
            device.videoZoomFactor = newZoom
            device.unlockForConfiguration()
        } catch { }
    }
    
    public func zoomOut() {
        guard let device = currentCamera else { return }
        do {
            try device.lockForConfiguration()
            let newZoom: CGFloat = max(device.videoZoomFactor - CGFloat(0.5), CGFloat(1.0))
            device.videoZoomFactor = newZoom
            device.unlockForConfiguration()
        } catch { }
    }
    
    public func setZoom(factor: CGFloat) {
        guard let device = currentCamera else { return }
        do {
            try device.lockForConfiguration()
            let maxZoom: CGFloat = min(device.activeFormat.videoMaxZoomFactor, CGFloat(5.0))
            let clamped: CGFloat = max(CGFloat(1.0), min(factor, maxZoom))
            device.videoZoomFactor = clamped
            device.unlockForConfiguration()
        } catch { }
    }
    
    // Metodo per collegare la preview video Metal
    public func attachCamera(to view: MTHKView) {
        view.videoGravity = .resizeAspectFill
        view.videoOrientation = .landscapeRight
        view.attachStream(rtmpStream)
        rtmpStream.videoOrientation = .landscapeRight
    }
    
    public func updateOrientation(_ orientation: AVCaptureVideoOrientation) {
        rtmpStream.videoOrientation = orientation
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
            self.isPublishing = true
        }
    }
    
    public func stopStreaming() {
        self.isPublishing = false
        rtmpStream.close()
        rtmpConnection.close()
    }
}
