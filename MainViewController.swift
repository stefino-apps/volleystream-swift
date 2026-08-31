import UIKit
import HaishinKit
import AVFoundation

class MainViewController: UIViewController {

    var lfView: MTHKView!
    var scoreboardView: ScoreboardOverlayView!
    
    // UI Controls
    var startStreamButton: UIButton!
    var modeButton: UIButton!
    var shareLiveButton: UIButton!
    var shareRemoteButton: UIButton!
    var muteButton: UIButton!
    var sponsorButton: UIButton!
    var replayButton: UIButton!
    var highlightButton: UIButton!
    
    // Control Buttons
    var btnScoreHome: UIButton!
    var btnScoreAway: UIButton!
    var btnMinusHome: UIButton!
    var btnMinusAway: UIButton!
    var btnTimeoutHome: UIButton!
    var btnTimeoutAway: UIButton!
    
    // Basket Specific Buttons
    var btnScoreHome2: UIButton!
    var btnScoreHome3: UIButton!
    var btnScoreAway2: UIButton!
    var btnScoreAway3: UIButton!
    var btnEndQuarter: UIButton!
    
    var lblTimer: UILabel!
    
    // Grid Overlay
    var gridLayer: CAShapeLayer?
    var currentMode: Int = 0 // 0 = Normal, 1 = Grid, 2 = Clean
    
    var initialSport: String = "volley"
    var initialTheme: String = "neon"
    var sessionId: String?
    
    var localState = RemoteMatchState()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        localState.sportType = initialSport
        localState.overlayTheme = initialTheme
        localState.teamA = AppPreferences.shared.teamHome
        localState.teamB = AppPreferences.shared.teamAway
        localState.isPuntoDeOro = UserDefaults.standard.bool(forKey: "punto_de_oro")
        
        setupCameraView()
        setupScoreboardOverlay()
        setupControls()
        setupGridLayer()
        updateLocalState()
        
