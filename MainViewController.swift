import UIKit
import HaishinKit
import AVFoundation

class MainViewController: UIViewController {

    var lfView: MTHKView!
    var scoreboardView: ScoreboardOverlayView!
    
    // Top Bar UI Controls
    var closeButton: UIButton!
    var modeButton: UIButton!
    var shareLiveButton: UIButton!
    var shareRemoteButton: UIButton!
    var replayButton: UIButton!
    var highlightButton: UIButton!
    
    // Bottom Center UI Controls
    var startStreamButton: UIButton!
    var muteButton: UIButton!
    var sponsorButton: UIButton!
    
    // Left (Team A / Home) Controls
    var btnScoreHome: UIButton!
    var btnMinusHome: UIButton!
    var btnTimeoutHome: UIButton!
    var btnScoreHome2: UIButton!
    var btnScoreHome3: UIButton!
    
    // Right (Team B / Away) Controls
    var btnScoreAway: UIButton!
    var btnMinusAway: UIButton!
    var btnTimeoutAway: UIButton!
    var btnScoreAway2: UIButton!
    var btnScoreAway3: UIButton!
    
    // Center Action Button
    var btnEndQuarter: UIButton!
    
    // Zoom Controls
    var zoomInButton: UIButton!
    var zoomOutButton: UIButton!
    
    // Clean mode tap recognizer
    var backgroundTapGesture: UITapGestureRecognizer?
    
    // Grid Overlay
    var gridLayer: CAShapeLayer?
    var currentMode: Int = 0 // 0 = Normal, 1 = Clean, 2 = Grid
    
    // Grid Mode 4-Quadrant UI
    var gridContainerTR: UIView!
    var gridContainerBL: UIView!
    var gridContainerBR: UIView!
    var lblTeamAGrid: UILabel!
    var lblScoreAGrid: UILabel!
    var lblTeamBGrid: UILabel!
    var lblScoreBGrid: UILabel!
    var btnSetMinusGrid: UIButton!
    var lblSetGrid: UILabel!
    var btnSetPlusGrid: UIButton!
    
    var initialSport: String = "volley"
    var initialTheme: String = "neon"
    var sessionId: String?
    var onDismissRequested: (() -> Void)?
    
    var localState = RemoteMatchState()
    var isAudioMuted = false
    private var stateHistory: [RemoteMatchState] = []
    
