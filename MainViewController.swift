import UIKit
import HaishinKit

class MainViewController: UIViewController {

    var lfView: MTHKView!
    var scoreboardView: ScoreboardOverlayView!
    
    // UI Controls
    var startStreamButton: UIButton!
    var modeButton: UIButton!
    var shareLiveButton: UIButton!
    var shareRemoteButton: UIButton!
    
    // Grid Overlay
    var gridLayer: CAShapeLayer?
    var currentMode: Int = 0 // 0 = Normal, 1 = Grid, 2 = Clean
    
    var initialSport: String = "volley"
    var initialTheme: String = "neon"
    var sessionId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCameraView()
        setupScoreboardOverlay()
        setupControls()
        setupGridLayer()
        
        FirebaseManager.shared.onStateUpdated = { [weak self] state in
            DispatchQueue.main.async {
                self?.scoreboardView.updateFromState(state)
                StreamManager.shared.videoEffect.currentState = state
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
    
    private func setupGridLayer() {
        let path = UIBezierPath()
        let w = view.bounds.width
        let h = view.bounds.height
        
        path.move(to: CGPoint(x: w/3, y: 0)); path.addLine(to: CGPoint(x: w/3, y: h))
        path.move(to: CGPoint(x: 2*w/3, y: 0)); path.addLine(to: CGPoint(x: 2*w/3, y: h))
        path.move(to: CGPoint(x: 0, y: h/3)); path.addLine(to: CGPoint(x: w, y: h/3))
        path.move(to: CGPoint(x: 0, y: 2*h/3)); path.addLine(to: CGPoint(x: w, y: 2*h/3))
        
        let layer = CAShapeLayer()
        layer.path = path.cgPath
        layer.strokeColor = UIColor.white.withAlphaComponent(0.5).cgColor
        layer.lineWidth = 1
        layer.isHidden = true
        view.layer.addSublayer(layer)
        self.gridLayer = layer
    }
    
    private func handleRemoteCommand(_ command: String) {
        if command == "TRIGGER_REPLAY" {
            ReplayManager.shared.startPlayback()
            if var state = getLocalState() {
                state.isReplaying = true
                FirebaseManager.shared.updateMatchState(state)
            }
        } else if command == "TRIGGER_HIGHLIGHT" {
            // Save highlight locally
        }
    }
    
    private func getLocalState() -> RemoteMatchState? {
        return RemoteMatchState()
    }
    
    private func setupCameraView() {
        lfView = MTHKView(frame: view.bounds)
        lfView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(lfView)
        StreamManager.shared.attachCamera(to: lfView)
    }
    
    private func setupScoreboardOverlay() {
        scoreboardView = ScoreboardOverlayView(frame: CGRect(x: 50, y: 50, width: 400, height: 80))
        view.addSubview(scoreboardView)
        StreamManager.shared.videoEffect.scoreboardView = self.scoreboardView
    }
    
    private func setupControls() {
        let safeY = view.bounds.height - 80
        startStreamButton = UIButton(frame: CGRect(x: view.bounds.width - 200, y: safeY, width: 180, height: 50))
        startStreamButton.setTitle("start_live".localized, for: .normal)
        startStreamButton.backgroundColor = .red
        startStreamButton.layer.cornerRadius = 25
        startStreamButton.addTarget(self, action: #selector(startLive), for: .touchUpInside)
        view.addSubview(startStreamButton)
        
        modeButton = UIButton(frame: CGRect(x: 20, y: safeY, width: 120, height: 50))
        modeButton.setTitle("Normale", for: .normal)
        modeButton.backgroundColor = .darkGray
        modeButton.layer.cornerRadius = 10
        modeButton.addTarget(self, action: #selector(toggleMode), for: .touchUpInside)
        view.addSubview(modeButton)
        
        shareLiveButton = UIButton(frame: CGRect(x: 160, y: safeY, width: 150, height: 50))
        shareLiveButton.setTitle("Share Live", for: .normal)
        shareLiveButton.backgroundColor = .systemBlue
        shareLiveButton.layer.cornerRadius = 10
        shareLiveButton.addTarget(self, action: #selector(shareLive), for: .touchUpInside)
        view.addSubview(shareLiveButton)
        
        shareRemoteButton = UIButton(frame: CGRect(x: 330, y: safeY, width: 150, height: 50))
        shareRemoteButton.setTitle("Share Remote", for: .normal)
        shareRemoteButton.backgroundColor = .systemGreen
        shareRemoteButton.layer.cornerRadius = 10
        shareRemoteButton.addTarget(self, action: #selector(shareRemote), for: .touchUpInside)
        view.addSubview(shareRemoteButton)
    }
    
    @objc func toggleMode() {
        currentMode = (currentMode + 1) % 3
        
        let hideControls = (currentMode == 2)
        startStreamButton.isHidden = hideControls
        shareLiveButton.isHidden = hideControls
        shareRemoteButton.isHidden = hideControls
        // modeButton is always visible to switch back
        
        gridLayer?.isHidden = (currentMode != 1)
        
        switch currentMode {
        case 0: modeButton.setTitle("Normale", for: .normal)
        case 1: modeButton.setTitle("Griglia", for: .normal)
        case 2: modeButton.setTitle("Clean", for: .normal)
        default: break
        }
    }
    
    @objc func shareLive() {
        let link = "https://youtube.com/live/YOUR_STREAM_ID"
        let activity = UIActivityViewController(activityItems: [link], applicationActivities: nil)
        present(activity, animated: true)
    }
    
    @objc func shareRemote() {
        let link = "volleypro://remote?id=\(sessionId ?? "12345")"
        let msg = "Controlla la regia da qui: \(link)"
        let activity = UIActivityViewController(activityItems: [msg], applicationActivities: nil)
        present(activity, animated: true)
    }
    
    @objc func startLive() {
        if startStreamButton.backgroundColor == .red {
            StreamManager.shared.startStreaming(url: "rtmp://a.rtmp.youtube.com/live2", streamKey: "test")
            startStreamButton.setTitle("STOP", for: .normal)
            startStreamButton.backgroundColor = .gray
        } else {
            StreamManager.shared.stopStreaming()
            startStreamButton.setTitle("start_live".localized, for: .normal)
            startStreamButton.backgroundColor = .red
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
}

