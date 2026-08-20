import Foundation

class AppPreferences {
    static let shared = AppPreferences()
    private let defaults = UserDefaults.standard
    
    // Chiavi
    private let keySport = "selected_sport"
    private let keyTeamHome = "team_home"
    private let keyTeamAway = "team_away"
    private let keyResolution = "video_resolution"
    private let keyFPS = "video_fps"
    private let keyReplayEnabled = "instant_replay_enabled"
    private let keyIsPremium = "is_premium"
    
    var selectedSport: String {
        get { defaults.string(forKey: keySport) ?? "🏐 VOLLEY" }
        set { defaults.set(newValue, forKey: keySport) }
    }
    
    var teamHome: String {
        get { defaults.string(forKey: keyTeamHome) ?? "CASA" }
        set { defaults.set(newValue, forKey: keyTeamHome) }
    }
    
    var teamAway: String {
        get { defaults.string(forKey: keyTeamAway) ?? "OSPITE" }
        set { defaults.set(newValue, forKey: keyTeamAway) }
    }
    
    var videoResolution: Int {
        get { defaults.integer(forKey: keyResolution) == 0 ? 1080 : defaults.integer(forKey: keyResolution) }
        set { defaults.set(newValue, forKey: keyResolution) }
    }
    
    var videoFPS: Int {
        get { defaults.integer(forKey: keyFPS) == 0 ? 60 : defaults.integer(forKey: keyFPS) }
        set { defaults.set(newValue, forKey: keyFPS) }
    }
    
    var isReplayEnabled: Bool {
        get { defaults.bool(forKey: keyReplayEnabled) }
        set { defaults.set(newValue, forKey: keyReplayEnabled) }
    }
}
