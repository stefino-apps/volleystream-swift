import SwiftUI
import Combine
import WebKit

struct WelcomeView: View {
    @StateObject private var storeManager = StoreKitManager.shared
    @State private var navigateToSetup = false
    @State private var showLangPicker = false
    @State private var showMenu = false
    @State private var selectedBadgeInfo: String? = nil
    @State private var navigateToRemote = false
    @State private var showDeleteAccountAlert = false
    @State private var activeLegalDoc: LegalDocType? = nil
    @AppStorage("app_lang") private var appLang = "it"
    
    let languages = [
        "it": "Italiano", "en": "English", "es": "Español",
        "fr": "Français", "de": "Deutsch", "pt-PT": "Português",
        "pl": "Polski", "ru": "Русский", "hi": "हिन्दी"
    ]
    
    enum LegalDocType: Identifiable {
        case privacy
        case terms
        
        var id: String {
            switch self {
            case .privacy: return "privacy"
            case .terms: return "terms"
            }
        }
        
        var title: String {
            switch self {
            case .privacy: return "Informativa sulla Privacy"
            case .terms: return "Termini di Servizio"
            }
        }
        
        var htmlFileName: String {
            switch self {
            case .privacy: return "privacy.html"
            case .terms: return "terms.html"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 2/255, green: 6/255, blue: 23/255).edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Top Bar: Menu (Left), Tutorial (Center-Right), Language (Right)
                    HStack(spacing: 8) {
                        Button(action: { showMenu = true }) {
                            Image(systemName: "line.horizontal.3")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                        }
                        .actionSheet(isPresented: $showMenu) {
                            ActionSheet(title: Text("Menu"), buttons: [
                                .default(Text("menu_privacy".localized.isEmpty ? "Privacy Policy" : "menu_privacy".localized)) {
                                    activeLegalDoc = .privacy
                                },
                                .default(Text("menu_terms".localized.isEmpty ? "Termini di Servizio" : "menu_terms".localized)) {
                                    activeLegalDoc = .terms
                                },
                                .default(Text("menu_contacts".localized.isEmpty ? "Contatti" : "menu_contacts".localized)) {
                                    openSupportEmail()
                                },
                                .default(Text("Tutorial Schermate")) {
                                    if let url = URL(string: "https://volleystreampro.com/tutorial") { UIApplication.shared.open(url) }
                                },
                                .destructive(Text("menu_delete_account".localized.isEmpty ? "Cancella Account" : "menu_delete_account".localized)) {
                                    showDeleteAccountAlert = true
                                },
                                .cancel()
                            ])
                        }
                        
                        Spacer()
                        
                        // Tutorial Button
                        Button(action: {
                            if let url = URL(string: "https://volleystreampro.com/tutorial") { UIApplication.shared.open(url) }
                        }) {
                            Text("TUTORIAL")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(hex: "#22c55e"))
                                .cornerRadius(16)
                        }
                        
                        // Language Button
                        Button(action: { showLangPicker = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "globe")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "#06b6d4"))
                                Text("language_button".localized)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Color(hex: "#06b6d4"))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                        }
                        .actionSheet(isPresented: $showLangPicker) {
                            ActionSheet(title: Text("select_language".localized), buttons: languages.map { lang in
                                .default(Text(lang.value)) {
                                    appLang = lang.key
                                }
                            } + [.cancel()])
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            // Top Right Trial & Subscription Button
                            HStack {
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("free_trial".localized)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(Color(hex: "#22c55e"))
                                    
                                    Button(action: {}) {
                                        Text("PREMIUM")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(Color(hex: "#06b6d4"))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(Color(hex: "#0f172a"))
                                            .cornerRadius(12)
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#06b6d4"), lineWidth: 1))
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 12)
                            
                            // Title
                            Text("VOLLEYSTREAM PRO")
                                .font(.system(size: 32, weight: .bold, design: .default))
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
                                .padding(.top, 16)
                            
                            // Glowing line
                            Rectangle()
                                .fill(LinearGradient(
                                    colors: [Color(hex: "#38BDF8"), Color(hex: "#FACC15")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(width: 120, height: 4)
                                .padding(.top, 8)
                            
                            // Badges
                            VStack(spacing: 14) {
                                AndroidBadgeView(text: "badge_remote".localized) { selectedBadgeInfo = "popup_remote_msg".localized }
                                AndroidBadgeView(text: "badge_premium".localized) { selectedBadgeInfo = "popup_premium_msg".localized }
                                AndroidBadgeView(text: "badge_tv_graphics".localized) { selectedBadgeInfo = "popup_tv_graphics_msg".localized }
                                AndroidBadgeView(text: "badge_remote_control".localized) { selectedBadgeInfo = "popup_remote_control_msg".localized }
                                AndroidBadgeView(text: "badge_local_record".localized) { selectedBadgeInfo = "popup_local_record_msg".localized }
                                AndroidBadgeView(text: "badge_instant_replay".localized) { selectedBadgeInfo = "popup_instant_replay_msg".localized }
                                
                                Button(action: { navigateToRemote = true }) {
                                    Text("btn_remote_mode".localized)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color(hex: "#EF4444"))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.white, lineWidth: 2)
                                        )
                                }
                                .padding(.top, 12)
                                
                                NavigationLink(destination: RemoteControlView(), isActive: $navigateToRemote) {
                                    EmptyView()
                                }
                            }
                            .padding(.top, 24)
                            .padding(.horizontal, 24)
                        }
                        .padding(.bottom, 16)
                    }
                    
                    // Footer Legal Links: Privacy Policy • Termini di Utilizzo • Contatti
                    HStack(spacing: 12) {
                        Button(action: { activeLegalDoc = .privacy }) {
                            Text("Privacy Policy")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(hex: "#94a3b8"))
                                .underline()
                        }
                        
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "#475569"))
                        
                        Button(action: { activeLegalDoc = .terms }) {
                            Text("Termini d'uso")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(hex: "#94a3b8"))
                                .underline()
                        }
                        
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "#475569"))
                        
                        Button(action: { openSupportEmail() }) {
                            Text("Contatti")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(hex: "#94a3b8"))
                                .underline()
                        }
                    }
                    .padding(.bottom, 6)
                    
                    // Version Text matching Android
                    Text("v1.0.74 (74)")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "#475569"))
                        .padding(.bottom, 8)
                    
                    // Next Button (AVANTI)
                    NavigationLink(destination: SettingsView(), isActive: $navigateToSetup) {
                        Button(action: { navigateToSetup = true }) {
                            Text("btn_next".localized)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(Color(hex: "#06b6d4"))
                                .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $activeLegalDoc) { doc in
                LegalDocSheetView(doc: doc)
            }
            .alert(isPresented: $showDeleteAccountAlert) {
                Alert(
                    title: Text("Eliminazione Account"),
                    message: Text("Sei sicuro di voler eliminare in via definitiva l'accesso del tuo account Google/YouTube da questa app? Questa azione revocherà i permessi e cancellerà tutti i dati locali associati."),
                    primaryButton: .destructive(Text("Elimina")) {
                        YouTubeManager.shared.disconnect()
                        AppPreferences.shared.clearAll()
                    },
                    secondaryButton: .cancel(Text("Annulla"))
                )
            }
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
    
    private func openSupportEmail() {
        let email = "volleystreampro@gmail.com"
        let subject = "VolleyStream Pro - Support"
        if let url = URL(string: "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(url)
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

// In-App Legal Document Viewer
struct LegalDocSheetView: View {
    let doc: WelcomeView.LegalDocType
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#0f172a").edgesIgnoringSafeArea(.all)
                
                LegalWebView(fileName: doc.htmlFileName)
            }
            .navigationBarTitle(Text(doc.title), displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Chiudi")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "#06b6d4"))
            })
        }
    }
}

struct LegalWebView: UIViewRepresentable {
    let fileName: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 1.0)
        
        if let fileURL = Bundle.main.url(forResource: (fileName as NSString).deletingPathExtension, withExtension: (fileName as NSString).pathExtension) {
            webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL.deletingLastPathComponent())
        } else if let localPath = Bundle.main.path(forResource: fileName, ofType: nil),
                  let htmlString = try? String(contentsOfFile: localPath, encoding: .utf8) {
            webView.loadHTMLString(htmlString, baseURL: nil)
        } else {
            // Web fallback
            let fallbackURL = fileName.contains("privacy") ? "https://volleystreampro.com/privacy.html" : "https://volleystreampro.com/terms.html"
            if let url = URL(string: fallbackURL) {
                webView.load(URLRequest(url: url))
            }
        }
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
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
