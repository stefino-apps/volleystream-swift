import UIKit

class ScoreboardOverlayView: UIView {

    var currentState = RemoteMatchState()
    var currentTheme = "neon"
    var homeLogo: UIImage?
    var awayLogo: UIImage?
    
    // Alert state
    var isAlertActive = false
    var alertText = ""
    var alertSubtext = ""
    var alertIsMatchPoint = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.clipsToBounds = false
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.backgroundColor = .clear
        self.clipsToBounds = false
    }
    
    func updateFromState(_ state: RemoteMatchState) {
        self.currentState = state
        self.currentTheme = state.overlayTheme.isEmpty ? "neon" : state.overlayTheme
        
        if let homeData = AppPreferences.shared.loadImage(name: "logoHome.png") {
            self.homeLogo = UIImage(data: homeData)
        }
        if let awayData = AppPreferences.shared.loadImage(name: "logoAway.png") {
            self.awayLogo = UIImage(data: awayData)
        }
        
        // Calcola se c'è un Set Point o Match Point
        if let sp = getSetPointInfo(state: state) {
            self.alertIsMatchPoint = sp.isMatchPoint
            self.alertText = sp.isMatchPoint ? "MATCH POINT" : "SET POINT"
            self.alertSubtext = sp.team == "A" ? state.teamA.uppercased() : state.teamB.uppercased()
        } else {
            self.alertText = ""
            self.alertSubtext = ""
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
        let scoreColor: UIColor
        
        init(theme: String) {
            switch theme {
            case "minimal":
                boxBgColor = UIColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.95)
                boxBorderColor = UIColor(red: 71/255, green: 85/255, blue: 105/255, alpha: 1.0)
                boxBorderWidth = 2.0
                boxCornerRadius = 12.0
                hasHeaderBg = false
                headerBgColor = .clear
                headerTextColor = UIColor(red: 148/255, green: 163/255, blue: 184/255, alpha: 1.0)
                dividerColor = UIColor(red: 51/255, green: 65/255, blue: 85/255, alpha: 1.0)
                timeoutActiveColor = UIColor(red: 56/255, green: 189/255, blue: 248/255, alpha: 1.0)
                timeoutInactiveColor = UIColor(red: 30/255, green: 41/255, blue: 59/255, alpha: 1.0)
                scoreColor = .white
            case "glass":
                boxBgColor = UIColor(red: 17/255, green: 24/255, blue: 39/255, alpha: 0.40)
                boxBorderColor = UIColor.white.withAlphaComponent(0.50)
                boxBorderWidth = 2.5
                boxCornerRadius = 24.0
                hasHeaderBg = true
                headerBgColor = UIColor.white.withAlphaComponent(0.15)
                headerTextColor = .white
                dividerColor = UIColor.white.withAlphaComponent(0.25)
                timeoutActiveColor = .white
                timeoutInactiveColor = UIColor.white.withAlphaComponent(0.20)
                scoreColor = .white
            case "classic":
                boxBgColor = UIColor(red: 17/255, green: 17/255, blue: 17/255, alpha: 1.0)
                boxBorderColor = .clear
                boxBorderWidth = 0.0
                boxCornerRadius = 4.0
                hasHeaderBg = true
                headerBgColor = UIColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1.0)
                headerTextColor = .white
                dividerColor = UIColor(red: 51/255, green: 51/255, blue: 51/255, alpha: 1.0)
                timeoutActiveColor = UIColor(red: 226/255, green: 232/255, blue: 240/255, alpha: 1.0)
                timeoutInactiveColor = UIColor(red: 71/255, green: 85/255, blue: 105/255, alpha: 1.0)
                scoreColor = .white
            case "odometer_blue":
                boxBgColor = UIColor(red: 0/255, green: 29/255, blue: 61/255, alpha: 0.90)
                boxBorderColor = UIColor(red: 0/255, green: 168/255, blue: 232/255, alpha: 1.0)
                boxBorderWidth = 2.0
                boxCornerRadius = 24.0
                hasHeaderBg = false
                headerBgColor = .clear
                headerTextColor = .white
                dividerColor = UIColor(red: 0/255, green: 168/255, blue: 232/255, alpha: 1.0)
                timeoutActiveColor = UIColor(red: 144/255, green: 224/255, blue: 239/255, alpha: 1.0)
                timeoutInactiveColor = UIColor(red: 0/255, green: 53/255, blue: 102/255, alpha: 1.0)
                scoreColor = UIColor(red: 144/255, green: 224/255, blue: 239/255, alpha: 1.0)
            case "odometer_red":
                boxBgColor = UIColor(red: 74/255, green: 4/255, blue: 4/255, alpha: 0.90)
                boxBorderColor = UIColor(red: 255/255, green: 107/255, blue: 107/255, alpha: 1.0)
                boxBorderWidth = 2.0
                boxCornerRadius = 24.0
                hasHeaderBg = false
                headerBgColor = .clear
                headerTextColor = .white
                dividerColor = UIColor(red: 255/255, green: 107/255, blue: 107/255, alpha: 1.0)
                timeoutActiveColor = UIColor(red: 255/255, green: 217/255, blue: 61/255, alpha: 1.0)
                timeoutInactiveColor = UIColor(red: 74/255, green: 4/255, blue: 4/255, alpha: 1.0)
                scoreColor = UIColor(red: 255/255, green: 217/255, blue: 61/255, alpha: 1.0)
            case "odometer_dark":
                boxBgColor = UIColor(red: 13/255, green: 13/255, blue: 13/255, alpha: 0.94)
                boxBorderColor = UIColor(red: 233/255, green: 69/255, blue: 96/255, alpha: 1.0)
                boxBorderWidth = 2.5
                boxCornerRadius = 24.0
                hasHeaderBg = false
                headerBgColor = .clear
                headerTextColor = .white
                dividerColor = UIColor(red: 233/255, green: 69/255, blue: 96/255, alpha: 1.0)
                timeoutActiveColor = UIColor(red: 233/255, green: 69/255, blue: 96/255, alpha: 1.0)
                timeoutInactiveColor = UIColor(red: 26/255, green: 26/255, blue: 46/255, alpha: 1.0)
                scoreColor = UIColor(red: 233/255, green: 69/255, blue: 96/255, alpha: 1.0)
            default: // "neon"
                boxBgColor = UIColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 0.90)
                boxBorderColor = UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 1.0)
                boxBorderWidth = 2.0
                boxCornerRadius = 20.0
                hasHeaderBg = true
                headerBgColor = UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 1.0)
                headerTextColor = .black
                dividerColor = UIColor(red: 51/255, green: 65/255, blue: 85/255, alpha: 1.0)
                timeoutActiveColor = UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0)
                timeoutInactiveColor = UIColor(red: 51/255, green: 65/255, blue: 85/255, alpha: 1.0)
                scoreColor = .white
            }
        }
    }
    
    // MARK: - Set Point Info
    
    struct SetPointInfo {
        let team: String // "A" or "B"
        let isMatchPoint: Bool
    }
    
    private func getSetPointInfo(state: RemoteMatchState) -> SetPointInfo? {
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
        
        let x: CGFloat = 2
        let y: CGFloat = 2
        let w: CGFloat = bounds.width - 4
        let h: CGFloat = bounds.height - 4
        
        // Render base box
        drawScoreboardBase(ctx: ctx, x: x, y: y, w: w, h: h, headerH: 18, infoText: getHeaderTitle(state: state), style: style)
        
        // Render Sport Content
        let sport = state.sportType.lowercased()
        switch sport {
        case "basket":
            drawBasketScoreboard(ctx: ctx, x: x, y: y, w: w, h: h, state: state, style: style)
        case "soccer":
            drawSoccerScoreboard(ctx: ctx, x: x, y: y, w: w, h: h, state: state, style: style)
        case "handball", "pallamano":
            drawHandballScoreboard(ctx: ctx, x: x, y: y, w: w, h: h, state: state, style: style)
        case "tennis", "padel":
            drawTennisScoreboard(ctx: ctx, x: x, y: y, w: w, h: h, state: state, style: style)
        case "darts":
            drawDartsScoreboard(ctx: ctx, x: x, y: y, w: w, h: h, state: state, style: style)
        case "billiards", "biliardo":
            drawBilliardsScoreboard(ctx: ctx, x: x, y: y, w: w, h: h, state: state, style: style)
        case "cricket":
            drawCricketScoreboard(ctx: ctx, x: x, y: y, w: w, h: h, state: state, style: style)
        default:
            drawVolleyScoreboard(ctx: ctx, x: x, y: y, w: w, h: h, state: state, style: style)
        }
        
        // Render Attached SET POINT / MATCH POINT Badge on the right
        if let sp = getSetPointInfo(state: state), !state.isSetFinished && !state.isMatchFinished {
            let badgeW: CGFloat = sp.isMatchPoint ? 92 : 80
            let badgeH: CGFloat = 20
            let badgeX = x + w - 1
            let badgeY = (sp.team == "A") ? y + 20 : y + 38
            drawAttachedSetPointBadge(ctx: ctx, x: badgeX, y: badgeY, w: badgeW, h: badgeH, isMatchPoint: sp.isMatchPoint)
        }
    }
    
    // MARK: - Header Titles
    
    private func getHeaderTitle(state: RemoteMatchState) -> String {
        let sport = state.sportType.lowercased()
        switch sport {
        case "basket":
            return "BASKET | QUARTO \(state.currentSet) DI \(state.totalPeriods)".uppercased()
        case "soccer":
            let half = state.currentSet == 1 ? "1° TEMPO" : (state.currentSet == 2 ? "2° TEMPO" : "SUPPL.")
            return "CALCIO | \(half)".uppercased()
        case "handball", "pallamano":
            let half = state.currentSet == 1 ? "1° TEMPO" : "2° TEMPO"
            return "PALLAMANO | \(half)".uppercased()
        case "tennis":
            return "TENNIS | SET \(state.currentSet)".uppercased()
        case "padel":
            let isDeuce = state.tennisPointsA == 3 && state.tennisPointsB == 3 && !state.isTiebreak
            if state.isPuntoDeOro && isDeuce {
                return "PADEL | SET \(state.currentSet) | ★ PUNTO DE ORO".uppercased()
            }
            return "PADEL | SET \(state.currentSet)".uppercased()
        case "darts":
            return "FRECCETTE - \(state.dartsMode)".uppercased()
        case "billiards", "biliardo":
            return "BILIARDO | FRAME \(state.currentSet)".uppercased()
        case "cricket":
            return "CRICKET | INNINGS \(state.currentSet)".uppercased()
        case "beach_volley", "beach volley":
            let total = state.scoreA + state.scoreB
            let interval = state.currentSet == 3 ? 5 : 7
            if total > 0 && total % interval == 0 {
                return "🏖️ CAMBIO CAMPO (SIDE SWITCH)".uppercased()
            }
            return "BEACH VOLLEY | SET \(state.currentSet)".uppercased()
        default:
            let tieBreak = state.isFifthSet ? "• TIE-BREAK" : ""
            return "VOLLEY | SET \(state.currentSet) \(tieBreak)".uppercased()
        }
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
        let font = UIFont.systemFont(ofSize: 8.5, weight: .black)
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
        let headerH: CGFloat = 14
        let rowH = (h - headerH) / 2
        let row1Y = y + headerH + (rowH - 13) / 2
        let row2Y = y + headerH + rowH + (rowH - 13) / 2
        
        let isBeach = (state.sportType.lowercased() == "beach_volley" || state.sportType.lowercased() == "beach volley")
        let maxTos = isBeach ? 1 : 2
        
        let hasStarted = state.scoreA > 0 || state.scoreB > 0
        let srvA = hasStarted && state.servingTeam == "A"
        let srvB = hasStarted && state.servingTeam == "B"
        
        // Row Home (Team A)
        drawTeamRow(ctx: ctx, x: x + 4, y: row1Y, name: state.teamA, pts: state.scoreA, tos: state.timeoutA, maxTos: maxTos, isSrv: srvA, color: UIColor(red: 236/255, green: 72/255, blue: 153/255, alpha: 1.0), logo: homeLogo, style: style, w: w - 8)
        
        // Row Away (Team B)
        drawTeamRow(ctx: ctx, x: x + 4, y: row2Y, name: state.teamB, pts: state.scoreB, tos: state.timeoutB, maxTos: maxTos, isSrv: srvB, color: UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 1.0), logo: awayLogo, style: style, w: w - 8)
    }
    
    private func drawTeamRow(ctx: CGContext, x: CGFloat, y: CGFloat, name: String, pts: Int, tos: Int, maxTos: Int, isSrv: Bool, color: UIColor, logo: UIImage?, style: ThemeStyles, w: CGFloat) {
        var curX = x
        if let logo = logo {
            logo.draw(in: CGRect(x: curX, y: y + 1, width: 12, height: 12))
            curX += 15
        }
        
        if isSrv {
            drawVolleyBall(ctx: ctx, cx: curX + 4, cy: y + 6, r: 4.5)
            curX += 11
        }
        
        let nameFont = UIFont.systemFont(ofSize: 10.5, weight: .bold)
        let nameAttrs: [NSAttributedString.Key: Any] = [.font: nameFont, .foregroundColor: UIColor.white]
        let trimName = name.count > 10 ? String(name.prefix(10)) : name
        trimName.uppercased().draw(at: CGPoint(x: curX, y: y), withAttributes: nameAttrs)
        
        let toX = x + (w * 0.48)
        for i in 0..<maxTos {
            let toRect = CGRect(x: toX + CGFloat(i * 8), y: y + 4.5, width: 5.5, height: 3)
            let toColor = (i < tos) ? style.timeoutActiveColor : style.timeoutInactiveColor
            toColor.setFill()
            UIBezierPath(roundedRect: toRect, cornerRadius: 1.0).fill()
        }
        
        let scoreFont = UIFont.systemFont(ofSize: 15.5, weight: .heavy)
        let scoreAttrs: [NSAttributedString.Key: Any] = [.font: scoreFont, .foregroundColor: color]
        let scoreStr = "\(pts)"
        let scoreSize = (scoreStr as NSString).size(withAttributes: scoreAttrs)
        let scoreX = x + w - scoreSize.width - 4
        scoreStr.draw(at: CGPoint(x: scoreX, y: y - 2), withAttributes: scoreAttrs)
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
        
        drawTeamRowBasket(ctx: ctx, x: x + 4, y: row1Y, name: state.teamA, pts: state.scoreA, fouls: state.foulsA, tos: state.timeoutA, color: UIColor(red: 236/255, green: 72/255, blue: 153/255, alpha: 1.0), logo: homeLogo, style: style, w: w - 8)
        drawTeamRowBasket(ctx: ctx, x: x + 4, y: row2Y, name: state.teamB, pts: state.scoreB, fouls: state.foulsB, tos: state.timeoutB, color: UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 1.0), logo: awayLogo, style: style, w: w - 8)
    }
    
    private func drawTeamRowBasket(ctx: CGContext, x: CGFloat, y: CGFloat, name: String, pts: Int, fouls: Int, tos: Int, color: UIColor, logo: UIImage?, style: ThemeStyles, w: CGFloat) {
        var curX = x
        if let logo = logo {
            logo.draw(in: CGRect(x: curX, y: y + 1, width: 12, height: 12))
            curX += 15
        }
        
        let nameFont = UIFont.systemFont(ofSize: 10.5, weight: .bold)
        let trimName = name.count > 8 ? String(name.prefix(8)) : name
        trimName.uppercased().draw(at: CGPoint(x: curX, y: y), withAttributes: [.font: nameFont, .foregroundColor: UIColor.white])
        
        let toX = x + (w * 0.42)
        for i in 0..<3 {
            let toRect = CGRect(x: toX + CGFloat(i * 7), y: y + 4.5, width: 5, height: 3)
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
        
        drawTeamRowSoccer(ctx: ctx, x: x + 4, y: row1Y, name: state.teamA, pts: state.scoreA, redCards: state.redCardsA, color: UIColor(red: 236/255, green: 72/255, blue: 153/255, alpha: 1.0), logo: homeLogo, style: style, w: w - 8)
        drawTeamRowSoccer(ctx: ctx, x: x + 4, y: row2Y, name: state.teamB, pts: state.scoreB, redCards: state.redCardsB, color: UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 1.0), logo: awayLogo, style: style, w: w - 8)
    }
    
    private func drawTeamRowSoccer(ctx: CGContext, x: CGFloat, y: CGFloat, name: String, pts: Int, redCards: Int, color: UIColor, logo: UIImage?, style: ThemeStyles, w: CGFloat) {
        var curX = x
        if let logo = logo {
            logo.draw(in: CGRect(x: curX, y: y + 1, width: 12, height: 12))
            curX += 15
        }
        
        let nameFont = UIFont.systemFont(ofSize: 10.5, weight: .bold)
        let trimName = name.count > 10 ? String(name.prefix(10)) : name
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
        
        drawTeamRowTennis(ctx: ctx, x: x + 4, y: row1Y, name: state.teamA, pts: state.tennisPointsA, games: state.tennisGamesA, sets: state.setsA, isTiebreak: state.isTiebreak, color: UIColor(red: 236/255, green: 72/255, blue: 153/255, alpha: 1.0), logo: homeLogo, style: style, w: w - 8)
        drawTeamRowTennis(ctx: ctx, x: x + 4, y: row2Y, name: state.teamB, pts: state.tennisPointsB, games: state.tennisGamesB, sets: state.setsB, isTiebreak: state.isTiebreak, color: UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 1.0), logo: awayLogo, style: style, w: w - 8)
    }
    
    private func drawTeamRowTennis(ctx: CGContext, x: CGFloat, y: CGFloat, name: String, pts: Int, games: Int, sets: Int, isTiebreak: Bool, color: UIColor, logo: UIImage?, style: ThemeStyles, w: CGFloat) {
        var curX = x
        if let logo = logo {
            logo.draw(in: CGRect(x: curX, y: y + 1, width: 12, height: 12))
            curX += 15
        }
        
        let nameFont = UIFont.systemFont(ofSize: 10.5, weight: .bold)
        let trimName = name.count > 8 ? String(name.prefix(8)) : name
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
        
        let trimA = state.teamA.count > 8 ? String(state.teamA.prefix(8)) : state.teamA
        let trimB = state.teamB.count > 8 ? String(state.teamB.prefix(8)) : state.teamB
        
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
        
        ptsStrA.draw(at: CGPoint(x: x + w - sizeA.width - 4, y: row1Y - 2), withAttributes: [.font: ptsFont, .foregroundColor: UIColor(red: 236/255, green: 72/255, blue: 153/255, alpha: 1.0)])
        ptsStrB.draw(at: CGPoint(x: x + w - sizeB.width - 4, y: row2Y - 2), withAttributes: [.font: ptsFont, .foregroundColor: UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 1.0)])
    }
    
    // MARK: - Billiards & Cricket Scoreboards
    
    private func drawBilliardsScoreboard(ctx: CGContext, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, state: RemoteMatchState, style: ThemeStyles) {
        let headerH: CGFloat = 14
        let rowH = (h - headerH) / 2
        let row1Y = y + headerH + (rowH - 13) / 2
        let row2Y = y + headerH + rowH + (rowH - 13) / 2
        
        let trimA = state.teamA.count > 8 ? String(state.teamA.prefix(8)) : state.teamA
        let trimB = state.teamB.count > 8 ? String(state.teamB.prefix(8)) : state.teamB
        
        trimA.uppercased().draw(at: CGPoint(x: x + 4, y: row1Y), withAttributes: [.font: UIFont.systemFont(ofSize: 10, weight: .bold), .foregroundColor: UIColor.white])
        trimB.uppercased().draw(at: CGPoint(x: x + 4, y: row2Y), withAttributes: [.font: UIFont.systemFont(ofSize: 10, weight: .bold), .foregroundColor: UIColor.white])
        
        "F:\(state.setsA)".draw(at: CGPoint(x: x + (w * 0.48), y: row1Y + 1), withAttributes: [.font: UIFont.systemFont(ofSize: 9, weight: .bold), .foregroundColor: UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0)])
        "F:\(state.setsB)".draw(at: CGPoint(x: x + (w * 0.48), y: row2Y + 1), withAttributes: [.font: UIFont.systemFont(ofSize: 9, weight: .bold), .foregroundColor: UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0)])
        
        let ptsFont = UIFont.systemFont(ofSize: 15, weight: .heavy)
        let ptsStrA = "\(state.scoreA)"
        let ptsStrB = "\(state.scoreB)"
        let sizeA = (ptsStrA as NSString).size(withAttributes: [.font: ptsFont])
        let sizeB = (ptsStrB as NSString).size(withAttributes: [.font: ptsFont])
        
        ptsStrA.draw(at: CGPoint(x: x + w - sizeA.width - 4, y: row1Y - 2), withAttributes: [.font: ptsFont, .foregroundColor: UIColor(red: 236/255, green: 72/255, blue: 153/255, alpha: 1.0)])
        ptsStrB.draw(at: CGPoint(x: x + w - sizeB.width - 4, y: row2Y - 2), withAttributes: [.font: ptsFont, .foregroundColor: UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 1.0)])
    }
    
    private func drawCricketScoreboard(ctx: CGContext, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, state: RemoteMatchState, style: ThemeStyles) {
        let headerH: CGFloat = 14
        let rowH = (h - headerH) / 2
        let row1Y = y + headerH + (rowH - 13) / 2
        let row2Y = y + headerH + rowH + (rowH - 13) / 2
        
        let oversA = "\(state.cricketBallsA / 6).\(state.cricketBallsA % 6)"
        let oversB = "\(state.cricketBallsB / 6).\(state.cricketBallsB % 6)"
        
        let trimA = state.teamA.count > 8 ? String(state.teamA.prefix(8)) : state.teamA
        let trimB = state.teamB.count > 8 ? String(state.teamB.prefix(8)) : state.teamB
        
        trimA.uppercased().draw(at: CGPoint(x: x + 4, y: row1Y), withAttributes: [.font: UIFont.systemFont(ofSize: 10, weight: .bold), .foregroundColor: UIColor.white])
        trimB.uppercased().draw(at: CGPoint(x: x + 4, y: row2Y), withAttributes: [.font: UIFont.systemFont(ofSize: 10, weight: .bold), .foregroundColor: UIColor.white])
        
        "(\(oversA)ov)".draw(at: CGPoint(x: x + (w * 0.44), y: row1Y + 1), withAttributes: [.font: UIFont.systemFont(ofSize: 8.5, weight: .bold), .foregroundColor: UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0)])
        "(\(oversB)ov)".draw(at: CGPoint(x: x + (w * 0.44), y: row2Y + 1), withAttributes: [.font: UIFont.systemFont(ofSize: 8.5, weight: .bold), .foregroundColor: UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 1.0)])
        
        let ptsFont = UIFont.systemFont(ofSize: 14.5, weight: .heavy)
        let ptsStrA = "\(state.scoreA)/\(state.foulsA)"
        let ptsStrB = "\(state.scoreB)/\(state.foulsB)"
        let sizeA = (ptsStrA as NSString).size(withAttributes: [.font: ptsFont])
        let sizeB = (ptsStrB as NSString).size(withAttributes: [.font: ptsFont])
        
        ptsStrA.draw(at: CGPoint(x: x + w - sizeA.width - 4, y: row1Y - 2), withAttributes: [.font: ptsFont, .foregroundColor: UIColor(red: 236/255, green: 72/255, blue: 153/255, alpha: 1.0)])
        ptsStrB.draw(at: CGPoint(x: x + w - sizeB.width - 4, y: row2Y - 2), withAttributes: [.font: ptsFont, .foregroundColor: UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 1.0)])
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
}
