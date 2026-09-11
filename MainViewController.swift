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
    var currentMode: Int = 0 // 0 = Normal, 1 = Grid, 2 = Clean
    
    var initialSport: String = "volley"
    var initialTheme: String = "neon"
    var sessionId: String?
    var onDismissRequested: (() -> Void)?
    
    var localState = RemoteMatchState()
    var isAudioMuted = false
    
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
        
        let isGrid = (currentMode == 1)
        let isClean = (currentMode == 2)
        
        // Hide / Show controls based on Clean mode
        let allControls: [UIView] = [
            closeButton, modeButton, shareLiveButton, shareRemoteButton, replayButton, highlightButton,
            zoomInButton, zoomOutButton, startStreamButton, muteButton, sponsorButton,
            btnScoreHome, btnTimeoutHome, btnMinusHome, btnScoreAway, btnTimeoutAway, btnMinusAway,
            btnScoreHome2, btnScoreHome3, btnScoreAway2, btnScoreAway3, btnEndQuarter
        ]
        
        if isClean {
            lfView.frame = view.bounds
            lfView.layer.cornerRadius = 0
            scoreboardView.transform = .identity
            scoreboardView.frame = CGRect(x: safeLeft, y: safeTop, width: 280, height: 54)
            gridLayer?.isHidden = true
            allControls.forEach { $0.isHidden = true }
            return
        } else {
            allControls.forEach { $0.isHidden = false }
        }
        
        let isBasket = (self.localState.sportType.lowercased() == "basket")
        let isSoccer = (self.localState.sportType.lowercased() == "soccer")
        let isBiliardo = (self.localState.sportType.lowercased() == "biliardo" || self.localState.sportType.lowercased() == "billiards")
        let isTennis = (self.localState.sportType.lowercased() == "tennis" || self.localState.sportType.lowercased() == "padel")
        
        btnScoreHome2.isHidden = !isBasket
        btnScoreHome3.isHidden = !isBasket
        btnScoreAway2.isHidden = !isBasket
        btnScoreAway3.isHidden = !isBasket
        btnEndQuarter.isHidden = !(isBasket || isSoccer || isBiliardo)
        
        // Dynamic labels for sports
        if isSoccer {
            btnTimeoutHome.setTitle("RC", for: .normal)
            btnTimeoutHome.backgroundColor = .systemRed
            btnTimeoutAway.setTitle("RC", for: .normal)
            btnTimeoutAway.backgroundColor = .systemRed
            btnEndQuarter.setTitle("FINE TEMPO", for: .normal)
        } else if isTennis {
            btnTimeoutHome.setTitle("GAME", for: .normal)
            btnTimeoutHome.backgroundColor = .systemPurple
            btnTimeoutAway.setTitle("GAME", for: .normal)
            btnTimeoutAway.backgroundColor = .systemPurple
        } else if isBiliardo {
            btnEndQuarter.setTitle("NEXT FRAME", for: .normal)
        } else {
            btnTimeoutHome.setTitle("T.O.", for: .normal)
            btnTimeoutHome.backgroundColor = UIColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.85)
            btnTimeoutAway.setTitle("T.O.", for: .normal)
            btnTimeoutAway.backgroundColor = UIColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.85)
            btnEndQuarter.setTitle("FINE QUARTO", for: .normal)
        }
        
        if isGrid {
            // === GRID MODE: PREVIEW ON LEFT, FULL CONTROLS ON RIGHT ===
            let safeW = w - safeLeft - safeRight
            let safeH = h - safeTop - safeBottom
            let previewW = safeW * 0.48
            let previewH = safeH
            
            lfView.frame = CGRect(x: safeLeft, y: safeTop, width: previewW, height: previewH)
            lfView.layer.cornerRadius = 12
            lfView.clipsToBounds = true
            scoreboardView.transform = CGAffineTransform(scaleX: 0.62, y: 0.62)
            scoreboardView.frame.origin = CGPoint(x: safeLeft + 6, y: safeTop + 6)
            gridLayer?.isHidden = false
            
            let panelX = safeLeft + previewW + 10
            let panelW = safeW - previewW - 10
            
            // Row 1: Top Tools (8 buttons)
            let row1Y = safeTop
            let numTopBtns: CGFloat = 8
            let topGap: CGFloat = 5
            let topBtnW = (panelW - (numTopBtns - 1) * topGap) / numTopBtns
            let topBtnH = min(36, topBtnW)
            
            closeButton.frame = CGRect(x: panelX + 0 * (topBtnW + topGap), y: row1Y, width: topBtnW, height: topBtnH)
            modeButton.frame = CGRect(x: panelX + 1 * (topBtnW + topGap), y: row1Y, width: topBtnW, height: topBtnH)
            shareLiveButton.frame = CGRect(x: panelX + 2 * (topBtnW + topGap), y: row1Y, width: topBtnW, height: topBtnH)
            shareRemoteButton.frame = CGRect(x: panelX + 3 * (topBtnW + topGap), y: row1Y, width: topBtnW, height: topBtnH)
            replayButton.frame = CGRect(x: panelX + 4 * (topBtnW + topGap), y: row1Y, width: topBtnW, height: topBtnH)
            highlightButton.frame = CGRect(x: panelX + 5 * (topBtnW + topGap), y: row1Y, width: topBtnW, height: topBtnH)
            zoomInButton.frame = CGRect(x: panelX + 6 * (topBtnW + topGap), y: row1Y, width: topBtnW, height: topBtnH)
            zoomOutButton.frame = CGRect(x: panelX + 7 * (topBtnW + topGap), y: row1Y, width: topBtnW, height: topBtnH)
            
            // Row 2: Stream & Broadcast Action Bar
            let row2Y = row1Y + topBtnH + 8
            let row2H: CGFloat = 40
            let liveW: CGFloat = max(70, panelW * 0.28)
            let sideBtnW: CGFloat = 38
            
            startStreamButton.frame = CGRect(x: panelX, y: row2Y, width: liveW, height: row2H)
            muteButton.frame = CGRect(x: panelX + liveW + 6, y: row2Y, width: sideBtnW, height: row2H)
            sponsorButton.frame = CGRect(x: panelX + liveW + 6 + sideBtnW + 6, y: row2Y, width: sideBtnW, height: row2H)
            
            let eqX = panelX + liveW + 6 + sideBtnW + 6 + sideBtnW + 6
            let eqW = panelX + panelW - eqX
            btnEndQuarter.frame = CGRect(x: eqX, y: row2Y, width: max(80, eqW), height: row2H)
            
            // Row 3 & 4: Scoring Buttons (Home on left, Away on right)
            let row3Y = row2Y + row2H + 10
            let row3H = safeTop + previewH - row3Y
            let teamColW = (panelW - 10) / 2
            
            // Team Home Controls
            let teamAX = panelX
            let subBtnW: CGFloat = 42
            let mainScoreW = teamColW - subBtnW - 6
            let subH = (row3H - 6) / 2
            
            btnTimeoutHome.frame = CGRect(x: teamAX, y: row3Y, width: subBtnW, height: subH)
            btnMinusHome.frame = CGRect(x: teamAX, y: row3Y + subH + 6, width: subBtnW, height: subH)
            btnScoreHome.frame = CGRect(x: teamAX + subBtnW + 6, y: row3Y, width: mainScoreW, height: row3H)
            
            if isBasket {
                let basketW: CGFloat = 30
                btnScoreHome.frame = CGRect(x: teamAX + subBtnW + 6, y: row3Y, width: mainScoreW - basketW - 4, height: row3H)
                btnScoreHome2.frame = CGRect(x: teamAX + subBtnW + 6 + mainScoreW - basketW, y: row3Y, width: basketW, height: subH)
                btnScoreHome3.frame = CGRect(x: teamAX + subBtnW + 6 + mainScoreW - basketW, y: row3Y + subH + 6, width: basketW, height: subH)
            }
            
            // Team Away Controls
            let teamBX = panelX + teamColW + 10
            if isBasket {
                let basketW: CGFloat = 30
                btnScoreAway2.frame = CGRect(x: teamBX, y: row3Y, width: basketW, height: subH)
                btnScoreAway3.frame = CGRect(x: teamBX, y: row3Y + subH + 6, width: basketW, height: subH)
                btnScoreAway.frame = CGRect(x: teamBX + basketW + 4, y: row3Y, width: mainScoreW - basketW - 4, height: row3H)
                btnTimeoutAway.frame = CGRect(x: teamBX + mainScoreW + 6, y: row3Y, width: subBtnW, height: subH)
                btnMinusAway.frame = CGRect(x: teamBX + mainScoreW + 6, y: row3Y + subH + 6, width: subBtnW, height: subH)
            } else {
                btnScoreAway.frame = CGRect(x: teamBX, y: row3Y, width: mainScoreW, height: row3H)
                btnTimeoutAway.frame = CGRect(x: teamBX + mainScoreW + 6, y: row3Y, width: subBtnW, height: subH)
                btnMinusAway.frame = CGRect(x: teamBX + mainScoreW + 6, y: row3Y + subH + 6, width: subBtnW, height: subH)
            }
            
        } else {
            // === NORMAL FULLSCREEN MODE ===
            lfView.frame = view.bounds
            lfView.layer.cornerRadius = 0
            scoreboardView.transform = .identity
            scoreboardView.frame = CGRect(x: safeLeft, y: safeTop, width: 280, height: 54)
            gridLayer?.isHidden = true
            
            // 1. TOP RIGHT ACTION BAR
            let isPortrait = w < h
            let btnSize: CGFloat = isPortrait ? min(34, (w - safeLeft - safeRight) / 8) : 40
            let btnGap: CGFloat = isPortrait ? 4 : 8
            var currentRightX = w - safeRight - btnSize
            
            closeButton.frame = CGRect(x: currentRightX, y: safeTop, width: btnSize, height: btnSize)
            currentRightX -= (btnSize + btnGap)
            
            modeButton.frame = CGRect(x: currentRightX, y: safeTop, width: btnSize, height: btnSize)
            currentRightX -= (btnSize + btnGap)
            
            shareLiveButton.frame = CGRect(x: currentRightX, y: safeTop, width: btnSize, height: btnSize)
            currentRightX -= (btnSize + btnGap)
            
            shareRemoteButton.frame = CGRect(x: currentRightX, y: safeTop, width: btnSize, height: btnSize)
            currentRightX -= (btnSize + btnGap)
            
            replayButton.frame = CGRect(x: currentRightX, y: safeTop, width: btnSize, height: btnSize)
            currentRightX -= (btnSize + btnGap)
            
            highlightButton.frame = CGRect(x: currentRightX, y: safeTop, width: btnSize, height: btnSize)
            
            // Zoom Buttons
            let zoomW: CGFloat = isPortrait ? 28 : 36
            let zoomH: CGFloat = isPortrait ? 26 : 32
            let zoomX = w - safeRight - zoomW
            zoomInButton.frame = CGRect(x: zoomX, y: safeTop + btnSize + 10, width: zoomW, height: zoomH)
            zoomOutButton.frame = CGRect(x: zoomX, y: safeTop + btnSize + 10 + zoomH + 4, width: zoomW, height: zoomH)
            
            // 2. BOTTOM CENTER CONTROLS
            let centerX = w / 2
            let streamBtnW: CGFloat = isPortrait ? 60 : 72
            let streamBtnH: CGFloat = isPortrait ? 46 : 54
            let bottomCenterY = h - safeBottom - streamBtnH
            let sideBtnSize: CGFloat = isPortrait ? 38 : 44
            
            startStreamButton.frame = CGRect(x: centerX - streamBtnW / 2, y: bottomCenterY, width: streamBtnW, height: streamBtnH)
            muteButton.frame = CGRect(x: centerX - streamBtnW / 2 - sideBtnSize - 8, y: bottomCenterY + (streamBtnH - sideBtnSize) / 2, width: sideBtnSize, height: sideBtnSize)
            sponsorButton.frame = CGRect(x: centerX + streamBtnW / 2 + 8, y: bottomCenterY + (streamBtnH - sideBtnSize) / 2, width: sideBtnSize, height: sideBtnSize)
            btnEndQuarter.frame = CGRect(x: centerX - 60, y: bottomCenterY - 36, width: 120, height: 30)
            
            // 3. BOTTOM LEFT CONTROLS (Team A)
            let scoreBtnSize: CGFloat = isPortrait ? min(54, (w - 180) / 2) : 70
            let subBtnW: CGFloat = isPortrait ? 40 : 50
            let subBtnH: CGFloat = (scoreBtnSize - 4) / 2
            let bottomScoreY = h - safeBottom - scoreBtnSize
            
            btnTimeoutHome.frame = CGRect(x: safeLeft, y: bottomScoreY, width: subBtnW, height: subBtnH)
            btnMinusHome.frame = CGRect(x: safeLeft, y: bottomScoreY + subBtnH + 4, width: subBtnW, height: subBtnH)
            btnScoreHome.frame = CGRect(x: safeLeft + subBtnW + 8, y: bottomScoreY, width: scoreBtnSize, height: scoreBtnSize)
            
            if isBasket {
                let basketW: CGFloat = isPortrait ? 34 : 44
                btnScoreHome2.frame = CGRect(x: safeLeft + subBtnW + scoreBtnSize + 8, y: bottomScoreY, width: basketW, height: subBtnH)
                btnScoreHome3.frame = CGRect(x: safeLeft + subBtnW + scoreBtnSize + 8, y: bottomScoreY + subBtnH + 4, width: basketW, height: subBtnH)
            }
            
            // 4. BOTTOM RIGHT CONTROLS (Team B)
            let rightSubX = w - safeRight - subBtnW
            btnTimeoutAway.frame = CGRect(x: rightSubX, y: bottomScoreY, width: subBtnW, height: subBtnH)
            btnMinusAway.frame = CGRect(x: rightSubX, y: bottomScoreY + subBtnH + 4, width: subBtnW, height: subBtnH)
            
            let rightScoreX = rightSubX - scoreBtnSize - 8
            btnScoreAway.frame = CGRect(x: rightScoreX, y: bottomScoreY, width: scoreBtnSize, height: scoreBtnSize)
            
            if isBasket {
                let basketW: CGFloat = isPortrait ? 34 : 44
                btnScoreAway2.frame = CGRect(x: rightScoreX - basketW - 8, y: bottomScoreY, width: basketW, height: subBtnH)
                btnScoreAway3.frame = CGRect(x: rightScoreX - basketW - 8, y: bottomScoreY + subBtnH + 4, width: basketW, height: subBtnH)
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
    
    func updateLocalState() {
        localState.lastUpdate = Int64(Date().timeIntervalSince1970 * 1000)
        scoreboardView.updateFromState(localState)
        StreamManager.shared.videoEffect.currentState = localState
        FirebaseManager.shared.updateMatchState(localState)
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
    
    @objc func incScoreA() {
        let sport = localState.sportType.lowercased()
        if sport == "tennis" || sport == "padel" {
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
    
    @objc func incScoreA2() { localState.scoreA += 2; updateLocalState() }
    @objc func incScoreA3() { localState.scoreA += 3; updateLocalState() }
    
    @objc func decScoreA() {
        let sport = localState.sportType.lowercased()
        if sport == "tennis" || sport == "padel" {
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
        if sport == "soccer" {
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
        if sport == "tennis" || sport == "padel" {
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
    
    @objc func incScoreB2() { localState.scoreB += 2; updateLocalState() }
    @objc func incScoreB3() { localState.scoreB += 3; updateLocalState() }
    
    @objc func decScoreB() {
        let sport = localState.sportType.lowercased()
        if sport == "tennis" || sport == "padel" {
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
        if sport == "soccer" {
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
        ReplayManager.shared.startPlayback()
    }
    
    @objc func triggerHighlight() {
        // Salva clip highlight
    }
    
    private func handleRemoteCommand(_ command: String) {
        if command == "TRIGGER_REPLAY" {
            ReplayManager.shared.startPlayback()
            localState.isReplaying = true
            FirebaseManager.shared.updateMatchState(localState)
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
            
            if UserDefaults.standard.bool(forKey: "record_locally") {
                LocalVideoRecorder.shared.startRecording()
            }
            
            startStreamButton.setTitle("STOP", for: .normal)
            startStreamButton.backgroundColor = .systemGray
        } else {
            StreamManager.shared.stopStreaming()
            
            if LocalVideoRecorder.shared.isRecordingState {
                LocalVideoRecorder.shared.stopRecording { savedUrl in
                    if let _ = savedUrl {
                        print("Video salvato.")
                    }
                }
            }
            
            startStreamButton.setTitle("GO\nLIVE", for: .normal)
            startStreamButton.backgroundColor = UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1.0)
        }
    }
}



