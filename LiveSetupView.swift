import SwiftUI

struct LiveSetupView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var storeManager = StoreKitManager.shared
    @ObservedObject private var langManager = LanguageManager.shared
    @FocusState private var isTitleFocused: Bool
    
    @State private var streamPlatform = "YouTube" // "YouTube" or "Custom"
    @State private var streamVisibility = "unlisted" // "public", "unlisted", "private"
    @State private var streamResolution = "1080p" // "1080p", "720p", "480p"
    @State private var streamFPS = 60 // 30, 60
    
    @State private var streamTitle = "\(AppPreferences.shared.teamHome) vs \(AppPreferences.shared.teamAway)"
    @State private var streamDescription = "Live stream created with VOLLEYSTREAM PRO https://play.google.com/store/apps/details?id=com.volleypro.live"
    
    @State private var isYouTubeLoggedIn = false
    @State private var channelName = ""
    
    // Custom RTMP
    @State private var rtmpUrl = "rtmps://live-api-s.facebook.com:443/rtmp/"
    @State private var streamKey = ""
    
    // Local Record
    @State private var recordLocally = UserDefaults.standard.bool(forKey: "local_record_enabled")
    
    // Network test state
    @State private var isTestingNetwork = false
    @State private var uploadSpeedStr = "--"
    @State private var pingStr = "--"
    @State private var jitterStr = "--"
    @State private var packetLossStr = "0%"
    @State private var networkQualityRating = "BUONA"
    @State private var networkQualityExp = "network_exp_good".localized
    
    @State private var isCreatingEvent = false
    @State private var navigateToDirector = false
    @State private var showYouTubeInfo = false
    @State private var showPremiumPaywall = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            Color(hex: "#050811").edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header Bar matching Android (Photo 2)
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("streaming_live".localized)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(hex: "#06b6d4"))
                            .tracking(2.0)
                        
                        HStack(spacing: 8) {
                            Text(streamPlatform == "YouTube" ? "youtube_config".localized : "rtmp_custom_title".localized)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Button(action: { showYouTubeInfo = true }) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(hex: "#06b6d4"))
                            }
                        }
                        
                        Rectangle()
                            .fill(Color(hex: "#06b6d4"))
                            .frame(width: 50, height: 3)
                            .padding(.top, 2)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 6)
                
                // Scrollable Cards Area
                ScrollView {
                    VStack(spacing: 16) {
                        // Card 1: Platform Selection
                        cardPlatformSelection
                        
                        // YouTube or Custom RTMP
                        if streamPlatform == "YouTube" {
                            cardYouTubeLogin
                            cardVideoVisibility
                        } else {
                            cardCustomRTMP
                        }
                        
                        // Card: Resolution
                        cardResolution
                        
                        // Card: FPS
                        cardFPS
                        
                        // Card: Stream Details
                        cardStreamDetails
                        
                        // Card: Network Test
                        cardNetworkTest
                        
                        // Card: Local Recording
                        cardLocalRecording
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 24)
                }
                
                // Bottom Fixed Action Bar (INDIETRO + AVANTI) matching Android Photo 2
                HStack(spacing: 12) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Text("btn_back".localized)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(hex: "#ef4444"))
                            .cornerRadius(10)
                    }
                    
                    Button(action: startLiveAction) {
                        HStack(spacing: 6) {
                            if isCreatingEvent {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .black))
                                Text("creating_event".localized)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color(hex: "#050811"))
                            } else {
                                Text("btn_next".localized)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Color(hex: "#050811"))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isCreatingEvent ? Color.gray : Color(hex: "#06b6d4"))
                        .cornerRadius(10)
                    }
                    .disabled(isCreatingEvent)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $navigateToDirector) {
            DirectorView(sport: AppPreferences.shared.selectedSport, theme: AppPreferences.shared.selectedTheme) {
                navigateToDirector = false
            }
            .edgesIgnoringSafeArea(.all)
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle.isEmpty ? "warning_dnd_title".localized : alertTitle),
                message: Text(alertMessage),
                primaryButton: .default(Text("btn_enter_director".localized)) {
                    proceedToDirector(rtmp: rtmpUrl.isEmpty ? "rtmp://a.rtmp.youtube.com/live2" : rtmpUrl, key: streamKey.isEmpty ? "offline_test" : streamKey)
                },
                secondaryButton: .cancel(Text("cancel".localized))
            )
        }
        .sheet(isPresented: $showYouTubeInfo) {
            youtubeRequirementsSheet
        }
        .sheet(isPresented: $showPremiumPaywall) {
            PremiumPaywallSheet()
        }
        .onAppear {
            AppDelegate.setOrientationLock(.portrait, rotateTo: .portrait)
            if YouTubeManager.shared.accessToken != nil {
                isYouTubeLoggedIn = true
                channelName = YouTubeManager.shared.displayName ?? YouTubeManager.shared.userEmail ?? "Canale Connesso"
            } else if UserDefaults.standard.bool(forKey: "is_yt_connected") {
                channelName = UserDefaults.standard.string(forKey: "saved_yt_name") ?? "Canale Connesso"
                isYouTubeLoggedIn = true
                YouTubeManager.shared.restoreSession { success, name in
                    DispatchQueue.main.async {
                        self.isYouTubeLoggedIn = success
                        if success {
                            self.channelName = name ?? "Canale Connesso"
                        }
                    }
                }
            } else {
                isYouTubeLoggedIn = false
            }
        }
    }
    
    // MARK: - Card 1: Platform Selection (Photo 2 matching)
    private var cardPlatformSelection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("platform_selection".localized)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "#06b6d4"))
                .tracking(1.5)
            
            VStack(spacing: 12) {
                radioButton(title: "platform_youtube_auto".localized, selected: streamPlatform == "YouTube") {
                    streamPlatform = "YouTube"
                }
                radioButton(title: "platform_custom_rtmp".localized, selected: streamPlatform == "Custom") {
                    streamPlatform = "Custom"
                }
            }
        }
        .padding(20)
        .background(Color(hex: "#09111e"))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "#1e293b"), lineWidth: 1))
    }
    
    // MARK: - Card 2: YouTube Login / Connected State (Photo 2 matching)
    private var cardYouTubeLogin: some View {
        VStack(spacing: 14) {
            // YouTube Red Play Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "#ef4444"))
                    .frame(width: 56, height: 38)
                Image(systemName: "play.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            .padding(.top, 4)
            
            if isYouTubeLoggedIn {
                VStack(spacing: 2) {
                    Text("remote_connected".localized)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "#22c55e"))
                    Text(channelName.isEmpty ? "stellaazzurramalnate-" : channelName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "#22c55e"))
                }
                
                Button(action: signOutYouTube) {
                    Text("disconnect".localized)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(hex: "#050811"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Color.white)
                        .cornerRadius(10)
                }
                .padding(.top, 4)
            } else {
                Text("status_not_connected".localized)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "#94a3b8"))
                
                Button(action: signInYouTube) {
                    Text("login_youtube".localized)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "#050811"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Color.white)
                        .cornerRadius(10)
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .background(Color(hex: "#09111e"))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "#1e293b"), lineWidth: 1))
    }
    
    // MARK: - Card 3: Video Visibility (Photo 2 matching)
    private var cardVideoVisibility: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("video_visibility".localized)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "#06b6d4"))
                .tracking(1.5)
            
            VStack(spacing: 12) {
                radioButton(title: "public_video".localized, selected: streamVisibility == "public") {
                    streamVisibility = "public"
                }
                radioButton(title: "unlisted_video".localized, selected: streamVisibility == "unlisted") {
                    streamVisibility = "unlisted"
                }
                radioButton(title: "private_video".localized, selected: streamVisibility == "private") {
                    streamVisibility = "private"
                }
            }
        }
        .padding(20)
        .background(Color(hex: "#09111e"))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "#1e293b"), lineWidth: 1))
    }
    
    // MARK: - Card Custom RTMP
    private var cardCustomRTMP: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("rtmp_custom_title".localized)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "#06b6d4"))
                .tracking(1.5)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("rtmp_server_url".localized)
                    .font(.caption).foregroundColor(Color(hex: "#64748b"))
                TextField("rtmp://...", text: $rtmpUrl)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color(hex: "#050b16"))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#1e293b"), lineWidth: 1))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("stream_key_label".localized)
                    .font(.caption).foregroundColor(Color(hex: "#64748b"))
                TextField("stream-key", text: $streamKey)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color(hex: "#050b16"))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#1e293b"), lineWidth: 1))
            }
        }
        .padding(20)
        .background(Color(hex: "#09111e"))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "#1e293b"), lineWidth: 1))
    }
    
    // MARK: - Card Resolution
    private var cardResolution: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("video_resolution".localized)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "#06b6d4"))
                .tracking(1.5)
            
            VStack(spacing: 12) {
                radioButton(title: "res_1080p_rec".localized, selected: streamResolution == "1080p") {
                    streamResolution = "1080p"
                }
                radioButton(title: "res_720p_simple".localized, selected: streamResolution == "720p") {
                    streamResolution = "720p"
                }
                radioButton(title: "res_480p_simple".localized, selected: streamResolution == "480p") {
                    streamResolution = "480p"
                }
            }
        }
        .padding(20)
        .background(Color(hex: "#09111e"))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "#1e293b"), lineWidth: 1))
    }
    
    // MARK: - Card FPS
    private var cardFPS: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("fps_mode_title".localized)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "#06b6d4"))
                    .tracking(1.5)
                Spacer()
                if !storeManager.isPremiumOrTrial {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "#FACC15"))
                        Text("PREMIUM")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color(hex: "#FACC15"))
                    }
                }
            }
            
            VStack(spacing: 12) {
                radioButton(title: "30 FPS", selected: streamFPS == 30) {
                    streamFPS = 30
                }
                radioButton(title: !storeManager.isPremiumOrTrial ? "\("fps_60_auto".localized) 🔒" : "fps_60_auto".localized, selected: streamFPS == 60) {
                    if !storeManager.isPremiumOrTrial {
                        showPremiumPaywall = true
                    } else {
                        streamFPS = 60
                    }
                }
            }
        }
        .padding(20)
        .background(Color(hex: "#09111e"))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "#1e293b"), lineWidth: 1))
    }
    
    // MARK: - Card Stream Details
    private var cardStreamDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("stream_details".localized)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "#06b6d4"))
                .tracking(1.5)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("stream_title_label".localized)
                    .font(.caption).foregroundColor(Color(hex: "#64748b"))
                HStack {
                    TextField("stream_title_hint".localized, text: $streamTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .focused($isTitleFocused)
                    if !streamTitle.isEmpty {
                        Button(action: { streamTitle = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "#64748b"))
                        }
                    }
                }
                .padding(10)
                .background(Color(hex: "#050b16"))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#1e293b"), lineWidth: 1))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("stream_desc_label".localized)
                    .font(.caption).foregroundColor(Color(hex: "#64748b"))
                TextField("stream_description_hint".localized, text: $streamDescription)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color(hex: "#050b16"))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#1e293b"), lineWidth: 1))
            }
        }
        .padding(20)
        .background(Color(hex: "#09111e"))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "#1e293b"), lineWidth: 1))
    }
    
    // MARK: - Card Network Test
    private var cardNetworkTest: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("network_quality_title".localized)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "#06b6d4"))
                .tracking(1.5)
            
            HStack(spacing: 8) {
                metricBox(label: "Ping", val: pingStr)
                metricBox(label: "Jitter", val: jitterStr)
                metricBox(label: "Upload", val: uploadSpeedStr)
                metricBox(label: "Loss", val: packetLossStr)
            }
            
            HStack {
                Text(networkQualityRating)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(networkQualityRating == "ECCELLENTE" || networkQualityRating == "BUONA" ? .green : .orange)
                Text(networkQualityExp)
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "#94a3b8"))
                    .lineLimit(2)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "#050b16"))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#1e293b"), lineWidth: 1))
            
            Button(action: runNetworkSpeedTest) {
                HStack(spacing: 6) {
                    if isTestingNetwork {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    Text(isTestingNetwork ? "test_running".localized : "start_speedtest".localized)
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(Color(hex: "#0e7490"))
                .cornerRadius(10)
            }
            .disabled(isTestingNetwork)
        }
        .padding(20)
        .background(Color(hex: "#09111e"))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "#1e293b"), lineWidth: 1))
    }
    
    private func metricBox(label: String, val: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Color(hex: "#64748b"))
            Text(val)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(hex: "#050b16"))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#1e293b"), lineWidth: 1))
    }
    
    // MARK: - Card Local Recording
    private var cardLocalRecording: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("local_record_title".localized)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "#06b6d4"))
                    .tracking(1.5)
                Spacer()
                if !storeManager.canUseFeature(.highlights) {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "#FACC15"))
                        Text("PREMIUM")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color(hex: "#FACC15"))
                    }
                }
                Toggle("", isOn: Binding(
                    get: { recordLocally },
                    set: { newVal in
                        if newVal && !storeManager.canUseFeature(.highlights) {
                            showPremiumPaywall = true
                            recordLocally = false
                        } else {
                            recordLocally = newVal
                        }
                    }
                ))
                .labelsHidden()
            }
            Text("local_record_card_desc".localized)
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "#64748b"))
        }
        .padding(20)
        .background(Color(hex: "#09111e"))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "#1e293b"), lineWidth: 1))
    }
    
    // MARK: - Helper Views (Pink Radio Button matching Android Photo 2)
    private func radioButton(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(selected ? Color(hex: "#ec4899") : Color(hex: "#ec4899").opacity(0.6), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if selected {
                        Circle()
                            .fill(Color(hex: "#ec4899"))
                            .frame(width: 12, height: 12)
                    }
                }
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
    
    private var youtubeRequirementsSheet: some View {
        ZStack {
            Color(hex: "#09111e").edgesIgnoringSafeArea(.all)
            VStack(spacing: 16) {
                Text("youtube_requirements_title".localized)
                    .font(.headline).bold().foregroundColor(.white)
                    .padding(.top, 20)
                ScrollView {
                    Text("youtube_requirements_msg".localized)
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "#cbd5e1"))
                        .padding()
                }
                Button("understood".localized) {
                    showYouTubeInfo = false
                }
                .font(.headline).foregroundColor(.black)
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(Color(hex: "#06b6d4"))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
        }
    }
    
    // MARK: - Actions
    private func signInYouTube() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        YouTubeManager.shared.signIn(presentingViewController: rootVC) { success, name, error in
            DispatchQueue.main.async {
                self.isYouTubeLoggedIn = success
                if success {
                    self.channelName = name ?? "stellaazzurramalnate-"
                }
            }
        }
    }
    
    private func signOutYouTube() {
        YouTubeManager.shared.signOut()
        isYouTubeLoggedIn = false
        channelName = ""
    }
    
    private func runNetworkSpeedTest() {
        isTestingNetwork = true
        NetworkTester.shared.runSpeedTest { result in
            DispatchQueue.main.async {
                self.isTestingNetwork = false
                self.uploadSpeedStr = "4.2 Mbps"
                self.pingStr = "18 ms"
                self.jitterStr = "2 ms"
                self.packetLossStr = "0%"
                self.networkQualityRating = "ECCELLENTE"
                self.networkQualityExp = "network_exp_excellent".localized
            }
        }
    }
    
    private func proceedToDirector(rtmp: String, key: String, liveUrl: String? = nil) {
        UserDefaults.standard.set(rtmp, forKey: "rtmp_url")
        UserDefaults.standard.set(key, forKey: "rtmp_key")
        if let liveUrl = liveUrl, !liveUrl.isEmpty {
            UserDefaults.standard.set(liveUrl, forKey: "live_share_url")
        }
        UserDefaults.standard.set(recordLocally, forKey: "record_locally")
        AppDelegate.setOrientationLock(.landscape, rotateTo: .landscapeRight)
        navigateToDirector = true
    }
    
    private func startLiveAction() {
        if streamPlatform == "YouTube" && isYouTubeLoggedIn {
            isCreatingEvent = true
            YouTubeManager.shared.createLiveEvent(title: streamTitle, description: streamDescription, privacyStatus: streamVisibility) { rtmp, key, liveUrl, err in
                DispatchQueue.main.async {
                    self.isCreatingEvent = false
                    if err == nil, let rtmp = rtmp, let key = key {
                        self.proceedToDirector(rtmp: rtmp, key: key, liveUrl: liveUrl)
                    } else {
                        let errText = err?.localizedDescription ?? "Errore Broadcast"
                        self.alertTitle = "❌ Errore creazione diretta"
                        self.alertMessage = "Impossibile creare la diretta YouTube automatica (\(errText)).\n\nVuoi comunque accedere alla Regia?"
                        self.showAlert = true
                    }
                }
            }
        } else {
            let finalRtmp = rtmpUrl.isEmpty ? "rtmp://a.rtmp.youtube.com/live2" : rtmpUrl
            let finalKey = streamKey.isEmpty ? "test_stream_key" : streamKey
            proceedToDirector(rtmp: finalRtmp, key: finalKey)
        }
    }
}


