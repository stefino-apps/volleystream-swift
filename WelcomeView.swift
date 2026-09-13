import SwiftUI
import Combine
import WebKit

struct BadgePopupData: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let icon: String
    let accentColor: Color
    let bgGradient: [Color]
}

struct WelcomeView: View {
    @StateObject private var storeManager = StoreKitManager.shared
    @State private var navigateToSetup = false
    @State private var showLangPicker = false
    @State private var showMenu = false
    @State private var showPremiumPaywall = false
    @State private var selectedBadgeData: BadgePopupData? = nil
    @State private var navigateToRemote = false
    @State private var showDeleteAccountAlert = false
    @State private var activeLegalDoc: LegalDocType? = nil
    @State private var isShowingSplash = true
    @State private var splashScale: CGFloat = 0.35
    @State private var splashOpacity: Double = 0.0
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
                                .destructive(Text("menu_delete_account".localized.isEmpty ? "Cancella Account" : "menu_delete_account".localized)) {
                                    showDeleteAccountAlert = true
                                },
                                .cancel()
                            ])
                        }
                        
                        Spacer()
                        
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
                                    if storeManager.isPremium {
                                        Text("PREMIUM ATTIVO")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(Color(hex: "#22c55e"))
                                    } else if storeManager.isTrialActive {
                                        Text("\(storeManager.daysRemainingInTrial) GIORNI PROVA")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(Color(hex: "#22c55e"))
                                    } else {
                                        Text("VERSIONE FREE")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(Color(hex: "#EF4444"))
                                    }
                                    
                                    Button(action: { showPremiumPaywall = true }) {
                                        Text("PREMIUM")
                                            .font(.system(size: 11, weight: .heavy))
                                            .foregroundColor(Color(hex: "#06b6d4"))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 5)
                                            .background(Color(hex: "#0f172a"))
                                            .cornerRadius(12)
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#06b6d4"), lineWidth: 1.5))
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
                                AndroidBadgeView(
                                    text: "badge_remote".localized,
                                    isLocked: false
                                ) {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        selectedBadgeData = BadgePopupData(
                                            title: "badge_remote".localized,
                                            message: "popup_remote_msg".localized,
                                            icon: "iphone.radiowaves.left.and.right",
                                            accentColor: Color(hex: "#06B6D4"),
                                            bgGradient: [Color(hex: "#083344"), Color(hex: "#09111e")]
                                        )
                                    }
                                }
                                
                                AndroidBadgeView(
                                    text: "badge_premium".localized,
                                    isLocked: false
                                ) {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        selectedBadgeData = BadgePopupData(
                                            title: "badge_premium".localized,
                                            message: "popup_premium_msg".localized,
                                            icon: "crown.fill",
                                            accentColor: Color(hex: "#FACC15"),
                                            bgGradient: [Color(hex: "#422006"), Color(hex: "#09111e")]
                                        )
                                    }
                                }
                                
                                AndroidBadgeView(
                                    text: "badge_tv_graphics".localized,
                                    isLocked: !storeManager.isPremiumOrTrial
                                ) {
                                    if !storeManager.isPremiumOrTrial {
                                        showPremiumPaywall = true
                                    } else {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            selectedBadgeData = BadgePopupData(
                                                title: "badge_tv_graphics".localized,
                                                message: "popup_tv_graphics_msg".localized,
                                                icon: "sparkles.tv.fill",
                                                accentColor: Color(hex: "#38BDF8"),
                                                bgGradient: [Color(hex: "#0c4a6e"), Color(hex: "#09111e")]
                                            )
                                        }
                                    }
                                }
                                
                                AndroidBadgeView(
                                    text: "badge_remote_control".localized,
                                    isLocked: !storeManager.isPremiumOrTrial
                                ) {
                                    if !storeManager.isPremiumOrTrial {
                                        showPremiumPaywall = true
                                    } else {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            selectedBadgeData = BadgePopupData(
                                                title: "badge_remote_control".localized,
                                                message: "popup_remote_control_msg".localized,
                                                icon: "gamecontroller.fill",
                                                accentColor: Color(hex: "#10B981"),
                                                bgGradient: [Color(hex: "#064e3b"), Color(hex: "#09111e")]
                                            )
                                        }
                                    }
                                }
                                
                                AndroidBadgeView(
                                    text: "badge_local_record".localized,
                                    isLocked: !storeManager.isPremiumOrTrial
                                ) {
                                    if !storeManager.isPremiumOrTrial {
                                        showPremiumPaywall = true
                                    } else {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            selectedBadgeData = BadgePopupData(
                                                title: "badge_local_record".localized,
                                                message: "popup_local_record_msg".localized,
                                                icon: "record.circle.fill",
                                                accentColor: Color(hex: "#EF4444"),
                                                bgGradient: [Color(hex: "#450a0a"), Color(hex: "#09111e")]
                                            )
                                        }
                                    }
                                }
                                
                                AndroidBadgeView(
                                    text: "badge_instant_replay".localized,
                                    isLocked: !storeManager.isPremiumOrTrial
                                ) {
                                    if !storeManager.isPremiumOrTrial {
                                        showPremiumPaywall = true
                                    } else {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            selectedBadgeData = BadgePopupData(
                                                title: "badge_instant_replay".localized,
                                                message: "popup_instant_replay_msg".localized,
                                                icon: "arrow.counterclockwise.circle.fill",
                                                accentColor: Color(hex: "#F59E0B"),
                                                bgGradient: [Color(hex: "#451a03"), Color(hex: "#09111e")]
                                            )
                                        }
                                    }
                                }
                                
                                Button(action: {
                                    if !storeManager.isPremiumOrTrial {
                                        showPremiumPaywall = true
                                    } else {
                                        navigateToRemote = true
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        if !storeManager.isPremiumOrTrial {
                                            Image(systemName: "lock.fill")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(Color(hex: "#FACC15"))
                                        }
                                        Text("btn_remote_mode".localized)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                        if !storeManager.isPremiumOrTrial {
                                            Image(systemName: "lock.fill")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(Color(hex: "#FACC15"))
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(Color(hex: "#EF4444"))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.top, 10)
                                
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
                
                // Animated Splash Screen Overlay
                if isShowingSplash {
                    Color.black.edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 24) {
                        if let img = UIImage(named: "app_logo.jpg") ?? UIImage(contentsOfFile: Bundle.main.path(forResource: "app_logo", ofType: "jpg") ?? "") {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 280, height: 280)
                                .cornerRadius(24)
                                .shadow(color: Color(hex: "#06b6d4").opacity(0.8), radius: 20)
                        } else {
                            Image(systemName: "video.badge.waveform.fill")
                                .font(.system(size: 90))
                                .foregroundColor(Color(hex: "#38BDF8"))
                        }
                        
                        Text("VOLLEYSTREAM PRO")
                            .font(.system(size: 30, weight: .heavy))
                            .italic()
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "#38BDF8"), Color(hex: "#FACC15"), Color(hex: "#C084FC")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .scaleEffect(splashScale)
                    .opacity(splashOpacity)
                    .onAppear {
                        withAnimation(.spring(response: 0.7, dampingFraction: 0.7, blendDuration: 0)) {
                            splashScale = 1.0
                            splashOpacity = 1.0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                isShowingSplash = false
                            }
                        }
                    }
                    .transition(.opacity)
                }
                
                // Rich Broadcast Badge Popup Modal
                if let badgeData = selectedBadgeData {
                    BadgeDetailModalView(data: badgeData) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedBadgeData = nil
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showPremiumPaywall) {
                PremiumPaywallSheet()
            }
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
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onOpenURL { url in
            print("WelcomeView onOpenURL: \(url.absoluteString)")
            var extractedCode: String?
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                extractedCode = components.queryItems?.first(where: { $0.name == "code" || $0.name == "id" })?.value
            }
            if extractedCode == nil || extractedCode?.isEmpty == true {
                let last = url.lastPathComponent
                if !last.isEmpty && last != "remote" && last != "/" {
                    extractedCode = last
                }
            }
            if let code = extractedCode, !code.isEmpty {
                let clean = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                UserDefaults.standard.set(clean, forKey: "incoming_remote_id")
                navigateToRemote = true
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

// MARK: - Premium Paywall Sheet (Purchase Modal)

struct PremiumPaywallSheet: View {
    @ObservedObject var storeManager = StoreKitManager.shared
    @Environment(\.presentationMode) var presentationMode
    @State private var restoreAlertMessage: String? = nil
    @State private var showLegalDoc: WelcomeView.LegalDocType? = nil
    
    var body: some View {
        ZStack {
            Color(hex: "#020617").edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Close button
                    HStack {
                        Spacer()
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(Color(hex: "#64748b"))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Crown & Title
                    VStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 52))
                            .foregroundColor(Color(hex: "#FACC15"))
                            .shadow(color: Color(hex: "#FACC15").opacity(0.8), radius: 14)
                        
                        Text("VOLLEYSTREAM PRO")
                            .font(.system(size: 26, weight: .heavy))
                            .italic()
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(hex: "#38BDF8"), Color(hex: "#FACC15")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("Sblocca tutte le funzionalità professionali")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#94a3b8"))
                    }
                    
                    // Features List
                    VStack(alignment: .leading, spacing: 16) {
                        PremiumFeatureRow(icon: "iphone.radiowaves.left.and.right", title: "Controllo Remoto (R.C.) senza limiti", subtitle: "Gestisci i punti dal secondo smartphone")
                        PremiumFeatureRow(icon: "photo.badge.checkmark", title: "Loghi e Sponsor Personalizzati", subtitle: "Mostra sponsor e loghi ufficiali delle squadre")
                        PremiumFeatureRow(icon: "arrow.counterclockwise.circle.fill", title: "Instant Replay & Highlights", subtitle: "Rivedi i punti salienti ed esporta video")
                        PremiumFeatureRow(icon: "tv.fill", title: "Nessun Watermark Promozionale", subtitle: "Nessuna scritta promozionale su YouTube")
                        PremiumFeatureRow(icon: "video.fill", title: "Streaming HD 1080p @ 60 FPS", subtitle: "Massima qualità e fluidità broadcast")
                    }
                    .padding(20)
                    .background(Color(hex: "#0f172a"))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "#1e293b"), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    
                    // Pricing info
                    VStack(spacing: 6) {
                        Text("7 GIORNI DI PROVA GRATUITA INCLUSI")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundColor(Color(hex: "#22c55e"))
                        
                        Text("Poi solo €39,99 / anno (€3,33/mese). Annulla in qualsiasi momento.")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#cbd5e1"))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    
                    if let err = storeManager.purchaseErrorMessage {
                        Text(err)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    
                    // Purchase Button
                    Button(action: {
                        Task {
                            let success = await storeManager.purchasePremium()
                            if success {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            if storeManager.isPurchasing {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .black))
                            }
                            Text(storeManager.isPremium ? "ABBONAMENTO ATTIVO" : "PROVA GRATIS PER 7 GIORNI")
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#FACC15"), Color(hex: "#EAB308")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: Color(hex: "#FACC15").opacity(0.4), radius: 8)
                    }
                    .disabled(storeManager.isPurchasing || storeManager.isPremium)
                    .padding(.horizontal, 20)
                    
                    // Restore Button
                    Button(action: {
                        Task {
                            await storeManager.restorePurchases()
                            if storeManager.isPremium {
                                restoreAlertMessage = "Abbonamento Premium ripristinato con successo!"
                            } else {
                                restoreAlertMessage = "Nessun abbonamento attivo trovato per questo account Apple ID."
                            }
                        }
                    }) {
                        Text("Ripristina Acquisti")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: "#06b6d4"))
                            .underline()
                    }
                    .padding(.top, 2)
                    
                    // Apple Review Guideline 3.1.2 Required Subscription Disclaimer
                    VStack(spacing: 8) {
                        Text("Dettagli abbonamento: La prova gratuita dura 7 giorni. Al termine, l'abbonamento si rinnova automaticamente a €39,99/anno a meno che non venga annullato almeno 24 ore prima della scadenza. Il pagamento viene addebitato sull'account Apple ID alla conferma. Puoi gestire e annullare l'abbonamento nelle Impostazioni dell'account App Store.")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "#64748b"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        HStack(spacing: 16) {
                            Button(action: { showLegalDoc = .privacy }) {
                                Text("Informativa sulla Privacy")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Color(hex: "#06b6d4"))
                                    .underline()
                            }
                            
                            Text("•")
                                .font(.system(size: 10))
                                .foregroundColor(Color(hex: "#475569"))
                            
                            Button(action: { showLegalDoc = .terms }) {
                                Text("Termini di Servizio (EULA)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Color(hex: "#06b6d4"))
                                    .underline()
                            }
                        }
                        .padding(.top, 2)
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .sheet(item: $showLegalDoc) { doc in
            LegalDocSheetView(doc: doc)
        }
        .alert(isPresented: Binding<Bool>(
            get: { restoreAlertMessage != nil },
            set: { if !$0 { restoreAlertMessage = nil } }
        )) {
            Alert(
                title: Text("Ripristino Acquisti"),
                message: Text(restoreAlertMessage ?? ""),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(hex: "#00FFCC"))
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#94a3b8"))
            }
        }
    }
}

