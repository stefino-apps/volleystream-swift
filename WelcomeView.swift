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
    @ObservedObject private var langManager = LanguageManager.shared
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
            case .privacy: return "privacy_policy_title".localized
            case .terms: return "terms_of_use_title".localized
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
                    // Top Bar: Menu (Left), Language (Right)
                    HStack(spacing: 8) {
                        Button(action: { showMenu = true }) {
                            Image(systemName: "line.horizontal.3")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                        }
                        .actionSheet(isPresented: $showMenu) {
                            ActionSheet(title: Text("Menu"), buttons: [
                                .default(Text("menu_privacy".localized)) {
                                    activeLegalDoc = .privacy
                                },
                                .default(Text("menu_terms".localized)) {
                                    activeLegalDoc = .terms
                                },
                                .default(Text("menu_contacts".localized)) {
                                    openSupportEmail()
                                },
                                .destructive(Text("menu_delete_account".localized)) {
                                    showDeleteAccountAlert = true
                                },
                                .cancel(Text("cancel".localized))
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
                                    LanguageManager.shared.setLanguage(lang.key)
                                    appLang = lang.key
                                }
                            } + [.cancel(Text("cancel".localized))])
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
                                        Text("premium_active".localized)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(Color(hex: "#22c55e"))
                                    } else if storeManager.isTrialActive {
                                        Text(String(format: "trial_days_remaining".localized, storeManager.daysRemainingInTrial))
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(Color(hex: "#22c55e"))
                                    } else {
                                        Text("free_version".localized)
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
                            Text("menu_privacy".localized)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(hex: "#94a3b8"))
                                .underline()
                        }
                        
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "#475569"))
                        
                        Button(action: { activeLegalDoc = .terms }) {
                            Text("menu_terms".localized)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(hex: "#94a3b8"))
                                .underline()
                        }
                        
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "#475569"))
                        
                        Button(action: { openSupportEmail() }) {
                            Text("menu_contacts".localized)
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
                    title: Text("delete_account_confirm_title".localized),
                    message: Text("delete_account_confirm_msg".localized),
                    primaryButton: .destructive(Text("btn_delete".localized)) {
                        YouTubeManager.shared.disconnect()
                        AppPreferences.shared.clearAll()
                    },
                    secondaryButton: .cancel(Text("cancel".localized))
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
    @ObservedObject private var langManager = LanguageManager.shared
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
                        
                        Text("unlock_all_features".localized)
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#94a3b8"))
                    }
                    
                    // Features List
                    VStack(alignment: .leading, spacing: 16) {
                        PremiumFeatureRow(icon: "iphone.radiowaves.left.and.right", title: "feat_rc_unlimited".localized, subtitle: "feat_rc_unlimited_sub".localized)
                        PremiumFeatureRow(icon: "photo.badge.checkmark", title: "feat_logos_sponsors".localized, subtitle: "feat_logos_sponsors_sub".localized)
                        PremiumFeatureRow(icon: "arrow.counterclockwise.circle.fill", title: "feat_replay_hl".localized, subtitle: "feat_replay_hl_sub".localized)
                        PremiumFeatureRow(icon: "tv.fill", title: "feat_no_watermark".localized, subtitle: "feat_no_watermark_sub".localized)
                        PremiumFeatureRow(icon: "video.fill", title: "feat_hd_stream".localized, subtitle: "feat_hd_stream_sub".localized)
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
                        Text("sub_trial_badge".localized)
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundColor(Color(hex: "#22c55e"))
                        
                        Text("sub_price_desc".localized)
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
                            Text(storeManager.isPremium ? "active_subscription".localized : "btn_try_free".localized)
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
                                restoreAlertMessage = "restore_success".localized
                            } else {
                                restoreAlertMessage = "restore_none".localized
                            }
                        }
                    }) {
                        Text("btn_restore_purchases".localized)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: "#06b6d4"))
                            .underline()
                    }
                    .padding(.top, 2)
                    
                    // Apple Review Guideline 3.1.2 Required Subscription Disclaimer
                    VStack(spacing: 8) {
                        Text("sub_disclaimer".localized)
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "#64748b"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        HStack(spacing: 16) {
                            Button(action: { showLegalDoc = .privacy }) {
                                Text("menu_privacy".localized)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Color(hex: "#06b6d4"))
                                    .underline()
                            }
                            
                            Text("•")
                                .font(.system(size: 10))
                                .foregroundColor(Color(hex: "#475569"))
                            
                            Button(action: { showLegalDoc = .terms }) {
                                Text("eula_terms".localized)
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
                title: Text("restore_title".localized),
                message: Text(restoreAlertMessage ?? ""),
                dismissButton: .default(Text("ok".localized))
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
    @ObservedObject private var langManager = LanguageManager.shared
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
                                Text(doc == .privacy ? "privacy_policy_title".localized : "terms_of_use_title".localized)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                Text("VolleyStream Pro • \("legal_updated".localized)")
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
                            Text("legal_questions_title".localized)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(hex: "#06b6d4"))
                            Text("legal_questions_desc".localized)
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
            .navigationBarTitle(Text(doc == .privacy ? "menu_privacy".localized : "menu_terms".localized), displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("btn_close".localized)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "#06b6d4"))
            })
        }
    }
    
    private var privacyContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            legalCard(title: "privacy_sec1_title".localized, text: "privacy_sec1_text".localized)
            legalCard(title: "privacy_sec2_title".localized, text: "privacy_sec2_text".localized)
            legalCard(title: "privacy_sec3_title".localized, text: "privacy_sec3_text".localized)
            legalCard(title: "privacy_sec4_title".localized, text: "privacy_sec4_text".localized)
            legalCard(title: "privacy_sec5_title".localized, text: "privacy_sec5_text".localized)
            legalCard(title: "privacy_sec6_title".localized, text: "privacy_sec6_text".localized)
            legalCard(title: "privacy_sec7_title".localized, text: "privacy_sec7_text".localized)
        }
    }
    
    private var termsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            legalCard(title: "terms_sec1_title".localized, text: "terms_sec1_text".localized)
            legalCard(title: "terms_sec2_title".localized, text: "terms_sec2_text".localized)
            legalCard(title: "terms_sec3_title".localized, text: "terms_sec3_text".localized)
            legalCard(title: "terms_sec4_title".localized, text: "terms_sec4_text".localized)
            legalCard(title: "terms_sec5_title".localized, text: "terms_sec5_text".localized)
            legalCard(title: "terms_sec6_title".localized, text: "terms_sec6_text".localized)
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
                        Text("understood".localized)
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

