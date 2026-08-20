import SwiftUI

struct WelcomeView: View {
    @StateObject private var storeManager = StoreKitManager.shared
    @State private var navigateToSetup = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.vspDark.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Text("welcome_subtitle".localized)
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("welcome_title".localized)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.vspRed)
                    
                    Spacer()
                    
                    // Features Grid
                    VStack(alignment: .leading, spacing: 15) {
                        FeatureRow(icon: "video.fill", text: "badge_remote".localized)
                        FeatureRow(icon: "tv", text: "badge_tv_graphics".localized)
                        FeatureRow(icon: "wifi", text: "badge_premium".localized)
                        FeatureRow(icon: "iphone.radiowaves.left.and.right", text: "badge_remote_control".localized)
                    }
                    .padding()
                    .background(Color.vspPanel)
                    .cornerRadius(12)
                    
                    Spacer()
                    
                    if !storeManager.isPremium {
                        Button(action: {
                            Task { await storeManager.purchasePremium() }
                        }) {
                            Text("free_trial".localized)
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.neonGradient)
                                .cornerRadius(25)
                        }
                    } else {
                        Text("active_subscription".localized)
                            .foregroundColor(.green)
                            .bold()
                    }
                    
                    NavigationLink(destination: LiveSetupView(), isActive: $navigateToSetup) {
                        Button(action: { navigateToSetup = true }) {
                            Text("btn_next".localized)
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(25)
                        }
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct FeatureRow: View {
    var icon: String
    var text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.vspRed)
                .frame(width: 30)
            Text(text)
                .foregroundColor(.white)
                .font(.subheadline)
        }
    }
}
