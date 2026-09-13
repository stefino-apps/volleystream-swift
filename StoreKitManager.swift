import Foundation
import StoreKit

enum PremiumFeature {
    case remoteControl
    case customLogos
    case instantReplay
    case highlights
    case sponsors
    case cleanWatermark
}

class StoreKitManager: ObservableObject, @unchecked Sendable {
    static let shared = StoreKitManager()
    
    @Published var isPremium: Bool = false
    @Published var subscriptionStatus: String = "premium".localized
    @Published var isPurchasing: Bool = false
    @Published var purchaseErrorMessage: String? = nil
    
    // Product identifier for App Store Connect
    private let productIDs = ["com.volleystream.pro.sub_yearly_3999"]
    
    // Trial duration: 7 days in seconds
    private let trialDurationSeconds: TimeInterval = 7 * 24 * 60 * 60
    
    init() {
        initTrialIfNeeded()
        Task {
            await checkActiveSubscriptions()
        }
    }
    
    // MARK: - 7 Days Free Trial Logic (Protected via iOS Keychain against reinstall resets)
    
    private let keychainService = "com.volleystream.pro.trial"
    private let keychainAccount = "first_launch_timestamp"
    
    private func saveToKeychain(key: String, value: String) {
        if let data = value.data(using: .utf8) {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: keychainService,
                kSecAttrAccount as String: key,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
            ]
            SecItemDelete(query as CFDictionary)
            SecItemAdd(query as CFDictionary, nil)
        }
    }
    
    private func readFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    private func initTrialIfNeeded() {
        // 1. Prova a leggere dal Keychain (persiste anche se l'app viene disinstallata)
        if let tsString = readFromKeychain(key: keychainAccount), let _ = Double(tsString) {
            return
        }
        
        // 2. Se non esiste nel Keychain, controlla UserDefaults come fallback
        let defaults = UserDefaults.standard
        if let ts = defaults.object(forKey: "first_launch_timestamp") as? Double, ts > 0 {
            saveToKeychain(key: keychainAccount, value: String(ts))
            return
        }
        
        // 3. Primo avvio in assoluto: genera timestamp e salva sia in Keychain che in UserDefaults
        let nowTs = Date().timeIntervalSince1970
        saveToKeychain(key: keychainAccount, value: String(nowTs))
        defaults.set(nowTs, forKey: "first_launch_timestamp")
    }
    
    var firstLaunchDate: Date {
        if let tsString = readFromKeychain(key: keychainAccount), let ts = Double(tsString), ts > 0 {
            return Date(timeIntervalSince1970: ts)
        }
        let ts = UserDefaults.standard.double(forKey: "first_launch_timestamp")
        return ts > 0 ? Date(timeIntervalSince1970: ts) : Date()
    }
    
    var isTrialActive: Bool {
        if isPremium { return false }
        let elapsed = Date().timeIntervalSince(firstLaunchDate)
        return elapsed < trialDurationSeconds
    }
    
    var daysRemainingInTrial: Int {
        let elapsed = Date().timeIntervalSince(firstLaunchDate)
        let remainingSeconds = max(0, trialDurationSeconds - elapsed)
        return max(1, Int(ceil(remainingSeconds / (24 * 60 * 60))))
    }
    
    var isPremiumOrTrial: Bool {
        return isPremium || isTrialActive
    }
    
    func canUseFeature(_ feature: PremiumFeature) -> Bool {
        if isPremium { return true }
        if isTrialActive {
            // All features allowed during trial, except clean watermark is only for paid Premium
            if feature == .cleanWatermark {
                return false
            }
            return true
        }
        return false
    }
    
    // MARK: - StoreKit 2 Purchase & Entitlements
    
    func purchasePremium() async -> Bool {
        DispatchQueue.main.async {
            self.isPurchasing = true
            self.purchaseErrorMessage = nil
        }
        
        do {
            let products = try await Product.products(for: productIDs)
            guard let product = products.first else {
                DispatchQueue.main.async {
                    self.isPurchasing = false
                    self.purchaseErrorMessage = "Prodotto non disponibile al momento. Riprova più tardi."
                }
                return false
            }
            
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    DispatchQueue.main.async {
                        self.isPurchasing = false
                        self.isPremium = true
                        UserDefaults.standard.set(true, forKey: "is_premium_unlocked")
                        self.subscriptionStatus = "sub_active_welcome".localized
                    }
                    return true
                case .unverified(_, let error):
                    DispatchQueue.main.async {
                        self.isPurchasing = false
                        self.purchaseErrorMessage = error.localizedDescription
                    }
                    return false
                }
            case .userCancelled:
                DispatchQueue.main.async {
                    self.isPurchasing = false
                }
                return false
            case .pending:
                DispatchQueue.main.async {
                    self.isPurchasing = false
                    self.purchaseErrorMessage = "Transazione in attesa di approvazione."
                }
                return false
            @unknown default:
                DispatchQueue.main.async {
                    self.isPurchasing = false
                }
                return false
            }
        } catch {
            DispatchQueue.main.async {
                self.isPurchasing = false
                self.purchaseErrorMessage = error.localizedDescription
            }
            return false
        }
    }
    
    func checkActiveSubscriptions() async {
        var hasActiveSub = UserDefaults.standard.bool(forKey: "is_premium_unlocked")
        
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if transaction.productType == .autoRenewable || transaction.productType == .nonConsumable {
                    hasActiveSub = true
                }
            case .unverified(_, _):
                continue
            }
        }
        
        let active = hasActiveSub
        DispatchQueue.main.async {
            self.isPremium = active
            if active {
                self.subscriptionStatus = "sub_active_welcome".localized
            } else if self.isTrialActive {
                self.subscriptionStatus = "\(self.daysRemainingInTrial)d PROVA"
            } else {
                self.subscriptionStatus = "premium".localized
            }
        }
    }
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await checkActiveSubscriptions()
        } catch {
            print("Errore restore: \(error)")
        }
    }
}
