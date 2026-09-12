import Foundation
import CoreImage
import CoreMedia
import AVFoundation
import UIKit
import Photos

class ReplayManager {
    static let shared = ReplayManager()
    
    static var isDeviceSupported: Bool {
        return true
    }
    
    // Configurazione Replay e Highlights
    var replayDuration: Int {
        let d = UserDefaults.standard.integer(forKey: "replay_duration_seconds")
        return d == 0 ? 5 : d
    }
    var highlightDuration: Int {
        let d = UserDefaults.standard.integer(forKey: "highlight_duration_seconds")
        return d == 0 ? 10 : d
    }
    var replaySpeed: Double {
        let s = UserDefaults.standard.double(forKey: "replay_speed_factor")
        return s == 0 ? 0.5 : s
    }
    
    // Callback stato Replay per sincronizzazione UI / Firebase
    var onReplayStateChanged: ((Bool) -> Void)?
    
    // Transizione Stinger (Animazione TV broadcast prima e dopo il replay)
    var stingerStartTime: TimeInterval = 0
    let stingerDuration: TimeInterval = 0.80 // 800ms perfetto per broadcast TV
    var isStingerPlaying: Bool = false
    var isOutroStinger: Bool = false
    
    // Buffer circolare video accelerato via GPU Metal (CVPixelBuffer)
    private var frameBuffer: [CVPixelBuffer] = []
    private var playbackBuffer: [CVPixelBuffer] = []
    private var pixelBufferPool: CVPixelBufferPool?
    
    private var maxFrames: Int {
        let maxSec = max(20, max(replayDuration, highlightDuration))
        return maxSec * 30
    }
    private var isRecording = true
    private var isPlaying = false
    private var playbackFraction: Double = 0.0
    private var lastRecordedTime: TimeInterval = 0
    private var lastPlaybackTime: TimeInterval = 0
    
    // Registrazione continua audio per Highlights
    private var audioRecorder: AVAudioRecorder?
    private var rollingAudioUrl: URL?
    
    private let queue = DispatchQueue(label: "com.volleypro.replayQueue", qos: .userInteractive)
    private let ciContext = CIContext(options: [
        .useSoftwareRenderer: false,
        .priorityRequestLow: false
    ])
    
    private init() {
        setupPixelBufferPool(width: 960, height: 540)
        startRollingAudioRecording()
    }
    
    private func setupPixelBufferPool(width: Int, height: Int) {
        let poolAttributes: [String: Any] = [
            kCVPixelBufferPoolMinimumBufferCountKey as String: 700
        ]
        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        var pool: CVPixelBufferPool?
        let status = CVPixelBufferPoolCreate(kCFAllocatorDefault, poolAttributes as CFDictionary, pixelBufferAttributes as CFDictionary, &pool)
        if status == kCVReturnSuccess {
            self.pixelBufferPool = pool
        }
    }
    
    // MARK: - Registratore Audio Continuo per Highlights
    
