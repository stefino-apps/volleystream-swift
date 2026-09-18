import Foundation
import SwiftUI
import Combine

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "app_lang")
            updateBundles()
            NotificationCenter.default.post(name: Notification.Name("AppLanguageChanged"), object: currentLanguage)
        }
    }
    
    private var activeBundle: Bundle?
    private var fallbackBundle: Bundle?
    private var italianBundle: Bundle?
    
    private init() {
        let saved = UserDefaults.standard.string(forKey: "app_lang") ?? "it"
        self.currentLanguage = saved
        updateBundles()
    }
    
    private func updateBundles() {
        if let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj") {
            activeBundle = Bundle(path: path)
        } else {
            activeBundle = nil
        }
        
        if let enPath = Bundle.main.path(forResource: "en", ofType: "lproj") {
            fallbackBundle = Bundle(path: enPath)
        }
        
        if let itPath = Bundle.main.path(forResource: "it", ofType: "lproj") {
            italianBundle = Bundle(path: itPath)
        }
    }
    
    func setLanguage(_ lang: String) {
        if currentLanguage != lang {
            currentLanguage = lang
        }
    }
    
    func localizedString(for key: String) -> String {
        // 1. Cerca nella lingua corrente
        if let bundle = activeBundle {
            let res = NSLocalizedString(key, tableName: nil, bundle: bundle, value: "__NOT_FOUND__", comment: "")
            if res != "__NOT_FOUND__" && !res.isEmpty {
                return res
            }
        }
        
        // 2. Fallback su Inglese
        if let enBundle = fallbackBundle {
            let res = NSLocalizedString(key, tableName: nil, bundle: enBundle, value: "__NOT_FOUND__", comment: "")
            if res != "__NOT_FOUND__" && !res.isEmpty {
                return res
            }
        }
        
        // 3. Fallback su Italiano
        if let itBundle = italianBundle {
            let res = NSLocalizedString(key, tableName: nil, bundle: itBundle, value: "__NOT_FOUND__", comment: "")
            if res != "__NOT_FOUND__" && !res.isEmpty {
                return res
            }
        }
        
        // 4. Default bundle o key
        let res = NSLocalizedString(key, value: key, comment: "")
        return res.isEmpty ? key : res
    }
    
    func localizedString(for key: String, with args: [CVarArg]) -> String {
        let format = localizedString(for: key)
        return String(format: format, arguments: args)
    }
}

extension String {
    var localized: String {
        return LanguageManager.shared.localizedString(for: self)
    }
    
    func localized(with args: CVarArg...) -> String {
        return LanguageManager.shared.localizedString(for: self, with: args)
    }
}