struct AlertInfo: Identifiable {
    let id = UUID()
    let message: String
}

struct AndroidBadgeView: View {
    var text: String
    var isLocked: Bool = false
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "#FACC15"))
                }
                Text(text)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(Color(hex: "#00FFCC"))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "#FACC15"))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 64)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(Color(hex: "#0f172a").opacity(0.5))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(hex: "#FACC15"), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// In-App Native Legal Document Viewer
struct LegalDocSheetView: View {
    let doc: WelcomeView.LegalDocType
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#09111e").edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // Header Badge
                        HStack {
                            Image(systemName: doc == .privacy ? "lock.shield.fill" : "doc.text.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color(hex: "#06b6d4"))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(doc == .privacy ? "Informativa sulla Privacy" : "Termini di Servizio")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                Text("VolleyStream Pro • Ultimo aggiornamento: Marzo 2026")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "#94a3b8"))
                            }
                        }
                        .padding(.vertical, 8)
                        
                        Divider().background(Color(hex: "#334155"))
                        
                        if doc == .privacy {
                            privacyContent
                        } else {
                            termsContent
                        }
                        
                        // Contact Card
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Domande o Contatti?")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(hex: "#06b6d4"))
                            Text("Per qualsiasi domanda riguardante la privacy o i termini di servizio, puoi contattare il nostro team di supporto a:")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#cbd5e1"))
                            Text("✉️ volleystreampro@gmail.com")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(16)
                        .background(Color(hex: "#1e293b"))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#06b6d4").opacity(0.4), lineWidth: 1))
                        .padding(.top, 10)
                    }
                    .padding(20)
                }
            }
            .navigationBarTitle(Text(doc == .privacy ? "Privacy Policy" : "Termini d'Uso"), displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Chiudi")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "#06b6d4"))
            })
        }
    }
    
    private var privacyContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            legalCard(title: "1. Titolare del Trattamento", text: "Il titolare del trattamento dei dati è VolleyStream Pro. Contatto email: volleystreampro@gmail.com. La protezione e riservatezza dei tuoi dati è la nostra priorità.")
            
            legalCard(title: "2. Fotocamera e Microfono", text: "L'applicazione richiede l'accesso a Fotocamera e Microfono esclusivamente per consentire la ripresa e la trasmissione in diretta streaming su YouTube e il salvataggio locale dei match e degli highlights sul tuo dispositivo. Nessun flusso audio/video viene registrato o memorizzato sui nostri server.")
            
            legalCard(title: "3. Account Google e YouTube API Services", text: "VolleyStream Pro utilizza i servizi API di YouTube per consentirti di trasmettere live sul tuo canale. L'uso dell'app implica l'accettazione dei Termini di Servizio di YouTube (https://www.youtube.com/t/terms) e delle Norme sulla Privacy di Google (https://policies.google.com/privacy). Puoi revocare l'accesso in qualsiasi momento da myaccount.google.com/permissions.")
            
            legalCard(title: "4. Firebase e Controllo Remoto", text: "Utilizziamo Google Firebase per la sincronizzazione temporanea dei punteggi, del tabellone e del controllo remoto durante la partita. I dati vengono crittografati in transito (HTTPS) e cancellati al termine della sessione.")
            
            legalCard(title: "5. Pagamenti e Abbonamenti", text: "Tutti i pagamenti e gli abbonamenti sono gestiti in modo sicuro e autonomo tramite Apple App Store / In-App Purchase. Non raccogliamo né memorizziamo alcun dato relativo a carte di credito o conti bancari.")
            
            legalCard(title: "6. Tutela dei Minori e Consenso", text: "Qualora le riprese coinvolgano soggetti minorenni, l'Utente ha l'obbligo tassativo di ottenere il preventivo consenso scritto dai genitori o tutori legali prima di avviare qualsiasi trasmissione o registrazione.")
            
            legalCard(title: "7. Diritti dell'Utente (GDPR)", text: "Hai il diritto di richiedere in qualsiasi momento l'accesso, la rettifica, la cancellazione o la revoca del consenso per qualsiasi dato associato al tuo utilizzo inviando un'email a volleystreampro@gmail.com.")
        }
    }
    
    private var termsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            legalCard(title: "1. Accettazione dei Termini", text: "Scaricando, installando o utilizzando VolleyStream Pro, accetti integralmente i presenti Termini di Servizio. Se non accetti questi termini, ti preghiamo di non utilizzare l'applicazione.")
            
            legalCard(title: "2. Licenza d'Uso", text: "Ti concediamo una licenza personale, non esclusiva, non trasferibile e revocabile per utilizzare l'app a scopi personali, sportivi o di trasmissione di eventi in conformità con i presenti Termini.")
            
            legalCard(title: "3. Abbonamenti e Rinnovo Automatico", text: "VolleyStream Pro offre piani di abbonamento per accedere a tutte le funzionalità avanzate (overlay grafici pro, replay istantaneo, highlights, controllo remoto, 10 sport). L'abbonamento si rinnova automaticamente a meno che non venga annullato almeno 24 ore prima della scadenza tramite le Impostazioni del tuo ID Apple.")
            
            legalCard(title: "4. Responsabilità sui Contenuti Trasmessi", text: "L'Utente è l'unico responsabile delle immagini e dei suoni trasmessi. È vietato trasmettere contenuti protetti da copyright senza autorizzazione, contenuti illeciti, diffamatori o offensivi. L'Utente si impegna a rispettare tutte le normative sulla privacy e la tutela dei minori.")
            
            legalCard(title: "5. YouTube API Terms of Service", text: "L'utilizzo delle funzioni di live streaming su YouTube richiede il rispetto dei YouTube Terms of Service (https://www.youtube.com/t/terms). VolleyStream Pro opera come interfaccia tecnica per la trasmissione verso la piattaforma YouTube.")
            
            legalCard(title: "6. Limitazione di Responsabilità", text: "VolleyStream Pro fornisce il servizio 'così com'è'. Non possiamo garantire l'assenza di interruzioni causate da problemi di rete, instabilità della connessione Wi-Fi/4G/5G dell'utente o malfunzionamenti dei server di terze parti.")
        }
    }
    
    private func legalCard(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color(hex: "#38bdf8"))
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#e2e8f0"))
                .lineSpacing(4)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#131f33"))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#334155"), lineWidth: 1))
    }
}