        let sessionId = UserDefaults.standard.string(forKey: "remote_session_id") ?? "REGIA_01"
        FirebaseManager.shared.createSession(id: sessionId) { success in
            print("Firebase Host Session Created: \(success)")
        }
        
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !UserDefaults.standard.bool(forKey: "has_seen_tutorial") {
            let tutorial = TutorialOverlayView()
            tutorial.startTutorial(in: self.view, steps: [
                (view: startStreamButton as UIView?, text: "Premi qui per andare LIVE e registrare!"),
                (view: modeButton as UIView?, text: "Cambia il layout (Normale, Griglia, Clean)"),
                (view: btnScoreHome as UIView?, text: "Tocca per assegnare i punti! (E cambia battuta in automatico)"),
                (view: shareRemoteButton as UIView?, text: "Condividi il Telecomando con un assistente!"),
                (view: scoreboardView as UIView?, text: "Questo è il tabellone che vedranno da casa!")
            ])
        }
    }
    
    private var hasLayoutOnce = false
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Only layout if bounds are valid landscape
        if !hasLayoutOnce && view.bounds.width > view.bounds.height {
            hasLayoutOnce = true
            lfView.frame = view.bounds
            // Trigger layout recalculation using toggleMode logic without changing mode
            let targetMode = currentMode
            currentMode = (targetMode + 2) % 3
            toggleMode()
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
        if localState.sportType == "tennis" || localState.sportType == "padel" {
            if localState.tennisPointsA == 3 && localState.tennisPointsB < 3 {
                localState.tennisGamesA += 1
                localState.tennisPointsA = 0
                localState.tennisPointsB = 0
            } else if localState.tennisPointsA == 3 && localState.tennisPointsB == 3 {
                if localState.sportType == "padel" && localState.isPuntoDeOro {
                    // Chi fa punto qui, vince il game
                    localState.tennisGamesA += 1
                    localState.tennisPointsA = 0
                    localState.tennisPointsB = 0
                } else {
                    localState.tennisPointsA = 4
                }
            } else if localState.tennisPointsA == 3 && localState.tennisPointsB == 4 {
                localState.tennisPointsB = 3
            } else if localState.tennisPointsA == 4 {
                localState.tennisGamesA += 1
                localState.tennisPointsA = 0
                localState.tennisPointsB = 0
            } else {
                localState.tennisPointsA += 1
            }
        } else {
            localState.scoreA += 1
            if localState.sportType == "volley" || localState.sportType == "beach volley" {
                localState.servingTeam = "A"
            }
        }
        updateLocalState()
    }
    
    @objc func incScoreA2() { localState.scoreA += 2; updateLocalState() }
    @objc func incScoreA3() { localState.scoreA += 3; updateLocalState() }
    
    @objc func decScoreA() {
        if localState.sportType == "tennis" || localState.sportType == "padel" {
            if localState.tennisPointsA > 0 { localState.tennisPointsA -= 1 }
        } else {
            if localState.scoreA > 0 { localState.scoreA -= 1 }
        }
        updateLocalState()
    }
    
    @objc func toA() {
        if localState.sportType == "soccer" {
            localState.redCardsA += 1
        } else if localState.sportType == "tennis" || localState.sportType == "padel" {
            localState.tennisGamesA += 1
        } else {
            localState.timeoutA += 1
        }
        updateLocalState()
    }
    
    @objc func incScoreB() {
        if localState.sportType == "tennis" || localState.sportType == "padel" {
            if localState.tennisPointsB == 3 && localState.tennisPointsA < 3 {
                localState.tennisGamesB += 1
                localState.tennisPointsA = 0
                localState.tennisPointsB = 0
            } else if localState.tennisPointsB == 3 && localState.tennisPointsA == 3 {
                if localState.sportType == "padel" && localState.isPuntoDeOro {
                    localState.tennisGamesB += 1
                    localState.tennisPointsA = 0
                    localState.tennisPointsB = 0
                } else {
                    localState.tennisPointsB = 4
                }
            } else if localState.tennisPointsB == 3 && localState.tennisPointsA == 4 {
                localState.tennisPointsA = 3
            } else if localState.tennisPointsB == 4 {
                localState.tennisGamesB += 1
                localState.tennisPointsA = 0
                localState.tennisPointsB = 0
            } else {
                localState.tennisPointsB += 1
            }
        } else {
            localState.scoreB += 1
            if localState.sportType == "volley" || localState.sportType == "beach volley" {
                localState.servingTeam = "B"
            }
        }
        updateLocalState()
    }
    
    @objc func incScoreB2() { localState.scoreB += 2; updateLocalState() }
    @objc func incScoreB3() { localState.scoreB += 3; updateLocalState() }
    
    @objc func decScoreB() {
        if localState.sportType == "tennis" || localState.sportType == "padel" {
            if localState.tennisPointsB > 0 { localState.tennisPointsB -= 1 }
        } else {
            if localState.scoreB > 0 { localState.scoreB -= 1 }
        }
        updateLocalState()
    }
    
    @objc func toB() {
        if localState.sportType == "soccer" {
            localState.redCardsB += 1
        } else if localState.sportType == "tennis" || localState.sportType == "padel" {
            localState.tennisGamesB += 1
        } else {
            localState.timeoutB += 1
        }
        updateLocalState()
    }
    
    @objc func endQuarter() {
        if localState.currentSet < localState.totalPeriods {
            localState.currentSet += 1
        }
        updateLocalState()
    }
    
    @objc func toggleSponsor() {
        localState.fullScreenSponsor.toggle()
        updateLocalState()
    }
    
    private func setupCameraView() {
        lfView = MTHKView(frame: view.bounds)
        lfView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        lfView.videoGravity = AVLayerVideoGravity.resizeAspectFill
        view.addSubview(lfView)
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
        scoreboardView = ScoreboardOverlayView(frame: CGRect(x: 50, y: 50, width: 400, height: 80))
        view.addSubview(scoreboardView)
        StreamManager.shared.videoEffect.scoreboardView = self.scoreboardView
    }
    
    private func setupControls() {
        let safeY = view.bounds.height - 80
        let centerX = view.bounds.width / 2
        let topY: CGFloat = 20
        let rightX = view.bounds.width - 20
        
        // Centered buttons
        startStreamButton = UIButton(frame: CGRect(x: centerX - 30, y: safeY, width: 60, height: 60))
        startStreamButton.setTitle("GO\nLIVE", for: .normal)
        startStreamButton.titleLabel?.numberOfLines = 2
        startStreamButton.titleLabel?.textAlignment = .center
        startStreamButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        startStreamButton.backgroundColor = .systemRed
        startStreamButton.layer.cornerRadius = 8
        startStreamButton.addTarget(self, action: #selector(startLive), for: .touchUpInside)
        view.addSubview(startStreamButton)
        
        muteButton = UIButton(frame: CGRect(x: centerX - 100, y: safeY, width: 60, height: 60))
        muteButton.setImage(UIImage(systemName: "speaker.wave.2.fill"), for: .normal)
        muteButton.tintColor = .systemTeal
        muteButton.backgroundColor = UIColor(white: 0.1, alpha: 0.8)
        muteButton.layer.cornerRadius = 16
        muteButton.addTarget(self, action: #selector(toggleMute), for: .touchUpInside)
        view.addSubview(muteButton)
        
        sponsorButton = UIButton(frame: CGRect(x: centerX + 40, y: safeY, width: 60, height: 60))
        sponsorButton.setTitle("S", for: .normal)
        sponsorButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)
        sponsorButton.backgroundColor = UIColor(white: 0.1, alpha: 0.8)
        sponsorButton.layer.cornerRadius = 16
        sponsorButton.addTarget(self, action: #selector(toggleSponsor), for: .touchUpInside)
        view.addSubview(sponsorButton)
        
        // Top right buttons
        modeButton = UIButton(frame: CGRect(x: rightX - 60, y: topY, width: 50, height: 50))
        modeButton.setTitle("L", for: .normal)
        modeButton.setTitleColor(.black, for: .normal)
        modeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)
        modeButton.backgroundColor = .systemYellow
        modeButton.layer.cornerRadius = 25
        modeButton.addTarget(self, action: #selector(toggleMode), for: .touchUpInside)
        view.addSubview(modeButton)
        
        shareLiveButton = UIButton(frame: CGRect(x: rightX - 120, y: topY, width: 50, height: 50))
        shareLiveButton.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        shareLiveButton.tintColor = .systemGreen
        shareLiveButton.backgroundColor = UIColor(white: 0.1, alpha: 0.8)
        shareLiveButton.layer.cornerRadius = 12
        shareLiveButton.addTarget(self, action: #selector(shareLive), for: .touchUpInside)
        view.addSubview(shareLiveButton)
        
        shareRemoteButton = UIButton(frame: CGRect(x: rightX - 190, y: topY, width: 60, height: 50))
        shareRemoteButton.setTitle("R.C.", for: .normal)
        shareRemoteButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        shareRemoteButton.backgroundColor = UIColor(white: 0.1, alpha: 0.8)
        shareRemoteButton.layer.cornerRadius = 12
        shareRemoteButton.addTarget(self, action: #selector(shareRemote), for: .touchUpInside)
        view.addSubview(shareRemoteButton)
        
        replayButton = UIButton(frame: CGRect(x: rightX - 260, y: topY, width: 60, height: 50))
        replayButton.setTitle("REP", for: .normal)
        replayButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        replayButton.backgroundColor = .systemBlue
        replayButton.layer.cornerRadius = 12
        replayButton.addTarget(self, action: #selector(triggerReplay), for: .touchUpInside)
        view.addSubview(replayButton)
        
        highlightButton = UIButton(frame: CGRect(x: rightX - 330, y: topY, width: 60, height: 50))
        highlightButton.setTitle("HL", for: .normal)
        highlightButton.setTitleColor(.systemYellow, for: .normal)
        highlightButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        highlightButton.backgroundColor = UIColor(white: 0.1, alpha: 0.8)
        highlightButton.layer.cornerRadius = 12
        highlightButton.addTarget(self, action: #selector(triggerHighlight), for: .touchUpInside)
        view.addSubview(highlightButton)
        
        // Team A (Home) Buttons - Left Side
        btnScoreHome = UIButton(frame: CGRect(x: 100, y: view.bounds.height - 120, width: 90, height: 90))
        btnScoreHome.setTitle("+1", for: .normal)
        btnScoreHome.titleLabel?.font = UIFont.boldSystemFont(ofSize: 32)
        btnScoreHome.backgroundColor = .systemPink
        btnScoreHome.layer.cornerRadius = 24
        btnScoreHome.addTarget(self, action: #selector(incScoreA), for: .touchUpInside)
        view.addSubview(btnScoreHome)
        
        btnTimeoutHome = UIButton(frame: CGRect(x: 20, y: view.bounds.height - 120, width: 70, height: 40))
        btnTimeoutHome.setTitle("T.O.", for: .normal)
        btnTimeoutHome.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btnTimeoutHome.backgroundColor = UIColor(white: 0.1, alpha: 0.8)
        btnTimeoutHome.layer.cornerRadius = 8
        btnTimeoutHome.addTarget(self, action: #selector(toA), for: .touchUpInside)
        view.addSubview(btnTimeoutHome)
        
        btnMinusHome = UIButton(frame: CGRect(x: 20, y: view.bounds.height - 65, width: 70, height: 35))
        btnMinusHome.setTitle("—", for: .normal)
        btnMinusHome.backgroundColor = UIColor(white: 0.1, alpha: 0.8)
        btnMinusHome.layer.cornerRadius = 8
        btnMinusHome.addTarget(self, action: #selector(decScoreA), for: .touchUpInside)
        view.addSubview(btnMinusHome)
        
        // Team B (Away) Buttons - Right Side
        btnScoreAway = UIButton(frame: CGRect(x: rightX - 180, y: view.bounds.height - 120, width: 90, height: 90))
        btnScoreAway.setTitle("+1", for: .normal)
        btnScoreAway.titleLabel?.font = UIFont.boldSystemFont(ofSize: 32)
        btnScoreAway.backgroundColor = .systemTeal
        btnScoreAway.layer.cornerRadius = 24
        btnScoreAway.addTarget(self, action: #selector(incScoreB), for: .touchUpInside)
        view.addSubview(btnScoreAway)
        
        btnTimeoutAway = UIButton(frame: CGRect(x: rightX - 80, y: view.bounds.height - 120, width: 70, height: 40))
        btnTimeoutAway.setTitle("T.O.", for: .normal)
        btnTimeoutAway.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btnTimeoutAway.backgroundColor = UIColor(white: 0.1, alpha: 0.8)
        btnTimeoutAway.layer.cornerRadius = 8
        btnTimeoutAway.addTarget(self, action: #selector(toB), for: .touchUpInside)
        view.addSubview(btnTimeoutAway)
        
        btnMinusAway = UIButton(frame: CGRect(x: rightX - 80, y: view.bounds.height - 65, width: 70, height: 35))
        btnMinusAway.setTitle("—", for: .normal)
        btnMinusAway.backgroundColor = UIColor(white: 0.1, alpha: 0.8)
        btnMinusAway.layer.cornerRadius = 8
        btnMinusAway.addTarget(self, action: #selector(decScoreB), for: .touchUpInside)
        view.addSubview(btnMinusAway)
        
        // Basket Buttons Setup
        btnScoreHome2 = UIButton(frame: .zero)
        btnScoreHome2.setTitle("+2", for: .normal)
        btnScoreHome2.backgroundColor = .systemPink
        btnScoreHome2.addTarget(self, action: #selector(incScoreA2), for: .touchUpInside)
        view.addSubview(btnScoreHome2)
        
        btnScoreHome3 = UIButton(frame: .zero)
        btnScoreHome3.setTitle("+3", for: .normal)
        btnScoreHome3.backgroundColor = .systemPink
        btnScoreHome3.addTarget(self, action: #selector(incScoreA3), for: .touchUpInside)
        view.addSubview(btnScoreHome3)
        
        btnScoreAway2 = UIButton(frame: .zero)
        btnScoreAway2.setTitle("+2", for: .normal)
        btnScoreAway2.backgroundColor = .systemTeal
        btnScoreAway2.addTarget(self, action: #selector(incScoreB2), for: .touchUpInside)
        view.addSubview(btnScoreAway2)
        
        btnScoreAway3 = UIButton(frame: .zero)
        btnScoreAway3.setTitle("+3", for: .normal)
        btnScoreAway3.backgroundColor = .systemTeal
        btnScoreAway3.addTarget(self, action: #selector(incScoreB3), for: .touchUpInside)
        view.addSubview(btnScoreAway3)
        
        btnEndQuarter = UIButton(frame: .zero)
        btnEndQuarter.setTitle("Fine Quarto", for: .normal)
        btnEndQuarter.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        btnEndQuarter.backgroundColor = .systemPurple
        btnEndQuarter.addTarget(self, action: #selector(endQuarter), for: .touchUpInside)
        view.addSubview(btnEndQuarter)
    }
    
    var isAudioMuted = false
    
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
        
        muteButton.backgroundColor = isAudioMuted ? .red : .orange
    }
    
    @objc func triggerReplay() {
        ReplayManager.shared.startPlayback()
    }
    
    @objc func triggerHighlight() {
        // Salva clip highlight
    }
    
    @objc func toggleMode() {
        currentMode = (currentMode + 1) % 3
        
        let hideControls = (currentMode == 2)
        let isGrid = (currentMode == 1)
        
        let w = view.bounds.width
        let h = view.bounds.height
        let safeY = h - 80
        let centerX = w / 2
        let topY: CGFloat = 20
        let rightX = w - 20
        
        UIView.animate(withDuration: 0.3) {
            self.view.backgroundColor = isGrid ? UIColor(white: 0.1, alpha: 1.0) : .black
            
            if isGrid {
                self.lfView.frame = CGRect(x: 0, y: 0, width: w / 2, height: h / 2)
                self.scoreboardView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                self.scoreboardView.frame.origin = CGPoint(x: 25, y: 25)
            } else {
                self.lfView.frame = self.view.bounds
                self.scoreboardView.transform = .identity
                self.scoreboardView.frame.origin = CGPoint(x: 50, y: 50)
            }
            
            // Applica nascondimenti Clean Mode
            self.startStreamButton.isHidden = hideControls
            self.shareLiveButton.isHidden = hideControls
            self.shareRemoteButton.isHidden = hideControls
            self.muteButton.isHidden = hideControls
            self.sponsorButton.isHidden = hideControls
            self.replayButton.isHidden = hideControls
            self.highlightButton.isHidden = hideControls
            self.btnScoreHome.isHidden = hideControls
            self.btnScoreAway.isHidden = hideControls
            self.btnMinusHome.isHidden = hideControls
            self.btnMinusAway.isHidden = hideControls
            self.btnTimeoutHome.isHidden = hideControls
            self.btnTimeoutAway.isHidden = hideControls
            
            let isBasket = (self.localState.sportType == "basket")
            let isSoccer = (self.localState.sportType == "soccer")
            let isBiliardo = (self.localState.sportType == "biliardo")
            
            self.btnScoreHome2.isHidden = hideControls || !isBasket
            self.btnScoreHome3.isHidden = hideControls || !isBasket
            self.btnScoreAway2.isHidden = hideControls || !isBasket
            self.btnScoreAway3.isHidden = hideControls || !isBasket
            self.btnEndQuarter.isHidden = hideControls || !(isBasket || isSoccer || isBiliardo)
            
            if isSoccer {
                self.btnEndQuarter.setTitle("Fine Tempo", for: .normal)
            } else if isBiliardo {
                self.btnEndQuarter.setTitle("Next Frame", for: .normal)
            } else {
                self.btnEndQuarter.setTitle("Fine Quarto", for: .normal)
            }
            
            if !hideControls {
                if isGrid {
                    let by = h / 2 + 50
                    self.startStreamButton.frame = CGRect(x: centerX - 40, y: by - 30, width: 80, height: 50)
                    self.startStreamButton.layer.cornerRadius = 8
                    
                    self.replayButton.frame = CGRect(x: centerX - 120, y: by - 30, width: 70, height: 70)
                    self.replayButton.layer.cornerRadius = 35
                    
                    self.highlightButton.frame = CGRect(x: centerX + 50, y: by - 30, width: 70, height: 70)
                    self.highlightButton.layer.cornerRadius = 35
                    self.highlightButton.backgroundColor = .systemYellow
                    self.highlightButton.setTitleColor(.black, for: .normal)
                    
                    // Home (Left)
                    self.btnScoreHome.frame = CGRect(x: 50, y: by - 15, width: 80, height: 80)
                    self.btnScoreHome.layer.cornerRadius = 40
                    self.btnMinusHome.frame = CGRect(x: 140, y: by + 5, width: 50, height: 50)
                    self.btnMinusHome.layer.cornerRadius = 25
                    self.btnMinusHome.backgroundColor = .systemRed
                    self.btnTimeoutHome.frame = CGRect(x: 200, y: by + 5, width: 50, height: 50)
                    self.btnTimeoutHome.layer.cornerRadius = 25
                    
                    // Away (Right)
                    self.btnScoreAway.frame = CGRect(x: w - 130, y: by - 15, width: 80, height: 80)
                    self.btnScoreAway.layer.cornerRadius = 40
                    self.btnMinusAway.frame = CGRect(x: w - 190, y: by + 5, width: 50, height: 50)
                    self.btnMinusAway.layer.cornerRadius = 25
                    self.btnMinusAway.backgroundColor = .systemRed
                    self.btnTimeoutAway.frame = CGRect(x: w - 250, y: by + 5, width: 50, height: 50)
                    self.btnTimeoutAway.layer.cornerRadius = 25
                    
                    if localState.sportType == "soccer" {
                        self.btnTimeoutHome.setTitle("R", for: .normal)
                        self.btnTimeoutHome.backgroundColor = .systemRed
                        self.btnTimeoutAway.setTitle("R", for: .normal)
                        self.btnTimeoutAway.backgroundColor = .systemRed
                    } else if localState.sportType == "tennis" || localState.sportType == "padel" {
                        self.btnTimeoutHome.setTitle("G", for: .normal)
                        self.btnTimeoutHome.backgroundColor = .systemPurple
                        self.btnTimeoutAway.setTitle("G", for: .normal)
                        self.btnTimeoutAway.backgroundColor = .systemPurple
                    } else {
                        self.btnTimeoutHome.setTitle("T", for: .normal)
                        self.btnTimeoutHome.backgroundColor = UIColor(white: 0.1, alpha: 0.8)
                        self.btnTimeoutAway.setTitle("T", for: .normal)
                        self.btnTimeoutAway.backgroundColor = UIColor(white: 0.1, alpha: 0.8)
                    }
                    
                    if isBasket {
                        self.btnScoreHome2.frame = CGRect(x: 50, y: by + 75, width: 60, height: 60)
                        self.btnScoreHome2.layer.cornerRadius = 30
                        self.btnScoreHome3.frame = CGRect(x: 120, y: by + 75, width: 60, height: 60)
                        self.btnScoreHome3.layer.cornerRadius = 30
                        self.btnScoreAway2.frame = CGRect(x: w - 130, y: by + 75, width: 60, height: 60)
                        self.btnScoreAway2.layer.cornerRadius = 30
                        self.btnScoreAway3.frame = CGRect(x: w - 200, y: by + 75, width: 60, height: 60)
                        self.btnScoreAway3.layer.cornerRadius = 30
                        self.btnEndQuarter.frame = CGRect(x: centerX - 50, y: by + 40, width: 100, height: 40)
                        self.btnEndQuarter.layer.cornerRadius = 20
                    } else if isSoccer || localState.sportType == "biliardo" {
                        self.btnEndQuarter.frame = CGRect(x: centerX - 50, y: by + 40, width: 100, height: 40)
                        self.btnEndQuarter.layer.cornerRadius = 20
                    }
                    
                    // Top Right (Circle Row)
                    self.sponsorButton.frame = CGRect(x: centerX + 150, y: 30, width: 60, height: 60)
                    self.sponsorButton.layer.cornerRadius = 30
                    self.sponsorButton.backgroundColor = .systemYellow
                    self.sponsorButton.setTitleColor(.black, for: .normal)
                    
                    self.shareRemoteButton.frame = CGRect(x: centerX + 220, y: 30, width: 60, height: 60)
                    self.shareRemoteButton.layer.cornerRadius = 30
                    self.shareRemoteButton.backgroundColor = .systemYellow
                    self.shareRemoteButton.setTitleColor(.black, for: .normal)
                    
                    self.shareLiveButton.frame = CGRect(x: centerX + 290, y: 30, width: 60, height: 60)
                    self.shareLiveButton.layer.cornerRadius = 30
                    self.shareLiveButton.backgroundColor = .systemYellow
                    self.shareLiveButton.tintColor = .black
                    
                    self.muteButton.frame = CGRect(x: centerX + 360, y: 30, width: 60, height: 60)
                    self.muteButton.layer.cornerRadius = 30
                    self.muteButton.backgroundColor = .systemYellow
                    self.muteButton.tintColor = .black
                    
                } else {
                    // Posizioni normali
                    self.startStreamButton.frame = CGRect(x: centerX - 30, y: safeY, width: 60, height: 60)
                    self.startStreamButton.layer.cornerRadius = 8
                    
                    self.muteButton.frame = CGRect(x: centerX - 100, y: safeY, width: 60, height: 60)
                    self.muteButton.layer.cornerRadius = 16
                    self.muteButton.backgroundColor = UIColor(white: 0.1, alpha: 0.8)
                    self.muteButton.tintColor = .systemTeal
                    
                    self.sponsorButton.frame = CGRect(x: centerX + 40, y: safeY, width: 60, height: 60)
                    self.sponsorButton.layer.cornerRadius = 16
                    self.sponsorButton.backgroundColor = UIColor(white: 0.1, alpha: 0.8)
                    self.sponsorButton.setTitleColor(.white, for: .normal)
                    
                    self.shareLiveButton.frame = CGRect(x: rightX - 120, y: topY, width: 50, height: 50)
                    self.shareLiveButton.layer.cornerRadius = 12
                    self.shareLiveButton.backgroundColor = UIColor(white: 0.1, alpha: 0.8)
                    self.shareLiveButton.tintColor = .systemGreen
                    
                    self.shareRemoteButton.frame = CGRect(x: rightX - 190, y: topY, width: 60, height: 50)
                    self.shareRemoteButton.layer.cornerRadius = 12
                    self.shareRemoteButton.backgroundColor = UIColor(white: 0.1, alpha: 0.8)
                    self.shareRemoteButton.setTitleColor(.white, for: .normal)
                    
                    self.replayButton.frame = CGRect(x: rightX - 260, y: topY, width: 60, height: 50)
                    self.replayButton.layer.cornerRadius = 12
                    
                    self.highlightButton.frame = CGRect(x: rightX - 330, y: topY, width: 60, height: 50)
                    self.highlightButton.layer.cornerRadius = 12
                    self.highlightButton.backgroundColor = UIColor(white: 0.1, alpha: 0.8)
                    self.highlightButton.setTitleColor(.systemYellow, for: .normal)
                    
                    self.btnScoreHome.frame = CGRect(x: 100, y: safeY - 40, width: 90, height: 90)
                    self.btnScoreHome.layer.cornerRadius = 24
                    self.btnMinusHome.frame = CGRect(x: 20, y: safeY + 15, width: 70, height: 35)
                    self.btnMinusHome.layer.cornerRadius = 8
                    self.btnMinusHome.backgroundColor = UIColor(white: 0.1, alpha: 0.8)
                    self.btnTimeoutHome.frame = CGRect(x: 20, y: safeY - 40, width: 70, height: 40)
                    self.btnTimeoutHome.layer.cornerRadius = 8
                    self.btnTimeoutHome.setTitle("T.O.", for: .normal)
                    
                    self.btnScoreAway.frame = CGRect(x: rightX - 180, y: safeY - 40, width: 90, height: 90)
                    self.btnScoreAway.layer.cornerRadius = 24
                    self.btnMinusAway.frame = CGRect(x: rightX - 80, y: safeY + 15, width: 70, height: 35)
                    self.btnMinusAway.layer.cornerRadius = 8
                    self.btnMinusAway.backgroundColor = UIColor(white: 0.1, alpha: 0.8)
                    self.btnTimeoutAway.frame = CGRect(x: rightX - 80, y: safeY - 40, width: 70, height: 40)
                    self.btnTimeoutAway.layer.cornerRadius = 8
                    
                    if localState.sportType == "soccer" {
                        self.btnTimeoutHome.setTitle("RC", for: .normal)
                        self.btnTimeoutHome.backgroundColor = .systemRed
                        self.btnTimeoutAway.setTitle("RC", for: .normal)
                        self.btnTimeoutAway.backgroundColor = .systemRed
                    } else if localState.sportType == "tennis" || localState.sportType == "padel" {
                        self.btnTimeoutHome.setTitle("GAME", for: .normal)
                        self.btnTimeoutHome.backgroundColor = .systemPurple
                        self.btnTimeoutAway.setTitle("GAME", for: .normal)
                        self.btnTimeoutAway.backgroundColor = .systemPurple
                    } else {
                        self.btnTimeoutHome.setTitle("T.O.", for: .normal)
                        self.btnTimeoutHome.backgroundColor = UIColor(white: 0.1, alpha: 0.8)
                        self.btnTimeoutAway.setTitle("T.O.", for: .normal)
                        self.btnTimeoutAway.backgroundColor = UIColor(white: 0.1, alpha: 0.8)
                    }
                    
                    if isBasket {
                        self.btnScoreHome2.frame = CGRect(x: 100, y: safeY - 100, width: 40, height: 40)
                        self.btnScoreHome2.layer.cornerRadius = 8
                        self.btnScoreHome3.frame = CGRect(x: 150, y: safeY - 100, width: 40, height: 40)
                        self.btnScoreHome3.layer.cornerRadius = 8
                        
                        self.btnScoreAway2.frame = CGRect(x: rightX - 180, y: safeY - 100, width: 40, height: 40)
                        self.btnScoreAway2.layer.cornerRadius = 8
                        self.btnScoreAway3.frame = CGRect(x: rightX - 130, y: safeY - 100, width: 40, height: 40)
                        self.btnScoreAway3.layer.cornerRadius = 8
                        
                        self.btnEndQuarter.frame = CGRect(x: centerX - 50, y: topY, width: 100, height: 40)
                        self.btnEndQuarter.layer.cornerRadius = 8
                    } else if isSoccer || localState.sportType == "biliardo" {
                        self.btnEndQuarter.frame = CGRect(x: centerX - 50, y: topY, width: 100, height: 40)
                        self.btnEndQuarter.layer.cornerRadius = 8
                    }
                }
            }
        }
        
        switch currentMode {
        case 0: modeButton.setTitle("L", for: .normal)
        case 1: modeButton.setTitle("G", for: .normal) // Griglia
        case 2: modeButton.setTitle("C", for: .normal) // Clean
        default: break
        }
    }
    
    @objc func shareLive() {
        let link = "https://youtube.com/live/YOUR_STREAM_ID"
        let activity = UIActivityViewController(activityItems: [link], applicationActivities: nil)
        present(activity, animated: true)
    }
    
    @objc func shareRemote() {
        let sessionId = UserDefaults.standard.string(forKey: "remote_session_id") ?? "REGIA_01"
        let customLink = "volleypro://remote?code=\(sessionId)"
        let httpsLink = "https://volleystreampro.com/remote?code=\(sessionId)"
        let msg = "🏐 VolleyPro Live - Telecomando\n\nCodice Sessione: \(sessionId)\n\nClicca qui se usi Android:\n\(httpsLink)\n\nClicca qui se usi iOS:\n\(customLink)"
        
        let activity = UIActivityViewController(activityItems: [msg], applicationActivities: nil)
        present(activity, animated: true)
    }
    
    @objc func startLive() {
        if startStreamButton.backgroundColor == .systemRed {
            let rtmpUrl = UserDefaults.standard.string(forKey: "rtmp_url") ?? "rtmp://a.rtmp.youtube.com/live2"
            let rtmpKey = UserDefaults.standard.string(forKey: "rtmp_key") ?? "test"
            
            StreamManager.shared.startStreaming(url: rtmpUrl, streamKey: rtmpKey)
            
            if UserDefaults.standard.bool(forKey: "record_locally") {
                LocalVideoRecorder.shared.startRecording()
            }
            
            startStreamButton.setTitle("STOP", for: .normal)
            startStreamButton.backgroundColor = .gray
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
            startStreamButton.backgroundColor = .systemRed
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
}