    func startRollingAudioRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .videoRecording, options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
            try session.setActive(true)
        } catch {
            print("ReplayManager: Setup audio session error: \(error)")
        }
        
        let tempDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let audioUrl = tempDir.appendingPathComponent("replay_rolling_audio.m4a")
        self.rollingAudioUrl = audioUrl
        
        try? FileManager.default.removeItem(at: audioUrl)
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 128000
        ]
        
        do {
            let recorder = try AVAudioRecorder(url: audioUrl, settings: settings)
            recorder.isMeteringEnabled = false
            recorder.prepareToRecord()
            if recorder.record() {
                self.audioRecorder = recorder
            } else {
                print("ReplayManager: audioRecorder.record() returned false")
            }
        } catch {
            print("ReplayManager: Avvio audio recorder per highlight: \(error)")
        }
    }
    
    func configure(durationSeconds: Int, speedFactor: Double) {
        UserDefaults.standard.set(max(5, min(durationSeconds, 10)), forKey: "replay_duration_seconds")
        UserDefaults.standard.set(speedFactor, forKey: "replay_speed_factor")
    }
    
    // MARK: - Registrazione Frame Live (Zero CPU lag via Metal CVPixelBuffer)
    
    func recordFrame(_ image: CIImage) {
        let now = CACurrentMediaTime()
        // Campiona a ~30 fps
        guard (now - lastRecordedTime) >= 0.030 else { return }
        lastRecordedTime = now
        
        let extent = image.extent
        guard extent.width > 0 && extent.height > 0 else { return }
        
        queue.async { [weak self] in
            guard let self = self, let pool = self.pixelBufferPool else { return }
            
            // Scala a 960x540 direttamente in GPU Metal
            let scaleX = 960.0 / extent.width
            let scaleY = 540.0 / extent.height
            let scaledImage = image.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
            
            var pixelBuffer: CVPixelBuffer?
            let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBuffer)
            
            if status == kCVReturnSuccess, let buffer = pixelBuffer {
                self.ciContext.render(scaledImage, to: buffer)
                self.frameBuffer.append(buffer)
                
                if self.frameBuffer.count > self.maxFrames {
                    self.frameBuffer.removeFirst()
                }
            }
        }
    }
    
    // MARK: - Gestione Playback & Slow Motion
    
    func startPlayback() {
        startReplay()
    }
    
    func startReplay() {
        queue.async {
            guard !self.frameBuffer.isEmpty else { return }
            let count = min(self.replayDuration * 30, self.frameBuffer.count)
            self.playbackBuffer = Array(self.frameBuffer.suffix(count))
            self.isPlaying = true
            self.isStingerPlaying = true
            self.isOutroStinger = false
            self.stingerStartTime = CACurrentMediaTime()
            self.lastPlaybackTime = 0
            self.playbackFraction = 0.0
            
            DispatchQueue.main.async {
                ReplayAudioPlayer.shared.playSwoosh() // Effetto audio SOLO all'inizio del Replay
                self.onReplayStateChanged?(true)
            }
        }
    }
    
    func stopPlayback() {
        stopReplay()
    }
    
    func stopReplay() {
        queue.async {
            if self.isPlaying && !self.isOutroStinger {
                self.triggerOutroStinger()
            } else if !self.isStingerPlaying {
                self.forceStopReplay()
            }
        }
    }
    
    func triggerOutroStinger() {
        queue.async {
            guard self.isPlaying, !self.isOutroStinger else { return }
            self.isStingerPlaying = true
            self.isOutroStinger = true
            self.stingerStartTime = CACurrentMediaTime()
            // Nessun effetto audio in uscita dal replay su richiesta utente
        }
    }
    
    func forceStopReplay() {
        queue.async {
            self.isPlaying = false
            self.isStingerPlaying = false
            self.isOutroStinger = false
            self.isRecording = true
            self.playbackFraction = 0.0
            self.lastPlaybackTime = 0
            self.playbackBuffer.removeAll()
            DispatchQueue.main.async {
                self.onReplayStateChanged?(false)
            }
        }
    }
    
    func getStingerProgress() -> Double {
        var progress: Double = 0.0
        queue.sync {
            if !self.isStingerPlaying { return }
            let elapsed = CACurrentMediaTime() - self.stingerStartTime
            progress = min(max(elapsed / self.stingerDuration, 0.0), 1.0)
        }
        return progress
    }
    
    func getPlaybackFrame() -> CIImage? {
        var frame: CIImage?
        queue.sync {
            guard self.isPlaying, !self.playbackBuffer.isEmpty else { return }
            
            let now = CACurrentMediaTime()
            
            if self.isStingerPlaying {
                let elapsed = now - self.stingerStartTime
                if elapsed >= self.stingerDuration {
                    self.isStingerPlaying = false
                    self.lastPlaybackTime = now
                    if self.isOutroStinger {
                        // Replay terminato: torna alla trasmissione live
                        self.isPlaying = false
                        self.isOutroStinger = false
                        self.isRecording = true
                        self.playbackFraction = 0.0
                        self.lastPlaybackTime = 0
                        self.playbackBuffer.removeAll()
                        DispatchQueue.main.async {
                            self.onReplayStateChanged?(false)
                        }
                        return
                    }
                } else {
                    if !self.isOutroStinger {
                        // Durante l'intro stinger mostra il primo frame dell'azione
                        if let firstBuf = self.playbackBuffer.first {
                            frame = CIImage(cvPixelBuffer: firstBuf).transformed(by: CGAffineTransform(scaleX: 2.0, y: 2.0))
                        }
                        return
                    }
                }
            }
            
            let idx = min(Int(self.playbackFraction), self.playbackBuffer.count - 1)
            let buffer = self.playbackBuffer[idx]
            frame = CIImage(cvPixelBuffer: buffer).transformed(by: CGAffineTransform(scaleX: 2.0, y: 2.0))
            
            // Avanzamento a tempo reale calibrato per il vero RALLENTATORE (Slow Motion)
            let dt: Double
            if self.lastPlaybackTime == 0 {
                dt = 0.016 // ~60fps step
            } else {
                dt = min(max(now - self.lastPlaybackTime, 0.001), 0.050)
            }
            self.lastPlaybackTime = now
            
            // 30 frame/secondo registrati: a 0.5x avanziamo di 15 frame ogni secondo di orologio
            let deltaFrames = dt * 30.0 * self.replaySpeed
            self.playbackFraction += deltaFrames
            
            if Int(self.playbackFraction) >= self.playbackBuffer.count {
                // Raggiunta la fine dell'azione: attiva lo stinger in uscita (Outro verso LIVE)
                if !self.isOutroStinger {
                    self.isStingerPlaying = true
                    self.isOutroStinger = true
                    self.stingerStartTime = CACurrentMediaTime()
                    // Nessun audio swoosh in uscita dal replay
                }
            }
        }
        return frame
    }
    
    var isReplaying: Bool {
        var playing = false
        queue.sync { playing = self.isPlaying }
        return playing
    }
    
    var isStingerActive: Bool {
        var active = false
        queue.sync { active = self.isStingerPlaying }
        return active
    }
    
    var isOutroActive: Bool {
        var outro = false
        queue.sync { outro = self.isOutroStinger }
        return outro
    }
    
    // MARK: - Salvataggio Highlight in Galleria con AUDIO Completo
    
    func saveHighlightClip(completion: @escaping (Bool, String?) -> Void) {
        queue.async {
            // 1. Ferma e finalizza la registrazione audio per scrivere l'header moov
            self.audioRecorder?.stop()
            self.audioRecorder = nil
            
            let tempDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            let timestamp = Int(Date().timeIntervalSince1970)
            let highlightAudioUrl = tempDir.appendingPathComponent("HighlightAudio_\(timestamp).m4a")
            
            if let rollingUrl = self.rollingAudioUrl, FileManager.default.fileExists(atPath: rollingUrl.path) {
                try? FileManager.default.copyItem(at: rollingUrl, to: highlightAudioUrl)
            }
            
            // 2. Riavvia immediatamente la registrazione audio rolling per i prossimi highlight
            self.startRollingAudioRecording()
            
            let availableFrames = self.frameBuffer.isEmpty ? self.playbackBuffer : self.frameBuffer
            let hlFrameCount = min(self.highlightDuration * 30, availableFrames.count)
            let framesToExport = Array(availableFrames.suffix(hlFrameCount))
            guard !framesToExport.isEmpty else {
                try? FileManager.default.removeItem(at: highlightAudioUrl)
                DispatchQueue.main.async { completion(false, "Nessun frame registrato per l'highlight") }
                return
            }
            
            let tempVideoUrl = tempDir.appendingPathComponent("TempHighlightVideo_\(timestamp).mp4")
            let finalOutputUrl = tempDir.appendingPathComponent("Highlight_\(timestamp).mp4")
            
            try? FileManager.default.removeItem(at: tempVideoUrl)
            try? FileManager.default.removeItem(at: finalOutputUrl)
            
            do {
                let assetWriter = try AVAssetWriter(outputURL: tempVideoUrl, fileType: .mp4)
                let videoSettings: [String: Any] = [
                    AVVideoCodecKey: AVVideoCodecType.h264,
                    AVVideoWidthKey: 1920,
                    AVVideoHeightKey: 1080
                ]
                let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
                videoInput.expectsMediaDataInRealTime = false
                
                let sourcePixelBufferAttributes: [String: Any] = [
                    kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
                    kCVPixelBufferWidthKey as String: 1920,
                    kCVPixelBufferHeightKey as String: 1080
                ]
                let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput, sourcePixelBufferAttributes: sourcePixelBufferAttributes)
                
                if assetWriter.canAdd(videoInput) {
                    assetWriter.add(videoInput)
                }
                
                assetWriter.startWriting()
                assetWriter.startSession(atSourceTime: .zero)
                
                let fps: Int64 = 30
                var frameIndex: Int64 = 0
                
                for buffer in framesToExport {
                    while !videoInput.isReadyForMoreMediaData {
                        Thread.sleep(forTimeInterval: 0.005)
                    }
                    
                    if let pool = adaptor.pixelBufferPool {
                        var targetBuffer: CVPixelBuffer?
                        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &targetBuffer)
                        if let tb = targetBuffer {
                            let srcImg = CIImage(cvPixelBuffer: buffer).transformed(by: CGAffineTransform(scaleX: 2.0, y: 2.0))
                            self.ciContext.render(srcImg, to: tb)
                            let presentTime = CMTimeMake(value: frameIndex, timescale: Int32(fps))
                            adaptor.append(tb, withPresentationTime: presentTime)
                            frameIndex += 1
                        }
                    }
                }
                
                videoInput.markAsFinished()
                assetWriter.finishWriting { [weak self] in
                    guard let self = self else { return }
                    
                    // Unisci l'audio registrato dal rolling recorder con la clip video
                    self.mergeHighlightAudioAndVideo(videoUrl: tempVideoUrl, audioUrl: highlightAudioUrl, videoDurationSeconds: Double(framesToExport.count) / 30.0, outputUrl: finalOutputUrl) { success in
                        let targetUrl = success ? finalOutputUrl : tempVideoUrl
                        
                        PHPhotoLibrary.requestAuthorization { status in
                            if status == .authorized || status == .limited {
                                PHPhotoLibrary.shared().performChanges({
                                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: targetUrl)
                                }) { saved, error in
                                    try? FileManager.default.removeItem(at: tempVideoUrl)
                                    try? FileManager.default.removeItem(at: highlightAudioUrl)
                                    if success { try? FileManager.default.removeItem(at: finalOutputUrl) }
                                    
                                    DispatchQueue.main.async {
                                        completion(saved, error?.localizedDescription)
                                    }
                                }
                            } else {
                                if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(targetUrl.path) {
                                    UISaveVideoAtPathToSavedPhotosAlbum(targetUrl.path, nil, nil, nil)
                                    try? FileManager.default.removeItem(at: highlightAudioUrl)
                                    DispatchQueue.main.async { completion(true, nil) }
                                } else {
                                    try? FileManager.default.removeItem(at: highlightAudioUrl)
                                    DispatchQueue.main.async { completion(false, "Permesso galleria non concesso") }
                                }
                            }
                        }
                    }
                }
                
            } catch {
                try? FileManager.default.removeItem(at: highlightAudioUrl)
                DispatchQueue.main.async { completion(false, error.localizedDescription) }
            }
        }
    }
    
    private func mergeHighlightAudioAndVideo(videoUrl: URL, audioUrl: URL, videoDurationSeconds: Double, outputUrl: URL, completion: @escaping (Bool) -> Void) {
        guard FileManager.default.fileExists(atPath: audioUrl.path) else {
            completion(false)
            return
        }
        
        let composition = AVMutableComposition()
        let videoAsset = AVURLAsset(url: videoUrl)
        let audioAsset = AVURLAsset(url: audioUrl)
        
        guard let compVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            completion(false)
            return
        }
        
        let videoDuration = videoAsset.duration
        let videoTimeRange = CMTimeRange(start: .zero, duration: videoDuration)
        
        if let sourceVideoTrack = videoAsset.tracks(withMediaType: .video).first {
            try? compVideoTrack.insertTimeRange(videoTimeRange, of: sourceVideoTrack, at: .zero)
            compVideoTrack.preferredTransform = sourceVideoTrack.preferredTransform
        }
        
        // Estrai gli ultimi N secondi di audio corrispondenti alla durata del video
        if let sourceAudioTrack = audioAsset.tracks(withMediaType: .audio).first {
            if let compAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                let audioTotalSec = CMTimeGetSeconds(audioAsset.duration)
                let clipDuration = CMTimeGetSeconds(videoDuration)
                let audioStartSec = max(0.0, audioTotalSec - clipDuration)
                
                let startCM = CMTime(seconds: audioStartSec, preferredTimescale: 44100)
                let durCM = CMTime(seconds: min(clipDuration, audioTotalSec), preferredTimescale: 44100)
                let audioRange = CMTimeRange(start: startCM, duration: durCM)
                
                try? compAudioTrack.insertTimeRange(audioRange, of: sourceAudioTrack, at: .zero)
            }
        }
        
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            completion(false)
            return
        }
        
        exportSession.outputURL = outputUrl
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        exportSession.exportAsynchronously {
            completion(exportSession.status == .completed)
        }
    }
}


