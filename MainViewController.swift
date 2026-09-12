import UIKit
import HaishinKit
import AVFoundation

class MainViewController: UIViewController {

    var lfView: MTHKView!
    var scoreboardView: ScoreboardOverlayView?
    
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
    var currentMode: Int = 0 // 0 = Normal, 1 = Grid, 2 = Clean
    
    // Grid Mode 4-Quadrant UI
    var gridContainerTR: UIView!
    var gridContainerBL: UIView!
    var gridContainerBR: UIView!
    var imgTeamAGrid: UIImageView!
    var lblTeamAGrid: UILabel!
    var lblScoreAGrid: UILabel!
    var imgTeamBGrid: UIImageView!
    var lblTeamBGrid: UILabel!
    var lblScoreBGrid: UILabel!
    var btnTextGrid: UIButton!
    var btnCrGrid: UIButton!
    var setPillContainer: UIView!
    var btnSetMinusGrid: UIButton!
    var lblSetGrid: UILabel!
    var btnSetPlusGrid: UIButton!
    var lblStorageGrid: UILabel!
    
    var initialSport: String = "volley"
    var initialTheme: String = "neon"
    var sessionId: String?
    var onDismissRequested: (() -> Void)?
    
    var localState = RemoteMatchState()
    var isAudioMuted = false
    private var stateHistory: [RemoteMatchState] = []
    private var isSetTransitionInProgress = false
    
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
    