    // MARK: - Lifecycle & Orientation
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .landscapeRight
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        AppDelegate.setOrientationLock(.landscape, rotateTo: .landscapeRight)
        StreamManager.shared.updateOrientation(.landscapeRight)
        refreshMatchState()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AppDelegate.setOrientationLock(.landscape, rotateTo: .landscapeRight)
        StreamManager.shared.updateOrientation(.landscapeRight)
        refreshMatchState()
        layoutAllViews()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard let self = self else { return }
            self.layoutAllViews()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AppDelegate.setOrientationLock(.allButUpsideDown, rotateTo: .portrait)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] _ in
            let orient: AVCaptureVideoOrientation = (UIDevice.current.orientation == .landscapeLeft) ? .landscapeLeft : .landscapeRight
            StreamManager.shared.updateOrientation(orient)
            self?.layoutAllViews()
        }) { [weak self] _ in
            self?.layoutAllViews()
        }
    }
    
    func refreshMatchState() {
        self.localState.sportType = AppPreferences.shared.selectedSport
        self.localState.overlayTheme = AppPreferences.shared.selectedTheme
        self.localState.teamA = AppPreferences.shared.teamHome
        self.localState.teamB = AppPreferences.shared.teamAway
        self.localState.isPuntoDeOro = UserDefaults.standard.bool(forKey: "punto_de_oro")
        
        if self.localState.sportType.lowercased() == "darts" {
            let startScore = UserDefaults.standard.integer(forKey: "darts_initial_score")
            let initial = (startScore == 301) ? 301 : 501
            if self.localState.scoreA == 0 && self.localState.scoreB == 0 {
                self.localState.scoreA = initial
                self.localState.scoreB = initial
                self.localState.dartsActivePlayer = "A"
            }
        }
        updateLocalState()
    }
    
    private func forceLandscapeOrientation() {
        AppDelegate.setOrientationLock(.landscape, rotateTo: .landscapeRight)
    }
    
    private func forcePortraitOrientation() {
        AppDelegate.setOrientationLock(.allButUpsideDown, rotateTo: .portrait)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        self.localState.sportType = AppPreferences.shared.selectedSport
        self.localState.overlayTheme = AppPreferences.shared.selectedTheme
        self.localState.teamA = AppPreferences.shared.teamHome
        self.localState.teamB = AppPreferences.shared.teamAway
        self.localState.isPuntoDeOro = UserDefaults.standard.bool(forKey: "punto_de_oro")
        
        if self.localState.sportType.lowercased() == "darts" {
            let startScore = UserDefaults.standard.integer(forKey: "darts_initial_score")
            let initial = (startScore == 301) ? 301 : 501
            self.localState.scoreA = initial
            self.localState.scoreB = initial
            self.localState.dartsActivePlayer = "A"
        }
        
        setupCameraView()
        setupScoreboardOverlay()
        setupControls()
        setupGridLayer()
        updateLocalState()
        
        // Gestore tap a schermo intero per Clean Mode
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleScreenTap))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        self.backgroundTapGesture = tap
        
        let sessionId = UserDefaults.standard.string(forKey: "remote_session_id") ?? "REGIA_01"
        FirebaseManager.shared.createSession(id: sessionId, initialState: self.localState) { success in
            print("Firebase Host Session Created: \(success)")
        }
        
        FirebaseManager.shared.onStateUpdated = { [weak self] state in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.localState = state
                self.scoreboardView.updateFromState(state)
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutAllViews()
    }
    
    // MARK: - Setup Views
    
    private func setupCameraView() {
        lfView = MTHKView(frame: view.bounds)
        lfView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        lfView.videoGravity = AVLayerVideoGravity.resizeAspectFill
        view.addSubview(lfView)
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        lfView.addGestureRecognizer(pinch)
        
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                AVCaptureDevice.requestAccess(for: .audio) { _ in
                    DispatchQueue.main.async {
                        StreamManager.shared.attachDevices()
                        StreamManager.shared.attachCamera(to: self.lfView)
                    }
                }
            }
        }
    }
    
    private func setupScoreboardOverlay() {
        scoreboardView = ScoreboardOverlayView(frame: CGRect(x: 20, y: 15, width: 280, height: 54))
        view.addSubview(scoreboardView)
        StreamManager.shared.videoEffect.scoreboardView = self.scoreboardView
    }
    
    private func setupGridLayer() {
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor.white.withAlphaComponent(0.4).cgColor
        layer.lineWidth = 1
        layer.isHidden = true
        view.layer.addSublayer(layer)
        self.gridLayer = layer
    }
    
    private func updateGridPath() {
        guard let layer = gridLayer else { return }
        let path = UIBezierPath()
        let w = view.bounds.width
        let h = view.bounds.height
        
        path.move(to: CGPoint(x: w/3, y: 0)); path.addLine(to: CGPoint(x: w/3, y: h))
        path.move(to: CGPoint(x: 2*w/3, y: 0)); path.addLine(to: CGPoint(x: 2*w/3, y: h))
        path.move(to: CGPoint(x: 0, y: h/3)); path.addLine(to: CGPoint(x: w, y: h/3))
        path.move(to: CGPoint(x: 0, y: 2*h/3)); path.addLine(to: CGPoint(x: w, y: 2*h/3))
        
        layer.path = path.cgPath
    }
    
    // MARK: - Setup Controls
    
    private func setupControls() {
        let darkBg = UIColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.85)
        
        // 1. Close Button (Exit Regia)
        closeButton = createButton(title: nil, systemImage: "xmark", bgColor: UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.9), tintColor: .white, radius: 12)
        closeButton.addTarget(self, action: #selector(confirmExit), for: .touchUpInside)
        view.addSubview(closeButton)
        
        // 2. Mode Button (L/G/C)
        modeButton = createButton(title: "L", systemImage: nil, bgColor: UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0), tintColor: .black, radius: 12)
        modeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        modeButton.setTitleColor(.black, for: .normal)
        modeButton.addTarget(self, action: #selector(toggleMode), for: .touchUpInside)
        view.addSubview(modeButton)
        
        // 3. Share Live
        shareLiveButton = createButton(title: nil, systemImage: "square.and.arrow.up", bgColor: darkBg, tintColor: UIColor(red: 74/255, green: 222/255, blue: 128/255, alpha: 1.0), radius: 12)
        shareLiveButton.addTarget(self, action: #selector(shareLive), for: .touchUpInside)
        view.addSubview(shareLiveButton)
        
        // 4. Share Remote
        shareRemoteButton = createButton(title: "R.C.", systemImage: nil, bgColor: darkBg, tintColor: .white, radius: 12)
        shareRemoteButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        shareRemoteButton.addTarget(self, action: #selector(shareRemote), for: .touchUpInside)
        view.addSubview(shareRemoteButton)
        
        // 5. Replay Button
        replayButton = createButton(title: "REP", systemImage: nil, bgColor: UIColor(red: 37/255, green: 99/255, blue: 235/255, alpha: 0.9), tintColor: .white, radius: 12)
        replayButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
        replayButton.addTarget(self, action: #selector(triggerReplay), for: .touchUpInside)
        view.addSubview(replayButton)
        
        // 6. Highlight Button
        highlightButton = createButton(title: "HL", systemImage: nil, bgColor: darkBg, tintColor: UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0), radius: 12)
        highlightButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        highlightButton.setTitleColor(UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0), for: .normal)
        highlightButton.addTarget(self, action: #selector(triggerHighlight), for: .touchUpInside)
        view.addSubview(highlightButton)
        
        // Zoom Controls
        zoomInButton = createButton(title: "+", systemImage: nil, bgColor: darkBg, tintColor: UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 1.0), radius: 8)
        zoomInButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        zoomInButton.addTarget(self, action: #selector(zoomIn), for: .touchUpInside)
        view.addSubview(zoomInButton)
        
        zoomOutButton = createButton(title: "−", systemImage: nil, bgColor: darkBg, tintColor: UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 1.0), radius: 8)
        zoomOutButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        zoomOutButton.addTarget(self, action: #selector(zoomOut), for: .touchUpInside)
        view.addSubview(zoomOutButton)
        
        // Center Controls
        startStreamButton = UIButton(type: .system)
        startStreamButton.setTitle("GO\nLIVE", for: .normal)
        startStreamButton.titleLabel?.numberOfLines = 2
        startStreamButton.titleLabel?.textAlignment = .center
        startStreamButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
        startStreamButton.setTitleColor(.white, for: .normal)
        startStreamButton.backgroundColor = UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1.0)
        startStreamButton.layer.cornerRadius = 14
        startStreamButton.layer.borderWidth = 2
        startStreamButton.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        startStreamButton.addTarget(self, action: #selector(startLive), for: .touchUpInside)
        view.addSubview(startStreamButton)
        
        muteButton = createButton(title: nil, systemImage: "speaker.wave.2.fill", bgColor: darkBg, tintColor: UIColor(red: 56/255, green: 189/255, blue: 248/255, alpha: 1.0), radius: 14)
        muteButton.addTarget(self, action: #selector(toggleMute), for: .touchUpInside)
        view.addSubview(muteButton)
        
        sponsorButton = createButton(title: "S", systemImage: nil, bgColor: darkBg, tintColor: UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0), radius: 14)
        sponsorButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        sponsorButton.setTitleColor(UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0), for: .normal)
        sponsorButton.addTarget(self, action: #selector(toggleSponsor), for: .touchUpInside)
        view.addSubview(sponsorButton)
        
        // Team A (Home) Buttons
        btnScoreHome = UIButton(type: .system)
        btnScoreHome.setTitle("+1", for: .normal)
        btnScoreHome.titleLabel?.font = UIFont.boldSystemFont(ofSize: 30)
        btnScoreHome.setTitleColor(.white, for: .normal)
        btnScoreHome.backgroundColor = UIColor(red: 236/255, green: 72/255, blue: 153/255, alpha: 0.95)
        btnScoreHome.layer.cornerRadius = 20
        btnScoreHome.layer.borderWidth = 2
        btnScoreHome.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        btnScoreHome.addTarget(self, action: #selector(incScoreA), for: .touchUpInside)
        
        let longPressA = UILongPressGestureRecognizer(target: self, action: #selector(setServeA(_:)))
        btnScoreHome.addGestureRecognizer(longPressA)
        view.addSubview(btnScoreHome)
        
        btnTimeoutHome = createButton(title: "T.O.", systemImage: nil, bgColor: darkBg, tintColor: .white, radius: 10)
        btnTimeoutHome.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
        btnTimeoutHome.addTarget(self, action: #selector(toA), for: .touchUpInside)
        view.addSubview(btnTimeoutHome)
        
        btnMinusHome = createButton(title: "−", systemImage: nil, bgColor: darkBg, tintColor: .white, radius: 10)
        btnMinusHome.titleLabel?.font = UIFont.boldSystemFont(ofSize: 22)
        btnMinusHome.addTarget(self, action: #selector(decScoreA), for: .touchUpInside)
        view.addSubview(btnMinusHome)
        
        // Team B (Away) Buttons
        btnScoreAway = UIButton(type: .system)
        btnScoreAway.setTitle("+1", for: .normal)
        btnScoreAway.titleLabel?.font = UIFont.boldSystemFont(ofSize: 30)
        btnScoreAway.setTitleColor(.white, for: .normal)
        btnScoreAway.backgroundColor = UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 0.95)
        btnScoreAway.layer.cornerRadius = 20
        btnScoreAway.layer.borderWidth = 2
        btnScoreAway.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        btnScoreAway.addTarget(self, action: #selector(incScoreB), for: .touchUpInside)
        
        let longPressB = UILongPressGestureRecognizer(target: self, action: #selector(setServeB(_:)))
        btnScoreAway.addGestureRecognizer(longPressB)
        view.addSubview(btnScoreAway)
        
        btnTimeoutAway = createButton(title: "T.O.", systemImage: nil, bgColor: darkBg, tintColor: .white, radius: 10)
        btnTimeoutAway.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
        btnTimeoutAway.addTarget(self, action: #selector(toB), for: .touchUpInside)
        view.addSubview(btnTimeoutAway)
        
        btnMinusAway = createButton(title: "−", systemImage: nil, bgColor: darkBg, tintColor: .white, radius: 10)
        btnMinusAway.titleLabel?.font = UIFont.boldSystemFont(ofSize: 22)
        btnMinusAway.addTarget(self, action: #selector(decScoreB), for: .touchUpInside)
        view.addSubview(btnMinusAway)
        
        // Basket Specific Buttons
        btnScoreHome2 = createButton(title: "+2", systemImage: nil, bgColor: UIColor(red: 236/255, green: 72/255, blue: 153/255, alpha: 0.85), tintColor: .white, radius: 10)
        btnScoreHome2.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        btnScoreHome2.addTarget(self, action: #selector(incScoreA2), for: .touchUpInside)
        view.addSubview(btnScoreHome2)
        
        btnScoreHome3 = createButton(title: "+3", systemImage: nil, bgColor: UIColor(red: 236/255, green: 72/255, blue: 153/255, alpha: 0.85), tintColor: .white, radius: 10)
        btnScoreHome3.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        btnScoreHome3.addTarget(self, action: #selector(incScoreA3), for: .touchUpInside)
        view.addSubview(btnScoreHome3)
        
        btnScoreAway2 = createButton(title: "+2", systemImage: nil, bgColor: UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 0.85), tintColor: .white, radius: 10)
        btnScoreAway2.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        btnScoreAway2.addTarget(self, action: #selector(incScoreB2), for: .touchUpInside)
        view.addSubview(btnScoreAway2)
        
        btnScoreAway3 = createButton(title: "+3", systemImage: nil, bgColor: UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 0.85), tintColor: .white, radius: 10)
        btnScoreAway3.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        btnScoreAway3.addTarget(self, action: #selector(incScoreB3), for: .touchUpInside)
        view.addSubview(btnScoreAway3)
        
        // End Quarter / Period Button
        btnEndQuarter = createButton(title: "FINE QUARTO", systemImage: nil, bgColor: UIColor(red: 147/255, green: 51/255, blue: 234/255, alpha: 0.9), tintColor: .white, radius: 10)
        btnEndQuarter.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        btnEndQuarter.addTarget(self, action: #selector(endQuarter), for: .touchUpInside)
        view.addSubview(btnEndQuarter)
        
        // MARK: - Grid Mode 4-Quadrant UI Elements
        gridContainerTR = UIView()
        gridContainerTR.backgroundColor = UIColor(red: 24/255, green: 24/255, blue: 27/255, alpha: 0.95)
        gridContainerTR.layer.cornerRadius = 14
        gridContainerTR.layer.borderWidth = 1
        gridContainerTR.layer.borderColor = UIColor(red: 39/255, green: 39/255, blue: 42/255, alpha: 1.0).cgColor
        gridContainerTR.isHidden = true
        view.insertSubview(gridContainerTR, belowSubview: closeButton)
        
        gridContainerBL = UIView()
        gridContainerBL.backgroundColor = UIColor(red: 24/255, green: 24/255, blue: 27/255, alpha: 0.95)
        gridContainerBL.layer.cornerRadius = 14
        gridContainerBL.layer.borderWidth = 1.5
        gridContainerBL.layer.borderColor = UIColor(red: 236/255, green: 72/255, blue: 153/255, alpha: 0.4).cgColor
        gridContainerBL.isHidden = true
        view.insertSubview(gridContainerBL, belowSubview: btnScoreHome)
        
        gridContainerBR = UIView()
        gridContainerBR.backgroundColor = UIColor(red: 24/255, green: 24/255, blue: 27/255, alpha: 0.95)
        gridContainerBR.layer.cornerRadius = 14
        gridContainerBR.layer.borderWidth = 1.5
        gridContainerBR.layer.borderColor = UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 0.4).cgColor
        gridContainerBR.isHidden = true
        view.insertSubview(gridContainerBR, belowSubview: btnScoreAway)
        
        lblTeamAGrid = UILabel()
        lblTeamAGrid.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        lblTeamAGrid.textColor = UIColor(red: 236/255, green: 72/255, blue: 153/255, alpha: 1.0)
        lblTeamAGrid.text = "HOME"
        lblTeamAGrid.isHidden = true
        view.addSubview(lblTeamAGrid)
        
        lblScoreAGrid = UILabel()
        lblScoreAGrid.font = UIFont.systemFont(ofSize: 26, weight: .heavy)
        lblScoreAGrid.textColor = .white
        lblScoreAGrid.textAlignment = .right
        lblScoreAGrid.text = "0"
        lblScoreAGrid.isHidden = true
        view.addSubview(lblScoreAGrid)
        
        lblTeamBGrid = UILabel()
        lblTeamBGrid.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        lblTeamBGrid.textColor = UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 1.0)
        lblTeamBGrid.text = "GUEST"
        lblTeamBGrid.isHidden = true
        view.addSubview(lblTeamBGrid)
        
        lblScoreBGrid = UILabel()
        lblScoreBGrid.font = UIFont.systemFont(ofSize: 26, weight: .heavy)
        lblScoreBGrid.textColor = .white
        lblScoreBGrid.textAlignment = .right
        lblScoreBGrid.text = "0"
        lblScoreBGrid.isHidden = true
        view.addSubview(lblScoreBGrid)
        
        btnSetMinusGrid = createButton(title: "−", systemImage: nil, bgColor: UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1.0), tintColor: .white, radius: 10)
        btnSetMinusGrid.titleLabel?.font = UIFont.boldSystemFont(ofSize: 22)
        btnSetMinusGrid.addTarget(self, action: #selector(decSetAction), for: .touchUpInside)
        btnSetMinusGrid.isHidden = true
        view.addSubview(btnSetMinusGrid)
        
        lblSetGrid = UILabel()
        lblSetGrid.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        lblSetGrid.textColor = UIColor(red: 226/255, green: 232/255, blue: 240/255, alpha: 1.0)
        lblSetGrid.textAlignment = .center
        lblSetGrid.text = "SET 1"
        lblSetGrid.isHidden = true
        view.addSubview(lblSetGrid)
        
        btnSetPlusGrid = createButton(title: "+", systemImage: nil, bgColor: UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0), tintColor: .black, radius: 10)
        btnSetPlusGrid.titleLabel?.font = UIFont.boldSystemFont(ofSize: 22)
        btnSetPlusGrid.setTitleColor(.black, for: .normal)
        btnSetPlusGrid.addTarget(self, action: #selector(incSetAction), for: .touchUpInside)
        btnSetPlusGrid.isHidden = true
        view.addSubview(btnSetPlusGrid)
    }
    
    private func createButton(title: String?, systemImage: String?, bgColor: UIColor, tintColor: UIColor, radius: CGFloat) -> UIButton {
        let btn = UIButton(type: .system)
        if let title = title {
            btn.setTitle(title, for: .normal)
        }
        if let systemImage = systemImage {
            btn.setImage(UIImage(systemName: systemImage), for: .normal)
        }
        btn.tintColor = tintColor
        btn.setTitleColor(tintColor, for: .normal)
        btn.backgroundColor = bgColor
        btn.layer.cornerRadius = radius
        btn.clipsToBounds = true
        return btn
    }
    
    // MARK: - Dynamic Layout Function (No Overlaps, Safe Area Aware)
    
    private func layoutAllViews() {
        let w = view.bounds.width
        let h = view.bounds.height
        guard w > 0, h > 0 else { return }
        
        let safe = view.safeAreaInsets
        let safeTop = max(safe.top, 8)
        let safeBottom = max(safe.bottom, 12)
        let safeLeft = max(safe.left, 16)
        let safeRight = max(safe.right, 16)
        
        updateGridPath()
        
        // Mode 0: Normal ("L"), Mode 1: Grid ("G"), Mode 2: Clean ("C")
        let isGrid = (currentMode == 1)
        let isClean = (currentMode == 2)
        
        let allControls: [UIView] = [
            closeButton, modeButton, shareLiveButton, shareRemoteButton, replayButton, highlightButton,
            zoomInButton, zoomOutButton, startStreamButton, muteButton, sponsorButton,
            btnScoreHome, btnTimeoutHome, btnMinusHome, btnScoreAway, btnTimeoutAway, btnMinusAway,
            btnScoreHome2, btnScoreHome3, btnScoreAway2, btnScoreAway3, btnEndQuarter,
            gridContainerTR, gridContainerBL, gridContainerBR,
            lblTeamAGrid, lblScoreAGrid, lblTeamBGrid, lblScoreBGrid,
            btnSetMinusGrid, lblSetGrid, btnSetPlusGrid
        ]
        
        if isClean {
            lfView.frame = view.bounds
            lfView.layer.cornerRadius = 0
            scoreboardView.transform = .identity
            scoreboardView.frame = CGRect(x: safeLeft, y: safeTop, width: 280, height: 54)
            scoreboardView.isHidden = false
            gridLayer?.isHidden = true
            allControls.forEach { $0.isHidden = true }
            return
        }
        
        let isBasket = (self.localState.sportType.lowercased() == "basket")
        let isSoccer = (self.localState.sportType.lowercased() == "soccer")
        let isBiliardo = (self.localState.sportType.lowercased() == "biliardo" || self.localState.sportType.lowercased() == "billiards")
        let isTennis = (self.localState.sportType.lowercased() == "tennis" || self.localState.sportType.lowercased() == "padel")
        let isDarts = (self.localState.sportType.lowercased() == "darts")
        let hasExtraScoreBtns = isBasket || isDarts
        
        // Dynamic labels for sports
        if isSoccer {
            btnTimeoutHome.setTitle("RC", for: .normal)
            btnTimeoutHome.backgroundColor = .systemRed
            btnTimeoutAway.setTitle("RC", for: .normal)
            btnTimeoutAway.backgroundColor = .systemRed
            btnEndQuarter.setTitle("FINE TEMPO", for: .normal)
            btnScoreHome.setTitle("+1", for: .normal)
            btnScoreAway.setTitle("+1", for: .normal)
            btnMinusHome.setTitle("−", for: .normal)
            btnMinusAway.setTitle("−", for: .normal)
        } else if isTennis {
            btnTimeoutHome.setTitle("GAME", for: .normal)
            btnTimeoutHome.backgroundColor = .systemPurple
            btnTimeoutAway.setTitle("GAME", for: .normal)
            btnTimeoutAway.backgroundColor = .systemPurple
            btnScoreHome.setTitle("+1", for: .normal)
            btnScoreAway.setTitle("+1", for: .normal)
            btnMinusHome.setTitle("−", for: .normal)
            btnMinusAway.setTitle("−", for: .normal)
        } else if isBiliardo {
            btnEndQuarter.setTitle("NEXT FRAME", for: .normal)
            btnTimeoutHome.setTitle("FOUL", for: .normal)
            btnTimeoutAway.setTitle("FOUL", for: .normal)
            btnScoreHome.setTitle("+1", for: .normal)
            btnScoreAway.setTitle("+1", for: .normal)
            btnMinusHome.setTitle("−", for: .normal)
            btnMinusAway.setTitle("−", for: .normal)
        } else if isDarts {
            btnTimeoutHome.setTitle("LEG", for: .normal)
            btnTimeoutHome.backgroundColor = UIColor(red: 234/255, green: 179/255, blue: 8/255, alpha: 0.95)
            btnTimeoutAway.setTitle("LEG", for: .normal)
            btnTimeoutAway.backgroundColor = UIColor(red: 234/255, green: 179/255, blue: 8/255, alpha: 0.95)
            btnScoreHome.setTitle("-60", for: .normal)
            btnScoreAway.setTitle("-60", for: .normal)
            btnMinusHome.setTitle("+", for: .normal)
            btnMinusAway.setTitle("+", for: .normal)
            btnScoreHome2.setTitle("-20", for: .normal)
            btnScoreHome3.setTitle("-100", for: .normal)
            btnScoreAway2.setTitle("-20", for: .normal)
            btnScoreAway3.setTitle("-100", for: .normal)
            btnEndQuarter.setTitle("NEW LEG", for: .normal)
        } else {
            btnTimeoutHome.setTitle("T.O.", for: .normal)
            btnTimeoutHome.backgroundColor = UIColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.85)
            btnTimeoutAway.setTitle("T.O.", for: .normal)
            btnTimeoutAway.backgroundColor = UIColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.85)
            btnEndQuarter.setTitle("FINE QUARTO", for: .normal)
            btnScoreHome.setTitle("+1", for: .normal)
            btnScoreAway.setTitle("+1", for: .normal)
            btnMinusHome.setTitle("−", for: .normal)
            btnMinusAway.setTitle("−", for: .normal)
            if isBasket {
                btnScoreHome2.setTitle("+2", for: .normal)
                btnScoreHome3.setTitle("+3", for: .normal)
                btnScoreAway2.setTitle("+2", for: .normal)
                btnScoreAway3.setTitle("+3", for: .normal)
            }
        }
        
        if isGrid {
            // ==========================================
            // === MODE 2: 4-QUADRANT GRID REGIA MODE ===
            // ==========================================
            gridLayer?.isHidden = false
            
            let contentW = w - safeLeft - safeRight
            let contentH = h - safeTop - safeBottom
            let gap: CGFloat = 8.0
            let halfW = (contentW - gap) / 2.0
            let halfH = (contentH - gap) / 2.0
            
            // ----------------------------------------------------
            // QUADRANT 1: TOP-LEFT (Camera Preview + Scaled Scoreboard)
            // ----------------------------------------------------
            let q1Frame = CGRect(x: safeLeft, y: safeTop, width: halfW, height: halfH)
            lfView.frame = q1Frame
            lfView.layer.cornerRadius = 12
            lfView.clipsToBounds = true
            
            scoreboardView.transform = CGAffineTransform(scaleX: 0.50, y: 0.50)
            scoreboardView.frame.origin = CGPoint(x: safeLeft + 4, y: safeTop + 4)
            scoreboardView.isHidden = false
            
            // ----------------------------------------------------
            // QUADRANT 2: TOP-RIGHT (Director Bar & Set Controls)
            // ----------------------------------------------------
            let trX = safeLeft + halfW + gap
            let trY = safeTop
            let trW = halfW
            let trH = halfH
            
            gridContainerTR.frame = CGRect(x: trX, y: trY, width: trW, height: trH)
            gridContainerTR.isHidden = false
            
            let pad: CGFloat = 6.0
            let numTopBtns: CGFloat = 8.0
            let btnGap: CGFloat = 4.0
            let topBtnW = (trW - 2 * pad - (numTopBtns - 1) * btnGap) / numTopBtns
            let topBtnH = min(36.0, (trH - 3 * pad) * 0.45)
            let row1Y = trY + pad
            
            closeButton.frame = CGRect(x: trX + pad + 0 * (topBtnW + btnGap), y: row1Y, width: topBtnW, height: topBtnH)
            modeButton.frame = CGRect(x: trX + pad + 1 * (topBtnW + btnGap), y: row1Y, width: topBtnW, height: topBtnH)
            shareLiveButton.frame = CGRect(x: trX + pad + 2 * (topBtnW + btnGap), y: row1Y, width: topBtnW, height: topBtnH)
            shareRemoteButton.frame = CGRect(x: trX + pad + 3 * (topBtnW + btnGap), y: row1Y, width: topBtnW, height: topBtnH)
            replayButton.frame = CGRect(x: trX + pad + 4 * (topBtnW + btnGap), y: row1Y, width: topBtnW, height: topBtnH)
            highlightButton.frame = CGRect(x: trX + pad + 5 * (topBtnW + btnGap), y: row1Y, width: topBtnW, height: topBtnH)
            muteButton.frame = CGRect(x: trX + pad + 6 * (topBtnW + btnGap), y: row1Y, width: topBtnW, height: topBtnH)
            sponsorButton.frame = CGRect(x: trX + pad + 7 * (topBtnW + btnGap), y: row1Y, width: topBtnW, height: topBtnH)
            
            closeButton.isHidden = false
            modeButton.isHidden = false
            shareLiveButton.isHidden = false
            shareRemoteButton.isHidden = false
            replayButton.isHidden = false
            highlightButton.isHidden = false
            muteButton.isHidden = false
            sponsorButton.isHidden = false
            
            zoomInButton.isHidden = true
            zoomOutButton.isHidden = true
            
            // Row 2: Stream Action Button & Set Increment/Decrement
            let row2Y = row1Y + topBtnH + pad
            let row2H = trH - pad - (row2Y - trY)
            let liveW = max(70.0, trW * 0.28)
            startStreamButton.frame = CGRect(x: trX + pad, y: row2Y, width: liveW, height: row2H)
            startStreamButton.isHidden = false
            
            let setBtnW: CGFloat = min(36.0, row2H)
            let lblSetW = max(70.0, trW * 0.24)
            let setStartX = trX + pad + liveW + 8.0
            btnSetMinusGrid.frame = CGRect(x: setStartX, y: row2Y, width: setBtnW, height: row2H)
            lblSetGrid.frame = CGRect(x: setStartX + setBtnW + 4.0, y: row2Y, width: lblSetW, height: row2H)
            btnSetPlusGrid.frame = CGRect(x: setStartX + setBtnW + 4.0 + lblSetW + 4.0, y: row2Y, width: setBtnW, height: row2H)
            
            btnSetMinusGrid.isHidden = false
            lblSetGrid.isHidden = false
            btnSetPlusGrid.isHidden = false
            
            let eqX = setStartX + setBtnW + 4.0 + lblSetW + 4.0 + setBtnW + 8.0
            let eqW = trX + trW - pad - eqX
            if (isBasket || isSoccer || isBiliardo || isDarts) && eqW > 40 {
                btnEndQuarter.frame = CGRect(x: eqX, y: row2Y, width: eqW, height: row2H)
                btnEndQuarter.isHidden = false
            } else {
                btnEndQuarter.isHidden = true
            }
            
            // ----------------------------------------------------
            // QUADRANT 3: BOTTOM-LEFT (Team A Home Card)
            // ----------------------------------------------------
            let blX = safeLeft
            let blY = safeTop + halfH + gap
            let blW = halfW
            let blH = halfH
            
            gridContainerBL.frame = CGRect(x: blX, y: blY, width: blW, height: blH)
            gridContainerBL.isHidden = false
            
            lblTeamAGrid.frame = CGRect(x: blX + 12, y: blY + 6, width: blW - 80, height: 24)
            lblScoreAGrid.frame = CGRect(x: blX + blW - 70, y: blY + 4, width: 58, height: 28)
            lblTeamAGrid.isHidden = false
            lblScoreAGrid.isHidden = false
            
            let aBtnsY = blY + 34
            let aBtnsH = blH - 40
            let subW: CGFloat = 46.0
            let btnG: CGFloat = 6.0
            
            if hasExtraScoreBtns {
                let bskW: CGFloat = 36.0
                let mainScoreW = blW - 24 - subW - subW - (bskW * 2) - (btnG * 4)
                btnScoreHome.frame = CGRect(x: blX + 12, y: aBtnsY, width: mainScoreW, height: aBtnsH)
                btnMinusHome.frame = CGRect(x: blX + 12 + mainScoreW + btnG, y: aBtnsY, width: subW, height: aBtnsH)
                btnTimeoutHome.frame = CGRect(x: blX + 12 + mainScoreW + btnG + subW + btnG, y: aBtnsY, width: subW, height: aBtnsH)
                btnScoreHome2.frame = CGRect(x: blX + 12 + mainScoreW + btnG + subW + btnG + subW + btnG, y: aBtnsY, width: bskW, height: aBtnsH)
                btnScoreHome3.frame = CGRect(x: blX + 12 + mainScoreW + btnG + subW + btnG + subW + btnG + bskW + btnG, y: aBtnsY, width: bskW, height: aBtnsH)
                btnScoreHome2.isHidden = false
                btnScoreHome3.isHidden = false
            } else {
                let mainScoreW = blW - 24 - subW - subW - (btnG * 2)
                btnScoreHome.frame = CGRect(x: blX + 12, y: aBtnsY, width: mainScoreW, height: aBtnsH)
                btnMinusHome.frame = CGRect(x: blX + 12 + mainScoreW + btnG, y: aBtnsY, width: subW, height: aBtnsH)
                btnTimeoutHome.frame = CGRect(x: blX + 12 + mainScoreW + btnG + subW + btnG, y: aBtnsY, width: subW, height: aBtnsH)
                btnScoreHome2.isHidden = true
                btnScoreHome3.isHidden = true
            }
            btnScoreHome.isHidden = false
            btnMinusHome.isHidden = false
            btnTimeoutHome.isHidden = false
            
            // ----------------------------------------------------
            // QUADRANT 4: BOTTOM-RIGHT (Team B Away Card)
            // ----------------------------------------------------
            let brX = safeLeft + halfW + gap
            let brY = safeTop + halfH + gap
            let brW = halfW
            let brH = halfH
            
            gridContainerBR.frame = CGRect(x: brX, y: brY, width: brW, height: brH)
            gridContainerBR.isHidden = false
            
            lblTeamBGrid.frame = CGRect(x: brX + 12, y: brY + 6, width: brW - 80, height: 24)
            lblScoreBGrid.frame = CGRect(x: brX + brW - 70, y: brY + 4, width: 58, height: 28)
            lblTeamBGrid.isHidden = false
            lblScoreBGrid.isHidden = false
            
            let bBtnsY = brY + 34
            let bBtnsH = brH - 40
            
            if hasExtraScoreBtns {
                let bskW: CGFloat = 36.0
                let mainScoreW = brW - 24 - subW - subW - (bskW * 2) - (btnG * 4)
                btnScoreAway.frame = CGRect(x: brX + 12, y: bBtnsY, width: mainScoreW, height: bBtnsH)
                btnMinusAway.frame = CGRect(x: brX + 12 + mainScoreW + btnG, y: bBtnsY, width: subW, height: bBtnsH)
                btnTimeoutAway.frame = CGRect(x: brX + 12 + mainScoreW + btnG + subW + btnG, y: bBtnsY, width: subW, height: bBtnsH)
                btnScoreAway2.frame = CGRect(x: brX + 12 + mainScoreW + btnG + subW + btnG + subW + btnG, y: bBtnsY, width: bskW, height: bBtnsH)
                btnScoreAway3.frame = CGRect(x: brX + 12 + mainScoreW + btnG + subW + btnG + subW + btnG + bskW + btnG, y: bBtnsY, width: bskW, height: bBtnsH)
                btnScoreAway2.isHidden = false
                btnScoreAway3.isHidden = false
            } else {
                let mainScoreW = brW - 24 - subW - subW - (btnG * 2)
                btnScoreAway.frame = CGRect(x: brX + 12, y: bBtnsY, width: mainScoreW, height: bBtnsH)
                btnMinusAway.frame = CGRect(x: brX + 12 + mainScoreW + btnG, y: bBtnsY, width: subW, height: bBtnsH)
                btnTimeoutAway.frame = CGRect(x: brX + 12 + mainScoreW + btnG + subW + btnG, y: bBtnsY, width: subW, height: bBtnsH)
                btnScoreAway2.isHidden = true
                btnScoreAway3.isHidden = true
            }
            btnScoreAway.isHidden = false
            btnMinusAway.isHidden = false
            btnTimeoutAway.isHidden = false
            
            // Bring all 4-quadrant views to front
            view.bringSubviewToFront(gridContainerTR)
            view.bringSubviewToFront(closeButton)
            view.bringSubviewToFront(modeButton)
            view.bringSubviewToFront(shareLiveButton)
            view.bringSubviewToFront(shareRemoteButton)
            view.bringSubviewToFront(replayButton)
            view.bringSubviewToFront(highlightButton)
            view.bringSubviewToFront(muteButton)
            view.bringSubviewToFront(sponsorButton)
            view.bringSubviewToFront(startStreamButton)
            view.bringSubviewToFront(btnSetMinusGrid)
            view.bringSubviewToFront(lblSetGrid)
            view.bringSubviewToFront(btnSetPlusGrid)
            view.bringSubviewToFront(btnEndQuarter)
            
            view.bringSubviewToFront(gridContainerBL)
            view.bringSubviewToFront(lblTeamAGrid)
            view.bringSubviewToFront(lblScoreAGrid)
            view.bringSubviewToFront(btnScoreHome)
            view.bringSubviewToFront(btnMinusHome)
            view.bringSubviewToFront(btnTimeoutHome)
            view.bringSubviewToFront(btnScoreHome2)
            view.bringSubviewToFront(btnScoreHome3)
            
            view.bringSubviewToFront(gridContainerBR)
            view.bringSubviewToFront(lblTeamBGrid)
            view.bringSubviewToFront(lblScoreBGrid)
            view.bringSubviewToFront(btnScoreAway)
            view.bringSubviewToFront(btnMinusAway)
            view.bringSubviewToFront(btnTimeoutAway)
            view.bringSubviewToFront(btnScoreAway2)
            view.bringSubviewToFront(btnScoreAway3)
            
            view.bringSubviewToFront(scoreboardView)
            
        } else {
            // ==========================================
            // === MODE 0: NORMAL FULLSCREEN REGIA ===
            // ==========================================
            lfView.frame = view.bounds
            lfView.layer.cornerRadius = 0
            scoreboardView.transform = .identity
            scoreboardView.frame = CGRect(x: safeLeft, y: safeTop, width: 280, height: 54)
            scoreboardView.isHidden = false
            gridLayer?.isHidden = true
            
            gridContainerTR.isHidden = true
            gridContainerBL.isHidden = true
            gridContainerBR.isHidden = true
            lblTeamAGrid.isHidden = true
            lblScoreAGrid.isHidden = true
            lblTeamBGrid.isHidden = true
            lblScoreBGrid.isHidden = true
            btnSetMinusGrid.isHidden = true
            lblSetGrid.isHidden = true
            btnSetPlusGrid.isHidden = true
            
            // 1. TOP RIGHT ACTION BAR
            let isPortrait = w < h
            let btnSize: CGFloat = isPortrait ? min(34, (w - safeLeft - safeRight) / 8) : 40
            let btnGap: CGFloat = isPortrait ? 4 : 8
            var currentRightX = w - safeRight - btnSize
            
            closeButton.frame = CGRect(x: currentRightX, y: safeTop, width: btnSize, height: btnSize)
            closeButton.isHidden = false
            currentRightX -= (btnSize + btnGap)
            
            modeButton.frame = CGRect(x: currentRightX, y: safeTop, width: btnSize, height: btnSize)
            modeButton.isHidden = false
            currentRightX -= (btnSize + btnGap)
            
            shareLiveButton.frame = CGRect(x: currentRightX, y: safeTop, width: btnSize, height: btnSize)
            shareLiveButton.isHidden = false
            currentRightX -= (btnSize + btnGap)
            
            shareRemoteButton.frame = CGRect(x: currentRightX, y: safeTop, width: btnSize, height: btnSize)
            shareRemoteButton.isHidden = false
            currentRightX -= (btnSize + btnGap)
            
            let isReplayActive = AppPreferences.shared.isReplayEnabled && ReplayManager.isDeviceSupported
            replayButton.frame = CGRect(x: currentRightX, y: safeTop, width: btnSize, height: btnSize)
            replayButton.isHidden = false
            replayButton.alpha = isReplayActive ? 1.0 : 0.35
            currentRightX -= (btnSize + btnGap)
            
            highlightButton.frame = CGRect(x: currentRightX, y: safeTop, width: btnSize, height: btnSize)
            highlightButton.isHidden = false
            highlightButton.alpha = isReplayActive ? 1.0 : 0.35
            
            // Zoom Buttons
            let zoomW: CGFloat = isPortrait ? 28 : 36
            let zoomH: CGFloat = isPortrait ? 26 : 32
            let zoomX = w - safeRight - zoomW
            zoomInButton.frame = CGRect(x: zoomX, y: safeTop + btnSize + 10, width: zoomW, height: zoomH)
            zoomOutButton.frame = CGRect(x: zoomX, y: safeTop + btnSize + 10 + zoomH + 4, width: zoomW, height: zoomH)
            zoomInButton.isHidden = false
            zoomOutButton.isHidden = false
            
            // 2. BOTTOM CENTER CONTROLS
            let centerX = w / 2
            let streamBtnW: CGFloat = isPortrait ? 60 : 72
            let streamBtnH: CGFloat = isPortrait ? 46 : 54
            let bottomCenterY = h - safeBottom - streamBtnH
            let sideBtnSize: CGFloat = isPortrait ? 38 : 44
            
            startStreamButton.frame = CGRect(x: centerX - streamBtnW / 2, y: bottomCenterY, width: streamBtnW, height: streamBtnH)
            startStreamButton.isHidden = false
            
            muteButton.frame = CGRect(x: centerX - streamBtnW / 2 - sideBtnSize - 8, y: bottomCenterY + (streamBtnH - sideBtnSize) / 2, width: sideBtnSize, height: sideBtnSize)
            muteButton.isHidden = false
            
            sponsorButton.frame = CGRect(x: centerX + streamBtnW / 2 + 8, y: bottomCenterY + (streamBtnH - sideBtnSize) / 2, width: sideBtnSize, height: sideBtnSize)
            sponsorButton.isHidden = false
            
            if isBasket || isSoccer || isBiliardo || isDarts {
                btnEndQuarter.frame = CGRect(x: centerX - 60, y: bottomCenterY - 36, width: 120, height: 30)
                btnEndQuarter.isHidden = false
            } else {
                btnEndQuarter.isHidden = true
            }
            
            // 3. BOTTOM LEFT CONTROLS (Team A)
            let scoreBtnSize: CGFloat = isPortrait ? min(54, (w - 180) / 2) : 70
            let subBtnW: CGFloat = isPortrait ? 40 : 50
            let subBtnH: CGFloat = (scoreBtnSize - 4) / 2
            let bottomScoreY = h - safeBottom - scoreBtnSize
            
            btnTimeoutHome.frame = CGRect(x: safeLeft, y: bottomScoreY, width: subBtnW, height: subBtnH)
            btnMinusHome.frame = CGRect(x: safeLeft, y: bottomScoreY + subBtnH + 4, width: subBtnW, height: subBtnH)
            btnScoreHome.frame = CGRect(x: safeLeft + subBtnW + 8, y: bottomScoreY, width: scoreBtnSize, height: scoreBtnSize)
            btnTimeoutHome.isHidden = false
            btnMinusHome.isHidden = false
            btnScoreHome.isHidden = false
            
            if hasExtraScoreBtns {
                let basketW: CGFloat = isPortrait ? 34 : 44
                btnScoreHome2.frame = CGRect(x: safeLeft + subBtnW + scoreBtnSize + 8, y: bottomScoreY, width: basketW, height: subBtnH)
                btnScoreHome3.frame = CGRect(x: safeLeft + subBtnW + scoreBtnSize + 8, y: bottomScoreY + subBtnH + 4, width: basketW, height: subBtnH)
                btnScoreHome2.isHidden = false
                btnScoreHome3.isHidden = false
            } else {
                btnScoreHome2.isHidden = true
                btnScoreHome3.isHidden = true
            }
            
            // 4. BOTTOM RIGHT CONTROLS (Team B)
            let rightSubX = w - safeRight - subBtnW
            btnTimeoutAway.frame = CGRect(x: rightSubX, y: bottomScoreY, width: subBtnW, height: subBtnH)
            btnMinusAway.frame = CGRect(x: rightSubX, y: bottomScoreY + subBtnH + 4, width: subBtnW, height: subBtnH)
            
            let rightScoreX = rightSubX - scoreBtnSize - 8
            btnScoreAway.frame = CGRect(x: rightScoreX, y: bottomScoreY, width: scoreBtnSize, height: scoreBtnSize)
            btnTimeoutAway.isHidden = false
            btnMinusAway.isHidden = false
            btnScoreAway.isHidden = false
            
            if hasExtraScoreBtns {
                let basketW: CGFloat = isPortrait ? 34 : 44
                btnScoreAway2.frame = CGRect(x: rightScoreX - basketW - 8, y: bottomScoreY, width: basketW, height: subBtnH)
                btnScoreAway3.frame = CGRect(x: rightScoreX - basketW - 8, y: bottomScoreY + subBtnH + 4, width: basketW, height: subBtnH)
                btnScoreAway2.isHidden = false
                btnScoreAway3.isHidden = false
            } else {
                btnScoreAway2.isHidden = true
                btnScoreAway3.isHidden = true
            }
        }
    }
    
    // MARK: - Actions & Mode Switching
    
    @objc func handleScreenTap() {
        if currentMode == 2 {
            currentMode = 0
            modeButton.setTitle("L", for: .normal)
            UIView.animate(withDuration: 0.25) {
                self.layoutAllViews()
            }
        }
    }
    
    @objc func toggleMode() {
        currentMode = (currentMode + 1) % 3
        switch currentMode {
        case 0: modeButton.setTitle("L", for: .normal)
        case 1: modeButton.setTitle("G", for: .normal)
        case 2: modeButton.setTitle("C", for: .normal)
        default: break
        }
        
        UIView.animate(withDuration: 0.3) {
            self.layoutAllViews()
        }
    }
    
    @objc func confirmExit() {
        let alert = UIAlertController(title: "Esci dalla Regia", message: "Vuoi terminare la sessione di regia e tornare al menu?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Annulla", style: .cancel))
        alert.addAction(UIAlertAction(title: "Esci", style: .destructive) { [weak self] _ in
            self?.exitDirector()
        })
        present(alert, animated: true)
    }
    
    private func exitDirector() {
        StreamManager.shared.stopStreaming()
        if LocalVideoRecorder.shared.isRecordingState {
            LocalVideoRecorder.shared.stopRecording { _ in }
        }
        
        if let onDismiss = onDismissRequested {
            onDismiss()
        } else {
            dismiss(animated: true)
        }
    }
    
    // MARK: - Camera Zoom (Pinch & Buttons)
    
    private var initialPinchZoom: CGFloat = 1.0
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .began {
            initialPinchZoom = StreamManager.shared.currentCamera?.videoZoomFactor ?? 1.0
        } else if gesture.state == .changed || gesture.state == .ended {
            StreamManager.shared.setZoom(factor: initialPinchZoom * gesture.scale)
        }
    }
    
    @objc func zoomIn() {
        StreamManager.shared.zoomIn()
    }
    
    @objc func zoomOut() {
        StreamManager.shared.zoomOut()
    }
    
    // MARK: - Match State & Scoring (Volleyball & Multi-Sport)
    
    func updateLocalState(saveHistory: Bool = true) {
        if saveHistory {
            stateHistory.append(localState)
            if stateHistory.count > 20 {
                stateHistory.removeFirst()
            }
        }
        localState.lastUpdate = Int64(Date().timeIntervalSince1970 * 1000)
        scoreboardView.updateFromState(localState)
        StreamManager.shared.videoEffect.currentState = localState
        FirebaseManager.shared.updateMatchState(localState)
        
        // Update Grid Mode Cards
        if let lblTeamA = lblTeamAGrid {
            lblTeamA.text = localState.teamA.isEmpty ? "HOME" : localState.teamA.uppercased()
        }
        if let lblTeamB = lblTeamBGrid {
            lblTeamB.text = localState.teamB.isEmpty ? "GUEST" : localState.teamB.uppercased()
        }
        if let lblScoreA = lblScoreAGrid {
            lblScoreA.text = "\(localState.scoreA)"
        }
        if let lblScoreB = lblScoreBGrid {
            lblScoreB.text = "\(localState.scoreB)"
        }
        if let lblSet = lblSetGrid {
            let sport = localState.sportType.lowercased()
            if sport == "basket" {
                lblSet.text = "QUARTO \(localState.currentSet)"
            } else if sport == "soccer" {
                lblSet.text = "TEMPO \(localState.currentSet)"
            } else if sport == "tennis" || sport == "padel" {
                lblSet.text = "SET \(localState.currentSet)"
            } else {
                lblSet.text = "SET \(localState.currentSet)"
            }
        }
    }
    
    func undoLastAction() {
        guard !stateHistory.isEmpty else {
            showToast(message: "Nessuna azione da annullare")
            return
        }
        let previous = stateHistory.removeLast()
        localState = previous
        updateLocalState(saveHistory: false)
        showToast(message: "↩️ Azione annullata (UNDO)")
    }
    
    func resetDartsScores() {
        let initial = getDartsInitialScore()
        localState.scoreA = initial
        localState.scoreB = initial
        localState.dartsTurnScore = 0
        localState.dartsThrows = ["", "", ""]
        localState.isDartsBust = false
    }
    
    @objc func decSetAction() {
        if localState.currentSet > 1 {
            localState.currentSet -= 1
            updateLocalState()
        }
    }
    
    @objc func incSetAction() {
        localState.currentSet += 1
        updateLocalState()
    }
    
    @objc func setServeA(_ sender: UIGestureRecognizer) {
        if sender.state == .began {
            localState.servingTeam = (localState.servingTeam == "A") ? "" : "A"
            updateLocalState()
        }
    }
    
    @objc func setServeB(_ sender: UIGestureRecognizer) {
        if sender.state == .began {
            localState.servingTeam = (localState.servingTeam == "B") ? "" : "B"
            updateLocalState()
        }
    }
    
    private func getDartsInitialScore() -> Int {
        let startScore = UserDefaults.standard.integer(forKey: "darts_initial_score")
        return (startScore == 301) ? 301 : 501
    }
    
    private func checkDartsLeg(isHome: Bool, subtract: Int) {
        let current = isHome ? localState.scoreA : localState.scoreB
        let remaining = current - subtract
        if remaining == 0 {
            if isHome {
                localState.dartsLegsA += 1
            } else {
                localState.dartsLegsB += 1
            }
            let initial = getDartsInitialScore()
            localState.scoreA = initial
            localState.scoreB = initial
            localState.dartsActivePlayer = isHome ? "B" : "A"
            showToast(message: "🎯 LEG VINTA! (\(isHome ? localState.teamA : localState.teamB))")
        } else if remaining > 1 {
            if isHome {
                localState.scoreA = remaining
                localState.dartsActivePlayer = "B"
            } else {
                localState.scoreB = remaining
                localState.dartsActivePlayer = "A"
            }
        } else {
            showToast(message: "💥 BUST! Punteggio non valido.")
            if isHome {
                localState.dartsActivePlayer = "B"
            } else {
                localState.dartsActivePlayer = "A"
            }
        }
        updateLocalState()
    }
    
    @objc func incScoreA() {
        let sport = localState.sportType.lowercased()
        if sport == "darts" {
            checkDartsLeg(isHome: true, subtract: 60)
            return
        } else if sport == "tennis" || sport == "padel" {
            advanceTennisGame(isHome: true)
        } else if sport == "volley" || sport == "beach_volley" || sport == "beach volley" {
            localState.scoreA += 1
            localState.servingTeam = "A"
            checkVolleySetWin()
        } else {
            localState.scoreA += 1
        }
        updateLocalState()
    }
    
    @objc func incScoreA2() {
        let sport = localState.sportType.lowercased()
        if sport == "darts" {
            checkDartsLeg(isHome: true, subtract: 20)
            return
        }
        localState.scoreA += 2
        updateLocalState()
    }
    
    @objc func incScoreA3() {
        let sport = localState.sportType.lowercased()
        if sport == "darts" {
            checkDartsLeg(isHome: true, subtract: 100)
            return
        }
        localState.scoreA += 3
        updateLocalState()
    }
    
    @objc func decScoreA() {
        let sport = localState.sportType.lowercased()
        if sport == "darts" {
            let initial = getDartsInitialScore()
            localState.scoreA = min(initial, localState.scoreA + 20)
        } else if sport == "tennis" || sport == "padel" {
            if localState.tennisPointsA > 0 { localState.tennisPointsA -= 1 }
        } else {
            if localState.scoreA > 0 {
                localState.scoreA -= 1
                localState.isMatchFinished = false
                localState.isSetFinished = false
            }
        }
        updateLocalState()
    }
    
    @objc func toA() {
        let sport = localState.sportType.lowercased()
        if sport == "darts" {
            localState.dartsLegsA += 1
            let initial = getDartsInitialScore()
            localState.scoreA = initial
            localState.scoreB = initial
            localState.dartsActivePlayer = "B"
            showToast(message: "🎯 Leg assegnata a \(localState.teamA)")
        } else if sport == "soccer" {
            localState.redCardsA = (localState.redCardsA + 1) % 4
        } else if sport == "tennis" || sport == "padel" {
            localState.tennisGamesA += 1
            checkTennisSetWin()
        } else if sport == "beach_volley" || sport == "beach volley" {
            localState.timeoutA = (localState.timeoutA + 1) % 2
        } else if sport == "basket" {
            localState.timeoutA = (localState.timeoutA + 1) % 4
        } else {
            localState.timeoutA = (localState.timeoutA + 1) % 3
        }
        updateLocalState()
    }
    
    @objc func incScoreB() {
        let sport = localState.sportType.lowercased()
        if sport == "darts" {
            checkDartsLeg(isHome: false, subtract: 60)
            return
        } else if sport == "tennis" || sport == "padel" {
            advanceTennisGame(isHome: false)
        } else if sport == "volley" || sport == "beach_volley" || sport == "beach volley" {
            localState.scoreB += 1
            localState.servingTeam = "B"
            checkVolleySetWin()
        } else {
            localState.scoreB += 1
        }
        updateLocalState()
    }
    
    @objc func incScoreB2() {
        let sport = localState.sportType.lowercased()
        if sport == "darts" {
            checkDartsLeg(isHome: false, subtract: 20)
            return
        }
        localState.scoreB += 2
        updateLocalState()
    }
    
    @objc func incScoreB3() {
        let sport = localState.sportType.lowercased()
        if sport == "darts" {
            checkDartsLeg(isHome: false, subtract: 100)
            return
        }
        localState.scoreB += 3
        updateLocalState()
    }
    
    @objc func decScoreB() {
        let sport = localState.sportType.lowercased()
        if sport == "darts" {
            let initial = getDartsInitialScore()
            localState.scoreB = min(initial, localState.scoreB + 20)
        } else if sport == "tennis" || sport == "padel" {
            if localState.tennisPointsB > 0 { localState.tennisPointsB -= 1 }
        } else {
            if localState.scoreB > 0 {
                localState.scoreB -= 1
                localState.isMatchFinished = false
                localState.isSetFinished = false
            }
        }
        updateLocalState()
    }
    
    @objc func toB() {
        let sport = localState.sportType.lowercased()
        if sport == "darts" {
            localState.dartsLegsB += 1
            let initial = getDartsInitialScore()
            localState.scoreA = initial
            localState.scoreB = initial
            localState.dartsActivePlayer = "A"
            showToast(message: "🎯 Leg assegnata a \(localState.teamB)")
        } else if sport == "soccer" {
            localState.redCardsB = (localState.redCardsB + 1) % 4
        } else if sport == "tennis" || sport == "padel" {
            localState.tennisGamesB += 1
            checkTennisSetWin()
        } else if sport == "beach_volley" || sport == "beach volley" {
            localState.timeoutB = (localState.timeoutB + 1) % 2
        } else if sport == "basket" {
            localState.timeoutB = (localState.timeoutB + 1) % 4
        } else {
            localState.timeoutB = (localState.timeoutB + 1) % 3
        }
        updateLocalState()
    }
    
    private func checkVolleySetWin() {
        let sport = localState.sportType.lowercased()
        let isBeach = (sport == "beach_volley" || sport == "beach volley")
        let setsToWin = isBeach ? 2 : 3
        let targetScore = isBeach ? (localState.currentSet == 3 ? 15 : 21) : (localState.isFifthSet ? 15 : 25)
        
        var winner: String? = nil
        if localState.scoreA >= targetScore && (localState.scoreA - localState.scoreB) >= 2 {
            winner = "A"
        } else if localState.scoreB >= targetScore && (localState.scoreB - localState.scoreA) >= 2 {
            winner = "B"
        }
        
        if let winTeam = winner {
            localState.setScores.append([localState.scoreA, localState.scoreB])
            if winTeam == "A" {
                localState.setsA += 1
            } else {
                localState.setsB += 1
            }
            
            if localState.setsA >= setsToWin || localState.setsB >= setsToWin {
                localState.isMatchFinished = true
                localState.isSetFinished = true
            } else {
                localState.currentSet += 1
                localState.scoreA = 0
                localState.scoreB = 0
                localState.timeoutA = 0
                localState.timeoutB = 0
                localState.isFifthSet = (!isBeach && localState.currentSet == 5)
                localState.isSetFinished = false
            }
        }
    }
    
    private func advanceTennisGame(isHome: Bool) {
        if isHome {
            if localState.isTiebreak {
                localState.tennisPointsA += 1
                if localState.tennisPointsA >= 7 && (localState.tennisPointsA - localState.tennisPointsB) >= 2 {
                    localState.tennisGamesA += 1
                    localState.tennisPointsA = 0
                    localState.tennisPointsB = 0
                    localState.isTiebreak = false
                    checkTennisSetWin()
                }
            } else {
                if localState.tennisPointsA == 3 && localState.tennisPointsB < 3 {
                    localState.tennisGamesA += 1
                    localState.tennisPointsA = 0
                    localState.tennisPointsB = 0
                    checkTennisSetWin()
                } else if localState.tennisPointsA == 3 && localState.tennisPointsB == 3 {
                    if localState.sportType.lowercased() == "padel" && localState.isPuntoDeOro {
                        localState.tennisGamesA += 1
                        localState.tennisPointsA = 0
                        localState.tennisPointsB = 0
                        checkTennisSetWin()
                    } else {
                        localState.tennisPointsA = 4
                    }
                } else if localState.tennisPointsA == 3 && localState.tennisPointsB == 4 {
                    localState.tennisPointsB = 3
                } else if localState.tennisPointsA == 4 {
                    localState.tennisGamesA += 1
                    localState.tennisPointsA = 0
                    localState.tennisPointsB = 0
                    checkTennisSetWin()
                } else {
                    localState.tennisPointsA += 1
                }
            }
        } else {
            if localState.isTiebreak {
                localState.tennisPointsB += 1
                if localState.tennisPointsB >= 7 && (localState.tennisPointsB - localState.tennisPointsA) >= 2 {
                    localState.tennisGamesB += 1
                    localState.tennisPointsA = 0
                    localState.tennisPointsB = 0
                    localState.isTiebreak = false
                    checkTennisSetWin()
                }
            } else {
                if localState.tennisPointsB == 3 && localState.tennisPointsA < 3 {
                    localState.tennisGamesB += 1
                    localState.tennisPointsA = 0
                    localState.tennisPointsB = 0
                    checkTennisSetWin()
                } else if localState.tennisPointsB == 3 && localState.tennisPointsA == 3 {
                    if localState.sportType.lowercased() == "padel" && localState.isPuntoDeOro {
                        localState.tennisGamesB += 1
                        localState.tennisPointsA = 0
                        localState.tennisPointsB = 0
                        checkTennisSetWin()
                    } else {
                        localState.tennisPointsB = 4
                    }
                } else if localState.tennisPointsB == 3 && localState.tennisPointsA == 4 {
                    localState.tennisPointsA = 3
                } else if localState.tennisPointsB == 4 {
                    localState.tennisGamesB += 1
                    localState.tennisPointsA = 0
                    localState.tennisPointsB = 0
                    checkTennisSetWin()
                } else {
                    localState.tennisPointsB += 1
                }
            }
        }
    }
    
    private func checkTennisSetWin() {
        let setsToWin = localState.tennisSetsToWin
        if (localState.tennisGamesA >= 6 && (localState.tennisGamesA - localState.tennisGamesB) >= 2) || (localState.tennisGamesA == 7 && localState.tennisGamesB == 6) {
            localState.setScores.append([localState.tennisGamesA, localState.tennisGamesB])
            localState.setsA += 1
            localState.tennisGamesA = 0
            localState.tennisGamesB = 0
            localState.currentSet += 1
            if localState.setsA >= setsToWin {
                localState.isMatchFinished = true
            }
        } else if (localState.tennisGamesB >= 6 && (localState.tennisGamesB - localState.tennisGamesA) >= 2) || (localState.tennisGamesB == 7 && localState.tennisGamesA == 6) {
            localState.setScores.append([localState.tennisGamesA, localState.tennisGamesB])
            localState.setsB += 1
            localState.tennisGamesA = 0
            localState.tennisGamesB = 0
            localState.currentSet += 1
            if localState.setsB >= setsToWin {
                localState.isMatchFinished = true
            }
        } else if localState.tennisGamesA == 6 && localState.tennisGamesB == 6 {
            localState.isTiebreak = true
        }
    }
    
    @objc func endQuarter() {
        let sport = localState.sportType.lowercased()
        if sport == "basket" {
            if localState.currentSet < localState.totalPeriods {
                localState.currentSet += 1
                localState.foulsA = 0
                localState.foulsB = 0
            }
        } else if sport == "soccer" || sport == "handball" || sport == "pallamano" {
            if localState.currentSet < 2 {
                localState.currentSet += 1
            }
        } else if sport == "billiards" || sport == "biliardo" {
            localState.currentSet += 1
            localState.scoreA = 0
            localState.scoreB = 0
        } else if sport == "darts" {
            localState.currentSet += 1
            let initial = getDartsInitialScore()
            localState.scoreA = initial
            localState.scoreB = initial
            showToast(message: "🎯 Nuova Leg Iniziata")
        } else if sport == "volley" || sport == "beach_volley" || sport == "beach volley" {
            localState.setScores.append([localState.scoreA, localState.scoreB])
            if localState.scoreA > localState.scoreB {
                localState.setsA += 1
            } else if localState.scoreB > localState.scoreA {
                localState.setsB += 1
            }
            localState.currentSet += 1
            localState.scoreA = 0
            localState.scoreB = 0
            localState.timeoutA = 0
            localState.timeoutB = 0
            localState.isFifthSet = (localState.currentSet == 5)
        }
        updateLocalState()
    }
    
    @objc func toggleSponsor() {
        localState.fullScreenSponsor.toggle()
        updateLocalState()
    }
    
    @objc func toggleMute() {
        isAudioMuted.toggle()
        do {
            if isAudioMuted {
                StreamManager.shared.rtmpStream.attachAudio(nil)
            } else {
                if let audio = AVCaptureDevice.default(for: .audio) {
                    StreamManager.shared.rtmpStream.attachAudio(audio)
                }
            }
        }
        muteButton.backgroundColor = isAudioMuted ? .systemRed : UIColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.85)
        muteButton.tintColor = isAudioMuted ? .white : UIColor(red: 56/255, green: 189/255, blue: 248/255, alpha: 1.0)
    }
    
    @objc func triggerReplay() {
        guard AppPreferences.shared.isReplayEnabled && ReplayManager.isDeviceSupported else {
            showToast(message: "⚠️ Replay non abilitato o non supportato")
            return
        }
        ReplayManager.shared.startPlayback()
        localState.isReplaying = true
        FirebaseManager.shared.updateMatchState(localState)
        showToast(message: "⏪ Replay Istantaneo")
    }
    
    @objc func triggerHighlight() {
        guard AppPreferences.shared.isReplayEnabled && ReplayManager.isDeviceSupported else {
            showToast(message: "⚠️ Replay non abilitato o non supportato")
            return
        }
        let origBg = highlightButton.backgroundColor
        highlightButton.backgroundColor = UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0)
        highlightButton.setTitleColor(.black, for: .normal)
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        showToast(message: "⏳ Elaborazione clip highlight...")
        
        ReplayManager.shared.saveHighlightClip { [weak self] success, errorMsg in
            DispatchQueue.main.async {
                self?.highlightButton.backgroundColor = origBg
                self?.highlightButton.setTitleColor(UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0), for: .normal)
                
                let msg = success ? "⭐ Highlight salvato in Galleria!" : (errorMsg ?? "Errore salvataggio highlight")
                self?.showToast(message: msg)
            }
        }
    }
    
    @objc func shareLive() {
        var link = UserDefaults.standard.string(forKey: "live_share_url") ?? ""
        if link.isEmpty {
            if let broadcastId = UserDefaults.standard.string(forKey: "youtube_broadcast_id"), !broadcastId.isEmpty {
                link = "https://youtube.com/live/\(broadcastId)"
            } else if let liveUrl = YouTubeManager.shared.currentLiveUrl, !liveUrl.isEmpty {
                link = liveUrl
            } else if let broadcastId = YouTubeManager.shared.currentBroadcastId, !broadcastId.isEmpty {
                link = "https://youtube.com/live/\(broadcastId)"
            } else {
                link = "https://youtube.com"
            }
        }
        let msg = "🏐 VolleyPro Live - Segui la diretta streaming del match:\n\(link)"
        let activity = UIActivityViewController(activityItems: [msg], applicationActivities: nil)
        if let popover = activity.popoverPresentationController {
            popover.sourceView = shareLiveButton
        }
        present(activity, animated: true)
    }
    
    @objc func shareRemote() {
        let sessionId = UserDefaults.standard.string(forKey: "remote_session_id") ?? "REGIA_01"
        let customLink = "volleypro://remote?code=\(sessionId)"
        let httpsLink = "https://volleystreampro.com/remote?code=\(sessionId)"
        let msg = "🏐 VolleyPro Live - Telecomando\n\nCodice Sessione: \(sessionId)\n\nClicca qui se usi Android:\n\(httpsLink)\n\nClicca qui se usi iOS:\n\(customLink)"
        
        let activity = UIActivityViewController(activityItems: [msg], applicationActivities: nil)
        if let popover = activity.popoverPresentationController {
            popover.sourceView = shareRemoteButton
        }
        present(activity, animated: true)
    }
    
    @objc func startLive() {
        if startStreamButton.title(for: .normal)?.contains("GO") == true {
            let rtmpUrl = UserDefaults.standard.string(forKey: "rtmp_url") ?? "rtmp://a.rtmp.youtube.com/live2"
            let rtmpKey = UserDefaults.standard.string(forKey: "rtmp_key") ?? "test"
            
            StreamManager.shared.startStreaming(url: rtmpUrl, streamKey: rtmpKey)
            
            let shouldRecord = UserDefaults.standard.object(forKey: "record_locally") == nil ? true : UserDefaults.standard.bool(forKey: "record_locally")
            if shouldRecord {
                LocalVideoRecorder.shared.startRecording()
            }
            
            startStreamButton.setTitle("STOP", for: .normal)
            startStreamButton.backgroundColor = .systemGray
            showToast(message: "🔴 LIVE & Registrazione avviata")
        } else {
            StreamManager.shared.stopStreaming()
            
            if LocalVideoRecorder.shared.isRecordingState {
                LocalVideoRecorder.shared.stopRecording { [weak self] savedUrl in
                    DispatchQueue.main.async {
                        if let _ = savedUrl {
                            self?.showToast(message: "🎬 Match salvato in Galleria!")
                        }
                    }
                }
            }
            
            startStreamButton.setTitle("GO\nLIVE", for: .normal)
            startStreamButton.backgroundColor = UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1.0)
            showToast(message: "⏹️ LIVE terminata")
        }
    }
    
    // MARK: - Remote Control Command Handler
    
    func handleRemoteCommand(_ command: String) {
        print("MainViewController received remote command: \(command)")
        let isDarts = (self.localState.sportType.lowercased() == "darts")
        
        switch command {
        case "POINT_A", "TENNIS_POINT_A":
            if isDarts {
                checkDartsLeg(isHome: true, subtract: 60)
            } else {
                incScoreA()
            }
        case "POINT_B", "TENNIS_POINT_B":
            if isDarts {
                checkDartsLeg(isHome: false, subtract: 60)
            } else {
                incScoreB()
            }
        case "MINUS_A", "TENNIS_MINUS_A":
            if isDarts {
                checkDartsLeg(isHome: true, subtract: -60)
            } else {
                decScoreA()
            }
        case "MINUS_B", "TENNIS_MINUS_B":
            if isDarts {
                checkDartsLeg(isHome: false, subtract: -60)
            } else {
                decScoreB()
            }
        case "PLUS_2_A":
            if isDarts { checkDartsLeg(isHome: true, subtract: 20) }
            else { incScoreA2() }
        case "PLUS_3_A":
            if isDarts { checkDartsLeg(isHome: true, subtract: 100) }
            else { incScoreA3() }
        case "PLUS_2_B":
            if isDarts { checkDartsLeg(isHome: false, subtract: 20) }
            else { incScoreB2() }
        case "PLUS_3_B":
            if isDarts { checkDartsLeg(isHome: false, subtract: 100) }
            else { incScoreB3() }
        case "DARTS_SUB_20_A":
            checkDartsLeg(isHome: true, subtract: 20)
        case "DARTS_SUB_60_A":
            checkDartsLeg(isHome: true, subtract: 60)
        case "DARTS_SUB_100_A":
            checkDartsLeg(isHome: true, subtract: 100)
        case "DARTS_SUB_20_B":
            checkDartsLeg(isHome: false, subtract: 20)
        case "DARTS_SUB_60_B":
            checkDartsLeg(isHome: false, subtract: 60)
        case "DARTS_SUB_100_B":
            checkDartsLeg(isHome: false, subtract: 100)
        case "DARTS_LEG_A":
            localState.dartsLegsA += 1
            resetDartsScores()
            refreshMatchState()
        case "DARTS_LEG_B":
            localState.dartsLegsB += 1
            resetDartsScores()
            refreshMatchState()
        case "DARTS_BUST":
            showToast(message: "🎯 BUST!")
            localState.dartsActivePlayer = (localState.dartsActivePlayer == "A") ? "B" : "A"
            refreshMatchState()
        case "DARTS_RESET_LEG":
            resetDartsScores()
            refreshMatchState()
        case "TIMEOUT_A":
            toA()
        case "TIMEOUT_B":
            toB()
        case "FOUL_A":
            localState.foulsA += 1
            refreshMatchState()
        case "FOUL_B":
            localState.foulsB += 1
            refreshMatchState()
        case "TENNIS_GAME_A":
            localState.tennisGamesA += 1
            localState.tennisPointsA = 0
            localState.tennisPointsB = 0
            refreshMatchState()
        case "TENNIS_GAME_B":
            localState.tennisGamesB += 1
            localState.tennisPointsA = 0
            localState.tennisPointsB = 0
            refreshMatchState()
        case "NEXT_SET", "END_PERIOD":
            endQuarter()
        case "SOCCER_RED_A":
            localState.redCardsA = (localState.redCardsA > 0) ? 0 : 1
            refreshMatchState()
        case "SOCCER_RED_B":
            localState.redCardsB = (localState.redCardsB > 0) ? 0 : 1
            refreshMatchState()
        case "SOCCER_TIMER_TOGGLE":
            localState.timerRunning.toggle()
            refreshMatchState()
        case "TOGGLE_SPONSOR":
            toggleSponsor()
        case "SPONSOR_1":
            localState.currentSponsorIdx = 0
            localState.showSponsor = true
            refreshMatchState()
        case "SPONSOR_2":
            localState.currentSponsorIdx = 1
            localState.showSponsor = true
            refreshMatchState()
        case "SPONSOR_3":
            localState.currentSponsorIdx = 2
            localState.showSponsor = true
            refreshMatchState()
        case "SPONSOR_4":
            localState.currentSponsorIdx = 3
            localState.showSponsor = true
            refreshMatchState()
        case "TOGGLE_TEXT":
            localState.showScrollText.toggle()
            refreshMatchState()
        case "TOGGLE_MUTE", "MUTE", "UNMUTE":
            toggleMute()
        case "TOGGLE_STREAMING", "START_STREAM", "STOP_STREAM":
            startLive()
        case "HIGHLIGHT":
            triggerHighlight()
        case "INSTANT_REPLAY", "TRIGGER_REPLAY":
            triggerReplay()
        case "UNDO":
            undoLastAction()
        default:
            print("Unknown remote command: \(command)")
        }
    }
    
    // MARK: - Toast Message Helper
    
    func showToast(message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let toastLabel = UILabel()
            toastLabel.backgroundColor = UIColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.95)
            toastLabel.textColor = .white
            toastLabel.textAlignment = .center
            toastLabel.font = UIFont.systemFont(ofSize: 13, weight: .bold)
            toastLabel.text = message
            toastLabel.alpha = 0.0
            toastLabel.layer.cornerRadius = 16
            toastLabel.layer.borderWidth = 1.2
            toastLabel.layer.borderColor = UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 0.8).cgColor
            toastLabel.clipsToBounds = true
            
            let textSize = (message as NSString).size(withAttributes: [.font: toastLabel.font!])
            let toastWidth = min(self.view.bounds.width - 40, textSize.width + 36)
            toastLabel.frame = CGRect(x: (self.view.bounds.width - toastWidth) / 2, y: self.view.bounds.height - 70, width: toastWidth, height: 36)
            
            self.view.addSubview(toastLabel)
            self.view.bringSubviewToFront(toastLabel)
            
            UIView.animate(withDuration: 0.25, animations: {
                toastLabel.alpha = 1.0
            }) { _ in
                UIView.animate(withDuration: 0.3, delay: 2.2, options: .curveEaseOut, animations: {
                    toastLabel.alpha = 0.0
                }) { _ in
                    toastLabel.removeFromSuperview()
                }
            }
        }
    }
}



