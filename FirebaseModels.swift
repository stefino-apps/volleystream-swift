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
    
    // Set (solo volley)
    var setsA: Int = 0
    var setsB: Int = 0
    
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
    var scrollMessage: String = "NOTIZIE: La partita proceda con regolarita' e le squadre sono in campo."
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

    var isReplayEnabled: Bool = false
    var isReplaying: Bool = false
    var overlayTheme: String = "neon"
    var lastUpdate: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    
    init() {}
}

