import Foundation

// Modello Dati per Firebase Sync (Equivalente 1:1 a RemoteMatchState in Kotlin)

struct RemoteMatchState: Codable {
    var sportType: String = "volley"
    var totalPeriods: Int = 4

    var teamA: String = "HOME"
    var teamB: String = "GUEST"
    
    // Punti
    var scoreA: Int = 0
    var scoreB: Int = 0
    
    // Set (solo volley/tennis)
    var setsA: Int = 0
    var setsB: Int = 0
    var setScores: [[Int]] = []
    var isFifthSet: Bool = false
    var isSetFinished: Bool = false
    var isMatchFinished: Bool = false
    var tennisSetsToWin: Int = 2
    
    var currentSet: Int = 1
    
    // Falli (solo basket)
    var foulsA: Int = 0
    var foulsB: Int = 0

    // Timeout
    var timeoutA: Int = 0
    var timeoutB: Int = 0
    
    // Controllo Regia
    var isStreaming: Bool = false
    var streamingStatus: String = "OFFLINE"
    var isMuted: Bool = false
    var showSponsor: Bool = false
    var currentSponsorIdx: Int = -1
    var showScrollText: Bool = false
    var scrollMessage: String = "NOTIZIE: La partita procede con regolarità e le squadre sono in campo."
    var fullScreenSponsor: Bool = false
    var servingTeam: String = ""
    var dataUsageGB: Double = 0.0
    var batteryLevel: Int = 0
    var languageCode: String = "it"
    
    // Soccer specific
    var soccerHalfDuration: Int = 45
    var timerSeconds: Int = 0
    var timerRunning: Bool = false
    var timerStartTime: Int64 = 0
    var redCardsA: Int = 0
    var redCardsB: Int = 0
    var isGoalAlertActive: Bool = false
    var goalAlertTeam: String = ""
    var goalAlertStartTime: Int64 = 0
    
    // Tennis/Padel specific
    var tennisPointsA: Int = 0
    var tennisPointsB: Int = 0
    var tennisGamesA: Int = 0
    var tennisGamesB: Int = 0
    var isTiebreak: Bool = false
    var isPuntoDeOro: Bool = false

    // Darts specific
    var dartsMode: String = "501"
    var dartsActivePlayer: String = "A"
    var dartsLegsA: Int = 0
    var dartsLegsB: Int = 0
    var dartsThrows: [String] = ["", "", ""]
    var dartsTurnScore: Int = 0
    var isDartsBust: Bool = false

    // Cricket specific
    var cricketBallsA: Int = 0
    var cricketBallsB: Int = 0
    var cricketWicketsA: Int = 0
    var cricketWicketsB: Int = 0

    var isReplayEnabled: Bool = false
    var isReplaying: Bool = false
    var overlayTheme: String = "neon"
    var lastUpdate: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    
    init() {}
    
    // Safe Decoder that never fails on missing/extra fields from Android
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        sportType = (try? container.decodeIfPresent(String.self, forKey: .sportType)) ?? "volley"
        totalPeriods = (try? container.decodeIfPresent(Int.self, forKey: .totalPeriods)) ?? 4
        
        teamA = (try? container.decodeIfPresent(String.self, forKey: .teamA)) ?? "HOME"
        teamB = (try? container.decodeIfPresent(String.self, forKey: .teamB)) ?? "GUEST"
        
        scoreA = (try? container.decodeIfPresent(Int.self, forKey: .scoreA)) ?? 0
        scoreB = (try? container.decodeIfPresent(Int.self, forKey: .scoreB)) ?? 0
        
        setsA = (try? container.decodeIfPresent(Int.self, forKey: .setsA)) ?? 0
        setsB = (try? container.decodeIfPresent(Int.self, forKey: .setsB)) ?? 0
        setScores = (try? container.decodeIfPresent([[Int]].self, forKey: .setScores)) ?? []
        isFifthSet = (try? container.decodeIfPresent(Bool.self, forKey: .isFifthSet)) ?? false
        isSetFinished = (try? container.decodeIfPresent(Bool.self, forKey: .isSetFinished)) ?? false
        isMatchFinished = (try? container.decodeIfPresent(Bool.self, forKey: .isMatchFinished)) ?? false
        tennisSetsToWin = (try? container.decodeIfPresent(Int.self, forKey: .tennisSetsToWin)) ?? 2
        
        currentSet = (try? container.decodeIfPresent(Int.self, forKey: .currentSet)) ?? 1
        
        foulsA = (try? container.decodeIfPresent(Int.self, forKey: .foulsA)) ?? 0
        foulsB = (try? container.decodeIfPresent(Int.self, forKey: .foulsB)) ?? 0
        
