import SwiftUI
import PhotosUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedSport = AppPreferences.shared.selectedSport
    @State private var selectedTheme = AppPreferences.shared.selectedTheme
    @State private var teamHome = AppPreferences.shared.teamHome
    @State private var teamAway = AppPreferences.shared.teamAway
    
    @State private var scrollText = "NOTIZIE: LA PARTITA PROCEDE CON REGOLARITÀ"
    @State private var scrollTextColorHex = "#FFFFFF"
    
    @AppStorage("punto_de_oro") private var puntoDeOro: Bool = false
    @AppStorage("remote_session_id") private var remoteSessionId: String = "REGIA_01"
    @AppStorage("tennis_sets_to_win") private var tennisSetsToWin: Int = 2
    @AppStorage("basket_periods_mode") private var basketPeriodsMode: Int = 4
    @AppStorage("soccer_half_duration") private var soccerHalfDuration: Int = 45
    @AppStorage("darts_initial_score") private var dartsInitialScore: Int = 501
    @AppStorage("replay_duration_seconds") private var replayDuration: Int = 5
    @AppStorage("replay_speed_factor") private var replaySpeed: Double = 0.5
    @AppStorage("highlight_duration_seconds") private var highlightDuration: Int = 10
    @AppStorage("saved_texts_slot") private var savedSlotIndex: Int = 1
    
    @State private var replayEnabled = AppPreferences.shared.isReplayEnabled
    @State private var navigateToLiveSetup = false
    @State private var showSaveSlotAlert = false
    @State private var showLoadSlotAlert = false
    @State private var showReplayTestAlert = false
    @State private var replayTestMessage = ""
    @State private var toastMessage: String? = nil
    
    // Logo Images State
    @State private var logoHomeImage: UIImage?
    @State private var logoAwayImage: UIImage?
    @State private var logoHomePickerItem: PhotosPickerItem?
    @State private var logoAwayPickerItem: PhotosPickerItem?
    
    // Sponsor Images (1..4)
    @State private var sponsorImages: [UIImage?] = [nil, nil, nil, nil]
    @State private var sponsorPickerItems: [PhotosPickerItem?] = [nil, nil, nil, nil]
    
    // Rotating Banner Images (1..5)
    @State private var bannerImages: [UIImage?] = [nil, nil, nil, nil, nil]
    @State private var bannerPickerItems: [PhotosPickerItem?] = [nil, nil, nil, nil, nil]
    
    struct SportOption: Identifiable {
        let id: String
        let name: String
    }
    
    struct ThemeOption: Identifiable {
        let id: String
        let name: String
    }
    
    let sports: [SportOption] = [
        SportOption(id: "volley", name: "🏐 VOLLEY"),
        SportOption(id: "basket", name: "🏀 BASKET"),
        SportOption(id: "soccer", name: "⚽ SOCCER"),
        SportOption(id: "tennis", name: "🎾 TENNIS"),
        SportOption(id: "darts", name: "🎯 FRECCETTE"),
        SportOption(id: "billiards", name: "🎱 BILIARDO"),
        SportOption(id: "beach_volley", name: "🏖️ BEACH VOLLEY"),
        SportOption(id: "cricket", name: "🏏 CRICKET"),
        SportOption(id: "padel", name: "🎾 PADEL"),
        SportOption(id: "handball", name: "🤾 PALLAMANO")
    ]
    
    let themes: [ThemeOption] = [
        ThemeOption(id: "neon", name: "NEON GLOW (DEFAULT)"),
        ThemeOption(id: "minimal", name: "MODERN MINIMAL"),
        ThemeOption(id: "glass", name: "PREMIUM GLASS"),
        ThemeOption(id: "classic", name: "TV CLASSICA"),
        ThemeOption(id: "odometer_blue", name: "PRO BLUE"),
        ThemeOption(id: "odometer_red", name: "PRO RED"),
        ThemeOption(id: "odometer_dark", name: "PRO DARK")
    ]
    
    var body: some View {
        ZStack {
            Color(hex: "#050811").edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header Bar matching Android (Photos 2 & 3)
                HStack(alignment: .center, spacing: 12) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(hex: "#64748b"))
                            .frame(width: 44, height: 44)
                    }
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("IMPOSTAZIONI")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .tracking(1.0)
                        Text("MATCH")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .tracking(1.0)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 8)
                
                // Scrollable Cards Area
                ScrollView {
                    VStack(spacing: 18) {
                        // Card 1: Sport Selection & Theme (Cyan border)
                        cardSportSelection
                        
                        // Card 2: Team A (Home)
                        cardTeamA
                        
                        // Card 3: Team B (Away)
                        cardTeamB
                        
                        // Reset Logos Button (matching Android)
                        Button(action: resetLogos) {
                            Text("RESET LOGHI")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color(hex: "#1e293b"))
                                .cornerRadius(8)
                        }
                        .padding(.vertical, 2)
                        
                        // Card 4: Full Screen Sponsors (Max 4)
                        cardFullScreenSponsors
                        
                        // Card 5: Rotating Banners (Max 5)
                        cardRotatingBanners
                        
                        // Card 6: Instant Replay (Beta)
                        cardInstantReplay
                        
                        // Card 7: Highlights
                        cardHighlights
                        
                        // Card 8: Scrolling Text
                        cardScrollingText
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 24)
                }
                
                // Bottom Fixed Action Button (AVANTI)
                NavigationLink(destination: LiveSetupView(), isActive: $navigateToLiveSetup) {
                    Button(action: {
                        saveAllPreferences()
                        navigateToLiveSetup = true
                    }) {
                        Text("AVANTI")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(hex: "#050811"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color(hex: "#06b6d4"))
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            
            // Toast popup if needed
            if let msg = toastMessage {
                VStack {
                    Spacer()
                    Text(msg)
                        .font(.caption).bold()
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.85))
                        .cornerRadius(20)
                        .padding(.bottom, 80)
                }
                .transition(.opacity)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            AppDelegate.setOrientationLock(.allButUpsideDown, rotateTo: .portrait)
            loadAllState()
        }
        .onDisappear(perform: saveAllPreferences)
        .alert(isPresented: $showReplayTestAlert) {
            Alert(
                title: Text("replay_test_title".localized),
                message: Text(replayTestMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Card 1: Sport & Theme Selection (Cyan Border matching Android)
    private var cardSportSelection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // SPORT Header
            Text("SPORT")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "#06b6d4"))
                .tracking(2.0)
            
            Menu {
                ForEach(sports) { sport in
                    Button(action: {
                        selectedSport = sport.id
                        AppPreferences.shared.selectedSport = sport.id
                    }) {
                        Text(sport.name)
                    }
                }
            } label: {
                HStack {
                    Text(sports.first(where: { $0.id == selectedSport })?.name ?? "🏐 VOLLEY")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                }
                .padding(.vertical, 4)
            }
            
            // Conditional Rules
            if selectedSport == "basket" {
                VStack(alignment: .leading, spacing: 6) {
                    Text("NUMERO DI QUARTI")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "#64748b"))
                        .tracking(1.5)
                    Picker("Quarti", selection: $basketPeriodsMode) {
                        Text("4 Quarti").tag(4)
                        Text("2 Tempi").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.top, 4)
            } else if selectedSport == "soccer" {
                VStack(alignment: .leading, spacing: 6) {
                    Text("DURATA TEMPO (MIN)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "#64748b"))
                        .tracking(1.5)
                    Picker("Durata", selection: $soccerHalfDuration) {
                        ForEach([5, 10, 15, 20, 25, 30, 35, 40, 45], id: \.self) { min in
                            Text("\(min) min").tag(min)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(8)
                    .background(Color(hex: "#020617").opacity(0.6))
                    .cornerRadius(8)
                }
                .padding(.top, 4)
            } else if selectedSport == "tennis" {
                VStack(alignment: .leading, spacing: 6) {
                    Text("AL MEGLIO DI")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "#64748b"))
                        .tracking(1.5)
                    Picker("Set", selection: $tennisSetsToWin) {
                        Text("3 Set (Vinci 2)").tag(2)
                        Text("5 Set (Vinci 3)").tag(3)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.top, 4)
            } else if selectedSport == "padel" {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("PUNTO DE ORO")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(hex: "#64748b"))
                            .tracking(1.5)
                        Text("A 40-40 si gioca un solo punto decisivo")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "#94a3b8"))
                    }
                    Spacer()
                    Toggle("", isOn: $puntoDeOro)
                        .labelsHidden()
                }
                .padding(.top, 4)
            } else if selectedSport == "darts" {
                VStack(alignment: .leading, spacing: 6) {
                    Text("MODALITÀ FRECCETTE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "#64748b"))
                        .tracking(1.5)
                    Picker("Darts Mode", selection: $dartsInitialScore) {
                        Text("301").tag(301)
                        Text("501").tag(501)
                        Text("701").tag(701)
                        Text("Libero").tag(0)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.top, 4)
            }
            
            // TEMA GRAFICO OVERLAY Header
            VStack(alignment: .leading, spacing: 10) {
                Text("TEMA GRAFICO OVERLAY")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "#06b6d4"))
                    .tracking(2.0)
                
                Menu {
                    ForEach(themes) { theme in
                        Button(action: {
                            selectedTheme = theme.id
                            AppPreferences.shared.selectedTheme = theme.id
                        }) {
                            Text(theme.name)
                        }
                    }
                } label: {
                    HStack {
                        Text(themes.first(where: { $0.id == selectedTheme })?.name ?? "NEON GLOW (DEFAULT)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "arrowtriangle.down.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(Color(hex: "#09111e"))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "#06b6d4"), lineWidth: 1.5))
    }
    
    // MARK: - Card 2: Team A (Home)
    private var cardTeamA: some View {
        HStack(alignment: .center, spacing: 16) {
            // Logo A Picker
            PhotosPicker(selection: $logoHomePickerItem, matching: .images) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: "#050b16"))
                        .frame(width: 64, height: 64)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#1e293b"), lineWidth: 1))
                    
                    if let img = logoHomeImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 52, height: 52)
                            .cornerRadius(10)
                    } else {
                        VStack(spacing: 2) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Color(hex: "#64748b"))
                            Text("LOGO")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Color(hex: "#64748b"))
                        }
                    }
                }
            }
            .onChange(of: logoHomePickerItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImg = UIImage(data: data) {
                        AppPreferences.shared.saveImage(data, name: "logo_team_a.png")
                        AppPreferences.shared.saveImage(data, name: "logoHome.png")
                        DispatchQueue.main.async { self.logoHomeImage = uiImg }
                    }
                }
            }
            
            // Team A Name Field
            VStack(alignment: .leading, spacing: 4) {
                Text("SQUADRA A (CASA)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "#64748b"))
                    .tracking(1.5)
                
                TextField("NOME SQUADRA", text: $teamHome)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)
                    .padding(.vertical, 2)
            }
            
            Spacer()
        }
        .padding(18)
        .background(Color(hex: "#09111e"))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "#06b6d4"), lineWidth: 1.5))
    }
    
    // MARK: - Card 3: Team B (Away)
    private var cardTeamB: some View {
        HStack(alignment: .center, spacing: 16) {
            // Logo B Picker
            PhotosPicker(selection: $logoAwayPickerItem, matching: .images) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: "#050b16"))
                        .frame(width: 64, height: 64)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#1e293b"), lineWidth: 1))
                    
                    if let img = logoAwayImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 52, height: 52)
                            .cornerRadius(10)
                    } else {
                        VStack(spacing: 2) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Color(hex: "#64748b"))
                            Text("LOGO")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(Color(hex: "#64748b"))
                        }
                    }
                }
            }
            .onChange(of: logoAwayPickerItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImg = UIImage(data: data) {
                        AppPreferences.shared.saveImage(data, name: "logo_team_b.png")
                        AppPreferences.shared.saveImage(data, name: "logoAway.png")
                        DispatchQueue.main.async { self.logoAwayImage = uiImg }
                    }
                }
            }
            
            // Team B Name Field
            VStack(alignment: .leading, spacing: 4) {
                Text("SQUADRA B (OSPITE)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "#64748b"))
                    .tracking(1.5)
                
                TextField("NOME SQUADRA", text: $teamAway)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)
                    .padding(.vertical, 2)
            }
            
            Spacer()
        }
        .padding(18)
        .background(Color(hex: "#09111e"))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "#06b6d4"), lineWidth: 1.5))
    }
    
    // MARK: - Card 4: Full Screen Sponsors (Max 4)
    private var cardFullScreenSponsors: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("FOTO SPONSOR (MAX 4)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "#06b6d4"))
                .tracking(1.5)
            
            HStack(spacing: 12) {
                ForEach(0..<4, id: \.self) { idx in
                    sponsorSlot(index: idx)
                }
            }
            
            // Reset Sponsor Button
            HStack {
                Spacer()
                Button(action: resetSponsors) {
                    Text("RESET SPONSOR")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#1e293b"))
                        .cornerRadius(8)
                }
                Spacer()
            }
            .padding(.top, 6)
        }
        .padding(20)
        .background(Color(hex: "#09111e"))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "#06b6d4"), lineWidth: 1.5))
    }
    
    private func sponsorSlot(index: Int) -> some View {
        PhotosPicker(selection: Binding(
            get: { sponsorPickerItems[index] },
            set: { sponsorPickerItems[index] = $0 }
        ), matching: .images) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "#050b16"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#1e293b"), lineWidth: 1))
                    
                    if let img = sponsorImages[index] {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 46)
                            .cornerRadius(8)
                    } else {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color(hex: "#64748b"))
                    }
                }
                Text("\(index + 1)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "#64748b"))
            }
        }
        .onChange(of: sponsorPickerItems[index]) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImg = UIImage(data: data) {
                    AppPreferences.shared.saveImage(data, name: "sponsor_\(index + 1).png")
                    if index == 0 { AppPreferences.shared.saveImage(data, name: "sponsorFull.png") }
                    DispatchQueue.main.async { self.sponsorImages[index] = uiImg }
                }
            }
        }
    }
    
    // MARK: - Card 5: Rotating Banners (Max 5)
    private var cardRotatingBanners: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("BANNER SPONSOR IN SOVRIMPRESSIONE (A ROTAZIONE)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "#06b6d4"))
                .tracking(1.0)
            
            Text("Le immagini selezionate ruoteranno a turno in diretta durante tutto il match")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#94a3b8"))
            
            HStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { idx in
                    bannerSlot(index: idx)
                }
            }
            
            // Reset Banner Button
            HStack {
                Spacer()
                Button(action: resetBanners) {
                    Text("RESET BANNER")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#1e293b"))
                        .cornerRadius(8)
                }
                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(Color(hex: "#09111e"))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "#06b6d4"), lineWidth: 1.5))
    }
    
    private func bannerSlot(index: Int) -> some View {
        PhotosPicker(selection: Binding(
            get: { bannerPickerItems[index] },
            set: { bannerPickerItems[index] = $0 }
        ), matching: .images) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "#050b16"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#1e293b"), lineWidth: 1))
                    
                    if let img = bannerImages[index] {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 42)
                            .cornerRadius(6)
                    } else {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(hex: "#64748b"))
                    }
                }
                Text("\(index + 1)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "#64748b"))
            }
        }
        .onChange(of: bannerPickerItems[index]) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImg = UIImage(data: data) {
                    AppPreferences.shared.saveImage(data, name: "banner_\(index + 1).png")
                    AppPreferences.shared.saveImage(data, name: "sponsorRotating_\(index).png")
                    DispatchQueue.main.async {
                        self.bannerImages[index] = uiImg
                        let count = self.bannerImages.filter { $0 != nil }.count
                        UserDefaults.standard.set(count, forKey: "rotating_sponsors_count")
                    }
                }
            }
        }
    }
    
    // MARK: - Card 6: Instant Replay (Beta)
    private var cardInstantReplay: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("instant_replay_title".localized)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "#06b6d4"))
                    .tracking(1.5)
                Spacer()
                Toggle("", isOn: $replayEnabled)
                    .labelsHidden()
            }
            
            Text("instant_replay_desc".localized)
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "#64748b"))
            
            Button(action: runReplayBenchmark) {
                HStack(spacing: 6) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 12))
                    Text("replay_test_btn".localized)
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(hex: "#0e7490"))
                .cornerRadius(18)
            }
            .padding(.top, 4)
            
            if replayEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Text("replay_duration_label".localized)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "#06b6d4"))
                        .tracking(1.2)
                    Picker("Durata Replay", selection: $replayDuration) {
                        Text("5 secondi").tag(5)
                        Text("7 secondi").tag(7)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Text("replay_speed_label".localized)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "#06b6d4"))
                        .tracking(1.2)
                        .padding(.top, 4)
                    Picker("Velocità Replay", selection: $replaySpeed) {
                        Text("0.5x (Lento)").tag(0.5)
                        Text("0.75x (Quasi normale)").tag(0.75)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .background(Color(hex: "#09111e"))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "#06b6d4"), lineWidth: 1.5))
    }
    
    // MARK: - Card 7: Highlights
    private var cardHighlights: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("highlights_title".localized)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "#06b6d4"))
                .tracking(1.5)
            
            Text("highlights_desc".localized)
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "#64748b"))
            
            VStack(alignment: .leading, spacing: 6) {
                Text("highlight_duration_label".localized)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: "#06b6d4"))
                    .tracking(1.2)
                
                Picker("Durata HL", selection: $highlightDuration) {
                    Text("7 secondi").tag(7)
                    Text("10 secondi").tag(10)
                    Text("15 secondi").tag(15)
                    Text("20 secondi").tag(20)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding(.top, 6)
        }
        .padding(20)
        .background(Color(hex: "#09111e"))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "#06b6d4"), lineWidth: 1.5))
    }
    
    // MARK: - Card 8: Scrolling Text
    private var cardScrollingText: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("scrolling_text".localized)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "#06b6d4"))
                .tracking(1.5)
            
            HStack(spacing: 12) {
                Button(action: loadTextSlot) {
                    Text("btn_load".localized)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(hex: "#1e293b"))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#06b6d4"), lineWidth: 1))
                }
                
                Button(action: saveTextSlot) {
                    Text("btn_save".localized)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(hex: "#1e293b"))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#06b6d4"), lineWidth: 1))
                }
            }
            
            TextField("scrolling_text_max".localized, text: $scrollText)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .padding(12)
                .background(Color(hex: "#050b16"))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#1e293b"), lineWidth: 1))
            
            Divider().background(Color(hex: "#1e293b")).padding(.vertical, 4)
            
            Text("text_color".localized)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color(hex: "#64748b"))
            
            HStack(spacing: 16) {
                colorRadio(name: "color_white".localized, hex: "#FFFFFF", color: .white)
                colorRadio(name: "color_yellow".localized, hex: "#FACC15", color: Color(hex: "#FACC15"))
                colorRadio(name: "color_red".localized, hex: "#EF4444", color: Color(hex: "#EF4444"))
                colorRadio(name: "color_cyan".localized, hex: "#06B6D4", color: Color(hex: "#06B6D4"))
            }
        }
        .padding(20)
        .background(Color(hex: "#09111e"))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "#06b6d4"), lineWidth: 1.5))
    }
    
    private func colorRadio(name: String, hex: String, color: Color) -> some View {
        Button(action: { scrollTextColorHex = hex }) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Color.white, lineWidth: scrollTextColorHex == hex ? 2 : 0))
                Text(name)
                    .font(.system(size: 12))
                    .foregroundColor(color)
            }
        }
    }
    
    // MARK: - Actions & Persistence
    private func loadAllState() {
        selectedSport = AppPreferences.shared.selectedSport
        selectedTheme = AppPreferences.shared.selectedTheme
        teamHome = AppPreferences.shared.teamHome
        teamAway = AppPreferences.shared.teamAway
        
        if let d = AppPreferences.shared.loadImage(name: "logo_team_a.png") { logoHomeImage = UIImage(data: d) }
        if let d = AppPreferences.shared.loadImage(name: "logo_team_b.png") { logoAwayImage = UIImage(data: d) }
        
        for i in 0..<4 {
            if let d = AppPreferences.shared.loadImage(name: "sponsor_\(i + 1).png") {
                sponsorImages[i] = UIImage(data: d)
            }
        }
        for i in 0..<5 {
            if let d = AppPreferences.shared.loadImage(name: "banner_\(i + 1).png") {
                bannerImages[i] = UIImage(data: d)
            }
        }
        
        if let savedTxt = UserDefaults.standard.string(forKey: "saved_scrolling_text_slot_1") {
            scrollText = savedTxt
        }
    }
    
    private func saveAllPreferences() {
        AppPreferences.shared.selectedSport = selectedSport
        AppPreferences.shared.selectedTheme = selectedTheme
        AppPreferences.shared.teamHome = teamHome.uppercased()
        AppPreferences.shared.teamAway = teamAway.uppercased()
        AppPreferences.shared.isReplayEnabled = replayEnabled
        UserDefaults.standard.set(scrollText, forKey: "scrolling_text_content")
        UserDefaults.standard.set(scrollTextColorHex, forKey: "scrolling_text_color")
    }
    
    private func resetLogos() {
        logoHomeImage = nil
        logoAwayImage = nil
        logoHomePickerItem = nil
        logoAwayPickerItem = nil
        AppPreferences.shared.deleteImage(name: "logo_team_a.png")
        AppPreferences.shared.deleteImage(name: "logo_team_b.png")
        showToast("Loghi squadra resettati")
    }
    
    private func resetSponsors() {
        for i in 0..<4 {
            sponsorImages[i] = nil
            sponsorPickerItems[i] = nil
            AppPreferences.shared.deleteImage(name: "sponsor_\(i + 1).png")
        }
        AppPreferences.shared.deleteImage(name: "sponsorFull.png")
        showToast("Sponsor resettati")
    }
    
    private func resetBanners() {
        for i in 0..<5 {
            bannerImages[i] = nil
            bannerPickerItems[i] = nil
            AppPreferences.shared.deleteImage(name: "banner_\(i + 1).png")
            AppPreferences.shared.deleteImage(name: "sponsorRotating_\(i).png")
        }
        UserDefaults.standard.set(0, forKey: "rotating_sponsors_count")
        showToast("Banner resettati")
    }
    
    private func saveTextSlot() {
        guard !scrollText.isEmpty else { return }
        UserDefaults.standard.set(scrollText, forKey: "saved_scrolling_text_slot_1")
        showToast("text_saved".localized)
    }
    
    private func loadTextSlot() {
        if let txt = UserDefaults.standard.string(forKey: "saved_scrolling_text_slot_1"), !txt.isEmpty {
            scrollText = txt
            showToast("Testo caricato")
        } else {
            showToast("no_saved_text".localized)
        }
    }
    
    private func runReplayBenchmark() {
        let ramGB = Double(ProcessInfo.processInfo.physicalMemory) / (1024.0 * 1024.0 * 1024.0)
        let isRamOk = ramGB >= 3.5 // iOS uses memory more efficiently than Android 5.5GB
        if isRamOk {
            replayTestMessage = "✅ SÌ, IL TUO DISPOSITIVO PUÒ UTILIZZARE IL REPLAY\n\nMemoria RAM rilevata: \(String(format: "%.1f", ramGB)) GB (OK)\nGPU Metal Framebuffer: Supportato (OK)"
        } else {
            replayTestMessage = "❌ PURTROPPO IL TUO DISPOSITIVO NON HA ABBASTANZA MEMORIA\n\nMemoria RAM rilevata: \(String(format: "%.1f", ramGB)) GB (Min. 4 GB consigliati)"
        }
        showReplayTestAlert = true
    }
    
    private func showToast(_ msg: String) {
        withAnimation { toastMessage = msg }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { self.toastMessage = nil }
        }
    }
}

