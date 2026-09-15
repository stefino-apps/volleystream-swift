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
        get { defaults.string(forKey: keySport) ?? "volley" }
        set { defaults.set(newValue, forKey: keySport) }
    }
    
    var teamHome: String {
        get {
            let str = defaults.string(forKey: keyTeamHome) ?? "CASA"
            return str.count > 14 ? String(str.prefix(14)) : str
        }
        set {
            let trimmed = newValue.count > 14 ? String(newValue.prefix(14)) : newValue
            defaults.set(trimmed, forKey: keyTeamHome)
        }
    }
    
    var teamAway: String {
        get {
            let str = defaults.string(forKey: keyTeamAway) ?? "OSPITE"
            return str.count > 14 ? String(str.prefix(14)) : str
        }
        set {
            let trimmed = newValue.count > 14 ? String(newValue.prefix(14)) : newValue
            defaults.set(trimmed, forKey: keyTeamAway)
        }
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
    
    var beachSetsToWin: Int {
        get {
            let v = defaults.integer(forKey: "beach_sets_to_win")
            return v > 0 ? v : 2
        }
        set { defaults.set(newValue, forKey: "beach_sets_to_win") }
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
    
    func clearAll() {
        if let bundleID = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: bundleID)
        }
        deleteImage(name: "logo_team_a.png")
        deleteImage(name: "logo_team_b.png")
        deleteImage(name: "sponsorFull.png")
        for i in 1...4 { deleteImage(name: "sponsor_\(i).png") }
        for i in 0...4 {
            deleteImage(name: "banner_\(i + 1).png")
            deleteImage(name: "sponsorRotating_\(i).png")
        }
    }
}
