import UIKit

class ScoreboardOverlayView: UIView {
    
    private let backgroundView = UIView()
    private let homeNameLabel = UILabel()
    private let awayNameLabel = UILabel()
    private let scoreLabel = UILabel()
    private let extraLabel = UILabel() // Per Set, Quarti, Leg
    
    // Timeout
    private var homeTimeoutDots: [UIView] = []
    private var awayTimeoutDots: [UIView] = []
    
    // Soccer specific
    private let timerLabel = UILabel()
    private let homeServeIcon = UIImageView()
    private let awayServeIcon = UIImageView()
    private let redCardsLabel = UILabel()
    
    // Darts specific
    private let dartsExtraLabel = UILabel()
    
    // Sponsor e Marquee
    private let sponsorImageView = UIImageView()
    private let fullScreenSponsorView = UIImageView()
    
    private let marqueeBackground = UIView()
    private let marqueeLabel = UILabel()
    
    // Timer per sponsor rotanti
    private var sponsorTimer: Timer?
    private var currentSponsorIndex = 0
    private let sponsorImages = ["sponsor1", "sponsor2", "sponsor3"] // Dummy images
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // ... (resto della UI) ...
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        backgroundView.layer.cornerRadius = 10
        backgroundView.frame = bounds
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(backgroundView)
        
        let boldFont = UIFont.boldSystemFont(ofSize: 24)
        
        homeNameLabel.frame = CGRect(x: 10, y: 10, width: 120, height: 30)
        homeNameLabel.textColor = .white
        homeNameLabel.font = boldFont
        addSubview(homeNameLabel)
        
        awayNameLabel.frame = CGRect(x: 10, y: 40, width: 120, height: 30)
        awayNameLabel.textColor = .white
        awayNameLabel.font = boldFont
        addSubview(awayNameLabel)
        
        scoreLabel.frame = CGRect(x: 140, y: 10, width: 80, height: 60)
        scoreLabel.textColor = .yellow
        scoreLabel.font = UIFont.boldSystemFont(ofSize: 32)
        scoreLabel.textAlignment = .center
        scoreLabel.numberOfLines = 2
        addSubview(scoreLabel)
        
        extraLabel.frame = CGRect(x: 230, y: 10, width: 80, height: 60)
        extraLabel.textColor = .red
        extraLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        extraLabel.textAlignment = .center
        extraLabel.numberOfLines = 2
        addSubview(extraLabel)
        
        timerLabel.frame = CGRect(x: 320, y: 10, width: 70, height: 20)
        timerLabel.textColor = .white
        timerLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        timerLabel.textAlignment = .center
        addSubview(timerLabel)
        
        homeServeIcon.frame = CGRect(x: 105, y: 15, width: 20, height: 20)
        homeServeIcon.image = UIImage(systemName: "volleyball.fill")
        homeServeIcon.tintColor = .white
        addSubview(homeServeIcon)
        
        awayServeIcon.frame = CGRect(x: 105, y: 45, width: 20, height: 20)
        awayServeIcon.image = UIImage(systemName: "volleyball.fill")
        awayServeIcon.tintColor = .white
        addSubview(awayServeIcon)
        
        for i in 0..<3 { // Fino a 3 timeout per basket
            let homeDot = UIView(frame: CGRect(x: 130 + (i*12), y: 25, width: 8, height: 8))
            homeDot.backgroundColor = .darkGray
            homeDot.layer.cornerRadius = 4
            addSubview(homeDot)
            homeTimeoutDots.append(homeDot)
            
            let awayDot = UIView(frame: CGRect(x: 130 + (i*12), y: 55, width: 8, height: 8))
            awayDot.backgroundColor = .darkGray
            awayDot.layer.cornerRadius = 4
            addSubview(awayDot)
            awayTimeoutDots.append(awayDot)
        }
        
        sponsorImageView.frame = CGRect(x: 320, y: 35, width: 70, height: 35)
        sponsorImageView.contentMode = .scaleAspectFit
        sponsorImageView.isHidden = true
        addSubview(sponsorImageView)
        
        // Full screen sponsor
        // In una vera app la View di overlay sarebbe a grandezza intera.
        // Simuliamo l'overlay full screen ancorandolo alla superview o a coordinate ampie.
        fullScreenSponsorView.frame = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        fullScreenSponsorView.contentMode = .scaleAspectFill
        fullScreenSponsorView.isHidden = true
        fullScreenSponsorView.backgroundColor = .black
        // addSubview(fullScreenSponsorView) - verrebbe aggiunto alla window o al main container. Lo ignoriamo dal bounds qui.
        
        // Ticker (Marquee)
        marqueeBackground.frame = CGRect(x: -50, y: 900, width: 1920, height: 40) // Posizionato in basso
        marqueeBackground.backgroundColor = UIColor.blue.withAlphaComponent(0.8)
        marqueeBackground.isHidden = true
        
        marqueeLabel.frame = CGRect(x: 1920, y: 0, width: 2000, height: 40)
        marqueeLabel.textColor = .white
        marqueeLabel.font = UIFont.boldSystemFont(ofSize: 24)
        marqueeBackground.addSubview(marqueeLabel)
        