// MARK: - Rich Broadcast Badge Popup Modal
struct BadgeDetailModalView: View {
    let data: BadgePopupData
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Sfondo oscurato e sfocato
            Color.black.opacity(0.75)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    onDismiss()
                }
            
            // Carta Fumetto Broadcast Grande e Colorata
            VStack(spacing: 20) {
                // Header con Icona grande e Pulsante Chiudi
                HStack(alignment: .top) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [data.accentColor.opacity(0.4), data.accentColor.opacity(0.1)]),
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 40
                                )
                            )
                            .frame(width: 72, height: 72)
                        
                        Circle()
                            .stroke(data.accentColor, lineWidth: 2)
                            .frame(width: 72, height: 72)
                        
                        Image(systemName: data.icon)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(data.accentColor)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        onDismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color.white.opacity(0.6))
                    }
                }
                
                // Titolo Grande
                VStack(alignment: .leading, spacing: 6) {
                    Text(data.title.uppercased())
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(data.accentColor)
                        .tracking(1.1)
                    
                    Rectangle()
                        .fill(data.accentColor.opacity(0.4))
                        .frame(height: 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Messaggio descrittivo
                Text(data.message)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "#e2e8f0"))
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Bottone Azione Vivace
                Button(action: {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    onDismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text("HO CAPITO")
                            .font(.system(size: 15, weight: .heavy))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [data.accentColor, data.accentColor.opacity(0.75)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                    .shadow(color: data.accentColor.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .padding(.top, 4)
            }
            .padding(26)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: data.bgGradient),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(26)
            .overlay(
                RoundedRectangle(cornerRadius: 26)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [data.accentColor, data.accentColor.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.5
                    )
            )
            .shadow(color: Color.black.opacity(0.8), radius: 25, x: 0, y: 15)
            .padding(.horizontal, 24)
            .transition(.scale(scale: 0.85).combined(with: .opacity))
        }
        .zIndex(100)
    }
}

