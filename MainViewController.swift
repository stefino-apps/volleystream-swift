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
    var btnFoulHome: UIButton!
    var btnScoreHome2: UIButton!
    var btnScoreHome3: UIButton!
    
    // Right (Team B / Away) Controls
    var btnScoreAway: UIButton!
    var btnMinusAway: UIButton!
    var btnTimeoutAway: UIButton!
    var btnFoulAway: UIButton!
    var btnScoreAway2: UIButton!
    var btnScoreAway3: UIButton!
    
    // Center Action Button
    var btnEndQuarter: UIButton!
    var btnSoccerTimer: UIButton!
    var btnDartsCalc: UIButton!
    var matchTimer: Timer?
    var dartsKeypadContainer: UIView?
    var dartsCurrentInput: String = ""
    var dartsInputLabel: UILabel?
    var dartsPlayerBtnA: UIButton?
    var dartsPlayerBtnB: UIButton?
    
    // Zoom Controls
    var zoomInButton: UIButton!
    var zoomOutButton: UIButton!
    
    // Clean mode tap recognizer
    var backgroundTapGesture: UITapGestureRecognizer?
    
    // Grid Overlay
    var gridLayer: CAShapeLayer?
    var currentMode: Int = 0 // 0 = Normal, 1 = Grid, 2 = Clean
    
    // Grid Mode 4-Quadrant View Elements
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
    var isAudioMuted: Bool = false
    private var stateHistory: [RemoteMatchState] = []
    private var isSetTransitionInProgress: Bool = false
    
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
        AppDelegate.setOrientationLock(.portrait, rotateTo: .portrait)
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
        let savedScroll = UserDefaults.standard.string(forKey: "scrolling_text_content") ?? UserDefaults.standard.string(forKey: "saved_scrolling_text_slot_1") ?? ""
        if !savedScroll.isEmpty {
            self.localState.scrollMessage = savedScroll
        }
        if isViewLoaded {
            updateLocalState()
        }
    }
    
    private func forceLandscapeOrientation() {
        AppDelegate.setOrientationLock(.landscape, rotateTo: .landscapeRight)
    }
    
    private func forcePortraitOrientation() {
        AppDelegate.setOrientationLock(.portrait, rotateTo: .portrait)
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
        
        let savedScroll = UserDefaults.standard.string(forKey: "scrolling_text_content") ?? UserDefaults.standard.string(forKey: "saved_scrolling_text_slot_1") ?? ""
        if !savedScroll.isEmpty {
            self.localState.scrollMessage = savedScroll
        }
        
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
        
        ReplayManager.shared.onReplayStateChanged = { [weak self] isReplaying in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.localState.isReplaying = isReplaying
                FirebaseManager.shared.updateMatchState(self.localState)
                if !isReplaying {
                    self.showToast(message: "🔴 LIVE")
                }
            }
        }
        
        // Timer cronometro 1-secondo per Soccer e Handball
        matchTimer?.invalidate()
        matchTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.localState.timerRunning {
                self.localState.timerSeconds += 1
                self.updateSoccerTimerButton()
                StreamManager.shared.videoEffect.triggerOverlayUpdate(state: self.localState)
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
        
        btnFoulHome = createButton(title: "F: 0", systemImage: nil, bgColor: darkBg, tintColor: UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0), radius: 10)
        btnFoulHome.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
        btnFoulHome.addTarget(self, action: #selector(incFoulA), for: .touchUpInside)
        view.addSubview(btnFoulHome)
        
        btnScoreAway2 = createButton(title: "+2", systemImage: nil, bgColor: UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 0.85), tintColor: .white, radius: 10)
        btnScoreAway2.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        btnScoreAway2.addTarget(self, action: #selector(incScoreB2), for: .touchUpInside)
        view.addSubview(btnScoreAway2)
        
        btnScoreAway3 = createButton(title: "+3", systemImage: nil, bgColor: UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 0.85), tintColor: .white, radius: 10)
        btnScoreAway3.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        btnScoreAway3.addTarget(self, action: #selector(incScoreB3), for: .touchUpInside)
        view.addSubview(btnScoreAway3)
        
        btnFoulAway = createButton(title: "F: 0", systemImage: nil, bgColor: darkBg, tintColor: UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0), radius: 10)
        btnFoulAway.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
        btnFoulAway.addTarget(self, action: #selector(incFoulB), for: .touchUpInside)
        view.addSubview(btnFoulAway)
        
        // End Quarter / Period Button
        btnEndQuarter = createButton(title: "FINE QUARTO", systemImage: nil, bgColor: UIColor(red: 147/255, green: 51/255, blue: 234/255, alpha: 0.9), tintColor: .white, radius: 10)
        btnEndQuarter.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        btnEndQuarter.addTarget(self, action: #selector(endQuarter), for: .touchUpInside)
        view.addSubview(btnEndQuarter)
        
        // Soccer / Handball Timer Button
        btnSoccerTimer = createButton(title: "⏱️ 00:00", systemImage: nil, bgColor: UIColor(red: 16/255, green: 185/255, blue: 129/255, alpha: 0.95), tintColor: .white, radius: 10)
        btnSoccerTimer.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
        btnSoccerTimer.addTarget(self, action: #selector(toggleSoccerTimer), for: .touchUpInside)
        let longPressTimer = UILongPressGestureRecognizer(target: self, action: #selector(resetSoccerTimerAction(_:)))
        btnSoccerTimer.addGestureRecognizer(longPressTimer)
        btnSoccerTimer.isHidden = true
        view.addSubview(btnSoccerTimer)
        
        // Darts Calculator Button
        btnDartsCalc = createButton(title: "🎯 CALC", systemImage: nil, bgColor: UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 0.95), tintColor: .black, radius: 10)
        btnDartsCalc.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
        btnDartsCalc.setTitleColor(.black, for: .normal)
        btnDartsCalc.addTarget(self, action: #selector(toggleDartsKeypad), for: .touchUpInside)
        btnDartsCalc.isHidden = true
        view.addSubview(btnDartsCalc)
        
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
            btnScoreHome, btnTimeoutHome, btnMinusHome, btnFoulHome, btnScoreAway, btnTimeoutAway, btnMinusAway, btnFoulAway,
            btnScoreHome2, btnScoreHome3, btnScoreAway2, btnScoreAway3, btnEndQuarter, btnSoccerTimer, btnDartsCalc,
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
        
        let sport = self.localState.sportType.lowercased()
        let isBasket = (sport == "basket")
        let isSoccer = (sport == "soccer")
        let isBiliardo = (sport == "biliardo" || sport == "billiards")
        let isTennis = (sport == "tennis" || sport == "padel")
        let isDarts = (sport == "darts")
        let isCricket = (sport == "cricket")
        let isHandball = (sport == "handball" || sport == "pallamano")
        let hasExtraScoreBtns = isBasket || isDarts || isCricket
        let has2RowGrid = isBasket || isDarts || isCricket
        
        let darkBg = UIColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.85)
        
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
            btnTimeoutHome.backgroundColor = darkBg
            btnTimeoutAway.setTitle("FOUL", for: .normal)
            btnTimeoutAway.backgroundColor = darkBg
            btnScoreHome.setTitle("+1", for: .normal)
            btnScoreAway.setTitle("+1", for: .normal)
            btnMinusHome.setTitle("−", for: .normal)
            btnMinusAway.setTitle("−", for: .normal)
        } else if isCricket {
            btnScoreHome.setTitle("+1", for: .normal)
            btnScoreAway.setTitle("+1", for: .normal)
            btnScoreHome2.setTitle("+4", for: .normal)
            btnScoreAway2.setTitle("+4", for: .normal)
            btnScoreHome3.setTitle("+6", for: .normal)
            btnScoreAway3.setTitle("+6", for: .normal)
            btnMinusHome.setTitle("−", for: .normal)
            btnMinusAway.setTitle("−", for: .normal)
            btnTimeoutHome.setTitle("+BALL", for: .normal)
            btnTimeoutHome.backgroundColor = UIColor(red: 37/255, green: 99/255, blue: 235/255, alpha: 0.9)
            btnTimeoutAway.setTitle("+BALL", for: .normal)
            btnTimeoutAway.backgroundColor = UIColor(red: 37/255, green: 99/255, blue: 235/255, alpha: 0.9)
            btnEndQuarter.setTitle("INNINGS", for: .normal)
        } else if isHandball {
            btnScoreHome.setTitle("+1", for: .normal)
            btnScoreAway.setTitle("+1", for: .normal)
            btnMinusHome.setTitle("−", for: .normal)
            btnMinusAway.setTitle("−", for: .normal)
            btnTimeoutHome.setTitle("T.O.", for: .normal)
            btnTimeoutHome.backgroundColor = darkBg
            btnTimeoutAway.setTitle("T.O.", for: .normal)
            btnTimeoutAway.backgroundColor = darkBg
            btnEndQuarter.setTitle("FINE TEMPO", for: .normal)
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
            btnTimeoutHome.backgroundColor = darkBg
            btnTimeoutAway.setTitle("T.O.", for: .normal)
            btnTimeoutAway.backgroundColor = darkBg
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
            
            // Row 2: Set Controls Pill Container (Compatto [ - SET N + ])
            let pillY = topRowY + topBtnSize + 10.0
            let pillH: CGFloat = 30.0
            let btnSetSize: CGFloat = 22.0
            let pillW: CGFloat = 125.0
            let pillX = trX + 5.0
            setPillContainer.frame = CGRect(x: pillX, y: pillY, width: pillW, height: pillH)
            setPillContainer.layer.cornerRadius = pillH / 2
            setPillContainer.isHidden = false
            
            btnSetMinusGrid.frame = CGRect(x: pillX + 5.0, y: pillY + (pillH - btnSetSize) / 2, width: btnSetSize, height: btnSetSize)
            btnSetMinusGrid.layer.cornerRadius = btnSetSize / 2
            btnSetMinusGrid.backgroundColor = UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1.0)
            btnSetMinusGrid.isHidden = false
            
            lblSetGrid.frame = CGRect(x: pillX + 5.0 + btnSetSize + 2.0, y: pillY, width: 62.0, height: pillH)
            lblSetGrid.font = UIFont.boldSystemFont(ofSize: 12)
            lblSetGrid.isHidden = false
            
            btnSetPlusGrid.frame = CGRect(x: pillX + pillW - btnSetSize - 5.0, y: pillY + (pillH - btnSetSize) / 2, width: btnSetSize, height: btnSetSize)
            btnSetPlusGrid.layer.cornerRadius = btnSetSize / 2
            btnSetPlusGrid.backgroundColor = UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0)
            btnSetPlusGrid.isHidden = false
            
            lblStorageGrid.isHidden = true
            
            closeButton.isHidden = true
            shareRemoteButton.isHidden = true
            zoomInButton.isHidden = true
            zoomOutButton.isHidden = true
            btnEndQuarter.isHidden = true
            
            if isSoccer || isHandball {
                btnSoccerTimer.frame = CGRect(x: trX + 8.0, y: trY + trH - 34.0, width: trW - 16.0, height: 30.0)
                btnSoccerTimer.layer.cornerRadius = 8
                btnSoccerTimer.isHidden = false
                updateSoccerTimerButton()
                view.bringSubviewToFront(btnSoccerTimer)
            } else {
                btnSoccerTimer.isHidden = true
            }
            if isDarts {
                btnDartsCalc.frame = CGRect(x: trX + 8.0, y: trY + trH - 34.0, width: trW - 16.0, height: 30.0)
                btnDartsCalc.layer.cornerRadius = 8
                btnDartsCalc.isHidden = false
                view.bringSubviewToFront(btnDartsCalc)
            } else {
                btnDartsCalc.isHidden = true
            }
            
            // ----------------------------------------------------
            // QUADRANT 3: BOTTOM-LEFT (Team A Home Row)
            // ----------------------------------------------------
            let blX = safeLeft
            let blY = safeTop + topHalfH + gap
            let blW = bottomSideW
            let blH = bottomHalfH
            
            gridContainerBL.frame = CGRect(x: blX, y: blY, width: blW, height: blH)
            gridContainerBL.isHidden = false
            
            let logoSize: CGFloat = 26.0
            imgTeamAGrid.frame = CGRect(x: blX + 4.0, y: blY + 4.0, width: logoSize, height: logoSize)
            imgTeamAGrid.isHidden = false
            
            lblTeamAGrid.frame = CGRect(x: blX + 4.0 + logoSize + 6.0, y: blY + 2.0, width: max(30.0, blW - logoSize - 65.0), height: 28.0)
            lblTeamAGrid.font = UIFont.boldSystemFont(ofSize: 13)
            lblTeamAGrid.isHidden = false
            
            lblScoreAGrid.frame = CGRect(x: blX + blW - 55.0, y: blY + 2.0, width: 50.0, height: 32.0)
            lblScoreAGrid.font = UIFont.systemFont(ofSize: 26, weight: .heavy)
            lblScoreAGrid.isHidden = false
            
            if has2RowGrid {
                let btnW = min(56.0, (blW - 8.0) / 3.0)
                let btnH = min(46.0, (blH - 36.0) / 2.0)
                let row1Y = blY + 34.0
                let row2Y = row1Y + btnH + 4.0
                let spacing = (blW - (3.0 * btnW)) / 2.0
                
                // Row 1
                btnScoreHome.frame = CGRect(x: blX, y: row1Y, width: btnW, height: btnH)
                btnScoreHome.layer.cornerRadius = 12
                btnScoreHome.backgroundColor = UIColor(red: 236/255, green: 72/255, blue: 153/255, alpha: 1.0)
                btnScoreHome.titleLabel?.font = UIFont.boldSystemFont(ofSize: 22)
                btnScoreHome.isHidden = false
                
                btnScoreHome2.frame = CGRect(x: blX + btnW + spacing, y: row1Y, width: btnW, height: btnH)
                btnScoreHome2.layer.cornerRadius = 12
                btnScoreHome2.backgroundColor = UIColor(red: 236/255, green: 72/255, blue: 153/255, alpha: 0.85)
                btnScoreHome2.titleLabel?.font = UIFont.boldSystemFont(ofSize: 19)
                btnScoreHome2.isHidden = false
                
                btnScoreHome3.frame = CGRect(x: blX + 2.0 * (btnW + spacing), y: row1Y, width: btnW, height: btnH)
                btnScoreHome3.layer.cornerRadius = 12
                btnScoreHome3.backgroundColor = UIColor(red: 236/255, green: 72/255, blue: 153/255, alpha: 0.85)
                btnScoreHome3.titleLabel?.font = UIFont.boldSystemFont(ofSize: 19)
                btnScoreHome3.isHidden = false
                
                // Row 2
                btnMinusHome.frame = CGRect(x: blX, y: row2Y, width: btnW, height: btnH)
                btnMinusHome.layer.cornerRadius = 12
                btnMinusHome.backgroundColor = UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1.0)
                btnMinusHome.titleLabel?.font = UIFont.boldSystemFont(ofSize: 26)
                btnMinusHome.isHidden = false
                
                btnTimeoutHome.frame = CGRect(x: blX + btnW + spacing, y: row2Y, width: btnW, height: btnH)
                btnTimeoutHome.layer.cornerRadius = 12
                btnTimeoutHome.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
                btnTimeoutHome.isHidden = false
                
                btnFoulHome.frame = CGRect(x: blX + 2.0 * (btnW + spacing), y: row2Y, width: btnW, height: btnH)
                btnFoulHome.layer.cornerRadius = 12
                btnFoulHome.backgroundColor = darkBg
                btnFoulHome.setTitleColor(UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0), for: .normal)
                btnFoulHome.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
                btnFoulHome.isHidden = false
            } else {
                let btnSize = min(72.0, max(58.0, (blW - 12.0) / 3.0))
                let btnRowY = blY + blH - btnSize - 6.0
                let btnSpacing = (blW - (3.0 * btnSize)) / 2.0
                
                btnScoreHome.frame = CGRect(x: blX, y: btnRowY, width: btnSize, height: btnSize)
                btnScoreHome.layer.cornerRadius = btnSize / 2
                btnScoreHome.backgroundColor = UIColor(red: 236/255, green: 72/255, blue: 153/255, alpha: 1.0)
                btnScoreHome.titleLabel?.font = UIFont.boldSystemFont(ofSize: 32)
                btnScoreHome.isHidden = false
                
                btnMinusHome.frame = CGRect(x: blX + btnSize + btnSpacing, y: btnRowY, width: btnSize, height: btnSize)
                btnMinusHome.layer.cornerRadius = btnSize / 2
                btnMinusHome.backgroundColor = UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1.0)
                btnMinusHome.titleLabel?.font = UIFont.boldSystemFont(ofSize: 30)
                btnMinusHome.isHidden = false
                
                btnTimeoutHome.frame = CGRect(x: blX + 2.0 * (btnSize + btnSpacing), y: btnRowY, width: btnSize, height: btnSize)
                btnTimeoutHome.layer.cornerRadius = btnSize / 2
                btnTimeoutHome.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
                btnTimeoutHome.isHidden = false
                
                btnScoreHome2.isHidden = true
                btnScoreHome3.isHidden = true
                btnFoulHome.isHidden = true
            }
            
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
            replayButton.alpha = 1.0
            replayButton.isHidden = false
            
            highlightButton.frame = CGRect(x: bcX + subSpacing + subBtnSize + subSpacing, y: subY, width: subBtnSize, height: subBtnSize)
            highlightButton.layer.cornerRadius = subBtnSize / 2
            highlightButton.backgroundColor = UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0)
            highlightButton.setTitle("HL", for: .normal)
            highlightButton.setTitleColor(.black, for: .normal)
            highlightButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
            highlightButton.layer.borderWidth = 1.5
            highlightButton.layer.borderColor = UIColor.white.cgColor
            highlightButton.alpha = 1.0
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
            
            imgTeamBGrid.frame = CGRect(x: brX + 4.0, y: brY + 4.0, width: logoSize, height: logoSize)
            imgTeamBGrid.isHidden = false
            
            lblTeamBGrid.frame = CGRect(x: brX + 4.0 + logoSize + 6.0, y: brY + 2.0, width: max(30.0, brW - logoSize - 65.0), height: 28.0)
            lblTeamBGrid.font = UIFont.boldSystemFont(ofSize: 13)
            lblTeamBGrid.isHidden = false
            
            lblScoreBGrid.frame = CGRect(x: brX + brW - 55.0, y: brY + 2.0, width: 50.0, height: 32.0)
            lblScoreBGrid.font = UIFont.systemFont(ofSize: 26, weight: .heavy)
            lblScoreBGrid.isHidden = false
            
            if has2RowGrid {
                let btnW = min(56.0, (brW - 8.0) / 3.0)
                let btnH = min(46.0, (brH - 36.0) / 2.0)
                let row1Y = brY + 34.0
                let row2Y = row1Y + btnH + 4.0
                let spacing = (brW - (3.0 * btnW)) / 2.0
                
                // Row 1
                btnScoreAway.frame = CGRect(x: brX, y: row1Y, width: btnW, height: btnH)
                btnScoreAway.layer.cornerRadius = 12
                btnScoreAway.backgroundColor = UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 1.0)
                btnScoreAway.titleLabel?.font = UIFont.boldSystemFont(ofSize: 22)
                btnScoreAway.isHidden = false
                
                btnScoreAway2.frame = CGRect(x: brX + btnW + spacing, y: row1Y, width: btnW, height: btnH)
                btnScoreAway2.layer.cornerRadius = 12
                btnScoreAway2.backgroundColor = UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 0.85)
                btnScoreAway2.titleLabel?.font = UIFont.boldSystemFont(ofSize: 19)
                btnScoreAway2.isHidden = false
                
                btnScoreAway3.frame = CGRect(x: brX + 2.0 * (btnW + spacing), y: row1Y, width: btnW, height: btnH)
                btnScoreAway3.layer.cornerRadius = 12
                btnScoreAway3.backgroundColor = UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 0.85)
                btnScoreAway3.titleLabel?.font = UIFont.boldSystemFont(ofSize: 19)
                btnScoreAway3.isHidden = false
                
                // Row 2
                btnMinusAway.frame = CGRect(x: brX, y: row2Y, width: btnW, height: btnH)
                btnMinusAway.layer.cornerRadius = 12
                btnMinusAway.backgroundColor = UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1.0)
                btnMinusAway.titleLabel?.font = UIFont.boldSystemFont(ofSize: 26)
                btnMinusAway.isHidden = false
                
                btnTimeoutAway.frame = CGRect(x: brX + btnW + spacing, y: row2Y, width: btnW, height: btnH)
                btnTimeoutAway.layer.cornerRadius = 12
                btnTimeoutAway.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
                btnTimeoutAway.isHidden = false
                
                btnFoulAway.frame = CGRect(x: brX + 2.0 * (btnW + spacing), y: row2Y, width: btnW, height: btnH)
                btnFoulAway.layer.cornerRadius = 12
                btnFoulAway.backgroundColor = darkBg
                btnFoulAway.setTitleColor(UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0), for: .normal)
                btnFoulAway.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
                btnFoulAway.isHidden = false
            } else {
                let btnSize = min(72.0, max(58.0, (brW - 12.0) / 3.0))
                let btnRowY = brY + brH - btnSize - 6.0
                let btnSpacing = (brW - (3.0 * btnSize)) / 2.0
                
                btnScoreAway.frame = CGRect(x: brX, y: btnRowY, width: btnSize, height: btnSize)
                btnScoreAway.layer.cornerRadius = btnSize / 2
                btnScoreAway.backgroundColor = UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 1.0)
                btnScoreAway.titleLabel?.font = UIFont.boldSystemFont(ofSize: 32)
                btnScoreAway.isHidden = false
                
                btnMinusAway.frame = CGRect(x: brX + btnSize + btnSpacing, y: btnRowY, width: btnSize, height: btnSize)
                btnMinusAway.layer.cornerRadius = btnSize / 2
                btnMinusAway.backgroundColor = UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1.0)
                btnMinusAway.titleLabel?.font = UIFont.boldSystemFont(ofSize: 30)
                btnMinusAway.isHidden = false
                
                btnTimeoutAway.frame = CGRect(x: brX + 2.0 * (btnSize + btnSpacing), y: btnRowY, width: btnSize, height: btnSize)
                btnTimeoutAway.layer.cornerRadius = btnSize / 2
                btnTimeoutAway.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
                btnTimeoutAway.isHidden = false
                
                btnScoreAway2.isHidden = true
                btnScoreAway3.isHidden = true
                btnFoulAway.isHidden = true
            }
            
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
            view.bringSubviewToFront(btnScoreHome2)
            view.bringSubviewToFront(btnScoreHome3)
            view.bringSubviewToFront(btnMinusHome)
            view.bringSubviewToFront(btnTimeoutHome)
            view.bringSubviewToFront(btnFoulHome)
            
            view.bringSubviewToFront(startStreamButton)
            view.bringSubviewToFront(replayButton)
            view.bringSubviewToFront(highlightButton)
            
            view.bringSubviewToFront(gridContainerBR)
            view.bringSubviewToFront(imgTeamBGrid)
            view.bringSubviewToFront(lblTeamBGrid)
            view.bringSubviewToFront(lblScoreBGrid)
            view.bringSubviewToFront(btnScoreAway)
            view.bringSubviewToFront(btnScoreAway2)
            view.bringSubviewToFront(btnScoreAway3)
            view.bringSubviewToFront(btnMinusAway)
            view.bringSubviewToFront(btnTimeoutAway)
            view.bringSubviewToFront(btnFoulAway)
            
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
            
            replayButton.frame = CGRect(x: currentRightX, y: safeTop, width: btnSize, height: btnSize)
            replayButton.layer.cornerRadius = 12
            replayButton.backgroundColor = UIColor(red: 37/255, green: 99/255, blue: 235/255, alpha: 0.9)
            replayButton.setTitleColor(.white, for: .normal)
            replayButton.isHidden = false
            replayButton.alpha = 1.0
            currentRightX -= (btnSize + btnGap)
            
            highlightButton.frame = CGRect(x: currentRightX, y: safeTop, width: btnSize, height: btnSize)
            highlightButton.layer.cornerRadius = 12
            highlightButton.backgroundColor = darkBg
            highlightButton.setTitleColor(UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0), for: .normal)
            highlightButton.isHidden = false
            highlightButton.alpha = 1.0
            
            // Zoom Buttons (Distanziati e più comodi da premere)
            let zoomW: CGFloat = isPortrait ? 32 : 40
            let zoomH: CGFloat = isPortrait ? 30 : 36
            let zoomX = w - safeRight - zoomW
            let zoomSpacing: CGFloat = isPortrait ? 12 : 16
            let zoomStartY = safeTop + btnSize + 16
            zoomInButton.frame = CGRect(x: zoomX, y: zoomStartY, width: zoomW, height: zoomH)
            zoomInButton.layer.cornerRadius = 10
            zoomOutButton.frame = CGRect(x: zoomX, y: zoomStartY + zoomH + zoomSpacing, width: zoomW, height: zoomH)
            zoomOutButton.layer.cornerRadius = 10
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
            
            if isSoccer || isHandball {
                btnEndQuarter.frame = CGRect(x: centerX - 125, y: bottomCenterY - 40, width: 120, height: 34)
                btnEndQuarter.layer.cornerRadius = 10
                btnEndQuarter.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
                btnEndQuarter.isHidden = false
                
                btnSoccerTimer.frame = CGRect(x: centerX + 5, y: bottomCenterY - 40, width: 120, height: 34)
                btnSoccerTimer.layer.cornerRadius = 10
                btnSoccerTimer.isHidden = false
                updateSoccerTimerButton()
                btnDartsCalc.isHidden = true
            } else if isDarts {
                btnEndQuarter.frame = CGRect(x: centerX - 125, y: bottomCenterY - 40, width: 120, height: 34)
                btnEndQuarter.layer.cornerRadius = 10
                btnEndQuarter.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
                btnEndQuarter.isHidden = false
                
                btnDartsCalc.frame = CGRect(x: centerX + 5, y: bottomCenterY - 40, width: 120, height: 34)
                btnDartsCalc.layer.cornerRadius = 10
                btnDartsCalc.isHidden = false
                btnSoccerTimer.isHidden = true
            } else if isBasket || isBiliardo || isCricket {
                btnEndQuarter.frame = CGRect(x: centerX - 70, y: bottomCenterY - 40, width: 140, height: 34)
                btnEndQuarter.layer.cornerRadius = 10
                btnEndQuarter.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
                btnEndQuarter.isHidden = false
                btnSoccerTimer.isHidden = true
                btnDartsCalc.isHidden = true
            } else {
                btnEndQuarter.isHidden = true
                btnSoccerTimer.isHidden = true
                btnDartsCalc.isHidden = true
            }
            
            // 3. BOTTOM LEFT CONTROLS (Team A)
            let scoreBtnSize: CGFloat = isPortrait ? min(64, (w - 180) / 2) : 80
            let subBtnW: CGFloat = isPortrait ? 44 : 56
            let subBtnH: CGFloat = (scoreBtnSize - 4) / 2
            let bottomScoreY = h - safeBottom - scoreBtnSize
            
            btnTimeoutHome.frame = CGRect(x: safeLeft, y: bottomScoreY, width: subBtnW, height: subBtnH)
            btnTimeoutHome.layer.cornerRadius = 12
            btnTimeoutHome.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
            btnTimeoutHome.isHidden = false
            
            btnMinusHome.frame = CGRect(x: safeLeft, y: bottomScoreY + subBtnH + 4, width: subBtnW, height: subBtnH)
            btnMinusHome.layer.cornerRadius = 12
            btnMinusHome.titleLabel?.font = UIFont.boldSystemFont(ofSize: 26)
            btnMinusHome.backgroundColor = darkBg
            btnMinusHome.isHidden = false
            
            btnScoreHome.frame = CGRect(x: safeLeft + subBtnW + 8, y: bottomScoreY, width: scoreBtnSize, height: scoreBtnSize)
            btnScoreHome.layer.cornerRadius = 22
            btnScoreHome.titleLabel?.font = UIFont.boldSystemFont(ofSize: 34)
            btnScoreHome.backgroundColor = UIColor(red: 236/255, green: 72/255, blue: 153/255, alpha: 0.95)
            btnScoreHome.isHidden = false
            
            if hasExtraScoreBtns {
                let basketW: CGFloat = isPortrait ? 40 : 50
                btnScoreHome2.frame = CGRect(x: safeLeft + subBtnW + scoreBtnSize + 8, y: bottomScoreY, width: basketW, height: subBtnH)
                btnScoreHome2.layer.cornerRadius = 12
                btnScoreHome2.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
                
                btnScoreHome3.frame = CGRect(x: safeLeft + subBtnW + scoreBtnSize + 8, y: bottomScoreY + subBtnH + 4, width: basketW, height: subBtnH)
                btnScoreHome3.layer.cornerRadius = 12
                btnScoreHome3.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
                btnScoreHome2.isHidden = false
                btnScoreHome3.isHidden = false
                
                btnFoulHome.frame = CGRect(x: safeLeft + subBtnW + scoreBtnSize + basketW + 14, y: bottomScoreY, width: basketW, height: scoreBtnSize)
                btnFoulHome.layer.cornerRadius = 14
                btnFoulHome.backgroundColor = darkBg
                btnFoulHome.setTitleColor(UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0), for: .normal)
                btnFoulHome.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
                btnFoulHome.isHidden = false
            } else {
                btnScoreHome2.isHidden = true
                btnScoreHome3.isHidden = true
                btnFoulHome.isHidden = true
            }
            
            // 4. BOTTOM RIGHT CONTROLS (Team B)
            let rightSubX = w - safeRight - subBtnW
            btnTimeoutAway.frame = CGRect(x: rightSubX, y: bottomScoreY, width: subBtnW, height: subBtnH)
            btnTimeoutAway.layer.cornerRadius = 12
            btnTimeoutAway.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
            btnTimeoutAway.isHidden = false
            
            btnMinusAway.frame = CGRect(x: rightSubX, y: bottomScoreY + subBtnH + 4, width: subBtnW, height: subBtnH)
            btnMinusAway.layer.cornerRadius = 12
            btnMinusAway.titleLabel?.font = UIFont.boldSystemFont(ofSize: 26)
            btnMinusAway.backgroundColor = darkBg
            btnMinusAway.isHidden = false
            
            let rightScoreX = rightSubX - scoreBtnSize - 8
            btnScoreAway.frame = CGRect(x: rightScoreX, y: bottomScoreY, width: scoreBtnSize, height: scoreBtnSize)
            btnScoreAway.layer.cornerRadius = 22
            btnScoreAway.titleLabel?.font = UIFont.boldSystemFont(ofSize: 34)
            btnScoreAway.backgroundColor = UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 0.95)
            btnScoreAway.isHidden = false
            
            if hasExtraScoreBtns {
                let basketW: CGFloat = isPortrait ? 40 : 50
                btnScoreAway2.frame = CGRect(x: rightScoreX - basketW - 8, y: bottomScoreY, width: basketW, height: subBtnH)
                btnScoreAway2.layer.cornerRadius = 12
                btnScoreAway2.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
                
                btnScoreAway3.frame = CGRect(x: rightScoreX - basketW - 8, y: bottomScoreY + subBtnH + 4, width: basketW, height: subBtnH)
                btnScoreAway3.layer.cornerRadius = 12
                btnScoreAway3.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
                btnScoreAway2.isHidden = false
                btnScoreAway3.isHidden = false
                
                btnFoulAway.frame = CGRect(x: rightScoreX - basketW - 8 - basketW - 6, y: bottomScoreY, width: basketW, height: scoreBtnSize)
                btnFoulAway.layer.cornerRadius = 14
                btnFoulAway.backgroundColor = darkBg
                btnFoulAway.setTitleColor(UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0), for: .normal)
                btnFoulAway.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
                btnFoulAway.isHidden = false
            } else {
                btnScoreAway2.isHidden = true
                btnScoreAway3.isHidden = true
                btnFoulAway.isHidden = true
            }
            
            // Bring all control buttons to front over scoreboardView
            let mode0Buttons: [UIView] = [
                closeButton, modeButton, shareLiveButton, shareRemoteButton, replayButton, highlightButton,
                zoomInButton, zoomOutButton, startStreamButton, muteButton, sponsorButton,
                btnScoreHome, btnTimeoutHome, btnMinusHome, btnFoulHome, btnScoreAway, btnTimeoutAway, btnMinusAway, btnFoulAway,
                btnScoreHome2, btnScoreHome3, btnScoreAway2, btnScoreAway3, btnEndQuarter, btnSoccerTimer, btnDartsCalc
            ]
            mode0Buttons.forEach { view.bringSubviewToFront($0) }
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
        if localState.showScrollText && localState.scrollMessage.isEmpty {
            localState.scrollMessage = UserDefaults.standard.string(forKey: "scrolling_text_content") ?? UserDefaults.standard.string(forKey: "saved_scrolling_text_slot_1") ?? "\(localState.teamA) vs \(localState.teamB) • DIRETTA STREAMING"
        }
        updateLocalState()
        StreamManager.shared.videoEffect.triggerOverlayUpdate(state: self.localState)
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
        if let btnFoulA = btnFoulHome {
            btnFoulA.setTitle("F:\(localState.foulsA)", for: .normal)
        }
        if let btnFoulB = btnFoulAway {
            btnFoulB.setTitle("F:\(localState.foulsB)", for: .normal)
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
    
    @objc func incFoulA() {
        localState.foulsA += 1
        updateLocalState()
    }
    
    @objc func incFoulB() {
        localState.foulsB += 1
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
        if sport == "basket" {
            scoreboardView?.triggerTripleAlert()
            StreamManager.shared.videoEffect.scoreboardView?.triggerTripleAlert()
            showToast(message: "triple_alert".localized.uppercased())
        }
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
        if sport == "basket" {
            scoreboardView?.triggerTripleAlert()
            StreamManager.shared.videoEffect.scoreboardView?.triggerTripleAlert()
            showToast(message: "triple_alert".localized.uppercased())
        }
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
    
    // MARK: - Soccer / Handball Timer Actions
    
    @objc func toggleSoccerTimer() {
        localState.timerRunning.toggle()
        updateSoccerTimerButton()
        updateLocalState(saveHistory: false)
        showToast(message: localState.timerRunning ? "⏱️ Timer Avviato" : "⏸️ Timer in Pausa")
    }
    
    @objc func resetSoccerTimer() {
        localState.timerSeconds = 0
        localState.timerRunning = false
        updateSoccerTimerButton()
        updateLocalState(saveHistory: false)
        showToast(message: "🔄 Timer Azzerato")
    }
    
    @objc func resetSoccerTimerAction(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let alert = UIAlertController(title: "⏱️ Reset Timer", message: "Vuoi azzerare il cronometro della partita?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Annulla", style: .cancel))
        alert.addAction(UIAlertAction(title: "Azzera", style: .destructive) { [weak self] _ in
            self?.resetSoccerTimer()
        })
        present(alert, animated: true)
    }
    
    func updateSoccerTimerButton() {
        let m = localState.timerSeconds / 60
        let s = localState.timerSeconds % 60
        let timeStr = String(format: "%02d:%02d", m, s)
        let icon = localState.timerRunning ? "⏸️" : "▶️"
        btnSoccerTimer?.setTitle("\(icon) \(timeStr)", for: .normal)
        btnSoccerTimer?.backgroundColor = localState.timerRunning ? UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.95) : UIColor(red: 16/255, green: 185/255, blue: 129/255, alpha: 0.95)
    }

    // MARK: - Darts Calculator Modal
    
    @objc func toggleDartsKeypad() {
        if let container = dartsKeypadContainer, container.superview != nil {
            closeDartsKeypad()
        } else {
            openDartsKeypad()
        }
    }
    
    func openDartsKeypad() {
        dartsKeypadContainer?.removeFromSuperview()
        
        let container = UIView()
        container.backgroundColor = UIColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.97)
        container.layer.cornerRadius = 18
        container.layer.borderWidth = 1.5
        container.layer.borderColor = UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 0.8).cgColor
        container.clipsToBounds = true
        
        let modalW: CGFloat = 340
        let modalH: CGFloat = 310
        container.frame = CGRect(x: (view.bounds.width - modalW) / 2, y: (view.bounds.height - modalH) / 2, width: modalW, height: modalH)
        
        // 1. Header: Player Selection + Close
        let pA = UIButton(type: .system)
        pA.frame = CGRect(x: 12, y: 10, width: 120, height: 32)
        pA.layer.cornerRadius = 8
        pA.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
        let nameA = localState.teamA.isEmpty ? "CASA (A)" : localState.teamA
        pA.setTitle("🎯 \(nameA)", for: .normal)
        pA.addTarget(self, action: #selector(dartsSelectPlayerA), for: .touchUpInside)
        container.addSubview(pA)
        self.dartsPlayerBtnA = pA
        
        let pB = UIButton(type: .system)
        pB.frame = CGRect(x: 138, y: 10, width: 120, height: 32)
        pB.layer.cornerRadius = 8
        pB.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
        let nameB = localState.teamB.isEmpty ? "OSPITE (B)" : localState.teamB
        pB.setTitle("🎯 \(nameB)", for: .normal)
        pB.addTarget(self, action: #selector(dartsSelectPlayerB), for: .touchUpInside)
        container.addSubview(pB)
        self.dartsPlayerBtnB = pB
        
        let btnClose = UIButton(type: .system)
        btnClose.frame = CGRect(x: modalW - 40, y: 10, width: 30, height: 32)
        btnClose.setTitle("✕", for: .normal)
        btnClose.setTitleColor(.white, for: .normal)
        btnClose.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        btnClose.addTarget(self, action: #selector(closeDartsKeypad), for: .touchUpInside)
        container.addSubview(btnClose)
        
        // 2. Score Preview Display
        let lblDisplay = UILabel(frame: CGRect(x: 12, y: 48, width: modalW - 24, height: 36))
        lblDisplay.backgroundColor = UIColor(red: 30/255, green: 41/255, blue: 59/255, alpha: 1.0)
        lblDisplay.textColor = .white
        lblDisplay.textAlignment = .center
        lblDisplay.layer.cornerRadius = 8
        lblDisplay.clipsToBounds = true
        lblDisplay.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .bold)
        container.addSubview(lblDisplay)
        self.dartsInputLabel = lblDisplay
        
        // 3. Numeric Keypad (4 rows x 3 cols)
        let keys = [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
            ["C", "0", "⌫"]
        ]
        let padStartY: CGFloat = 90
        let keyW: CGFloat = (modalW - 24 - 16) / 3
        let keyH: CGFloat = 36
        let keyGap: CGFloat = 6
        
        for (rIdx, row) in keys.enumerated() {
            for (cIdx, key) in row.enumerated() {
                let btn = UIButton(type: .system)
                btn.frame = CGRect(x: 12 + CGFloat(cIdx) * (keyW + keyGap), y: padStartY + CGFloat(rIdx) * (keyH + keyGap), width: keyW, height: keyH)
                btn.setTitle(key, for: .normal)
                btn.layer.cornerRadius = 8
                btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
                
                if key == "C" {
                    btn.backgroundColor = UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.8)
                    btn.setTitleColor(.white, for: .normal)
                    btn.addTarget(self, action: #selector(dartsKeypadClear), for: .touchUpInside)
                } else if key == "⌫" {
                    btn.backgroundColor = UIColor(red: 234/255, green: 179/255, blue: 8/255, alpha: 0.8)
                    btn.setTitleColor(.black, for: .normal)
                    btn.addTarget(self, action: #selector(dartsKeypadBackspace), for: .touchUpInside)
                } else {
                    btn.backgroundColor = UIColor(red: 51/255, green: 65/255, blue: 85/255, alpha: 0.9)
                    btn.setTitleColor(.white, for: .normal)
                    btn.addTarget(self, action: #selector(dartsKeypadTapped(_:)), for: .touchUpInside)
                }
                container.addSubview(btn)
            }
        }
        
        // 4. Action Buttons: BUST & SOTTRAI
        let actionY = padStartY + 4 * (keyH + keyGap) + 4
        let bustBtn = UIButton(type: .system)
        bustBtn.frame = CGRect(x: 12, y: actionY, width: 90, height: 38)
        bustBtn.setTitle("💥 BUST", for: .normal)
        bustBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        bustBtn.setTitleColor(.white, for: .normal)
        bustBtn.backgroundColor = UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 0.9)
        bustBtn.layer.cornerRadius = 8
        bustBtn.addTarget(self, action: #selector(dartsBustAction), for: .touchUpInside)
        container.addSubview(bustBtn)
        
        let subBtn = UIButton(type: .system)
        subBtn.frame = CGRect(x: 110, y: actionY, width: modalW - 122, height: 38)
        subBtn.setTitle("🎯 CONFERMA SOTTRAI", for: .normal)
        subBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        subBtn.setTitleColor(.white, for: .normal)
        subBtn.backgroundColor = UIColor(red: 16/255, green: 185/255, blue: 129/255, alpha: 0.95)
        subBtn.layer.cornerRadius = 8
        subBtn.addTarget(self, action: #selector(dartsSubtractAction), for: .touchUpInside)
        container.addSubview(subBtn)
        
        view.addSubview(container)
        view.bringSubviewToFront(container)
        self.dartsKeypadContainer = container
        
        updateDartsKeypadUI()
    }
    
    @objc func closeDartsKeypad() {
        dartsKeypadContainer?.removeFromSuperview()
        dartsKeypadContainer = nil
        dartsCurrentInput = ""
    }
    
    @objc func dartsSelectPlayerA() {
        localState.dartsActivePlayer = "A"
        updateDartsKeypadUI()
        updateLocalState(saveHistory: false)
    }
    
    @objc func dartsSelectPlayerB() {
        localState.dartsActivePlayer = "B"
        updateDartsKeypadUI()
        updateLocalState(saveHistory: false)
    }
    
    @objc func dartsKeypadTapped(_ sender: UIButton) {
        guard let digit = sender.title(for: .normal) else { return }
        if dartsCurrentInput.count < 3 {
            let nextInput = dartsCurrentInput + digit
            if let val = Int(nextInput), val <= 180 {
                dartsCurrentInput = nextInput
            }
        }
        updateDartsKeypadUI()
    }
    
    @objc func dartsKeypadClear() {
        dartsCurrentInput = ""
        updateDartsKeypadUI()
    }
    
    @objc func dartsKeypadBackspace() {
        if !dartsCurrentInput.isEmpty {
            dartsCurrentInput.removeLast()
        }
        updateDartsKeypadUI()
    }
    
    @objc func dartsSubtractAction() {
        let pts = Int(dartsCurrentInput) ?? 0
        guard pts > 0 else {
            showToast(message: "Inserisci i punti tirati (1-180)")
            return
        }
        let isHome = (localState.dartsActivePlayer != "B")
        checkDartsLeg(isHome: isHome, subtract: pts)
        dartsCurrentInput = ""
        updateDartsKeypadUI()
    }
    
    @objc func dartsBustAction() {
        showToast(message: "💥 BUST! Turno passato.")
        localState.dartsActivePlayer = (localState.dartsActivePlayer == "A") ? "B" : "A"
        updateLocalState()
        dartsCurrentInput = ""
        updateDartsKeypadUI()
    }
    
    func updateDartsKeypadUI() {
        let isA = (localState.dartsActivePlayer != "B")
        dartsPlayerBtnA?.backgroundColor = isA ? UIColor(red: 236/255, green: 72/255, blue: 153/255, alpha: 0.95) : UIColor(red: 51/255, green: 65/255, blue: 85/255, alpha: 0.8)
        dartsPlayerBtnA?.setTitleColor(.white, for: .normal)
        
        dartsPlayerBtnB?.backgroundColor = !isA ? UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 0.95) : UIColor(red: 51/255, green: 65/255, blue: 85/255, alpha: 0.8)
        dartsPlayerBtnB?.setTitleColor(isA ? .white : .black, for: .normal)
        
        let curScore = isA ? localState.scoreA : localState.scoreB
        let pts = Int(dartsCurrentInput) ?? 0
        let rem = curScore - pts
        let inputStr = dartsCurrentInput.isEmpty ? "0" : dartsCurrentInput
        let pName = isA ? (localState.teamA.isEmpty ? "CASA" : localState.teamA) : (localState.teamB.isEmpty ? "OSPITE" : localState.teamB)
        
        dartsInputLabel?.text = "\(pName): \(curScore)  −  [\(inputStr)]  =  \(rem)"
    }
    
    @objc func toggleSponsor() {
        guard StoreKitManager.shared.canUseFeature(.sponsors) else {
            showToast(message: "⭐ Funzionalità Sponsor disponibile con Premium")
            return
        }
        let nextVal = !localState.fullScreenSponsor
        localState.fullScreenSponsor = nextVal
        localState.showSponsor = nextVal
        updateLocalState()
        StreamManager.shared.videoEffect.triggerOverlayUpdate(state: self.localState)
        showToast(message: nextVal ? "🖼️ Sponsor Schermo Intero ATTIVO" : "🖼️ Sponsor Schermo Intero DISATTIVATO")
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
        let iosLinkStr = "https://volleystreampro.com/remote?code=\(sessionId)&os=ios"
        let androidLinkStr = "https://volleystreampro.com/remote?code=\(sessionId)&os=android"
        
        let msg = """
        🏐 VolleyStream Pro - Telecomando Regia

        🔑 Codice Sessione: \(sessionId)

        🍏 Link Telecomando iOS (iPhone / iPad):
        \(iosLinkStr)

        🤖 Link Telecomando ANDROID (Chrome / Web):
        \(androidLinkStr)
        """
        
        var activityItems: [Any] = [msg]
        if let iosUrl = URL(string: iosLinkStr) {
            activityItems.append(iosUrl)
        }
        if let androidUrl = URL(string: androidLinkStr) {
            activityItems.append(androidUrl)
        }
        
        let activity = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        if let popover = activity.popoverPresentationController {
            popover.sourceView = shareRemoteButton
        }
        present(activity, animated: true)
    }
    
    @objc func startLive() {
        if startStreamButton.title(for: .normal)?.contains("GO") == true {
            showDoNotDisturbAlert { [weak self] in
                self?.executeStartLive()
            }
        } else {
            executeStopLive()
        }
    }
    
    private func showDoNotDisturbAlert(onConfirm: @escaping () -> Void) {
        let alert = UIAlertController(
            title: "🔕 MODALITÀ NON DISTURBARE",
            message: "Prima di avviare la diretta, ti consigliamo vivamente di attivare la modalità 'Non Disturbare' o 'Full Immersion' per evitare che chiamate o notifiche in arrivo interrompano la trasmissione e facciano cadere la connessione.\n\nPuoi aprire direttamente le impostazioni del telefono premendo il pulsante qui sotto.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "⚙️ APRI NON DISTURBARE", style: .default) { [weak self] _ in
            self?.openDoNotDisturbSettings()
        })
        
        alert.addAction(UIAlertAction(title: "🔴 AVVIA DIRETTA", style: .default) { _ in
            onConfirm()
        })
        
        alert.addAction(UIAlertAction(title: "ANNULLA", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    private func openDoNotDisturbSettings() {
        if let dndUrl = URL(string: "App-Prefs:root=DO_NOT_DISTURB"), UIApplication.shared.canOpenURL(dndUrl) {
            UIApplication.shared.open(dndUrl, options: [:], completionHandler: nil)
        } else if let prefsUrl = URL(string: "prefs:root=DO_NOT_DISTURB"), UIApplication.shared.canOpenURL(prefsUrl) {
            UIApplication.shared.open(prefsUrl, options: [:], completionHandler: nil)
        } else if let settingsUrl = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
        }
    }
    
    private func executeStartLive() {
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
    }
    
    private func executeStopLive() {
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
        case let s where s.hasPrefix("DARTS_SUB_"):
            let parts = s.components(separatedBy: "_")
            if parts.count >= 3, let pts = Int(parts[2]) {
                let player = parts.count >= 4 ? parts[3] : (localState.dartsActivePlayer.isEmpty ? "A" : localState.dartsActivePlayer)
                checkDartsLeg(isHome: (player == "A"), subtract: pts)
            }
        case "DARTS_SET_PLAYER_A":
            localState.dartsActivePlayer = "A"
            updateLocalState()
        case "DARTS_SET_PLAYER_B":
            localState.dartsActivePlayer = "B"
            updateLocalState()
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
            updateSoccerTimerButton()
            updateLocalState(saveHistory: false)
        case "SOCCER_TIMER_RESET":
            localState.timerSeconds = 0
            localState.timerRunning = false
            updateSoccerTimerButton()
            updateLocalState(saveHistory: false)
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



