import SwiftUI

struct WelcomeView: View {
    @StateObject private var storeManager = StoreKitManager.shared
    @State private var navigateToSetup = false
    @State private var showLangPicker = false
    @State private var showMenu = false
    @State private var selectedBadgeInfo: String? = nil
    @State private var navigateToRemote = false
    @AppStorage("app_lang") private var appLang = "it"
    
    let languages = [
        "it": "Italiano", "en": "English", "es": "Español",
        "fr": "Français", "de": "Deutsch", "pt-PT": "Português",
        "pl": "Polski", "ru": "Русский", "hi": "हिन्दी"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 2/255, green: 6/255, blue: 23/255).edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Top Bar
                    HStack {
                        Button(action: {
                            showMenu = true
                        }) {
                            Image(systemName: "line.horizontal.3")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        .actionSheet(isPresented: $showMenu) {
                            ActionSheet(title: Text("Menu"), buttons: [
                                .default(Text("Privacy Policy")) {
                                    if let url = URL(string: "https://volleystreampro.com/privacy.html") { UIApplication.shared.open(url) }
                                },
                                .default(Text("Termini d'uso")) {
                                    if let url = URL(string: "https://volleystreampro.com/terms.html") { UIApplication.shared.open(url) }
                                },
                                .default(Text("Contatti")) {
                                    if let url = URL(string: "mailto:support@volleystreampro.com") { UIApplication.shared.open(url) }
                                },
                                .default(Text("Tutorial Schermate")) {
                                    if let url = URL(string: "https://volleystreampro.com/tutorial") { UIApplication.shared.open(url) }
                                },
                                .destructive(Text("Cancella Account")) {},
                                .cancel()
                            ])
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showLangPicker = true
                        }) {
                            Image(systemName: "globe")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        .actionSheet(isPresented: $showLangPicker) {
                            ActionSheet(title: Text("Select Language"), buttons: languages.map { lang in
                                .default(Text(lang.value)) {
                                    appLang = lang.key
                                }
                            } + [.cancel()])
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 32)
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            // Title
                            Text("VOLLEYSTREAM PRO")
                                .font(.system(size: 36, weight: .bold, design: .default))
                                .italic()
                                .tracking(0.05)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(hex: "#38BDF8"), Color(hex: "#FACC15"), Color(hex: "#C084FC")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: Color(hex: "#06b6d4").opacity(0.8), radius: 10, x: 0, y: 0)
                                .padding(.top, 24)
                            
                            // Glowing line
                            Rectangle()
                                .fill(LinearGradient(
                                    colors: [Color(hex: "#38BDF8"), Color(hex: "#FACC15")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(width: 120, height: 4)
                                .padding(.top, 8)
                            
                            if !storeManager.isPremium {
                                Text("ABBONAMENTO SCADUTO / VERSIONE BASE")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                                    .padding(.top, 10)
                            } else {
                                Text("ABBONAMENTO PREMIUM ATTIVO")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                                    .padding(.top, 10)
                            }
                            
                            // Badges
                            VStack(spacing: 16) {
                                AndroidBadgeView(text: "badge_remote".localized) { selectedBadgeInfo = "Permette lo streaming in alta qualità" }
                                AndroidBadgeView(text: "badge_premium".localized) { selectedBadgeInfo = "Permette la gestione avanzata" }
                                AndroidBadgeView(text: "badge_tv_graphics".localized) { selectedBadgeInfo = "Grafiche TV sovraimpresse e tabellone" }
                                AndroidBadgeView(text: "badge_remote_control".localized) { selectedBadgeInfo = "Controlla il tabellone da un altro telefono" }
                                AndroidBadgeView(text: "badge_local_record".localized) { selectedBadgeInfo = "Salva il video nella galleria in MP4" }
                                AndroidBadgeView(text: "badge_instant_replay".localized) { selectedBadgeInfo = "Rivedi l'azione al rallentatore in diretta" }
                                
                                Button(action: { navigateToRemote = true }) {
                                    Text("btn_remote_mode".localized)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color(hex: "#EF4444"))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.white, lineWidth: 2)
                                        )
                                }
                                .padding(.top, 16)
                                
                                NavigationLink(destination: RemoteControlView(), isActive: $navigateToRemote) {
                                    EmptyView()
                                }
                            }
                            .padding(.top, 40)
                            .padding(.horizontal, 32)
                        }
                        .padding(.bottom, 20)
                    }
                    
                    // Version Text
                    Text("v1.0.56 (56)")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "#475569"))
                        .padding(.bottom, 8)
                    
                    // Next Button
                    NavigationLink(destination: SettingsView(), isActive: $navigateToSetup) {
                        Button(action: { navigateToSetup = true }) {
                            Text("btn_next".localized)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 64)
                                .background(Color(hex: "#06b6d4"))
                                .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .navigationBarHidden(true)
            .alert(item: Binding<AlertInfo?>(
                get: { selectedBadgeInfo.map { AlertInfo(message: $0) } },
                set: { if $0 == nil { selectedBadgeInfo = nil } }
            )) { info in
                Alert(title: Text("Info"), message: Text(info.message), dismissButton: .default(Text("OK")))
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onOpenURL { url in
            if url.scheme == "volleypro" && url.host == "remote" {
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let id = components.queryItems?.first(where: { $0.name == "code" || $0.name == "id" })?.value {
                    UserDefaults.standard.set(id, forKey: "incoming_remote_id")
                    navigateToRemote = true
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenRemoteControl"))) { _ in
            navigateToRemote = true
        }
    }
}

struct AlertInfo: Identifiable {
    let id = UUID()
    let message: String
}

struct AndroidBadgeView: View {
    var text: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "#00FFCC"))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(hex: "#FACC15"), lineWidth: 1)
                )
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