    deinit {
        FirebaseManager.shared.stopListening()
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
        if isViewLoaded {
            updateLocalState()
        }
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
        
        self.localState = RemoteMatchState()
        self.localState.sportType = AppPreferences.shared.selectedSport
        self.localState.overlayTheme = AppPreferences.shared.selectedTheme
        self.localState.teamA = AppPreferences.shared.teamHome
        self.localState.teamB = AppPreferences.shared.teamAway
        self.localState.isPuntoDeOro = UserDefaults.standard.bool(forKey: "punto_de_oro")
        self.localState.scoreA = 0
        self.localState.scoreB = 0
        self.localState.setsA = 0
        self.localState.setsB = 0
        self.localState.setScores = []
        self.localState.currentSet = 1
        self.localState.timeoutA = 0
        self.localState.timeoutB = 0
        self.localState.isSetFinished = false
        self.localState.isMatchFinished = false
        self.localState.servingTeam = ""
        self.localState.foulsA = 0
        self.localState.foulsB = 0
        self.isSetTransitionInProgress = false
        
        if self.localState.sportType.lowercased() == "darts" {
            let startScore = UserDefaults.standard.integer(forKey: "darts_initial_score")
            let initial = (startScore == 301) ? 301 : 501
            self.localState.scoreA = initial
            self.localState.scoreB = initial
            self.localState.dartsActivePlayer = "A"
        }
        
        setupCameraView()
        setupScoreboardOverlay()
        scoreboardView?.resetAlerts()
        setupControls()
        setupGridLayer()
        updateLocalState()
        
        // Gestore tap a schermo intero per Clean Mode
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleScreenTap))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        self.backgroundTapGesture = tap
        
        let sessionCode = "VS-" + String(UUID().uuidString.prefix(6)).uppercased()
        UserDefaults.standard.set(sessionCode, forKey: "remote_session_id")
        
        FirebaseManager.shared.createSession(id: sessionCode, initialState: self.localState) { success in
            print("Firebase Host Session Created: \(sessionCode) (success: \(success))")
        }
        
        FirebaseManager.shared.onCommandReceived = { [weak self] command in
            DispatchQueue.main.async {
                self?.handleRemoteCommand(command)
            }
        }
        
        StreamManager.shared.onPublishStatusChanged = { [weak self] isPublishing in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.localState.isStreaming = isPublishing
                self.localState.streamingStatus = isPublishing ? "LIVE" : "OFFLINE"
                self.startStreamButton?.setTitle(isPublishing ? "STOP" : "GO\nLIVE", for: .normal)
                self.startStreamButton?.backgroundColor = isPublishing ? .systemGray : UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1.0)
                self.updateLocalState(saveHistory: false)
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
        
        AVCaptureDevice.requestAccess(for: .video) { _ in
            AVCaptureDevice.requestAccess(for: .audio) { _ in
                DispatchQueue.main.async {
                    StreamManager.shared.attachDevices()
                    StreamManager.shared.attachCamera(to: self.lfView)
                }
            }
        }
    }
    
    private func setupScoreboardOverlay() {
        let sv = ScoreboardOverlayView(frame: view.bounds)
        sv.isUserInteractionEnabled = false
        sv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sv.isHidden = true
        view.addSubview(sv)
        self.scoreboardView = sv
        StreamManager.shared.videoEffect.scoreboardView = sv
        
        sv.onOverlayNeedsUpdate = { [weak self] in
            guard let self = self else { return }
            StreamManager.shared.videoEffect.triggerOverlayUpdate(state: self.localState)
        }
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
        gridContainerTR.backgroundColor = .clear
        gridContainerTR.isHidden = true
        view.addSubview(gridContainerTR)
        
        btnTextGrid = createButton(title: "TEXT", systemImage: nil, bgColor: UIColor(red: 51/255, green: 65/255, blue: 85/255, alpha: 0.9), tintColor: .white, radius: 14)
        btnTextGrid.titleLabel?.font = UIFont.boldSystemFont(ofSize: 11)
        btnTextGrid.setTitleColor(.white, for: .normal)
        btnTextGrid.addTarget(self, action: #selector(toggleTextAction), for: .touchUpInside)
        btnTextGrid.isHidden = true
        view.addSubview(btnTextGrid)
        
        btnCrGrid = createButton(title: "CR", systemImage: nil, bgColor: UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0), tintColor: .black, radius: 14)
        btnCrGrid.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
        btnCrGrid.setTitleColor(.black, for: .normal)
        btnCrGrid.addTarget(self, action: #selector(confirmResetMatch), for: .touchUpInside)
        btnCrGrid.isHidden = true
        view.addSubview(btnCrGrid)
        
        setPillContainer = UIView()
        setPillContainer.backgroundColor = UIColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.95)
        setPillContainer.layer.cornerRadius = 16
        setPillContainer.layer.borderWidth = 1
        setPillContainer.layer.borderColor = UIColor(red: 51/255, green: 65/255, blue: 85/255, alpha: 0.8).cgColor
        setPillContainer.isHidden = true
        view.addSubview(setPillContainer)
        
        btnSetMinusGrid = createButton(title: "−", systemImage: nil, bgColor: UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1.0), tintColor: .white, radius: 14)
        btnSetMinusGrid.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        btnSetMinusGrid.addTarget(self, action: #selector(decSetAction), for: .touchUpInside)
        btnSetMinusGrid.isHidden = true
        view.addSubview(btnSetMinusGrid)
        
        lblSetGrid = UILabel()
        lblSetGrid.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        lblSetGrid.textColor = .white
        lblSetGrid.textAlignment = .center
        lblSetGrid.text = "SET"
        lblSetGrid.isHidden = true
        view.addSubview(lblSetGrid)
        
        btnSetPlusGrid = createButton(title: "+", systemImage: nil, bgColor: UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0), tintColor: .black, radius: 14)
        btnSetPlusGrid.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        btnSetPlusGrid.setTitleColor(.black, for: .normal)
        btnSetPlusGrid.addTarget(self, action: #selector(incSetAction), for: .touchUpInside)
        btnSetPlusGrid.isHidden = true
        view.addSubview(btnSetPlusGrid)
        
        lblStorageGrid = UILabel()
        lblStorageGrid.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        lblStorageGrid.textColor = UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 1.0)
        lblStorageGrid.textAlignment = .right
        lblStorageGrid.text = "0.00 GB"
        lblStorageGrid.isHidden = true
        view.addSubview(lblStorageGrid)
        
        // Bottom Left (Team A)
        gridContainerBL = UIView()
        gridContainerBL.backgroundColor = .clear
        gridContainerBL.isHidden = true
        view.addSubview(gridContainerBL)
        
        imgTeamAGrid = UIImageView()
        imgTeamAGrid.contentMode = .scaleAspectFit
        imgTeamAGrid.layer.cornerRadius = 6
        imgTeamAGrid.clipsToBounds = true
        imgTeamAGrid.tintColor = UIColor(red: 236/255, green: 72/255, blue: 153/255, alpha: 1.0)
        imgTeamAGrid.isHidden = true
        view.addSubview(imgTeamAGrid)
        
        lblTeamAGrid = UILabel()
        lblTeamAGrid.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        lblTeamAGrid.textColor = UIColor(red: 236/255, green: 72/255, blue: 153/255, alpha: 1.0)
        lblTeamAGrid.text = "CASA"
        lblTeamAGrid.isHidden = true
        view.addSubview(lblTeamAGrid)
        
        lblScoreAGrid = UILabel()
        lblScoreAGrid.font = UIFont.systemFont(ofSize: 28, weight: .heavy)
        lblScoreAGrid.textColor = .white
        lblScoreAGrid.textAlignment = .right
        lblScoreAGrid.text = "0"
        lblScoreAGrid.isHidden = true
        view.addSubview(lblScoreAGrid)
        
        // Bottom Right (Team B)
        gridContainerBR = UIView()
        gridContainerBR.backgroundColor = .clear
        gridContainerBR.isHidden = true
        view.addSubview(gridContainerBR)
        
        imgTeamBGrid = UIImageView()
        imgTeamBGrid.contentMode = .scaleAspectFit
        imgTeamBGrid.layer.cornerRadius = 6
        imgTeamBGrid.clipsToBounds = true
        imgTeamBGrid.tintColor = UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 1.0)
        imgTeamBGrid.isHidden = true
        view.addSubview(imgTeamBGrid)
        
        lblTeamBGrid = UILabel()
        lblTeamBGrid.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        lblTeamBGrid.textColor = UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 1.0)
        lblTeamBGrid.text = "OSPITE"
        lblTeamBGrid.isHidden = true
        view.addSubview(lblTeamBGrid)
        
        lblScoreBGrid = UILabel()
        lblScoreBGrid.font = UIFont.systemFont(ofSize: 28, weight: .heavy)
        lblScoreBGrid.textColor = .white
        lblScoreBGrid.textAlignment = .right
        lblScoreBGrid.text = "0"
        lblScoreBGrid.isHidden = true
        view.addSubview(lblScoreBGrid)
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
            imgTeamAGrid, lblTeamAGrid, lblScoreAGrid,
            imgTeamBGrid, lblTeamBGrid, lblScoreBGrid,
            btnTextGrid, btnCrGrid, setPillContainer,
            btnSetMinusGrid, lblSetGrid, btnSetPlusGrid, lblStorageGrid
        ]
        
        if isClean {
            lfView.frame = view.bounds
            lfView.layer.cornerRadius = 0
            scoreboardView?.isHidden = true
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
            // === MODE 1: 4-QUADRANT GRID REGIA MODE ===
            // ==========================================
            gridLayer?.isHidden = true
            
            let contentW = w - safeLeft - safeRight
            let contentH = h - safeTop - safeBottom
            let gap: CGFloat = 8.0
            let topHalfW = (contentW - gap) / 2.0
            let topHalfH = (contentH - gap) * 0.48
            let bottomHalfH = contentH - topHalfH - gap
            let centerW: CGFloat = 90.0
            let bottomSideW = (contentW - centerW - (gap * 2.0)) / 2.0
            
            // ----------------------------------------------------
            // QUADRANT 1: TOP-LEFT (Camera Preview with Stream Overlay)
            // ----------------------------------------------------
            let q1Frame = CGRect(x: safeLeft, y: safeTop, width: topHalfW, height: topHalfH)
            lfView.frame = q1Frame
            lfView.layer.cornerRadius = 10
            lfView.clipsToBounds = true
            scoreboardView?.isHidden = true
            
            // ----------------------------------------------------
            // QUADRANT 2: TOP-RIGHT (Director Bar & Set Controls Pill)
            // ----------------------------------------------------
            let trX = safeLeft + topHalfW + gap
            let trY = safeTop
            let trW = topHalfW
            let trH = topHalfH
            
            gridContainerTR.frame = CGRect(x: trX, y: trY, width: trW, height: trH)
            gridContainerTR.isHidden = false
            
            // Top Circular Button Row (TEXT, S, CR, Share, Mute, Mode)
            let topBtnCount: CGFloat = 6.0
            let topBtnSize = min(34.0, (trW - 10.0 - ((topBtnCount - 1.0) * 8.0)) / topBtnCount)
            let topSpacing = (trW - 10.0 - (topBtnCount * topBtnSize)) / (topBtnCount - 1.0)
            let topRowY = trY + 4.0
            
            // 1. TEXT button
            btnTextGrid.frame = CGRect(x: trX + 5.0 + 0 * (topBtnSize + topSpacing), y: topRowY, width: topBtnSize, height: topBtnSize)
            btnTextGrid.layer.cornerRadius = topBtnSize / 2
            btnTextGrid.backgroundColor = UIColor(red: 51/255, green: 65/255, blue: 85/255, alpha: 0.9)
            btnTextGrid.setTitleColor(.white, for: .normal)
            btnTextGrid.titleLabel?.font = UIFont.boldSystemFont(ofSize: 11)
            btnTextGrid.isHidden = false
            
            // 2. Sponsor S button (Yellow circle, black text)
            sponsorButton.frame = CGRect(x: trX + 5.0 + 1 * (topBtnSize + topSpacing), y: topRowY, width: topBtnSize, height: topBtnSize)
            sponsorButton.layer.cornerRadius = topBtnSize / 2
            sponsorButton.backgroundColor = UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0)
            sponsorButton.setTitle("S", for: .normal)
            sponsorButton.setTitleColor(.black, for: .normal)
            sponsorButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
            sponsorButton.isHidden = false
            
            // 3. CR (Clear / Reset) button (Yellow circle, black text)
            btnCrGrid.frame = CGRect(x: trX + 5.0 + 2 * (topBtnSize + topSpacing), y: topRowY, width: topBtnSize, height: topBtnSize)
            btnCrGrid.layer.cornerRadius = topBtnSize / 2
            btnCrGrid.backgroundColor = UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0)
            btnCrGrid.setTitleColor(.black, for: .normal)
            btnCrGrid.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
            btnCrGrid.isHidden = false
            
            // 4. Share Live button (Yellow circle, black icon)
            shareLiveButton.frame = CGRect(x: trX + 5.0 + 3 * (topBtnSize + topSpacing), y: topRowY, width: topBtnSize, height: topBtnSize)
            shareLiveButton.layer.cornerRadius = topBtnSize / 2
            shareLiveButton.backgroundColor = UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0)
            shareLiveButton.tintColor = .black
            shareLiveButton.isHidden = false
            
            // 5. Mute Audio button (Yellow circle, black icon)
            muteButton.frame = CGRect(x: trX + 5.0 + 4 * (topBtnSize + topSpacing), y: topRowY, width: topBtnSize, height: topBtnSize)
            muteButton.layer.cornerRadius = topBtnSize / 2
            muteButton.backgroundColor = UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0)
            muteButton.tintColor = .black
            muteButton.setImage(UIImage(systemName: isAudioMuted ? "speaker.slash.fill" : "speaker.wave.2.fill"), for: .normal)
            muteButton.isHidden = false
            
            // 6. Mode Switch button (Yellow circle, black "L")
            modeButton.frame = CGRect(x: trX + 5.0 + 5 * (topBtnSize + topSpacing), y: topRowY, width: topBtnSize, height: topBtnSize)
            modeButton.layer.cornerRadius = topBtnSize / 2
            modeButton.backgroundColor = UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0)
            modeButton.setTitleColor(.black, for: .normal)
            modeButton.setTitle("L", for: .normal)
            modeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
            modeButton.isHidden = false
            
            // Row 2: Set Controls Pill Container
            let pillY = topRowY + topBtnSize + 14.0
            let pillH = max(36.0, trH - (pillY - trY) - 6.0)
            let pillW = min(trW - 10.0, 270.0)
            let pillX = trX + 5.0
            setPillContainer.frame = CGRect(x: pillX, y: pillY, width: pillW, height: pillH)
            setPillContainer.layer.cornerRadius = pillH / 2
            setPillContainer.isHidden = false
            
            let btnSetSize = max(26.0, pillH - 8.0)
            btnSetMinusGrid.frame = CGRect(x: pillX + 6.0, y: pillY + (pillH - btnSetSize) / 2, width: btnSetSize, height: btnSetSize)
            btnSetMinusGrid.layer.cornerRadius = btnSetSize / 2
            btnSetMinusGrid.backgroundColor = UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1.0)
            btnSetMinusGrid.isHidden = false
            
            lblSetGrid.frame = CGRect(x: pillX + 6.0 + btnSetSize + 4.0, y: pillY, width: 42.0, height: pillH)
            lblSetGrid.isHidden = false
            
            btnSetPlusGrid.frame = CGRect(x: pillX + 6.0 + btnSetSize + 4.0 + 42.0 + 4.0, y: pillY + (pillH - btnSetSize) / 2, width: btnSetSize, height: btnSetSize)
            btnSetPlusGrid.layer.cornerRadius = btnSetSize / 2
            btnSetPlusGrid.backgroundColor = UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0)
            btnSetPlusGrid.isHidden = false
            
            lblStorageGrid.frame = CGRect(x: pillX + pillW - 90.0, y: pillY, width: 82.0, height: pillH)
            lblStorageGrid.text = getFreeDiskSpaceString()
            lblStorageGrid.isHidden = false
            
            closeButton.isHidden = true
            shareRemoteButton.isHidden = true
            zoomInButton.isHidden = true
            zoomOutButton.isHidden = true
            btnEndQuarter.isHidden = true
            
            // ----------------------------------------------------
            // QUADRANT 3: BOTTOM-LEFT (Team A Home Row)
            // ----------------------------------------------------
            let blX = safeLeft
            let blY = safeTop + topHalfH + gap
            let blW = bottomSideW
            let blH = bottomHalfH
            
            gridContainerBL.frame = CGRect(x: blX, y: blY, width: blW, height: blH)
            gridContainerBL.isHidden = false
            
            let logoSize: CGFloat = 24.0
            imgTeamAGrid.frame = CGRect(x: blX + 4.0, y: blY + 6.0, width: logoSize, height: logoSize)
            imgTeamAGrid.isHidden = false
            
            lblTeamAGrid.frame = CGRect(x: blX + 4.0 + logoSize + 6.0, y: blY + 4.0, width: max(30.0, blW - logoSize - 65.0), height: 28.0)
            lblTeamAGrid.isHidden = false
            
            lblScoreAGrid.frame = CGRect(x: blX + blW - 55.0, y: blY + 2.0, width: 50.0, height: 32.0)
            lblScoreAGrid.isHidden = false
            
            let btnSize = min(46.0, blH - 42.0)
            let btnRowY = blY + blH - btnSize - 4.0
            let btnSpacing = (blW - (3.0 * btnSize)) / 2.0
            
            btnScoreHome.frame = CGRect(x: blX, y: btnRowY, width: btnSize, height: btnSize)
            btnScoreHome.layer.cornerRadius = btnSize / 2
            btnScoreHome.setTitle("+", for: .normal)
            btnScoreHome.backgroundColor = UIColor(red: 236/255, green: 72/255, blue: 153/255, alpha: 1.0)
            btnScoreHome.titleLabel?.font = UIFont.boldSystemFont(ofSize: 22)
            btnScoreHome.isHidden = false
            
            btnMinusHome.frame = CGRect(x: blX + btnSize + btnSpacing, y: btnRowY, width: btnSize, height: btnSize)
            btnMinusHome.layer.cornerRadius = btnSize / 2
            btnMinusHome.setTitle("−", for: .normal)
            btnMinusHome.backgroundColor = UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1.0)
            btnMinusHome.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
            btnMinusHome.isHidden = false
            
            btnTimeoutHome.frame = CGRect(x: blX + 2.0 * (btnSize + btnSpacing), y: btnRowY, width: btnSize, height: btnSize)
            btnTimeoutHome.layer.cornerRadius = btnSize / 2
            btnTimeoutHome.setTitle("T", for: .normal)
            btnTimeoutHome.backgroundColor = UIColor(red: 51/255, green: 65/255, blue: 85/255, alpha: 0.9)
            btnTimeoutHome.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
            btnTimeoutHome.isHidden = false
            
            btnScoreHome2.isHidden = true
            btnScoreHome3.isHidden = true
            
            // ----------------------------------------------------
            // BOTTOM-CENTER: (Go Live + Replay & Highlight)
            // ----------------------------------------------------
            let bcX = safeLeft + bottomSideW + gap
            let bcY = blY
            let bcW = centerW
            let bcH = blH
            
            let liveW: CGFloat = 84.0
            let liveH: CGFloat = 34.0
            startStreamButton.frame = CGRect(x: bcX + (bcW - liveW) / 2.0, y: bcY + 4.0, width: liveW, height: liveH)
            startStreamButton.layer.cornerRadius = 8
            startStreamButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
            startStreamButton.backgroundColor = StreamManager.shared.isPublishing ? UIColor(red: 16/255, green: 185/255, blue: 129/255, alpha: 1.0) : UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1.0)
            startStreamButton.setTitle(StreamManager.shared.isPublishing ? "STOP LIVE" : "GO LIVE", for: .normal)
            startStreamButton.isHidden = false
            
            let subBtnSize = min(42.0, bcH - liveH - 16.0)
            let subY = bcY + liveH + 8.0
            let subSpacing = (bcW - (2.0 * subBtnSize)) / 3.0
            
            replayButton.frame = CGRect(x: bcX + subSpacing, y: subY, width: subBtnSize, height: subBtnSize)
            replayButton.layer.cornerRadius = subBtnSize / 2
            replayButton.backgroundColor = UIColor(red: 37/255, green: 99/255, blue: 235/255, alpha: 1.0)
            replayButton.setTitle("REP", for: .normal)
            replayButton.setTitleColor(.white, for: .normal)
            replayButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
            replayButton.isHidden = false
            
            highlightButton.frame = CGRect(x: bcX + subSpacing + subBtnSize + subSpacing, y: subY, width: subBtnSize, height: subBtnSize)
            highlightButton.layer.cornerRadius = subBtnSize / 2
            highlightButton.backgroundColor = UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0)
            highlightButton.setTitle("HL", for: .normal)
            highlightButton.setTitleColor(.black, for: .normal)
            highlightButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
            highlightButton.layer.borderWidth = 1.5
            highlightButton.layer.borderColor = UIColor.white.cgColor
            highlightButton.isHidden = false
            
            // ----------------------------------------------------
            // QUADRANT 4: BOTTOM-RIGHT (Team B Away Row)
            // ----------------------------------------------------
            let brX = bcX + bcW + gap
            let brY = blY
            let brW = bottomSideW
            let brH = blH
            
            gridContainerBR.frame = CGRect(x: brX, y: brY, width: brW, height: brH)
            gridContainerBR.isHidden = false
            
            imgTeamBGrid.frame = CGRect(x: brX + 4.0, y: brY + 6.0, width: logoSize, height: logoSize)
            imgTeamBGrid.isHidden = false
            
            lblTeamBGrid.frame = CGRect(x: brX + 4.0 + logoSize + 6.0, y: brY + 4.0, width: max(30.0, brW - logoSize - 65.0), height: 28.0)
            lblTeamBGrid.isHidden = false
            
            lblScoreBGrid.frame = CGRect(x: brX + brW - 55.0, y: brY + 2.0, width: 50.0, height: 32.0)
            lblScoreBGrid.isHidden = false
            
            btnScoreAway.frame = CGRect(x: brX, y: btnRowY, width: btnSize, height: btnSize)
            btnScoreAway.layer.cornerRadius = btnSize / 2
            btnScoreAway.setTitle("+", for: .normal)
            btnScoreAway.backgroundColor = UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 1.0)
            btnScoreAway.titleLabel?.font = UIFont.boldSystemFont(ofSize: 22)
            btnScoreAway.isHidden = false
            
            btnMinusAway.frame = CGRect(x: brX + btnSize + btnSpacing, y: btnRowY, width: btnSize, height: btnSize)
            btnMinusAway.layer.cornerRadius = btnSize / 2
            btnMinusAway.setTitle("−", for: .normal)
            btnMinusAway.backgroundColor = UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1.0)
            btnMinusAway.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
            btnMinusAway.isHidden = false
            
            btnTimeoutAway.frame = CGRect(x: brX + 2.0 * (btnSize + btnSpacing), y: btnRowY, width: btnSize, height: btnSize)
            btnTimeoutAway.layer.cornerRadius = btnSize / 2
            btnTimeoutAway.setTitle("T", for: .normal)
            btnTimeoutAway.backgroundColor = UIColor(red: 51/255, green: 65/255, blue: 85/255, alpha: 0.9)
            btnTimeoutAway.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
            btnTimeoutAway.isHidden = false
            
            btnScoreAway2.isHidden = true
            btnScoreAway3.isHidden = true
            
            // Bring all 4-quadrant views to front
            view.bringSubviewToFront(gridContainerTR)
            view.bringSubviewToFront(btnTextGrid)
            view.bringSubviewToFront(sponsorButton)
            view.bringSubviewToFront(btnCrGrid)
            view.bringSubviewToFront(shareLiveButton)
            view.bringSubviewToFront(muteButton)
            view.bringSubviewToFront(modeButton)
            view.bringSubviewToFront(setPillContainer)
            view.bringSubviewToFront(btnSetMinusGrid)
            view.bringSubviewToFront(lblSetGrid)
            view.bringSubviewToFront(btnSetPlusGrid)
            view.bringSubviewToFront(lblStorageGrid)
            
            view.bringSubviewToFront(gridContainerBL)
            view.bringSubviewToFront(imgTeamAGrid)
            view.bringSubviewToFront(lblTeamAGrid)
            view.bringSubviewToFront(lblScoreAGrid)
            view.bringSubviewToFront(btnScoreHome)
            view.bringSubviewToFront(btnMinusHome)
            view.bringSubviewToFront(btnTimeoutHome)
            
            view.bringSubviewToFront(startStreamButton)
            view.bringSubviewToFront(replayButton)
            view.bringSubviewToFront(highlightButton)
            
            view.bringSubviewToFront(gridContainerBR)
            view.bringSubviewToFront(imgTeamBGrid)
            view.bringSubviewToFront(lblTeamBGrid)
            view.bringSubviewToFront(lblScoreBGrid)
            view.bringSubviewToFront(btnScoreAway)
            view.bringSubviewToFront(btnMinusAway)
            view.bringSubviewToFront(btnTimeoutAway)
            
        } else {
            // ==========================================
            // === MODE 0: NORMAL FULLSCREEN REGIA ===
            // ==========================================
            lfView.frame = view.bounds
            lfView.layer.cornerRadius = 0
            scoreboardView?.isHidden = true
            gridLayer?.isHidden = true
            
            gridContainerTR.isHidden = true
            gridContainerBL.isHidden = true
            gridContainerBR.isHidden = true
            imgTeamAGrid.isHidden = true
            lblTeamAGrid.isHidden = true
            lblScoreAGrid.isHidden = true
            imgTeamBGrid.isHidden = true
            lblTeamBGrid.isHidden = true
            lblScoreBGrid.isHidden = true
            btnTextGrid.isHidden = true
            btnCrGrid.isHidden = true
            setPillContainer.isHidden = true
            btnSetMinusGrid.isHidden = true
            lblSetGrid.isHidden = true
            btnSetPlusGrid.isHidden = true
            lblStorageGrid.isHidden = true
            
            let darkBg = UIColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.85)
            
            // 1. TOP RIGHT ACTION BAR
            let isPortrait = w < h
            let btnSize: CGFloat = isPortrait ? min(34, (w - safeLeft - safeRight) / 8) : 40
            let btnGap: CGFloat = isPortrait ? 4 : 8
            var currentRightX = w - safeRight - btnSize
            
            closeButton.frame = CGRect(x: currentRightX, y: safeTop, width: btnSize, height: btnSize)
            closeButton.layer.cornerRadius = 12
            closeButton.backgroundColor = UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.9)
            closeButton.tintColor = .white
            closeButton.isHidden = false
            currentRightX -= (btnSize + btnGap)
            
            modeButton.frame = CGRect(x: currentRightX, y: safeTop, width: btnSize, height: btnSize)
            modeButton.layer.cornerRadius = 12
            modeButton.backgroundColor = UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0)
            modeButton.setTitleColor(.black, for: .normal)
            modeButton.setTitle("L", for: .normal)
            modeButton.isHidden = false
            currentRightX -= (btnSize + btnGap)
            
            shareLiveButton.frame = CGRect(x: currentRightX, y: safeTop, width: btnSize, height: btnSize)
            shareLiveButton.layer.cornerRadius = 12
            shareLiveButton.backgroundColor = darkBg
            shareLiveButton.tintColor = UIColor(red: 74/255, green: 222/255, blue: 128/255, alpha: 1.0)
            shareLiveButton.isHidden = false
            currentRightX -= (btnSize + btnGap)
            
            shareRemoteButton.frame = CGRect(x: currentRightX, y: safeTop, width: btnSize, height: btnSize)
            shareRemoteButton.layer.cornerRadius = 12
            shareRemoteButton.backgroundColor = darkBg
            shareRemoteButton.setTitleColor(.white, for: .normal)
            shareRemoteButton.isHidden = false
            currentRightX -= (btnSize + btnGap)
            
            let isReplayActive = AppPreferences.shared.isReplayEnabled && ReplayManager.isDeviceSupported
            replayButton.frame = CGRect(x: currentRightX, y: safeTop, width: btnSize, height: btnSize)
            replayButton.layer.cornerRadius = 12
            replayButton.backgroundColor = UIColor(red: 37/255, green: 99/255, blue: 235/255, alpha: 0.9)
            replayButton.setTitleColor(.white, for: .normal)
            replayButton.isHidden = false
            replayButton.alpha = isReplayActive ? 1.0 : 0.35
            currentRightX -= (btnSize + btnGap)
            
            highlightButton.frame = CGRect(x: currentRightX, y: safeTop, width: btnSize, height: btnSize)
            highlightButton.layer.cornerRadius = 12
            highlightButton.backgroundColor = darkBg
            highlightButton.setTitleColor(UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0), for: .normal)
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
            startStreamButton.layer.cornerRadius = 14
            startStreamButton.setTitle(StreamManager.shared.isPublishing ? "STOP\nLIVE" : "GO\nLIVE", for: .normal)
            startStreamButton.isHidden = false
            
            muteButton.frame = CGRect(x: centerX - streamBtnW / 2 - sideBtnSize - 8, y: bottomCenterY + (streamBtnH - sideBtnSize) / 2, width: sideBtnSize, height: sideBtnSize)
            muteButton.layer.cornerRadius = 14
            muteButton.backgroundColor = darkBg
            muteButton.tintColor = UIColor(red: 56/255, green: 189/255, blue: 248/255, alpha: 1.0)
            muteButton.setImage(UIImage(systemName: isAudioMuted ? "speaker.slash.fill" : "speaker.wave.2.fill"), for: .normal)
            muteButton.isHidden = false
            
            sponsorButton.frame = CGRect(x: centerX + streamBtnW / 2 + 8, y: bottomCenterY + (streamBtnH - sideBtnSize) / 2, width: sideBtnSize, height: sideBtnSize)
            sponsorButton.layer.cornerRadius = 14
            sponsorButton.backgroundColor = darkBg
            sponsorButton.setTitleColor(UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0), for: .normal)
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
            btnTimeoutHome.layer.cornerRadius = 10
            btnTimeoutHome.backgroundColor = darkBg
            btnTimeoutHome.isHidden = false
            
            btnMinusHome.frame = CGRect(x: safeLeft, y: bottomScoreY + subBtnH + 4, width: subBtnW, height: subBtnH)
            btnMinusHome.layer.cornerRadius = 10
            btnMinusHome.backgroundColor = darkBg
            btnMinusHome.isHidden = false
            
            btnScoreHome.frame = CGRect(x: safeLeft + subBtnW + 8, y: bottomScoreY, width: scoreBtnSize, height: scoreBtnSize)
            btnScoreHome.layer.cornerRadius = 20
            btnScoreHome.setTitle(isSoccer || isTennis || isBiliardo ? "+1" : "+1", for: .normal)
            btnScoreHome.titleLabel?.font = UIFont.boldSystemFont(ofSize: 30)
            btnScoreHome.backgroundColor = UIColor(red: 236/255, green: 72/255, blue: 153/255, alpha: 0.95)
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
            btnTimeoutAway.layer.cornerRadius = 10
            btnTimeoutAway.backgroundColor = darkBg
            btnTimeoutAway.isHidden = false
            
            btnMinusAway.frame = CGRect(x: rightSubX, y: bottomScoreY + subBtnH + 4, width: subBtnW, height: subBtnH)
            btnMinusAway.layer.cornerRadius = 10
            btnMinusAway.backgroundColor = darkBg
            btnMinusAway.isHidden = false
            
            let rightScoreX = rightSubX - scoreBtnSize - 8
            btnScoreAway.frame = CGRect(x: rightScoreX, y: bottomScoreY, width: scoreBtnSize, height: scoreBtnSize)
            btnScoreAway.layer.cornerRadius = 20
            btnScoreAway.setTitle(isSoccer || isTennis || isBiliardo ? "+1" : "+1", for: .normal)
            btnScoreAway.titleLabel?.font = UIFont.boldSystemFont(ofSize: 30)
            btnScoreAway.backgroundColor = UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 0.95)
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
            
            // Bring all control buttons to front over scoreboardView
            let mode0Buttons: [UIView] = [
                closeButton, modeButton, shareLiveButton, shareRemoteButton, replayButton, highlightButton,
                zoomInButton, zoomOutButton, startStreamButton, muteButton, sponsorButton,
                btnScoreHome, btnTimeoutHome, btnMinusHome, btnScoreAway, btnTimeoutAway, btnMinusAway,
                btnScoreHome2, btnScoreHome3, btnScoreAway2, btnScoreAway3, btnEndQuarter
            ]
            mode0Buttons.forEach { view.bringSubviewToFront($0) }
        }
    }
    
    // MARK: - Helper Methods & Actions
    
    private func getFreeDiskSpaceString() -> String {
        if let space = try? URL(fileURLWithPath: NSHomeDirectory()).resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]).volumeAvailableCapacityForImportantUsage {
            let gb = Double(space) / (1024.0 * 1024.0 * 1024.0)
            return String(format: "%.2f GB", gb)
        } else if let space = try? URL(fileURLWithPath: NSHomeDirectory()).resourceValues(forKeys: [.volumeAvailableCapacityKey]).volumeAvailableCapacity {
            let gb = Double(space) / (1024.0 * 1024.0 * 1024.0)
            return String(format: "%.2f GB", gb)
        }
        return "0.00 GB"
    }
    
    @objc func toggleTextAction() {
        localState.showScrollText.toggle()
        refreshMatchState()
        showToast(message: localState.showScrollText ? "📝 Testo scorrevole ON" : "📝 Testo scorrevole OFF")
    }
    
    @objc func confirmResetMatch() {
        let alert = UIAlertController(title: "Reset Partita", message: "Vuoi azzerare il punteggio e i set della partita in corso?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Annulla", style: .cancel))
        alert.addAction(UIAlertAction(title: "Azzera", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.localState.scoreA = 0
            self.localState.scoreB = 0
            self.localState.setsA = 0
            self.localState.setsB = 0
            self.localState.currentSet = 1
            self.localState.timeoutA = 0
            self.localState.timeoutB = 0
            self.localState.servingTeam = ""
            self.updateLocalState()
            self.showToast(message: "🔄 Partita azzerata")
        })
        present(alert, animated: true)
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
        FirebaseManager.shared.stopListening()
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
        guard isViewLoaded, let sv = scoreboardView else { return }
        
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batLevel = UIDevice.current.batteryLevel
        let bat = (batLevel >= 0) ? Int(batLevel * 100) : 100
        localState.batteryLevel = max(1, bat)
        
        let streamingActive = StreamManager.shared.isPublishing || (startStreamButton?.title(for: .normal)?.contains("STOP") == true)
        localState.isStreaming = streamingActive
        localState.streamingStatus = streamingActive ? "LIVE" : "OFFLINE"
        localState.isMuted = isAudioMuted
        
        if saveHistory {
            stateHistory.append(localState)
            if stateHistory.count > 20 {
                stateHistory.removeFirst()
            }
        }
        localState.lastUpdate = Int64(Date().timeIntervalSince1970 * 1000)
        sv.updateFromState(localState)
        StreamManager.shared.videoEffect.currentState = localState
        FirebaseManager.shared.updateMatchState(localState)
        
        // Update Grid Mode Logos & Cards
        if let imgA = imgTeamAGrid {
            if let d = AppPreferences.shared.loadImage(name: "logo_team_a.png") ?? AppPreferences.shared.loadImage(name: "logoHome.png") {
                imgA.image = UIImage(data: d)
            } else {
                imgA.image = UIImage(systemName: "shield.fill")
            }
        }
        if let imgB = imgTeamBGrid {
            if let d = AppPreferences.shared.loadImage(name: "logo_team_b.png") ?? AppPreferences.shared.loadImage(name: "logoAway.png") {
                imgB.image = UIImage(data: d)
            } else {
                imgB.image = UIImage(systemName: "shield.fill")
            }
        }
        if let lblTeamA = lblTeamAGrid {
            lblTeamA.text = localState.teamA.isEmpty ? "CASA" : localState.teamA.uppercased()
        }
        if let lblTeamB = lblTeamBGrid {
            lblTeamB.text = localState.teamB.isEmpty ? "OSPITE" : localState.teamB.uppercased()
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
            } else {
                lblSet.text = "SET \(localState.currentSet)"
            }
        }
        if let lblStorage = lblStorageGrid {
            lblStorage.text = getFreeDiskSpaceString()
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
                isSetTransitionInProgress = false
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
            let name = localState.teamA.isEmpty ? "CASA" : localState.teamA
            scoreboardView?.triggerTimeoutAlert(teamName: name)
        } else if sport == "basket" {
            localState.timeoutA = (localState.timeoutA + 1) % 4
            let name = localState.teamA.isEmpty ? "CASA" : localState.teamA
            scoreboardView?.triggerTimeoutAlert(teamName: name)
        } else {
            localState.timeoutA = (localState.timeoutA + 1) % 3
            let name = localState.teamA.isEmpty ? "CASA" : localState.teamA
            scoreboardView?.triggerTimeoutAlert(teamName: name)
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
                isSetTransitionInProgress = false
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
            let name = localState.teamB.isEmpty ? "OSPITE" : localState.teamB
            scoreboardView?.triggerTimeoutAlert(teamName: name)
        } else if sport == "basket" {
            localState.timeoutB = (localState.timeoutB + 1) % 4
            let name = localState.teamB.isEmpty ? "OSPITE" : localState.teamB
            scoreboardView?.triggerTimeoutAlert(teamName: name)
        } else {
            localState.timeoutB = (localState.timeoutB + 1) % 3
            let name = localState.teamB.isEmpty ? "OSPITE" : localState.teamB
            scoreboardView?.triggerTimeoutAlert(teamName: name)
        }
        updateLocalState()
    }
    
    private func checkVolleySetWin() {
        guard !isSetTransitionInProgress, !localState.isSetFinished, !localState.isMatchFinished else { return }
        
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
            isSetTransitionInProgress = true
            let finalScoreA = localState.scoreA
            let finalScoreB = localState.scoreB
            localState.setScores.append([finalScoreA, finalScoreB])
            if winTeam == "A" {
                localState.setsA += 1
            } else {
                localState.setsB += 1
            }
            
            let isMatchFin = (localState.setsA >= setsToWin || localState.setsB >= setsToWin)
            let winName = (winTeam == "A") ? (localState.teamA.isEmpty ? "CASA" : localState.teamA) : (localState.teamB.isEmpty ? "OSPITE" : localState.teamB)
            
            showToast(message: isMatchFin ? "🏆 \(winName) vince il Match!" : "🎉 \(winName) vince il \(localState.currentSet)° Set!")
            
            // 1. La grafica di fine set appare dopo 2 secondi
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                guard let self = self else { return }
                self.localState.isSetFinished = true
                if isMatchFin {
                    self.localState.isMatchFinished = true
                }
                self.updateLocalState()
                
                // 2. Dura 8 secondi e poi avanza al set successivo
                DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) { [weak self] in
                    guard let self = self else { return }
                    if !isMatchFin {
                        self.localState.currentSet += 1
                        self.localState.scoreA = 0
                        self.localState.scoreB = 0
                        self.localState.timeoutA = 0
                        self.localState.timeoutB = 0
                        self.localState.isFifthSet = (!isBeach && self.localState.currentSet == 5)
                        self.localState.isSetFinished = false
                        self.isSetTransitionInProgress = false
                        self.updateLocalState()
                    } else {
                        self.isSetTransitionInProgress = false
                    }
                }
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
        var setWonA = false
        var setWonB = false
        if (localState.tennisGamesA >= 6 && (localState.tennisGamesA - localState.tennisGamesB) >= 2) || (localState.tennisGamesA == 7 && localState.tennisGamesB == 6) {
            setWonA = true
        } else if (localState.tennisGamesB >= 6 && (localState.tennisGamesB - localState.tennisGamesA) >= 2) || (localState.tennisGamesB == 7 && localState.tennisGamesA == 6) {
            setWonB = true
        } else if localState.tennisGamesA == 6 && localState.tennisGamesB == 6 {
            localState.isTiebreak = true
        }
        
        if setWonA || setWonB {
            let finalGamesA = localState.tennisGamesA
            let finalGamesB = localState.tennisGamesB
            localState.setScores.append([finalGamesA, finalGamesB])
            if setWonA {
                localState.setsA += 1
            } else {
                localState.setsB += 1
            }
            
            let isMatchFin = (localState.setsA >= setsToWin || localState.setsB >= setsToWin)
            let winName = setWonA ? (localState.teamA.isEmpty ? "CASA" : localState.teamA) : (localState.teamB.isEmpty ? "OSPITE" : localState.teamB)
            
            showToast(message: isMatchFin ? "🏆 \(winName) vince il Match!" : "🎉 \(winName) vince il \(localState.currentSet)° Set!")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
                guard let self = self else { return }
                self.localState.isSetFinished = true
                if isMatchFin {
                    self.localState.isMatchFinished = true
                }
                self.updateLocalState()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
                    guard let self = self else { return }
                    if !isMatchFin {
                        self.localState.tennisGamesA = 0
                        self.localState.tennisGamesB = 0
                        self.localState.tennisPointsA = 0
                        self.localState.tennisPointsB = 0
                        self.localState.isTiebreak = false
                        self.localState.currentSet += 1
                        self.localState.isSetFinished = false
                        self.updateLocalState()
                    }
                }
            }
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
        guard StoreKitManager.shared.canUseFeature(.sponsors) else {
            showToast(message: "⭐ Funzionalità Sponsor disponibile con Premium")
            return
        }
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
        guard StoreKitManager.shared.canUseFeature(.instantReplay) else {
            showToast(message: "⭐ Instant Replay disponibile con Premium")
            return
        }
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
        guard StoreKitManager.shared.canUseFeature(.highlights) else {
            showToast(message: "⭐ Highlights disponibile con Premium")
            return
        }
        let origBg = highlightButton.backgroundColor
        highlightButton.backgroundColor = UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0)
        highlightButton.setTitleColor(.black, for: .normal)
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        showToast(message: "⏳ Salvataggio highlight in Galleria...")
        
        ReplayManager.shared.saveHighlightClip { [weak self] success, errorMsg in
            DispatchQueue.main.async {
                self?.highlightButton.backgroundColor = origBg
                self?.highlightButton.setTitleColor(UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0), for: .normal)
                
                let msg = success ? "⭐ Highlight salvato in Galleria!" : (errorMsg ?? "Nessun frame registrato per l'highlight")
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
        guard StoreKitManager.shared.canUseFeature(.remoteControl) else {
            showToast(message: "⭐ Controllo Remoto disponibile con Premium")
            return
        }
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
            
            localState.isStreaming = true
            localState.streamingStatus = "LIVE"
            updateLocalState(saveHistory: false)
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
            
            localState.isStreaming = false
            localState.streamingStatus = "OFFLINE"
            updateLocalState(saveHistory: false)
        }
    }
    
    // MARK: - Remote Control Command Handler
    
    func handleRemoteCommand(_ command: String) {
        print("MainViewController received remote command: \(command)")
        let isDarts = (self.localState.sportType.lowercased() == "darts")
        
        let cmd = command.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch cmd {
        case "POINT_A", "TENNIS_POINT_A", "SCORE_A", "INC_A", "INC_SCORE_A", "+1_A", "ADD_A", "PUNTO_A", "A_PLUS", "A_POINT":
            if isDarts {
                checkDartsLeg(isHome: true, subtract: 60)
            } else {
                incScoreA()
            }
        case "POINT_B", "TENNIS_POINT_B", "SCORE_B", "INC_B", "INC_SCORE_B", "+1_B", "ADD_B", "PUNTO_B", "B_PLUS", "B_POINT":
            if isDarts {
                checkDartsLeg(isHome: false, subtract: 60)
            } else {
                incScoreB()
            }
        case "MINUS_A", "TENNIS_MINUS_A", "DEC_A", "DEC_SCORE_A", "-1_A", "SUB_A", "MENO_A", "A_MINUS":
            if isDarts {
                checkDartsLeg(isHome: true, subtract: -60)
            } else {
                decScoreA()
            }
        case "MINUS_B", "TENNIS_MINUS_B", "DEC_B", "DEC_SCORE_B", "-1_B", "SUB_B", "MENO_B", "B_MINUS":
            if isDarts {
                checkDartsLeg(isHome: false, subtract: -60)
            } else {
                decScoreB()
            }
        case "PLUS_2_A", "+2_A", "SCORE_A_2", "A_PLUS_2":
            if isDarts { checkDartsLeg(isHome: true, subtract: 20) }
            else { incScoreA2() }
        case "PLUS_3_A", "+3_A", "SCORE_A_3", "A_PLUS_3":
            if isDarts { checkDartsLeg(isHome: true, subtract: 100) }
            else { incScoreA3() }
        case "PLUS_2_B", "+2_B", "SCORE_B_2", "B_PLUS_2":
            if isDarts { checkDartsLeg(isHome: false, subtract: 20) }
            else { incScoreB2() }
        case "PLUS_3_B", "+3_B", "SCORE_B_3", "B_PLUS_3":
            if isDarts { checkDartsLeg(isHome: false, subtract: 100) }
            else { incScoreB3() }
        case "TIMEOUT_A", "TO_A", "TIME_OUT_A", "TOA", "TIMEOUTA":
            toA()
        case "TIMEOUT_B", "TO_B", "TIME_OUT_B", "TOB", "TIMEOUTB":
            toB()
        case "SET_PLUS", "INC_SET", "NEXT_SET", "END_PERIOD", "+1_SET":
            incSetAction()
        case "SET_MINUS", "DEC_SET", "-1_SET":
            decSetAction()
        case "SERVE_A", "SRV_A", "SERVEA":
            localState.servingTeam = (localState.servingTeam == "A") ? "" : "A"
            updateLocalState()
        case "SERVE_B", "SRV_B", "SERVEB":
            localState.servingTeam = (localState.servingTeam == "B") ? "" : "B"
            updateLocalState()
        case "RESET", "RESET_MATCH", "CLEAR", "CR":
            localState.scoreA = 0
            localState.scoreB = 0
            localState.timeoutA = 0
            localState.timeoutB = 0
            updateLocalState()
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
            updateLocalState()
        case "DARTS_LEG_B":
            localState.dartsLegsB += 1
            resetDartsScores()
            updateLocalState()
        case "DARTS_BUST":
            showToast(message: "🎯 BUST!")
            localState.dartsActivePlayer = (localState.dartsActivePlayer == "A") ? "B" : "A"
            updateLocalState()
        case "DARTS_RESET_LEG":
            resetDartsScores()
            updateLocalState()
        case "FOUL_A":
            localState.foulsA += 1
            updateLocalState()
        case "FOUL_B":
            localState.foulsB += 1
            updateLocalState()
        case "TENNIS_GAME_A":
            localState.tennisGamesA += 1
            localState.tennisPointsA = 0
            localState.tennisPointsB = 0
            updateLocalState()
        case "TENNIS_GAME_B":
            localState.tennisGamesB += 1
            localState.tennisPointsA = 0
            localState.tennisPointsB = 0
            updateLocalState()
        case "SOCCER_RED_A":
            localState.redCardsA = (localState.redCardsA > 0) ? 0 : 1
            updateLocalState()
        case "SOCCER_RED_B":
            localState.redCardsB = (localState.redCardsB > 0) ? 0 : 1
            updateLocalState()
        case "SOCCER_TIMER_TOGGLE":
            localState.timerRunning.toggle()
            updateLocalState()
        case "TOGGLE_SPONSOR":
            toggleSponsor()
        case "SPONSOR_1":
            localState.currentSponsorIdx = 0
            localState.showSponsor = true
            updateLocalState()
        case "SPONSOR_2":
            localState.currentSponsorIdx = 1
            localState.showSponsor = true
            updateLocalState()
        case "SPONSOR_3":
            localState.currentSponsorIdx = 2
            localState.showSponsor = true
            updateLocalState()
        case "SPONSOR_4":
            localState.currentSponsorIdx = 3
            localState.showSponsor = true
            updateLocalState()
        case "TOGGLE_TEXT":
            localState.showScrollText.toggle()
            updateLocalState()
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



