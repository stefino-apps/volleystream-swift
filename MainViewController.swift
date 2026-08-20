import UIKit
import HaishinKit

class MainViewController: UIViewController {

    var initialSport: String = "volley"
    var initialTheme: String = "neon"

    var lfView: MTHKView!
    var scoreboardView: ScoreboardOverlayView!
    
    // UI Controls
    var startStreamButton: UIButton!
    var sessionId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCameraView()
        setupScoreboardOverlay(); StreamManager.shared.videoEffect.scoreboardView = self.scoreboardView
        setupControls()
        
        // Collega Firebase per la regia
        FirebaseManager.shared.onStateUpdated = { [weak self] state in
            DispatchQueue.main.async {
                self?.scoreboardView.updateFromState(state); StreamManager.shared.videoEffect.currentState = state
                
                if state.isReplaying {
                    ReplayManager.shared.startPlayback()
                }
            }
        }
        
        FirebaseManager.shared.onCommandReceived = { [weak self] command in
            DispatchQueue.main.async {
                self?.handleRemoteCommand(command)
            }
        }
    }
    
    private func handleRemoteCommand(_ command: String) {
        if command == "TRIGGER_REPLAY" {
            ReplayManager.shared.startPlayback()
            // Se siamo l host, aggiorniamo lo stato
            if var state = getLocalState() {
                state.isReplaying = true
                FirebaseManager.shared.updateMatchState(state)
            }
        } else if command == "TRIGGER_HIGHLIGHT" {
            // Save highlight locally
        }
    }
    
    private func getLocalState() -> RemoteMatchState? {
        // In una vera app, mantenere il riferimento allo stato corrente
        return RemoteMatchState()
    }
    
    private func setupCameraView() {
        lfView = MTHKView(frame: view.bounds)
        lfView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(lfView)
        
        StreamManager.shared.attachCamera(to: lfView)
    }
    
    private func setupScoreboardOverlay(); StreamManager.shared.videoEffect.scoreboardView = self.scoreboardView {
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

