import UIKit

class ScoreboardOverlayView: UIView {

    var currentState = RemoteMatchState()
    var currentTheme = "neon"
    var homeLogo: UIImage?
    var awayLogo: UIImage?
    
    // Blinking Animation State (4.0s duration, 450ms ON / 250ms OFF matching Android)
    private var displayLink: CADisplayLink?
    var alertStartTime: TimeInterval = 0
    var isBlinkingAlert = false
    private var lastSetPointTeamTriggered: String? = nil
    private var lastSetPointSetIndex: Int = -1
    
    // Timeout Alert State (4.0s duration, 450ms ON / 250ms OFF matching Android)
    var isBlinkingTimeout = false
    var timeoutTeamName = ""
    var timeoutStartTime: TimeInterval = 0
    
    // Triple Alert State (3.5s duration, matching Android OverlayRenderer)
    var isBlinkingTriple = false
    var tripleStartTime: TimeInterval = 0
    
    var onOverlayNeedsUpdate: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.clipsToBounds = false
        setupDisplayLink()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.backgroundColor = .clear
        self.clipsToBounds = false
        setupDisplayLink()
    }
    
    deinit {
        displayLink?.invalidate()
    }
    
    private var lastTickTime: TimeInterval = 0
    
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayTick))
        displayLink?.preferredFramesPerSecond = 10
        displayLink?.isPaused = true
        displayLink?.add(to: .main, forMode: .common)
    }
    
    func resetAlerts() {
        self.isBlinkingAlert = false
        self.isBlinkingTimeout = false
        self.isBlinkingTriple = false
        self.timeoutTeamName = ""
        self.lastSetPointTeamTriggered = nil
        self.lastSetPointSetIndex = -1
        displayLink?.isPaused = true
        setNeedsDisplay()
        onOverlayNeedsUpdate?()
    }
    
    func triggerTimeoutAlert(teamName: String) {
        self.isBlinkingAlert = false
        self.isBlinkingTriple = false
        self.timeoutTeamName = teamName
        self.timeoutStartTime = Date().timeIntervalSince1970
        self.isBlinkingTimeout = true
        displayLink?.isPaused = false
        setNeedsDisplay()
        onOverlayNeedsUpdate?()
    }
    
    func triggerTripleAlert() {
        self.isBlinkingAlert = false
        self.isBlinkingTimeout = false
        self.tripleStartTime = Date().timeIntervalSince1970
        self.isBlinkingTriple = true
        displayLink?.isPaused = false
        setNeedsDisplay()
        onOverlayNeedsUpdate?()
    }
    
    @objc private func handleDisplayTick() {
        let now = Date().timeIntervalSince1970
        // Limita il tick di ridisegno a max 3 FPS durante il lampeggio per un uso CPU praticamente a zero
        guard (now - lastTickTime) >= 0.35 else { return }
        lastTickTime = now
        
        var alertActive = false
        
        if isBlinkingAlert {
            let elapsed = now - alertStartTime
            if elapsed >= 4.0 {
                isBlinkingAlert = false
            } else {
                alertActive = true
            }
        }
        
        if isBlinkingTimeout {
            let elapsed = now - timeoutStartTime
            if elapsed >= 4.0 {
                isBlinkingTimeout = false
            } else {
                alertActive = true
            }
        }
        
        if isBlinkingTriple {
            let elapsed = now - tripleStartTime
            if elapsed >= 3.5 {
                isBlinkingTriple = false
            } else {
                alertActive = true
            }
        }
        
        if !alertActive {
            displayLink?.isPaused = true
        }
        
        setNeedsDisplay()
        onOverlayNeedsUpdate?()
    }
    
    func updateFromState(_ state: RemoteMatchState) {
        self.currentState = state
        self.currentTheme = state.overlayTheme.isEmpty ? "neon" : state.overlayTheme
        
        if let homeData = AppPreferences.shared.loadImage(name: "logo_team_a.png") ?? AppPreferences.shared.loadImage(name: "logoHome.png") {
            self.homeLogo = UIImage(data: homeData)
        }
        if let awayData = AppPreferences.shared.loadImage(name: "logo_team_b.png") ?? AppPreferences.shared.loadImage(name: "logoAway.png") {
            self.awayLogo = UIImage(data: awayData)
        }
        
        // Reset tracking e spegni animazioni se il set cambia o se il set/match è terminato
        if state.currentSet != lastSetPointSetIndex || state.isSetFinished || state.isMatchFinished {
            lastSetPointTeamTriggered = nil
            lastSetPointSetIndex = state.currentSet
            if state.isSetFinished || state.isMatchFinished {
                isBlinkingAlert = false
                isBlinkingTimeout = false
                displayLink?.isPaused = true
            }
        }
        
        // Controlla se siamo entrati in Set Point o Match Point
        if let sp = getSetPointInfo(state: state), !state.isSetFinished && !state.isMatchFinished {
            // Lampeggia solo la PRIMA volta che questa squadra entra in Set Point nel set corrente
            if lastSetPointTeamTriggered != sp.team {
                lastSetPointTeamTriggered = sp.team
                lastSetPointSetIndex = state.currentSet
                alertStartTime = Date().timeIntervalSince1970
                isBlinkingTimeout = false
                isBlinkingAlert = true
                displayLink?.isPaused = false
            }
        } else {
            // Se nessuna squadra è a Set Point (es. parità ai vantaggi 24-24), resetta per il prossimo punto di vantaggio
            if !state.isSetFinished && !state.isMatchFinished {
                lastSetPointTeamTriggered = nil
            }
        }
        
        setNeedsDisplay()
    }
    
    // MARK: - Theme Styles
    
    struct ThemeStyles {
        let boxBgColor: UIColor
        let boxBorderColor: UIColor
        let boxBorderWidth: CGFloat
        let boxCornerRadius: CGFloat
        let hasHeaderBg: Bool
        let headerBgColor: UIColor
        let headerTextColor: UIColor
        let dividerColor: UIColor
        let timeoutActiveColor: UIColor
        let timeoutInactiveColor: UIColor
        let scoreColorA: UIColor
        let scoreColorB: UIColor
        
        init(theme: String) {
            switch theme.lowercased() {
            case "minimal":
                boxBgColor = UIColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.95)
                boxBorderColor = UIColor(red: 71/255, green: 85/255, blue: 105/255, alpha: 1.0)
                boxBorderWidth = 1.2
                boxCornerRadius = 8.0
                hasHeaderBg = false
                headerBgColor = .clear
                headerTextColor = UIColor(red: 148/255, green: 163/255, blue: 184/255, alpha: 1.0)
                dividerColor = UIColor(red: 51/255, green: 65/255, blue: 85/255, alpha: 1.0)
                timeoutActiveColor = UIColor(red: 56/255, green: 189/255, blue: 248/255, alpha: 1.0)
                timeoutInactiveColor = UIColor(red: 30/255, green: 41/255, blue: 59/255, alpha: 1.0)
                scoreColorA = .white
                scoreColorB = .white
            case "glass":
                boxBgColor = UIColor(red: 30/255, green: 41/255, blue: 59/255, alpha: 0.45)
                boxBorderColor = UIColor.white.withAlphaComponent(0.60)
                boxBorderWidth = 1.8
                boxCornerRadius = 14.0
                hasHeaderBg = true
                headerBgColor = UIColor.white.withAlphaComponent(0.18)
                headerTextColor = .white
                dividerColor = UIColor.white.withAlphaComponent(0.30)
                timeoutActiveColor = .white
                timeoutInactiveColor = UIColor.white.withAlphaComponent(0.25)
                scoreColorA = .white
                scoreColorB = .white
            case "classic":
                boxBgColor = UIColor(red: 17/255, green: 17/255, blue: 17/255, alpha: 0.98)
                boxBorderColor = UIColor(red: 55/255, green: 65/255, blue: 81/255, alpha: 1.0)
                boxBorderWidth = 1.0
                boxCornerRadius = 4.0
                hasHeaderBg = true
                headerBgColor = UIColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1.0)
                headerTextColor = UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0)
                dividerColor = UIColor(red: 55/255, green: 65/255, blue: 81/255, alpha: 1.0)
                timeoutActiveColor = UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0)
                timeoutInactiveColor = UIColor(red: 75/255, green: 85/255, blue: 99/255, alpha: 1.0)
                scoreColorA = UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0)
                scoreColorB = UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0)
            case "odometer_blue":
                boxBgColor = UIColor(red: 0/255, green: 29/255, blue: 61/255, alpha: 0.92)
                boxBorderColor = UIColor(red: 0/255, green: 168/255, blue: 232/255, alpha: 1.0)
                boxBorderWidth = 2.0
                boxCornerRadius = 12.0
                hasHeaderBg = true
                headerBgColor = UIColor(red: 0/255, green: 53/255, blue: 102/255, alpha: 1.0)
                headerTextColor = UIColor(red: 144/255, green: 224/255, blue: 239/255, alpha: 1.0)
                dividerColor = UIColor(red: 0/255, green: 119/255, blue: 182/255, alpha: 1.0)
                timeoutActiveColor = UIColor(red: 144/255, green: 224/255, blue: 239/255, alpha: 1.0)
                timeoutInactiveColor = UIColor(red: 0/255, green: 53/255, blue: 102/255, alpha: 1.0)
                scoreColorA = UIColor(red: 144/255, green: 224/255, blue: 239/255, alpha: 1.0)
                scoreColorB = UIColor(red: 144/255, green: 224/255, blue: 239/255, alpha: 1.0)
            case "odometer_red":
                boxBgColor = UIColor(red: 60/255, green: 4/255, blue: 4/255, alpha: 0.92)
                boxBorderColor = UIColor(red: 255/255, green: 107/255, blue: 107/255, alpha: 1.0)
                boxBorderWidth = 2.0
                boxCornerRadius = 12.0
                hasHeaderBg = true
                headerBgColor = UIColor(red: 120/255, green: 10/255, blue: 10/255, alpha: 1.0)
                headerTextColor = UIColor(red: 255/255, green: 217/255, blue: 61/255, alpha: 1.0)
                dividerColor = UIColor(red: 180/255, green: 30/255, blue: 30/255, alpha: 1.0)
                timeoutActiveColor = UIColor(red: 255/255, green: 217/255, blue: 61/255, alpha: 1.0)
                timeoutInactiveColor = UIColor(red: 100/255, green: 15/255, blue: 15/255, alpha: 1.0)
                scoreColorA = UIColor(red: 255/255, green: 217/255, blue: 61/255, alpha: 1.0)
                scoreColorB = UIColor(red: 255/255, green: 217/255, blue: 61/255, alpha: 1.0)
            case "odometer_dark":
                boxBgColor = UIColor(red: 13/255, green: 13/255, blue: 13/255, alpha: 0.96)
                boxBorderColor = UIColor(red: 229/255, green: 9/255, blue: 20/255, alpha: 1.0)
                boxBorderWidth = 2.0
                boxCornerRadius = 12.0
                hasHeaderBg = true
                headerBgColor = UIColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 1.0)
                headerTextColor = UIColor(red: 229/255, green: 9/255, blue: 20/255, alpha: 1.0)
                dividerColor = UIColor(red: 45/255, green: 45/255, blue: 45/255, alpha: 1.0)
                timeoutActiveColor = UIColor(red: 229/255, green: 9/255, blue: 20/255, alpha: 1.0)
                timeoutInactiveColor = UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 1.0)
                scoreColorA = UIColor(red: 229/255, green: 9/255, blue: 20/255, alpha: 1.0)
                scoreColorB = UIColor(red: 229/255, green: 9/255, blue: 20/255, alpha: 1.0)
            default: // "neon"
                boxBgColor = UIColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.90)
                boxBorderColor = UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 1.0)
                boxBorderWidth = 2.0
                boxCornerRadius = 12.0
                hasHeaderBg = true
                headerBgColor = UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 1.0)
                headerTextColor = .black
                dividerColor = UIColor(red: 51/255, green: 65/255, blue: 85/255, alpha: 1.0)
                timeoutActiveColor = UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0)
                timeoutInactiveColor = UIColor(red: 51/255, green: 65/255, blue: 85/255, alpha: 1.0)
                scoreColorA = UIColor(red: 236/255, green: 72/255, blue: 153/255, alpha: 1.0)
                scoreColorB = UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 1.0)
            }
        }
    }
    
    // MARK: - Set Point Info
    
    struct SetPointInfo {
        let team: String // "A" or "B"
        let isMatchPoint: Bool
    }
    
    func getSetPointInfo(state: RemoteMatchState) -> SetPointInfo? {
        let sport = state.sportType.lowercased()
        if sport == "darts" || sport == "basket" || sport == "soccer" || sport == "handball" || sport == "cricket" || sport == "billiards" || sport == "biliardo" {
            return nil
        }
        
        var isSetPointA = false
        var isSetPointB = false
        var isMatchPoint = false
        
        if sport == "tennis" || sport == "padel" {
            let isWinningGameWinsSetA = (state.tennisGamesA == 5 && state.tennisGamesB <= 4) || (state.tennisGamesA == 6 && state.tennisGamesB == 5) || state.isTiebreak
            let isGamePointA = state.isTiebreak ? (state.tennisPointsA >= 6 && state.tennisPointsA > state.tennisPointsB) : (state.tennisPointsA >= 3 && state.tennisPointsA > state.tennisPointsB)
            isSetPointA = isWinningGameWinsSetA && isGamePointA
            
            let isWinningGameWinsSetB = (state.tennisGamesB == 5 && state.tennisGamesA <= 4) || (state.tennisGamesB == 6 && state.tennisGamesA == 5) || state.isTiebreak
            let isGamePointB = state.isTiebreak ? (state.tennisPointsB >= 6 && state.tennisPointsB > state.tennisPointsA) : (state.tennisPointsB >= 3 && state.tennisPointsB > state.tennisPointsA)
            isSetPointB = isWinningGameWinsSetB && isGamePointB
            
            let winningSetA = state.setsA == state.tennisSetsToWin - 1
            let winningSetB = state.setsB == state.tennisSetsToWin - 1
            if isSetPointA && winningSetA { isMatchPoint = true }
            if isSetPointB && winningSetB { isMatchPoint = true }
        } else {
            let isBeach = (sport == "beach_volley" || sport == "beach volley")
            let target = isBeach ? (state.currentSet == 3 ? 14 : 20) : (state.isFifthSet ? 14 : 24)
            let setsNeeded = isBeach ? 1 : 2
            
            isSetPointA = state.scoreA >= target && state.scoreA > state.scoreB
            isSetPointB = state.scoreB >= target && state.scoreB > state.scoreA
            isMatchPoint = (isSetPointA && state.setsA >= setsNeeded) || (isSetPointB && state.setsB >= setsNeeded)
        }
        
        if isSetPointA { return SetPointInfo(team: "A", isMatchPoint: isMatchPoint) }
        if isSetPointB { return SetPointInfo(team: "B", isMatchPoint: isMatchPoint) }
        return nil
    }

    // MARK: - Drawing Engine (1:1 with Android OverlayRenderer)
    
    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        
        let state = currentState
        let style = ThemeStyles(theme: currentTheme)
        
        // 1. Se il Set o la Partita è conclusa, disegna la grafica Fine Set con i parziali dei set precedenti
        if state.isSetFinished || state.isMatchFinished {
            drawEndGameGraphics(ctx: ctx, rect: rect, state: state)
            return
        }
        
        // 2. Disegna il Tabellone Live in alto a sinistra (Ampio, fisso e ben leggibile)
        let x: CGFloat = (rect.width > 600) ? 20 : 2
        let y: CGFloat = (rect.height > 400) ? 15 : 2
        let boxW: CGFloat = 275.0
        let h: CGFloat = 58.0
        let headerH: CGFloat = 16.0
        
        drawScoreboardBase(ctx: ctx, x: x, y: y, w: boxW, h: h, headerH: headerH, infoText: getHeaderTitle(state: state), style: style)
        
        // Render Sport Content
        let sport = state.sportType.lowercased()
        switch sport {
        case "basket":
            drawBasketScoreboard(ctx: ctx, x: x, y: y, w: boxW, h: h, state: state, style: style)
        case "soccer":
            drawSoccerScoreboard(ctx: ctx, x: x, y: y, w: boxW, h: h, state: state, style: style)
        case "handball", "pallamano":
            drawHandballScoreboard(ctx: ctx, x: x, y: y, w: boxW, h: h, state: state, style: style)
        case "tennis", "padel":
            drawTennisScoreboard(ctx: ctx, x: x, y: y, w: boxW, h: h, state: state, style: style)
        case "darts":
            drawDartsScoreboard(ctx: ctx, x: x, y: y, w: boxW, h: h, state: state, style: style)
        case "billiards", "biliardo":
            drawBilliardsScoreboard(ctx: ctx, x: x, y: y, w: boxW, h: h, state: state, style: style)
        case "cricket":
            drawCricketScoreboard(ctx: ctx, x: x, y: y, w: boxW, h: h, state: state, style: style)
        default:
            drawVolleyScoreboard(ctx: ctx, x: x, y: y, w: boxW, h: h, state: state, style: style)
        }
        
        let sp = getSetPointInfo(state: state)
        
        // 3. Render Attached SET POINT / MATCH POINT Badge on the right of the scoreboard
        if let sp = sp {
            let badgeW: CGFloat = sp.isMatchPoint ? 82 : 74
            let badgeH: CGFloat = 19
            let badgeX = x + boxW - 2
            let badgeY = (sp.team == "A") ? y + 17 : y + 35
            drawAttachedSetPointBadge(ctx: ctx, x: badgeX, y: badgeY, w: badgeW, h: badgeH, isMatchPoint: sp.isMatchPoint)
        }
        
        // 4. Render Animazioni Lampeggianti Centrali (Solo se rect è a tutto schermo, non nel box scalato)
        if rect.width >= 600 {
            if let sp = sp, isBlinkingAlert {
                let elapsed = Date().timeIntervalSince1970 - alertStartTime
                if elapsed < 4.0 {
                    let show = ((Int(elapsed * 1000) % 700) < 450)
                    if show {
                        drawSpecialAlerts(ctx: ctx, rect: rect, sp: sp, state: state)
                    }
                } else {
                    isBlinkingAlert = false
                }
            }
            
            if isBlinkingTimeout {
                let elapsed = Date().timeIntervalSince1970 - timeoutStartTime
                if elapsed < 4.0 {
                    let show = ((Int(elapsed * 1000) % 700) < 450)
                    if show {
                        drawTimeoutAlert(ctx: ctx, rect: rect, teamName: timeoutTeamName, state: state)
                    }
                } else {
                    isBlinkingTimeout = false
                }
            }
            
            if isBlinkingTriple {
                let elapsed = Date().timeIntervalSince1970 - tripleStartTime
                if elapsed < 3.5 {
                    let show = ((Int(elapsed * 1000) % 600) < 400)
                    if show {
                        drawTripleAlert(ctx: ctx, rect: rect)
                    }
                } else {
                    isBlinkingTriple = false
                }
            }
        }
    }
    
    // MARK: - Header Titles
    
    private func getHeaderTitle(state: RemoteMatchState) -> String {
        let sport = state.sportType.lowercased()
        var baseTitle = ""
        switch sport {
        case "basket":
            baseTitle = "BASKET | Q\(state.currentSet)/\(state.totalPeriods)"
        case "soccer":
            let half = state.currentSet == 1 ? "1° TEMPO" : (state.currentSet == 2 ? "2° TEMPO" : "SUPPL.")
            baseTitle = "CALCIO | \(half)"
        case "handball", "pallamano":
            let half = state.currentSet == 1 ? "1° TEMPO" : "2° TEMPO"
            baseTitle = "PALLAMANO | \(half)"
        case "tennis":
            let setStr = state.isTiebreak ? "TIE-BREAK" : "SET \(state.currentSet)"
            baseTitle = "TENNIS | \(setStr)"
        case "padel":
            let setStr = state.isTiebreak ? "TIE-BREAK" : "SET \(state.currentSet)"
            let pdo = state.isPuntoDeOro ? " • PDO" : ""
            baseTitle = "PADEL | \(setStr)\(pdo)"
        case "darts":
            let player = state.dartsActivePlayer == "A" ? state.teamA : state.teamB
            baseTitle = "DARTS | TURNO: \(player)"
        case "billiards", "biliardo":
            baseTitle = "BILIARDO | FRAME \(state.currentSet)"
        case "cricket":
            baseTitle = "CRICKET | INNINGS \(state.currentSet)"
        case "beach_volley", "beach volley":
            if state.scoreA > 0 && (state.scoreA + state.scoreB) % 7 == 0 {
                baseTitle = "🏖️ CAMBIO CAMPO"
            } else {
                baseTitle = "BEACH VOLLEY | SET \(state.currentSet)"
            }
        default:
            let tieBreak = state.isFifthSet ? "• TIE-BREAK" : ""
            baseTitle = "VOLLEY | SET \(state.currentSet) \(tieBreak)"
        }
        
        return baseTitle.uppercased()
    }
    
    // MARK: - Base Scoreboard Box
    
    private func drawScoreboardBase(ctx: CGContext, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, headerH: CGFloat, infoText: String, style: ThemeStyles) {
        let boxRect = CGRect(x: x, y: y, width: w, height: h)
        let radius = min(style.boxCornerRadius, 10.0)
        let path = UIBezierPath(roundedRect: boxRect, cornerRadius: radius)
        
        // Fill box
        style.boxBgColor.setFill()
        path.fill()
        
        // Stroke border
        if style.boxBorderWidth > 0 {
            style.boxBorderColor.setStroke()
            path.lineWidth = style.boxBorderWidth
            path.stroke()
        }
        
        // Header background
        if style.hasHeaderBg {
            let headerRect = CGRect(x: x, y: y, width: w, height: headerH)
            let headerPath = UIBezierPath(roundedRect: headerRect, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: radius, height: radius))
            style.headerBgColor.setFill()
            headerPath.fill()
        }
        
        // Header text
        let font = UIFont.systemFont(ofSize: 9.0, weight: .black)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: style.headerTextColor,
            .paragraphStyle: paragraph
        ]
        let textRect = CGRect(x: x + 2, y: y + 1.5, width: w - 4, height: headerH)
        infoText.draw(in: textRect, withAttributes: attrs)
        
        // Divider line between Team A and Team B
        let divY = y + headerH + (h - headerH) / 2
        let divPath = UIBezierPath()
        divPath.move(to: CGPoint(x: x + 4, y: divY))
        divPath.addLine(to: CGPoint(x: x + w - 4, y: divY))
        style.dividerColor.setStroke()
        divPath.lineWidth = 0.8
        divPath.stroke()
    }
    
    // MARK: - Volley / Beach Volley Scoreboard
    
    private func drawVolleyScoreboard(ctx: CGContext, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, state: RemoteMatchState, style: ThemeStyles) {
        let headerH: CGFloat = 16.0
        let rowH = (h - headerH) / 2
        let row1Y = y + headerH
        let row2Y = y + headerH + rowH
        
        let isBeach = (state.sportType.lowercased() == "beach_volley" || state.sportType.lowercased() == "beach volley")
        let maxTos = isBeach ? 1 : 2
        
        let hasStarted = state.scoreA > 0 || state.scoreB > 0
        let srvA = hasStarted && state.servingTeam == "A"
        let srvB = hasStarted && state.servingTeam == "B"
        
        let trimTeamA = state.teamA.count > 14 ? String(state.teamA.prefix(14)) : state.teamA
        let trimTeamB = state.teamB.count > 14 ? String(state.teamB.prefix(14)) : state.teamB
        
        // Row Home (Team A)
        let nameA = state.setsA > 0 ? "\(trimTeamA) (\(state.setsA))" : trimTeamA
        drawTeamRow(ctx: ctx, x: x + 4, y: row1Y, name: nameA, pts: state.scoreA, tos: state.timeoutA, maxTos: maxTos, isSrv: srvA, color: style.scoreColorA, logo: homeLogo, style: style, w: w - 8, setScores: state.setScores.map { $0[0] }, opponentSetScores: state.setScores.map { $0[1] })
        
        // Row Away (Team B)
        let nameB = state.setsB > 0 ? "\(trimTeamB) (\(state.setsB))" : trimTeamB
        drawTeamRow(ctx: ctx, x: x + 4, y: row2Y, name: nameB, pts: state.scoreB, tos: state.timeoutB, maxTos: maxTos, isSrv: srvB, color: style.scoreColorB, logo: awayLogo, style: style, w: w - 8, setScores: state.setScores.map { $0[1] }, opponentSetScores: state.setScores.map { $0[0] })
    }
    
    private func drawTeamRow(ctx: CGContext, x: CGFloat, y: CGFloat, name: String, pts: Int, tos: Int, maxTos: Int, isSrv: Bool, color: UIColor, logo: UIImage?, style: ThemeStyles, w: CGFloat, setScores: [Int] = [], opponentSetScores: [Int] = []) {
        // 1. Dedicated fixed slot on the left for serve ball
        if isSrv {
            drawVolleyBall(ctx: ctx, cx: x + 6, cy: y + 8.0, r: 4.0)
        }
        
        // 2. Dedicated fixed slot for Team Logo
        let logoX = x + 14
        if let logo = logo {
            logo.draw(in: CGRect(x: logoX, y: y + 2.0, width: 13, height: 13))
        }
        
        // 3. Team name always starts at the EXACT same fixed position (never shifts)
        let nameX = (logo != nil) ? (logoX + 16) : (x + 14)
        let nameFont = UIFont.systemFont(ofSize: 11.5, weight: .bold)
        let nameAttrs: [NSAttributedString.Key: Any] = [.font: nameFont, .foregroundColor: UIColor.white]
        let trimName = name.count > 14 ? String(name.prefix(14)) : name
        trimName.uppercased().draw(at: CGPoint(x: nameX, y: y + 0.5), withAttributes: nameAttrs)
        
        // Timeouts dashes positioned directly UNDER team name at fixed position
        for i in 0..<maxTos {
            let toRect = CGRect(x: nameX + CGFloat(i) * 9.0, y: y + 13.5, width: 7.0, height: 2.5)
            let toColor = (i < tos) ? style.timeoutActiveColor : style.timeoutInactiveColor
            toColor.setFill()
            UIBezierPath(roundedRect: toRect, cornerRadius: 0.8).fill()
        }
        
        // 4. Previous Sets Columns - COMPLETELY FIXED POSITION right next to team names (never moves)
        if !setScores.isEmpty {
            let colWidth: CGFloat = 22.0
            let startSetX = x + 125.0
            let redColor = UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1.0)
            
            for (idx, myScore) in setScores.enumerated() {
                let oppScore = (idx < opponentSetScores.count) ? opponentSetScores[idx] : 0
                let isWon = myScore > oppScore
                let setFont = UIFont.systemFont(ofSize: 11.5, weight: .bold)
                let setAttrs: [NSAttributedString.Key: Any] = [
                    .font: setFont,
                    .foregroundColor: isWon ? redColor : UIColor.white
                ]
                let str = "\(myScore)"
                let strSize = (str as NSString).size(withAttributes: setAttrs)
                let colX = startSetX + CGFloat(idx) * colWidth + (colWidth - strSize.width) / 2.0
                str.draw(at: CGPoint(x: colX, y: y + 1.5), withAttributes: setAttrs)
            }
        }
        
        // 5. Current Set Score (Rightmost dedicated slot)
        let scoreFont = UIFont.systemFont(ofSize: 18.0, weight: .heavy)
        let scoreAttrs: [NSAttributedString.Key: Any] = [.font: scoreFont, .foregroundColor: color]
        let scoreStr = "\(pts)"
        let scoreSize = (scoreStr as NSString).size(withAttributes: scoreAttrs)
        let scoreX = x + w - scoreSize.width - 4
        scoreStr.draw(at: CGPoint(x: scoreX, y: y), withAttributes: scoreAttrs)
    }
    
    // MARK: - 3D Volleyball Serve Icon
    
    private func drawVolleyBall(ctx: CGContext, cx: CGFloat, cy: CGFloat, r: CGFloat) {
        ctx.saveGState()
        
        UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0).setFill()
        ctx.fillEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
        
        UIColor(red: 107/255, green: 33/255, blue: 168/255, alpha: 1.0).setFill()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: cx - r * 0.8, y: cy - r * 0.4))
        path.addCurve(to: CGPoint(x: cx + r * 0.8, y: cy + r * 0.2), controlPoint1: CGPoint(x: cx - r * 0.2, y: cy - r * 0.9), controlPoint2: CGPoint(x: cx + r * 0.5, y: cy - r * 0.4))
        path.addLine(to: CGPoint(x: cx + r * 0.6, y: cy + r * 0.6))
        path.addCurve(to: CGPoint(x: cx - r * 0.6, y: cy), controlPoint1: CGPoint(x: cx + r * 0.2, y: cy + r * 0.1), controlPoint2: CGPoint(x: cx - r * 0.3, y: cy - r * 0.1))
        path.close()
        path.fill()
        
        UIColor(red: 49/255, green: 46/255, blue: 129/255, alpha: 1.0).setStroke()
        let borderPath = UIBezierPath(ovalIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
        borderPath.lineWidth = 0.8
        borderPath.stroke()
        
        ctx.restoreGState()
    }
    
    // MARK: - Basketball Scoreboard
    
    private func drawBasketScoreboard(ctx: CGContext, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, state: RemoteMatchState, style: ThemeStyles) {
        let headerH: CGFloat = 14
        let rowH = (h - headerH) / 2
        let row1Y = y + headerH + (rowH - 13) / 2
        let row2Y = y + headerH + rowH + (rowH - 13) / 2
        
        drawTeamRowBasket(ctx: ctx, x: x + 4, y: row1Y, name: state.teamA, pts: state.scoreA, fouls: state.foulsA, tos: state.timeoutA, color: style.scoreColorA, logo: homeLogo, style: style, w: w - 8)
        drawTeamRowBasket(ctx: ctx, x: x + 4, y: row2Y, name: state.teamB, pts: state.scoreB, fouls: state.foulsB, tos: state.timeoutB, color: style.scoreColorB, logo: awayLogo, style: style, w: w - 8)
    }
    
    private func drawTeamRowBasket(ctx: CGContext, x: CGFloat, y: CGFloat, name: String, pts: Int, fouls: Int, tos: Int, color: UIColor, logo: UIImage?, style: ThemeStyles, w: CGFloat) {
        var curX = x
        if let logo = logo {
            logo.draw(in: CGRect(x: curX, y: y + 1, width: 12, height: 12))
            curX += 15
        }
        
        let nameFont = UIFont.systemFont(ofSize: 10.5, weight: .bold)
        let trimName = name.count > 14 ? String(name.prefix(14)) : name
        trimName.uppercased().draw(at: CGPoint(x: curX, y: y), withAttributes: [.font: nameFont, .foregroundColor: UIColor.white])
        
        let toX = x + (w * 0.42)
        for i in 0..<3 {
            let toRect = CGRect(x: toX + CGFloat(i) * 7.0, y: y + 4.5, width: 5, height: 3)
            let toColor = (i < tos) ? style.timeoutActiveColor : style.timeoutInactiveColor
            toColor.setFill()
            UIBezierPath(roundedRect: toRect, cornerRadius: 1.0).fill()
        }
        
        let isBonus = fouls >= 5
        let foulStr = isBonus ? "F:\(fouls)B" : "F:\(fouls)"
        let foulColor = isBonus ? UIColor.red : UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1.0)
        foulStr.draw(at: CGPoint(x: x + (w * 0.58), y: y + 2), withAttributes: [.font: UIFont.systemFont(ofSize: 8.5, weight: .bold), .foregroundColor: foulColor])
        
        let scoreFont = UIFont.systemFont(ofSize: 15.5, weight: .heavy)
        let scoreStr = "\(pts)"
        let scoreSize = (scoreStr as NSString).size(withAttributes: [.font: scoreFont])
        let scoreX = x + w - scoreSize.width - 4
        scoreStr.draw(at: CGPoint(x: scoreX, y: y - 2), withAttributes: [.font: scoreFont, .foregroundColor: color])
    }
    
    // MARK: - Soccer & Handball Scoreboards
    
    private func drawSoccerScoreboard(ctx: CGContext, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, state: RemoteMatchState, style: ThemeStyles) {
        let headerH: CGFloat = 14
        let rowH = (h - headerH) / 2
        let row1Y = y + headerH + (rowH - 13) / 2
        let row2Y = y + headerH + rowH + (rowH - 13) / 2
        
        drawTeamRowSoccer(ctx: ctx, x: x + 4, y: row1Y, name: state.teamA, pts: state.scoreA, redCards: state.redCardsA, color: style.scoreColorA, logo: homeLogo, style: style, w: w - 8)
        drawTeamRowSoccer(ctx: ctx, x: x + 4, y: row2Y, name: state.teamB, pts: state.scoreB, redCards: state.redCardsB, color: style.scoreColorB, logo: awayLogo, style: style, w: w - 8)
    }
    
    private func drawTeamRowSoccer(ctx: CGContext, x: CGFloat, y: CGFloat, name: String, pts: Int, redCards: Int, color: UIColor, logo: UIImage?, style: ThemeStyles, w: CGFloat) {
        var curX = x
        if let logo = logo {
            logo.draw(in: CGRect(x: curX, y: y + 1, width: 12, height: 12))
            curX += 15
        }
        
        let nameFont = UIFont.systemFont(ofSize: 10.5, weight: .bold)
        let trimName = name.count > 14 ? String(name.prefix(14)) : name
        trimName.uppercased().draw(at: CGPoint(x: curX, y: y), withAttributes: [.font: nameFont, .foregroundColor: UIColor.white])
        
        if redCards > 0 {
            let rcRect = CGRect(x: x + (w * 0.58), y: y + 2, width: 5, height: 8)
            UIColor.red.setFill()
            UIBezierPath(roundedRect: rcRect, cornerRadius: 1).fill()
            "\(redCards)".draw(at: CGPoint(x: x + (w * 0.58) + 7, y: y + 1), withAttributes: [.font: UIFont.systemFont(ofSize: 8.5, weight: .bold), .foregroundColor: UIColor.white])
        }
        
        let scoreFont = UIFont.systemFont(ofSize: 15.5, weight: .heavy)
        let scoreStr = "\(pts)"
        let scoreSize = (scoreStr as NSString).size(withAttributes: [.font: scoreFont])
        let scoreX = x + w - scoreSize.width - 4
        scoreStr.draw(at: CGPoint(x: scoreX, y: y - 2), withAttributes: [.font: scoreFont, .foregroundColor: color])
    }
    
    private func drawHandballScoreboard(ctx: CGContext, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, state: RemoteMatchState, style: ThemeStyles) {
        drawSoccerScoreboard(ctx: ctx, x: x, y: y, w: w, h: h, state: state, style: style)
    }
    
    // MARK: - Tennis / Padel Scoreboard
    
    private func drawTennisScoreboard(ctx: CGContext, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, state: RemoteMatchState, style: ThemeStyles) {
        let headerH: CGFloat = 14
        let rowH = (h - headerH) / 2
        let row1Y = y + headerH + (rowH - 13) / 2
        let row2Y = y + headerH + rowH + (rowH - 13) / 2
        
        drawTeamRowTennis(ctx: ctx, x: x + 4, y: row1Y, name: state.teamA, pts: state.tennisPointsA, games: state.tennisGamesA, sets: state.setsA, isTiebreak: state.isTiebreak, color: style.scoreColorA, logo: homeLogo, style: style, w: w - 8)
        drawTeamRowTennis(ctx: ctx, x: x + 4, y: row2Y, name: state.teamB, pts: state.tennisPointsB, games: state.tennisGamesB, sets: state.setsB, isTiebreak: state.isTiebreak, color: style.scoreColorB, logo: awayLogo, style: style, w: w - 8)
    }
    
    private func drawTeamRowTennis(ctx: CGContext, x: CGFloat, y: CGFloat, name: String, pts: Int, games: Int, sets: Int, isTiebreak: Bool, color: UIColor, logo: UIImage?, style: ThemeStyles, w: CGFloat) {
        var curX = x
        if let logo = logo {
            logo.draw(in: CGRect(x: curX, y: y + 1, width: 12, height: 12))
            curX += 15
        }
        
        let nameFont = UIFont.systemFont(ofSize: 10.5, weight: .bold)
        let trimName = name.count > 14 ? String(name.prefix(14)) : name
        trimName.uppercased().draw(at: CGPoint(x: curX, y: y), withAttributes: [.font: nameFont, .foregroundColor: UIColor.white])
        
        let sgStr = "S:\(sets) G:\(games)"
        sgStr.draw(at: CGPoint(x: x + (w * 0.44), y: y + 2), withAttributes: [.font: UIFont.systemFont(ofSize: 9, weight: .bold), .foregroundColor: UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0)])
        
        let ptsStr: String
        if isTiebreak {
            ptsStr = "\(pts)"
        } else {
            switch pts {
            case 1: ptsStr = "15"
            case 2: ptsStr = "30"
            case 3: ptsStr = "40"
            case 4: ptsStr = "AD"
            default: ptsStr = "0"
            }
        }
        
        let scoreFont = UIFont.systemFont(ofSize: 15, weight: .heavy)
        let scoreSize = (ptsStr as NSString).size(withAttributes: [.font: scoreFont])
        let scoreX = x + w - scoreSize.width - 4
        ptsStr.draw(at: CGPoint(x: scoreX, y: y - 2), withAttributes: [.font: scoreFont, .foregroundColor: color])
    }
    
    // MARK: - Darts Scoreboard
    
    private func drawDartsScoreboard(ctx: CGContext, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, state: RemoteMatchState, style: ThemeStyles) {
        let headerH: CGFloat = 14
        let rowH = (h - headerH) / 2
        let row1Y = y + headerH + (rowH - 13) / 2
        let row2Y = y + headerH + rowH + (rowH - 13) / 2
        
        let trimA = state.teamA.count > 14 ? String(state.teamA.prefix(14)) : state.teamA
        let trimB = state.teamB.count > 14 ? String(state.teamB.prefix(14)) : state.teamB
        
        let isA = state.dartsActivePlayer == "A"
        let isB = state.dartsActivePlayer == "B"
        
        let arrowA = isA ? "▶ " : ""
        let arrowB = isB ? "▶ " : ""
        
        "\(arrowA)\(trimA.uppercased())".draw(at: CGPoint(x: x + 4, y: row1Y), withAttributes: [.font: UIFont.systemFont(ofSize: 10, weight: .bold), .foregroundColor: UIColor.white])
        "\(arrowB)\(trimB.uppercased())".draw(at: CGPoint(x: x + 4, y: row2Y), withAttributes: [.font: UIFont.systemFont(ofSize: 10, weight: .bold), .foregroundColor: UIColor.white])
        
        "L:\(state.dartsLegsA)".draw(at: CGPoint(x: x + (w * 0.48), y: row1Y + 1), withAttributes: [.font: UIFont.systemFont(ofSize: 9, weight: .bold), .foregroundColor: UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0)])
        "L:\(state.dartsLegsB)".draw(at: CGPoint(x: x + (w * 0.48), y: row2Y + 1), withAttributes: [.font: UIFont.systemFont(ofSize: 9, weight: .bold), .foregroundColor: UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0)])
        
        let ptsFont = UIFont.systemFont(ofSize: 15, weight: .heavy)
        let ptsStrA = "\(state.scoreA)"
        let ptsStrB = "\(state.scoreB)"
        
        let sizeA = (ptsStrA as NSString).size(withAttributes: [.font: ptsFont])
        let sizeB = (ptsStrB as NSString).size(withAttributes: [.font: ptsFont])
        
        ptsStrA.draw(at: CGPoint(x: x + w - sizeA.width - 4, y: row1Y - 2), withAttributes: [.font: ptsFont, .foregroundColor: style.scoreColorA])
        ptsStrB.draw(at: CGPoint(x: x + w - sizeB.width - 4, y: row2Y - 2), withAttributes: [.font: ptsFont, .foregroundColor: style.scoreColorB])
    }
    
    // MARK: - Billiards & Cricket Scoreboards
    
    private func drawBilliardsScoreboard(ctx: CGContext, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, state: RemoteMatchState, style: ThemeStyles) {
        let headerH: CGFloat = 14
        let rowH = (h - headerH) / 2
        let row1Y = y + headerH + (rowH - 13) / 2
        let row2Y = y + headerH + rowH + (rowH - 13) / 2
        
        let trimA = state.teamA.count > 14 ? String(state.teamA.prefix(14)) : state.teamA
        let trimB = state.teamB.count > 14 ? String(state.teamB.prefix(14)) : state.teamB
        
        trimA.uppercased().draw(at: CGPoint(x: x + 4, y: row1Y), withAttributes: [.font: UIFont.systemFont(ofSize: 10, weight: .bold), .foregroundColor: UIColor.white])
        trimB.uppercased().draw(at: CGPoint(x: x + 4, y: row2Y), withAttributes: [.font: UIFont.systemFont(ofSize: 10, weight: .bold), .foregroundColor: UIColor.white])
        
        "F:\(state.setsA)".draw(at: CGPoint(x: x + (w * 0.48), y: row1Y + 1), withAttributes: [.font: UIFont.systemFont(ofSize: 9, weight: .bold), .foregroundColor: UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0)])
        "F:\(state.setsB)".draw(at: CGPoint(x: x + (w * 0.48), y: row2Y + 1), withAttributes: [.font: UIFont.systemFont(ofSize: 9, weight: .bold), .foregroundColor: UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0)])
        
        let ptsFont = UIFont.systemFont(ofSize: 15, weight: .heavy)
        let ptsStrA = "\(state.scoreA)"
        let ptsStrB = "\(state.scoreB)"
        let sizeA = (ptsStrA as NSString).size(withAttributes: [.font: ptsFont])
        let sizeB = (ptsStrB as NSString).size(withAttributes: [.font: ptsFont])
        
        ptsStrA.draw(at: CGPoint(x: x + w - sizeA.width - 4, y: row1Y - 2), withAttributes: [.font: ptsFont, .foregroundColor: style.scoreColorA])
        ptsStrB.draw(at: CGPoint(x: x + w - sizeB.width - 4, y: row2Y - 2), withAttributes: [.font: ptsFont, .foregroundColor: style.scoreColorB])
    }
    
    private func drawCricketScoreboard(ctx: CGContext, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, state: RemoteMatchState, style: ThemeStyles) {
        let headerH: CGFloat = 14
        let rowH = (h - headerH) / 2
        let row1Y = y + headerH + (rowH - 13) / 2
        let row2Y = y + headerH + rowH + (rowH - 13) / 2
        
        let oversA = "\(state.cricketBallsA / 6).\(state.cricketBallsA % 6)"
        let oversB = "\(state.cricketBallsB / 6).\(state.cricketBallsB % 6)"
        
        let trimA = state.teamA.count > 14 ? String(state.teamA.prefix(14)) : state.teamA
        let trimB = state.teamB.count > 14 ? String(state.teamB.prefix(14)) : state.teamB
        
        trimA.uppercased().draw(at: CGPoint(x: x + 4, y: row1Y), withAttributes: [.font: UIFont.systemFont(ofSize: 10, weight: .bold), .foregroundColor: UIColor.white])
        trimB.uppercased().draw(at: CGPoint(x: x + 4, y: row2Y), withAttributes: [.font: UIFont.systemFont(ofSize: 10, weight: .bold), .foregroundColor: UIColor.white])
        
        "(\(oversA)ov)".draw(at: CGPoint(x: x + (w * 0.44), y: row1Y + 1), withAttributes: [.font: UIFont.systemFont(ofSize: 8.5, weight: .bold), .foregroundColor: UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0)])
        "(\(oversB)ov)".draw(at: CGPoint(x: x + (w * 0.44), y: row2Y + 1), withAttributes: [.font: UIFont.systemFont(ofSize: 8.5, weight: .bold), .foregroundColor: UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0)])
        
        let ptsFont = UIFont.systemFont(ofSize: 14.5, weight: .heavy)
        let ptsStrA = "\(state.scoreA)/\(state.foulsA)"
        let ptsStrB = "\(state.scoreB)/\(state.foulsB)"
        let sizeA = (ptsStrA as NSString).size(withAttributes: [.font: ptsFont])
        let sizeB = (ptsStrB as NSString).size(withAttributes: [.font: ptsFont])
        
        ptsStrA.draw(at: CGPoint(x: x + w - sizeA.width - 4, y: row1Y - 2), withAttributes: [.font: ptsFont, .foregroundColor: style.scoreColorA])
        ptsStrB.draw(at: CGPoint(x: x + w - sizeB.width - 4, y: row2Y - 2), withAttributes: [.font: ptsFont, .foregroundColor: style.scoreColorB])
    }
    
    // MARK: - Attached Set Point / Match Point Badge (Right Side of Scoreboard)
    
    private func drawAttachedSetPointBadge(ctx: CGContext, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, isMatchPoint: Bool) {
        ctx.saveGState()
        
        let r: CGFloat = 6.0
        let path = UIBezierPath()
        path.move(to: CGPoint(x: x, y: y))
        path.addLine(to: CGPoint(x: x + w - r, y: y))
        path.addQuadCurve(to: CGPoint(x: x + w, y: y + r), controlPoint: CGPoint(x: x + w, y: y))
        path.addLine(to: CGPoint(x: x + w, y: y + h - r))
        path.addQuadCurve(to: CGPoint(x: x + w - r, y: y + h), controlPoint: CGPoint(x: x + w, y: y + h))
        path.addLine(to: CGPoint(x: x, y: y + h))
        path.close()
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors: [CGColor]
        if isMatchPoint {
            // Gold / Amber Broadcast Gradient
            colors = [
                UIColor(red: 180/255, green: 83/255, blue: 9/255, alpha: 1.0).cgColor,
                UIColor(red: 245/255, green: 158/255, blue: 11/255, alpha: 1.0).cgColor
            ]
        } else {
            // Deep Red / Bright Red Broadcast Gradient
            colors = [
                UIColor(red: 153/255, green: 27/255, blue: 27/255, alpha: 1.0).cgColor,
                UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1.0).cgColor
            ]
        }
        
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0.0, 1.0]) {
            ctx.addPath(path.cgPath)
            ctx.clip()
            ctx.drawLinearGradient(gradient, start: CGPoint(x: x, y: y), end: CGPoint(x: x + w, y: y + h), options: [])
        }
        
        ctx.restoreGState()
        
        let borderColor = isMatchPoint ? UIColor(red: 253/255, green: 230/255, blue: 138/255, alpha: 1.0) : UIColor(red: 254/255, green: 202/255, blue: 202/255, alpha: 1.0)
        borderColor.setStroke()
        path.lineWidth = 1.2
        path.stroke()
        
        let text = isMatchPoint ? "MATCH POINT" : "SET POINT"
        let font = UIFont.systemFont(ofSize: 9, weight: .black)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraph
        ]
        
        let textRect = CGRect(x: x + 2, y: y + 3.5, width: w - 4, height: h - 5)
        text.draw(in: textRect, withAttributes: attrs)
    }
    
    // MARK: - Special Alerts: Blinking Central SET POINT / MATCH POINT
    
    func drawSpecialAlerts(ctx: CGContext, rect: CGRect, sp: SetPointInfo, state: RemoteMatchState) {
        let textLine1 = sp.isMatchPoint ? "MATCH POINT" : "SET POINT"
        let teamName = (sp.team == "A") ? (state.teamA.isEmpty ? "CASA" : state.teamA) : (state.teamB.isEmpty ? "OSPITE" : state.teamB)
        let textLine2 = teamName.uppercased()
        
        let centerX = rect.width / 2.0
        let centerY = rect.height / 2.0 - 15.0
        
        let font1 = UIFont.systemFont(ofSize: min(52.0, rect.width * 0.075), weight: .black)
        let font2 = UIFont.systemFont(ofSize: min(28.0, rect.width * 0.042), weight: .bold)
        
        let pStyle = NSMutableParagraphStyle()
        pStyle.alignment = .center
        
        let accentColor = sp.isMatchPoint ? UIColor(red: 245/255, green: 158/255, blue: 11/255, alpha: 1.0) : UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1.0)
        
        // Sfondo pillola broadcast semi-trasparente
        let pillW = min(460.0, rect.width * 0.78)
        let pillH: CGFloat = 110.0
        let pillRect = CGRect(x: centerX - pillW / 2.0, y: centerY - 20.0, width: pillW, height: pillH)
        let pillPath = UIBezierPath(roundedRect: pillRect, cornerRadius: 18.0)
        
        ctx.saveGState()
        UIColor(red: 2/255, green: 6/255, blue: 23/255, alpha: 0.90).setFill()
        pillPath.fill()
        
        accentColor.setStroke()
        pillPath.lineWidth = 3.0
        pillPath.stroke()
        
        // Riga 1: MATCH POINT / SET POINT
        let line1Attrs: [NSAttributedString.Key: Any] = [
            .font: font1,
            .foregroundColor: accentColor,
            .paragraphStyle: pStyle
        ]
        textLine1.draw(in: CGRect(x: centerX - pillW / 2.0, y: centerY - 10.0, width: pillW, height: 55.0), withAttributes: line1Attrs)
        
        // Riga 2: NOME SQUADRA
        let line2Attrs: [NSAttributedString.Key: Any] = [
            .font: font2,
            .foregroundColor: UIColor.white,
            .paragraphStyle: pStyle
        ]
        textLine2.draw(in: CGRect(x: centerX - pillW / 2.0, y: centerY + 46.0, width: pillW, height: 35.0), withAttributes: line2Attrs)
        ctx.restoreGState()
    }
    
    // MARK: - Special Alerts: Blinking Central TIMEOUT
    
    func drawTimeoutAlert(ctx: CGContext, rect: CGRect, teamName: String, state: RemoteMatchState) {
        let textLine1 = "TIMEOUT"
        let tName = teamName.isEmpty ? "TEAM" : teamName
        let textLine2 = tName.uppercased()
        
        let centerX = rect.width / 2.0
        let centerY = rect.height / 2.0 - 15.0
        
        let font1 = UIFont.systemFont(ofSize: min(52.0, rect.width * 0.075), weight: .black)
        let font2 = UIFont.systemFont(ofSize: min(28.0, rect.width * 0.042), weight: .bold)
        
        let pStyle = NSMutableParagraphStyle()
        pStyle.alignment = .center
        
        let accentColor = UIColor(red: 234/255, green: 179/255, blue: 8/255, alpha: 1.0) // Giallo acceso broadcast per TIMEOUT
        
        // Sfondo pillola broadcast semi-trasparente
        let pillW = min(460.0, rect.width * 0.78)
        let pillH: CGFloat = 110.0
        let pillRect = CGRect(x: centerX - pillW / 2.0, y: centerY - 20.0, width: pillW, height: pillH)
        let pillPath = UIBezierPath(roundedRect: pillRect, cornerRadius: 18.0)
        
        ctx.saveGState()
        UIColor(red: 2/255, green: 6/255, blue: 23/255, alpha: 0.90).setFill()
        pillPath.fill()
        
        accentColor.setStroke()
        pillPath.lineWidth = 3.0
        pillPath.stroke()
        
        // Riga 1: TIMEOUT
        let line1Attrs: [NSAttributedString.Key: Any] = [
            .font: font1,
            .foregroundColor: accentColor,
            .paragraphStyle: pStyle
        ]
        textLine1.draw(in: CGRect(x: centerX - pillW / 2.0, y: centerY - 10.0, width: pillW, height: 55.0), withAttributes: line1Attrs)
        
        // Riga 2: NOME SQUADRA
        let line2Attrs: [NSAttributedString.Key: Any] = [
            .font: font2,
            .foregroundColor: UIColor.white,
            .paragraphStyle: pStyle
        ]
        textLine2.draw(in: CGRect(x: centerX - pillW / 2.0, y: centerY + 46.0, width: pillW, height: 35.0), withAttributes: line2Attrs)
        ctx.restoreGState()
    }
    
    // MARK: - Special Alerts: Blinking Central TRIPLA (3 POINTS) (1:1 con Android OverlayRenderer)
    
    func drawTripleAlert(ctx: CGContext, rect: CGRect) {
        let text = "🎯 TRIPLA!"
        let centerX = rect.width / 2.0
        let centerY = rect.height / 2.0 - 15.0
        
        let font = UIFont.systemFont(ofSize: min(65.0, rect.width * 0.09), weight: .black)
        let pStyle = NSMutableParagraphStyle()
        pStyle.alignment = .center
        
        let pillW = min(420.0, rect.width * 0.70)
        let pillH: CGFloat = 85.0
        let pillRect = CGRect(x: centerX - pillW / 2.0, y: centerY - 10.0, width: pillW, height: pillH)
        let pillPath = UIBezierPath(roundedRect: pillRect, cornerRadius: 18.0)
        
        ctx.saveGState()
        UIColor(red: 2/255, green: 6/255, blue: 23/255, alpha: 0.92).setFill()
        pillPath.fill()
        
        UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0).setStroke()
        pillPath.lineWidth = 3.5
        pillPath.stroke()
        
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0),
            .paragraphStyle: pStyle
        ]
        text.draw(in: CGRect(x: centerX - pillW / 2.0, y: centerY + 2.0, width: pillW, height: 65.0), withAttributes: attrs)
        ctx.restoreGState()
    }
    
    // MARK: - End Game Graphics: Fine Set / Risultato Finale con Parziali
    
    private func drawEndGameGraphics(ctx: CGContext, rect: CGRect, state: RemoteMatchState) {
        ctx.saveGState()
        
        // 1. Sfondo scuro oscurante broadcast
        UIColor(red: 2/255, green: 6/255, blue: 23/255, alpha: 0.92).setFill()
        UIBezierPath(rect: rect).fill()
        
        let isMatchFin = state.isMatchFinished
        let title = isMatchFin ? "RISULTATO FINALE" : "\(state.currentSet)° SET CONCLUSO"
        let titleColor = isMatchFin ? UIColor(red: 236/255, green: 72/255, blue: 153/255, alpha: 1.0) : UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 1.0)
        
        let pStyle = NSMutableParagraphStyle()
        pStyle.alignment = .center
        
        // 2. Titolo in alto (Grande e vistoso)
        let titleFont = UIFont.systemFont(ofSize: min(64.0, rect.height * 0.08), weight: .black)
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: titleColor,
            .paragraphStyle: pStyle
        ]
        let titleY = max(24.0, rect.height * 0.06)
        title.uppercased().draw(in: CGRect(x: 20, y: titleY, width: rect.width - 40, height: 75), withAttributes: titleAttrs)
        
        // 3. Loghi Squadre (Ingranditi)
        let logoSize = min(180.0, rect.height * 0.22)
        let centerY = rect.height * 0.40
        if let logoA = homeLogo {
            logoA.draw(in: CGRect(x: rect.width * 0.10, y: centerY - logoSize / 2, width: logoSize, height: logoSize))
        }
        if let logoB = awayLogo {
            logoB.draw(in: CGRect(x: rect.width * 0.90 - logoSize, y: centerY - logoSize / 2, width: logoSize, height: logoSize))
        }
        
        // 4. Punteggio Grande al centro
        let scoreFont = UIFont.systemFont(ofSize: min(130.0, rect.height * 0.16), weight: .heavy)
        let scoreAttrs: [NSAttributedString.Key: Any] = [
            .font: scoreFont,
            .foregroundColor: UIColor.white,
            .paragraphStyle: pStyle
        ]
        let scoreStr = "\(state.scoreA)  -  \(state.scoreB)"
        scoreStr.draw(in: CGRect(x: rect.width * 0.20, y: centerY - 65, width: rect.width * 0.60, height: 130), withAttributes: scoreAttrs)
        
        // 5. Nomi Squadre e Set Vinti (Ingranditi e ben spaziati)
        let nameFont = UIFont.systemFont(ofSize: min(34.0, rect.height * 0.048), weight: .bold)
        let nameAttrs: [NSAttributedString.Key: Any] = [
            .font: nameFont,
            .foregroundColor: UIColor(red: 148/255, green: 163/255, blue: 184/255, alpha: 1.0),
            .paragraphStyle: pStyle
        ]
        
        let teamStrA = "\(state.teamA.isEmpty ? "CASA" : state.teamA) (\(state.setsA))"
        let teamStrB = "\(state.teamB.isEmpty ? "OSPITE" : state.teamB) (\(state.setsB))"
        
        let namesY = centerY + logoSize / 2 + 16
        teamStrA.uppercased().draw(in: CGRect(x: rect.width * 0.02, y: namesY, width: rect.width * 0.44, height: 48), withAttributes: nameAttrs)
        teamStrB.uppercased().draw(in: CGRect(x: rect.width * 0.54, y: namesY, width: rect.width * 0.44, height: 48), withAttributes: nameAttrs)
        
        // 6. Schede Parziali dei Set Precedenti (Ingrandite in basso)
        var allSets: [[Int]] = state.setScores
        if allSets.isEmpty && (state.scoreA > 0 || state.scoreB > 0) {
            allSets.append([state.scoreA, state.scoreB])
        }
        
        if !allSets.isEmpty {
            let numSets = allSets.count
            let cardW = min(170.0, (rect.width - 80.0 - CGFloat(numSets - 1) * 16.0) / CGFloat(numSets))
            let cardH: CGFloat = min(90.0, rect.height * 0.12)
            let gap: CGFloat = 16.0
            let totalW = CGFloat(numSets) * cardW + CGFloat(numSets - 1) * gap
            var startX = (rect.width - totalW) / 2.0
            let cardY = rect.height - cardH - max(28.0, rect.height * 0.07)
            
            for (idx, scorePair) in allSets.enumerated() {
                let cardRect = CGRect(x: startX, y: cardY, width: cardW, height: cardH)
                let cPath = UIBezierPath(roundedRect: cardRect, cornerRadius: 12.0)
                UIColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.95).setFill()
                cPath.fill()
                UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 0.9).setStroke()
                cPath.lineWidth = 2.0
                cPath.stroke()
                
                let setLabel = "\(idx + 1)° SET"
                let lblFont = UIFont.systemFont(ofSize: 18.0, weight: .bold)
                let lblAttrs: [NSAttributedString.Key: Any] = [
                    .font: lblFont,
                    .foregroundColor: UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 1.0),
                    .paragraphStyle: pStyle
                ]
                setLabel.draw(in: CGRect(x: startX, y: cardY + 8, width: cardW, height: 24), withAttributes: lblAttrs)
                
                let ptsStr = "\(scorePair[0]) - \(scorePair[1])"
                let ptsFont = UIFont.systemFont(ofSize: 32.0, weight: .heavy)
                let ptsAttrs: [NSAttributedString.Key: Any] = [
                    .font: ptsFont,
                    .foregroundColor: UIColor.white,
                    .paragraphStyle: pStyle
                ]
                ptsStr.draw(in: CGRect(x: startX, y: cardY + 36, width: cardW, height: 44), withAttributes: ptsAttrs)
                
                startX += cardW + gap
            }
        }
        
        ctx.restoreGState()
    }
    
    // MARK: - Replay TV Stinger & Flashing Badge
    
    func drawReplayBadge(ctx: CGContext, rect: CGRect) {
        ctx.saveGState()
        let text = "REPLAY"
        let pStyle = NSMutableParagraphStyle()
        pStyle.alignment = .center
        
        let font = UIFont.systemFont(ofSize: min(60.0, rect.height * 0.075), weight: .black)
        let x: CGFloat = 0
        let y: CGFloat = max(24.0, rect.height * 0.04)
        let textRect = CGRect(x: x, y: y, width: rect.width, height: 70)
        
        // 1. Dark Shadow Stroke
        let shadowAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.clear,
            .strokeColor: UIColor(white: 0.0, alpha: 0.8),
            .strokeWidth: -10.0,
            .paragraphStyle: pStyle
        ]
        text.draw(in: CGRect(x: textRect.origin.x, y: textRect.origin.y + 4, width: textRect.width, height: textRect.height), withAttributes: shadowAttrs)
        
        // 2. Red Outline & White Fill
        let redAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white,
            .strokeColor: UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1.0),
            .strokeWidth: -6.0,
            .paragraphStyle: pStyle
        ]
        text.draw(in: textRect, withAttributes: redAttrs)
        
        ctx.restoreGState()
    }
    
    func drawReplayStingerTransition(ctx: CGContext, rect: CGRect, progress: Double, isOutro: Bool) {
        ctx.saveGState()
        let sweepProgress = CGFloat(progress)
        
        let width = rect.width
        let height = rect.height
        
        // Intro: from left to right (-width to 2*width)
        // Outro: from right to left (2*width to -width)
        let sweepX: CGFloat = isOutro ? (width * 2.0 - sweepProgress * width * 3.0) : (-width + sweepProgress * width * 3.0)
        let stingerText = isOutro ? "LIVE" : "REPLAY"
        
        // 1. Diagonal dark background band
        let pathDark = UIBezierPath()
        pathDark.move(to: CGPoint(x: sweepX - width * 0.25, y: 0))
        pathDark.addLine(to: CGPoint(x: sweepX + width * 0.85, y: 0))
        pathDark.addLine(to: CGPoint(x: sweepX + width * 0.65, y: height))
        pathDark.addLine(to: CGPoint(x: sweepX - width * 0.45, y: height))
        pathDark.close()
        
        UIColor(red: 11/255, green: 19/255, blue: 43/255, alpha: 0.94).setFill()
        pathDark.fill()
        
        // 2. Red accent diagonal stripe
        let pathRed = UIBezierPath()
        pathRed.move(to: CGPoint(x: sweepX + width * 0.78, y: 0))
        pathRed.addLine(to: CGPoint(x: sweepX + width * 0.86, y: 0))
        pathRed.addLine(to: CGPoint(x: sweepX + width * 0.66, y: height))
        pathRed.addLine(to: CGPoint(x: sweepX + width * 0.58, y: height))
        pathRed.close()
        
        UIColor(red: 220/255, green: 38/255, blue: 38/255, alpha: 1.0).setFill()
        pathRed.fill()
        
        // 3. Cyan accent diagonal stripe
        let pathCyan = UIBezierPath()
        pathCyan.move(to: CGPoint(x: sweepX - width * 0.28, y: 0))
        pathCyan.addLine(to: CGPoint(x: sweepX - width * 0.22, y: 0))
        pathCyan.addLine(to: CGPoint(x: sweepX - width * 0.42, y: height))
        pathCyan.addLine(to: CGPoint(x: sweepX - width * 0.48, y: height))
        pathCyan.close()
        
        UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 1.0).setFill()
        pathCyan.fill()
        
        // 4. Centered Badge Element (with scale & alpha animation when progress is 0.15...0.85)
        if sweepProgress >= 0.15 && sweepProgress <= 0.85 {
            let centerProgress = (sweepProgress - 0.15) / 0.70
            let alpha: CGFloat = centerProgress < 0.2 ? (centerProgress / 0.2) : (centerProgress > 0.8 ? ((1.0 - centerProgress) / 0.2) : 1.0)
            let scale: CGFloat = 0.85 + 0.30 * CGFloat(sin(Double(centerProgress) * .pi))
            
            ctx.saveGState()
            ctx.translateBy(x: rect.midX, y: rect.midY)
            ctx.scaleBy(x: scale, y: scale)
            
            let boxW: CGFloat = min(620.0, rect.width * 0.45)
            let boxH: CGFloat = min(160.0, rect.height * 0.18)
            let boxRect = CGRect(x: -boxW / 2, y: -boxH / 2, width: boxW, height: boxH)
            let boxPath = UIBezierPath(roundedRect: boxRect, cornerRadius: 24.0)
            
            UIColor(red: 15/255, green: 23/255, blue: 42/255, alpha: alpha * 0.95).setFill()
            boxPath.fill()
            
            UIColor(red: 220/255, green: 38/255, blue: 38/255, alpha: alpha).setStroke()
            boxPath.lineWidth = 4.0
            boxPath.stroke()
            
            let pStyle = NSMutableParagraphStyle()
            pStyle.alignment = .center
            
            let font = UIFont.systemFont(ofSize: min(80.0, boxH * 0.55), weight: .black)
            
            // Text Shadow
            let textShadowAttrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.clear,
                .strokeColor: UIColor(white: 0.0, alpha: alpha * 0.8),
                .strokeWidth: -12.0,
                .paragraphStyle: pStyle
            ]
            stingerText.draw(in: CGRect(x: -boxW / 2, y: -boxH * 0.32, width: boxW, height: boxH), withAttributes: textShadowAttrs)
            
            // Text Fill
            let textFillAttrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor(white: 1.0, alpha: alpha),
                .strokeColor: UIColor(red: 220/255, green: 38/255, blue: 38/255, alpha: alpha * 0.8),
                .strokeWidth: -3.0,
                .paragraphStyle: pStyle
            ]
            stingerText.draw(in: CGRect(x: -boxW / 2, y: -boxH * 0.32, width: boxW, height: boxH), withAttributes: textFillAttrs)
            
            ctx.restoreGState()
        }
        
        ctx.restoreGState()
    }
}