        // Nel VideoEffect queste view andrebbero disegnate. 
        // Per semplicita' le aggiungiamo alla view, anche se andrebbero fuori dai bounds attuali.
        self.clipsToBounds = false
        addSubview(marqueeBackground)
        addSubview(fullScreenSponsorView)
    }
    
    func updateFromState(_ state: RemoteMatchState) {
        homeNameLabel.text = state.teamA
        awayNameLabel.text = state.teamB
        
        // Colori in base al tema
        if state.overlayTheme == "neon" {
            backgroundView.backgroundColor = UIColor(red: 0.1, green: 0, blue: 0.3, alpha: 0.8)
            scoreLabel.textColor = .cyan
            extraLabel.textColor = .magenta
        } else {
            backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            scoreLabel.textColor = .yellow
            extraLabel.textColor = .red
        }
        
        timerLabel.isHidden = true
        homeServeIcon.isHidden = true
        awayServeIcon.isHidden = true
        
        switch state.sportType {
        case "volley":
            scoreLabel.text = "\(state.scoreA)\n\(state.scoreB)"
            extraLabel.text = "Set: \(state.setsA)\nSet: \(state.setsB)"
            updateTimeouts(countA: state.timeoutA, countB: state.timeoutB, max: 2)
            
        case "basket":
            scoreLabel.text = "\(state.scoreA)\n\(state.scoreB)"
            extraLabel.text = "Q\(state.currentSet)\nF: \(state.foulsA)-\(state.foulsB)"
            updateTimeouts(countA: state.timeoutA, countB: state.timeoutB, max: 3)
            
        case "soccer":
            scoreLabel.text = "\(state.scoreA)\n\(state.scoreB)"
            extraLabel.text = ""
            timerLabel.isHidden = false
            timerLabel.text = formatTimer(state.timerSeconds)
            updateTimeouts(countA: 0, countB: 0, max: 0)
            
        case "tennis":
            scoreLabel.text = "\(formatTennisScore(state.tennisPointsA))\n\(formatTennisScore(state.tennisPointsB))"
            extraLabel.text = "S:\(state.setsA) G:\(state.tennisGamesA)\nS:\(state.setsB) G:\(state.tennisGamesB)"
            updateTimeouts(countA: 0, countB: 0, max: 0)
            
        case "darts":
            scoreLabel.text = "\(state.scoreA)\n\(state.scoreB)"
            extraLabel.text = "L:\(state.dartsLegsA)\nL:\(state.dartsLegsB)"
            updateTimeouts(countA: 0, countB: 0, max: 0)
            
        case "cricket":
            scoreLabel.text = "\(state.scoreA)\n\(state.scoreB)"
            extraLabel.text = "B:\(state.cricketBallsA)\nB:\(state.cricketBallsB)"
            updateTimeouts(countA: 0, countB: 0, max: 0)
            
        default:
            scoreLabel.text = "\(state.scoreA)\n\(state.scoreB)"
            extraLabel.text = ""
        }
        
        // Sponsor Logics
        if state.showSponsor {
            sponsorImageView.isHidden = false
            if sponsorTimer == nil {
                sponsorTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
                    self?.rotateSponsor()
                }
            }
        } else {
            sponsorImageView.isHidden = true
            sponsorTimer?.invalidate()
            sponsorTimer = nil
        }
        
        if state.fullScreenSponsor {
            fullScreenSponsorView.isHidden = false
            fullScreenSponsorView.image = UIImage(systemName: "photo.fill")
        } else {
            fullScreenSponsorView.isHidden = true
        }
        
        // Marquee Logics
        if state.showScrollText {
            marqueeBackground.isHidden = false
            marqueeLabel.text = state.scrollMessage
            startMarquee()
        } else {
            marqueeBackground.isHidden = true
            marqueeLabel.layer.removeAllAnimations()
        }
    }
    
    private func rotateSponsor() {
        currentSponsorIndex = (currentSponsorIndex + 1) % sponsorImages.count
        sponsorImageView.image = UIImage(systemName: "star") // Usa immagini reali
    }
    
    private func startMarquee() {
        marqueeLabel.layer.removeAllAnimations()
        marqueeLabel.frame.origin.x = 1920
        
        UIView.animate(withDuration: 15.0, delay: 0, options: [.repeat, .curveLinear], animations: {
            self.marqueeLabel.frame.origin.x = -self.marqueeLabel.frame.width
        }, completion: nil)
    }
    
    private func updateTimeouts(countA: Int, countB: Int, max: Int) {
        for i in 0..<3 {
            homeTimeoutDots[i].isHidden = i >= max
            awayTimeoutDots[i].isHidden = i >= max
            
            homeTimeoutDots[i].backgroundColor = (i < countA) ? .red : .darkGray
            awayTimeoutDots[i].backgroundColor = (i < countB) ? .red : .darkGray
        }
    }
    
    private func formatTimer(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    private func formatTennisScore(_ points: Int) -> String {
        switch points {
        case 0: return "0"
        case 1: return "15"
        case 2: return "30"
        case 3: return "40"
        case 4: return "AD"
        default: return "\(points)"
        }
    }
}