        timeoutA = (try? container.decodeIfPresent(Int.self, forKey: .timeoutA)) ?? 0
        timeoutB = (try? container.decodeIfPresent(Int.self, forKey: .timeoutB)) ?? 0
        
        isStreaming = (try? container.decodeIfPresent(Bool.self, forKey: .isStreaming)) ?? false
        streamingStatus = (try? container.decodeIfPresent(String.self, forKey: .streamingStatus)) ?? "OFFLINE"
        isMuted = (try? container.decodeIfPresent(Bool.self, forKey: .isMuted)) ?? false
        showSponsor = (try? container.decodeIfPresent(Bool.self, forKey: .showSponsor)) ?? false
        currentSponsorIdx = (try? container.decodeIfPresent(Int.self, forKey: .currentSponsorIdx)) ?? -1
        showScrollText = (try? container.decodeIfPresent(Bool.self, forKey: .showScrollText)) ?? false
        scrollMessage = (try? container.decodeIfPresent(String.self, forKey: .scrollMessage)) ?? ""
        fullScreenSponsor = (try? container.decodeIfPresent(Bool.self, forKey: .fullScreenSponsor)) ?? false
        servingTeam = (try? container.decodeIfPresent(String.self, forKey: .servingTeam)) ?? ""
        
        if let d = try? container.decodeIfPresent(Double.self, forKey: .dataUsageGB) {
            dataUsageGB = d
        } else if let i = try? container.decodeIfPresent(Int.self, forKey: .dataUsageGB) {
            dataUsageGB = Double(i)
        } else {
            dataUsageGB = 0.0
        }
        
        batteryLevel = (try? container.decodeIfPresent(Int.self, forKey: .batteryLevel)) ?? 0
        languageCode = (try? container.decodeIfPresent(String.self, forKey: .languageCode)) ?? "it"
        
        soccerHalfDuration = (try? container.decodeIfPresent(Int.self, forKey: .soccerHalfDuration)) ?? 45
        timerSeconds = (try? container.decodeIfPresent(Int.self, forKey: .timerSeconds)) ?? 0
        timerRunning = (try? container.decodeIfPresent(Bool.self, forKey: .timerRunning)) ?? false
        timerStartTime = (try? container.decodeIfPresent(Int64.self, forKey: .timerStartTime)) ?? 0
        redCardsA = (try? container.decodeIfPresent(Int.self, forKey: .redCardsA)) ?? 0
        redCardsB = (try? container.decodeIfPresent(Int.self, forKey: .redCardsB)) ?? 0
        isGoalAlertActive = (try? container.decodeIfPresent(Bool.self, forKey: .isGoalAlertActive)) ?? false
        goalAlertTeam = (try? container.decodeIfPresent(String.self, forKey: .goalAlertTeam)) ?? ""
        goalAlertStartTime = (try? container.decodeIfPresent(Int64.self, forKey: .goalAlertStartTime)) ?? 0
        
        tennisPointsA = (try? container.decodeIfPresent(Int.self, forKey: .tennisPointsA)) ?? 0
        tennisPointsB = (try? container.decodeIfPresent(Int.self, forKey: .tennisPointsB)) ?? 0
        tennisGamesA = (try? container.decodeIfPresent(Int.self, forKey: .tennisGamesA)) ?? 0
        tennisGamesB = (try? container.decodeIfPresent(Int.self, forKey: .tennisGamesB)) ?? 0
        isTiebreak = (try? container.decodeIfPresent(Bool.self, forKey: .isTiebreak)) ?? false
        isPuntoDeOro = (try? container.decodeIfPresent(Bool.self, forKey: .isPuntoDeOro)) ?? false
        
        dartsMode = (try? container.decodeIfPresent(String.self, forKey: .dartsMode)) ?? "501"
        dartsActivePlayer = (try? container.decodeIfPresent(String.self, forKey: .dartsActivePlayer)) ?? "A"
        dartsLegsA = (try? container.decodeIfPresent(Int.self, forKey: .dartsLegsA)) ?? 0
        dartsLegsB = (try? container.decodeIfPresent(Int.self, forKey: .dartsLegsB)) ?? 0
        dartsThrows = (try? container.decodeIfPresent([String].self, forKey: .dartsThrows)) ?? ["", "", ""]
        dartsTurnScore = (try? container.decodeIfPresent(Int.self, forKey: .dartsTurnScore)) ?? 0
        isDartsBust = (try? container.decodeIfPresent(Bool.self, forKey: .isDartsBust)) ?? false
        
        cricketBallsA = (try? container.decodeIfPresent(Int.self, forKey: .cricketBallsA)) ?? 0
        cricketBallsB = (try? container.decodeIfPresent(Int.self, forKey: .cricketBallsB)) ?? 0
        cricketWicketsA = (try? container.decodeIfPresent(Int.self, forKey: .cricketWicketsA)) ?? 0
        cricketWicketsB = (try? container.decodeIfPresent(Int.self, forKey: .cricketWicketsB)) ?? 0
        
