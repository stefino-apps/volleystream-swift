import UIKit
import HaishinKit

class MainViewController: UIViewController {

    var lfView: MTHKView!
    var scoreboardView: ScoreboardOverlayView!
    
    // UI Controls
    var startStreamButton: UIButton!
    var connectFirebaseButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCameraView()
        setupScoreboardOverlay()
        setupControls()
        
        // Collega Firebase per il controllo remoto
        FirebaseManager.shared.onScoreUpdate = { [weak self] home, away in
            DispatchQueue.main.async {
                self?.scoreboardView.updateScore(home: home, away: away)
            }
        }
        
        FirebaseManager.shared.onSetsUpdate = { [weak self] home, away in
            DispatchQueue.main.async {
                self?.scoreboardView.updateSets(home: home, away: away)
            }
        }
        
        FirebaseManager.shared.onTeamNamesUpdate = { [weak self] home, away in
            DispatchQueue.main.async {
                self?.scoreboardView.updateTeams(home: home, away: away)
            }
        }
    }
    
    private func setupCameraView() {
        lfView = MTHKView(frame: view.bounds)
        lfView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(lfView)
        
        // Inizializza fotocamera
        StreamManager.shared.attachCamera(to: lfView)
    }
    
    private func setupScoreboardOverlay() {
        // Grafica in stile TV
        scoreboardView = ScoreboardOverlayView(frame: CGRect(x: 50, y: 50, width: 400, height: 80))
        view.addSubview(scoreboardView)
    }
    
    private func setupControls() {
        startStreamButton = UIButton(frame: CGRect(x: view.bounds.width - 200, y: view.bounds.height - 80, width: 180, height: 50))
        startStreamButton.setTitle("START LIVE", for: .normal)
        startStreamButton.backgroundColor = .red
        startStreamButton.layer.cornerRadius = 25
        startStreamButton.addTarget(self, action: #selector(startLive), for: .touchUpInside)
        view.addSubview(startStreamButton)
    }
    
    @objc func startLive() {
        if startStreamButton.titleLabel?.text == "START LIVE" {
            // Usa il simulato (o fai login con YouTubeManager)
            StreamManager.shared.startStreaming(url: "rtmp://src1.volleyscout.it/live", streamKey: "test")
            startStreamButton.setTitle("STOP", for: .normal)
            startStreamButton.backgroundColor = .gray
        } else {
            StreamManager.shared.stopStreaming()
            startStreamButton.setTitle("START LIVE", for: .normal)
            startStreamButton.backgroundColor = .red
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
}
