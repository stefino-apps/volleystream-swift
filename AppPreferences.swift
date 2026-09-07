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
        get { defaults.string(forKey: keySport) ?? "VOLLEY" }
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
    
    var selectedTheme: String {
        get { defaults.string(forKey: "selected_theme") ?? "neon" }
        set { defaults.set(newValue, forKey: "selected_theme") }
    }
    
    func saveImage(_ data: Data, name: String) {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(name)
        try? data.write(to: url)
    }
    
    func loadImage(name: String) -> Data? {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: url.path) {
            return try? Data(contentsOf: url)
        }
        // Fallback names check
        if name == "logo_team_a.png" {
            let altUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("logoHome.png")
            return try? Data(contentsOf: altUrl)
        } else if name == "logo_team_b.png" {
            let altUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("logoAway.png")
            return try? Data(contentsOf: altUrl)
        } else if name == "logoHome.png" {
            let altUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("logo_team_a.png")
            return try? Data(contentsOf: altUrl)
        } else if name == "logoAway.png" {
            let altUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("logo_team_b.png")
            return try? Data(contentsOf: altUrl)
        }
        return nil
    }
    
    func deleteImage(name: String) {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(name)
        try? FileManager.default.removeItem(at: url)
        if name == "logo_team_a.png" || name == "logoHome.png" {
            let u1 = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("logoHome.png")
            let u2 = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("logo_team_a.png")
            try? FileManager.default.removeItem(at: u1)
            try? FileManager.default.removeItem(at: u2)
        } else if name == "logo_team_b.png" || name == "logoAway.png" {
            let u1 = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("logoAway.png")
            let u2 = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("logo_team_b.png")
            try? FileManager.default.removeItem(at: u1)
            try? FileManager.default.removeItem(at: u2)
        }
    }
}
