import Foundation
import AVFoundation

class ReplayAudioPlayer {
    static let shared = ReplayAudioPlayer()
    private var audioPlayer: AVAudioPlayer?
    
    private init() {
        prepareSound()
    }
    
    func prepareSound() {
        var url = Bundle.main.url(forResource: "replay_swoosh", withExtension: "mp3")
        if url == nil {
            let directPath = Bundle.main.bundlePath + "/replay_swoosh.mp3"
            if FileManager.default.fileExists(atPath: directPath) {
                url = URL(fileURLWithPath: directPath)
            }
        }
        
        if let soundUrl = url {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
                try AVAudioSession.sharedInstance().setActive(true)
                audioPlayer = try AVAudioPlayer(contentsOf: soundUrl)
                audioPlayer?.volume = 1.0
                audioPlayer?.prepareToPlay()
            } catch {
                print("Errore caricamento audio swoosh: \(error)")
            }
        }
    }
    
    func playSwoosh() {
        if audioPlayer == nil {
            prepareSound()
        }
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        audioPlayer?.play()
    }
}
