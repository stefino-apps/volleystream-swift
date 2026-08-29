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
    
    // Testo Scorrevole
    private let keyTickerEnabled = "ticker_enabled"
    private let keyTickerText = "ticker_text"
    
    var tickerEnabled: Bool {
        get { defaults.bool(forKey: keyTickerEnabled) }
        set { defaults.set(newValue, forKey: keyTickerEnabled) }
    }
    
    var tickerText: String {
        get { defaults.string(forKey: keyTickerText) ?? "BENVENUTI ALLA DIRETTA" }
        set { defaults.set(newValue, forKey: keyTickerText) }
    }
    
    // Loghi e Sponsor
    private let keyHomeLogo = "home_logo_data"
    private let keyAwayLogo = "away_logo_data"
    private let keySponsor1 = "sponsor1_data"
    private let keySponsor2 = "sponsor2_data"
    private let keySponsorFS = "sponsor_fs_data"
    
    var homeLogoData: Data? {
        get { defaults.data(forKey: keyHomeLogo) }
        set { defaults.set(newValue, forKey: keyHomeLogo) }
    }
    
    var awayLogoData: Data? {
        get { defaults.data(forKey: keyAwayLogo) }
        set { defaults.set(newValue, forKey: keyAwayLogo) }
    }
    
    var sponsor1Data: Data? {
        get { defaults.data(forKey: keySponsor1) }
        set { defaults.set(newValue, forKey: keySponsor1) }
    }
    
    var sponsor2Data: Data? {
        get { defaults.data(forKey: keySponsor2) }
        set { defaults.set(newValue, forKey: keySponsor2) }
    }
    
    var sponsorFullScreenData: Data? {
        get { defaults.data(forKey: keySponsorFS) }
        set { defaults.set(newValue, forKey: keySponsorFS) }
    }
    
    // Sport Selezionato
    private let keySportType = "sport_type"
    
    var sportType: String {
        get { defaults.string(forKey: keySportType) ?? "volley" }
        set { defaults.set(newValue, forKey: keySportType) }
    }
}
