import Foundation
import StoreKit

class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    
    @Published var isPremium: Bool = false
    @Published var subscriptionStatus: String = "checking_purchases".localized
    
    // Sostituisce i product IDs di Google Play Billing (es. sub_yearly_3999)
    private let productIDs = ["com.volleypro.live.sub_yearly_3999"]
    
    init() {
        Task {
            await checkActiveSubscriptions()
        }
    }
    
    func purchasePremium() async {
        do {
            let products = try await Product.products(for: productIDs)
            guard let product = products.first else { return }
            
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    DispatchQueue.main.async {
                        self.isPremium = true
                        self.subscriptionStatus = "sub_active_welcome".localized
                    }
                case .unverified(_, _):
                    break
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            print("Acquisto fallito: \(error.localizedDescription)")
        }
    }
    
    func checkActiveSubscriptions() async {
        var hasActiveSub = false
        
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if transaction.productType == .autoRenewable {
                    hasActiveSub = true
                }
            case .unverified(_, _):
                continue
            }
        }
        
        DispatchQueue.main.async {
            self.isPremium = hasActiveSub
            if hasActiveSub {
                self.subscriptionStatus = "sub_active_welcome".localized
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