        isReplayEnabled = (try? container.decodeIfPresent(Bool.self, forKey: .isReplayEnabled)) ?? false
        isReplaying = (try? container.decodeIfPresent(Bool.self, forKey: .isReplaying)) ?? false
        overlayTheme = (try? container.decodeIfPresent(String.self, forKey: .overlayTheme)) ?? "neon"
        lastUpdate = (try? container.decodeIfPresent(Int64.self, forKey: .lastUpdate)) ?? Int64(Date().timeIntervalSince1970 * 1000)
    }
    
    // Direct Dictionary Initializer for 100% resilient parsing from Firebase snapshots
    init(dict: [String: Any]) {
        if let val = dict["sportType"] as? String { self.sportType = val }
        if let val = dict["totalPeriods"] as? Int { self.totalPeriods = val }
        if let val = dict["teamA"] as? String { self.teamA = val }
        if let val = dict["teamB"] as? String { self.teamB = val }
        
        if let val = dict["scoreA"] as? Int { self.scoreA = val }
        if let val = dict["scoreB"] as? Int { self.scoreB = val }
        if let val = dict["setsA"] as? Int { self.setsA = val }
        if let val = dict["setsB"] as? Int { self.setsB = val }
        if let val = dict["currentSet"] as? Int { self.currentSet = val }
        
        if let val = dict["foulsA"] as? Int { self.foulsA = val }
        if let val = dict["foulsB"] as? Int { self.foulsB = val }
        if let val = dict["timeoutA"] as? Int { self.timeoutA = val }
        if let val = dict["timeoutB"] as? Int { self.timeoutB = val }
        
        if let val = dict["isStreaming"] as? Bool { self.isStreaming = val }
        if let val = dict["streamingStatus"] as? String { self.streamingStatus = val }
        if let val = dict["isMuted"] as? Bool { self.isMuted = val }
        if let val = dict["showSponsor"] as? Bool { self.showSponsor = val }
        if let val = dict["currentSponsorIdx"] as? Int { self.currentSponsorIdx = val }
        if let val = dict["showScrollText"] as? Bool { self.showScrollText = val }
        if let val = dict["servingTeam"] as? String { self.servingTeam = val }
        
        if let val = dict["dataUsageGB"] as? Double { self.dataUsageGB = val }
        else if let val = dict["dataUsageGB"] as? Int { self.dataUsageGB = Double(val) }
        
        if let val = dict["batteryLevel"] as? Int { self.batteryLevel = val }
        if let val = dict["languageCode"] as? String { self.languageCode = val }
        
        if let val = dict["soccerHalfDuration"] as? Int { self.soccerHalfDuration = val }
        if let val = dict["timerSeconds"] as? Int { self.timerSeconds = val }
        if let val = dict["timerRunning"] as? Bool { self.timerRunning = val }
        if let val = dict["redCardsA"] as? Int { self.redCardsA = val }
        if let val = dict["redCardsB"] as? Int { self.redCardsB = val }
        if let val = dict["isGoalAlertActive"] as? Bool { self.isGoalAlertActive = val }
        if let val = dict["goalAlertTeam"] as? String { self.goalAlertTeam = val }
        
        if let val = dict["tennisPointsA"] as? Int { self.tennisPointsA = val }
        if let val = dict["tennisPointsB"] as? Int { self.tennisPointsB = val }
        if let val = dict["tennisGamesA"] as? Int { self.tennisGamesA = val }
        if let val = dict["tennisGamesB"] as? Int { self.tennisGamesB = val }
        if let val = dict["isTiebreak"] as? Bool { self.isTiebreak = val }
        
        if let val = dict["dartsMode"] as? String { self.dartsMode = val }
        if let val = dict["dartsActivePlayer"] as? String { self.dartsActivePlayer = val }
        if let val = dict["dartsLegsA"] as? Int { self.dartsLegsA = val }
        if let val = dict["dartsLegsB"] as? Int { self.dartsLegsB = val }
        if let val = dict["dartsThrows"] as? [String] { self.dartsThrows = val }
        if let val = dict["dartsTurnScore"] as? Int { self.dartsTurnScore = val }
        if let val = dict["isDartsBust"] as? Bool { self.isDartsBust = val }
        
        if let val = dict["cricketBallsA"] as? Int { self.cricketBallsA = val }
        if let val = dict["cricketBallsB"] as? Int { self.cricketBallsB = val }
        
        if let val = dict["isReplayEnabled"] as? Bool { self.isReplayEnabled = val }
        if let val = dict["isReplaying"] as? Bool { self.isReplaying = val }
        if let val = dict["overlayTheme"] as? String { self.overlayTheme = val }
    }
}

