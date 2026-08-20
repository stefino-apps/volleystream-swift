import Foundation

// Modelli Dati per Firebase Sync (equivalenti alle classi data in Kotlin)

struct MatchData: Codable {
    var score: ScoreData
    var sets: ScoreData
    var teams: TeamData
    var actions: ActionData
    var status: String
    
    // Inizializzazione vuota base
    init() {
        self.score = ScoreData(home: 0, away: 0)
        self.sets = ScoreData(home: 0, away: 0)
        self.teams = TeamData(home: "HOME", away: "AWAY")
        self.actions = ActionData(triggerReplay: false, triggerHighlight: false)
        self.status = "idle"
    }
}

struct ScoreData: Codable {
    var home: Int
    var away: Int
}

struct TeamData: Codable {
    var home: String
    var away: String
}

struct ActionData: Codable {
    var triggerReplay: Bool
    var triggerHighlight: Bool
}
