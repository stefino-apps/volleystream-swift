import Foundation
import AVFoundation
import UIKit

class ReplayAudioPlayer {
    static let shared = ReplayAudioPlayer()
    private var audioPlayer: AVAudioPlayer?
    
    private init() {
        setupAudioSession()
        prepareSound()
    }
    
    func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .videoRecording, options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers])
            try session.setActive(true)
        } catch {
            print("ReplayAudioPlayer: Setup audio session: \(error)")
        }
    }
    
    func prepareSound() {
        setupAudioSession()
        
        // 1. Cerca replay_swoosh.mp3 nel bundle principale o nelle cartelle dell'app
        var soundUrl = Bundle.main.url(forResource: "replay_swoosh", withExtension: "mp3")
        if soundUrl == nil {
            let directPath = Bundle.main.bundlePath + "/replay_swoosh.mp3"
            if FileManager.default.fileExists(atPath: directPath) {
                soundUrl = URL(fileURLWithPath: directPath)
            }
        }
        
        // 2. Se non presente, genera un file WAV swoosh broadcast in-memory e salvalo in cache
        if soundUrl == nil {
            soundUrl = generateProceduralSwooshWav()
        }
        
        if let soundUrl = soundUrl {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundUrl)
                audioPlayer?.volume = 1.0
                audioPlayer?.prepareToPlay()
            } catch {
                print("ReplayAudioPlayer: Errore inizializzazione player: \(error)")
            }
        }
    }
    
    func playSwoosh() {
        DispatchQueue.main.async {
            let feedback = UIImpactFeedbackGenerator(style: .heavy)
            feedback.impactOccurred()
            
            if self.audioPlayer == nil {
                self.prepareSound()
            }
            self.audioPlayer?.stop()
            self.audioPlayer?.currentTime = 0
            self.audioPlayer?.play()
        }
    }
    
    // Genera un effetto audio whoosh/swoosh broadcast procedurale (16-bit PCM WAV)
    private func generateProceduralSwooshWav() -> URL? {
        let tempDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let wavUrl = tempDir.appendingPathComponent("procedural_replay_swoosh.wav")
        
        if FileManager.default.fileExists(atPath: wavUrl.path) {
            return wavUrl
        }
        
        let sampleRate: Double = 44100.0
        let duration: Double = 0.65 // 650 ms
        let numSamples = Int(sampleRate * duration)
        var pcmData = Data()
        
        for i in 0..<numSamples {
            let t = Double(i) / sampleRate
            let progress = t / duration
            
            // Inviluppo: attacco rapido (0.15s), picco, decadimento morbido (0.5s)
            let envelope: Double
            if progress < 0.25 {
                envelope = progress / 0.25
            } else {
                envelope = pow(1.0 - (progress - 0.25) / 0.75, 1.8)
            }
            
            // Frequenza con sweep esponenziale da 600 Hz a 70 Hz (tipico swoosh TV)
            let freq = 70.0 + 530.0 * pow(1.0 - progress, 2.0)
            let phase = 2.0 * .pi * freq * t
            
            // Rumore bianco filtrato + tono armonico
            let noise = (Double.random(in: -1.0...1.0)) * 0.45
            let tone = sin(phase) * 0.55
            let mixedSample = (tone + noise) * envelope
            
            let sample16 = Int16(max(-32767, min(32767, mixedSample * 30000.0)))
            var littleEndian = sample16.littleEndian
            withUnsafeBytes(of: &littleEndian) { pcmData.append(contentsOf: $0) }
        }
        
        // Costruzione header WAV standard 44.1kHz 16-bit Mono
        var wavHeader = Data()
        wavHeader.append("RIFF".data(using: .ascii)!)
        var fileSize = UInt32(36 + pcmData.count).littleEndian
        withUnsafeBytes(of: &fileSize) { wavHeader.append(contentsOf: $0) }
        wavHeader.append("WAVE".data(using: .ascii)!)
        wavHeader.append("fmt ".data(using: .ascii)!)
        var subchunk1Size = UInt32(16).littleEndian
        withUnsafeBytes(of: &subchunk1Size) { wavHeader.append(contentsOf: $0) }
        var audioFormat = UInt16(1).littleEndian // PCM
        withUnsafeBytes(of: &audioFormat) { wavHeader.append(contentsOf: $0) }
        var numChannels = UInt16(1).littleEndian // Mono
        withUnsafeBytes(of: &numChannels) { wavHeader.append(contentsOf: $0) }
        var sampleRateU32 = UInt32(sampleRate).littleEndian
        withUnsafeBytes(of: &sampleRateU32) { wavHeader.append(contentsOf: $0) }
        var byteRate = UInt32(sampleRate * 2.0).littleEndian
        withUnsafeBytes(of: &byteRate) { wavHeader.append(contentsOf: $0) }
        var blockAlign = UInt16(2).littleEndian
        withUnsafeBytes(of: &blockAlign) { wavHeader.append(contentsOf: $0) }
        var bitsPerSample = UInt16(16).littleEndian
        withUnsafeBytes(of: &bitsPerSample) { wavHeader.append(contentsOf: $0) }
        wavHeader.append("data".data(using: .ascii)!)
        var dataSize = UInt32(pcmData.count).littleEndian
        withUnsafeBytes(of: &dataSize) { wavHeader.append(contentsOf: $0) }
        
        var fullWav = wavHeader
        fullWav.append(pcmData)
        
        do {
            try fullWav.write(to: wavUrl)
            return wavUrl
        } catch {
            print("ReplayAudioPlayer: Errore scrittura wav: \(error)")
            return nil
        }
    }
}

