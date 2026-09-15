import SwiftUI

struct TutorialStep: Identifiable {
    let id: Int
    let screenName: String
    let screenIcon: String
    let targetName: String
    let title: String
    let message: String
    let iconName: String
    let accentColor: Color
    let previewType: TutorialPreviewType
}

enum TutorialPreviewType {
    case welcome
    case welcomeLang
    case welcomePremium
    case welcomeBadges
    case welcomeRemote
    case welcomeStart
    
    case settingsSport
    case settingsTeams
    case settingsSponsors
    case settingsReplay
    case settingsText
    
    case setupPlatform
    case setupLogin
    case setupQuality
    case setupNetwork
    
    case directorTopBar
    case directorScores
    case directorSetPoint
    case directorReplayHL
    case directorButtons
    case directorGrid
    case directorGoLive
    case finish
}

struct TutorialOverlayView: View {
    @Binding var isPresented: Bool
    @State private var currentStepIndex: Int = 0
    @Namespace private var animationNamespace
    
    private var steps: [TutorialStep] {
        [
            // SCHERMATA 1: WELCOME
            TutorialStep(
                id: 0,
                screenName: "HOME",
                screenIcon: "house.fill",
                targetName: "BENVENUTO",
                title: "tutorial_welcome_btn".localized,
                message: "tutorial_welcome_start".localized,
                iconName: "hand.wave.fill",
                accentColor: Color(hex: "#06B6D4"),
                previewType: .welcome
            ),
            TutorialStep(
                id: 1,
                screenName: "HOME",
                screenIcon: "house.fill",
                targetName: "LINGUA",
                title: "language_button".localized,
                message: "tutorial_welcome_lang".localized,
                iconName: "globe",
                accentColor: Color(hex: "#38BDF8"),
                previewType: .welcomeLang
            ),
            TutorialStep(
                id: 2,
                screenName: "HOME",
                screenIcon: "house.fill",
                targetName: "PREMIUM & PROVA",
                title: "7 GIORNI GRATIS",
                message: "tutorial_welcome_premium".localized,
                iconName: "crown.fill",
                accentColor: Color(hex: "#FACC15"),
                previewType: .welcomePremium
            ),
            TutorialStep(
                id: 3,
                screenName: "HOME",
                screenIcon: "house.fill",
                targetName: "FUNZIONALITÀ",
                title: "FUNZIONI PRO",
                message: "tutorial_welcome_badges".localized,
                iconName: "sparkles",
                accentColor: Color(hex: "#EC4899"),
                previewType: .welcomeBadges
            ),
            TutorialStep(
                id: 4,
                screenName: "HOME",
                screenIcon: "house.fill",
                targetName: "TELECOMANDO (R.C.)",
                title: "CONTROL_REMOTE".localized.uppercased(),
                message: "tutorial_welcome_remote".localized,
                iconName: "iphone.radiowaves.left.and.right",
                accentColor: Color(hex: "#D97706"),
                previewType: .welcomeRemote
            ),
            TutorialStep(
                id: 5,
                screenName: "HOME",
                screenIcon: "house.fill",
                targetName: "AVVIA REGIA",
                title: "START_DIRECTION".localized.uppercased(),
                message: "tutorial_welcome_start_btn".localized,
                iconName: "arrow.right.circle.fill",
                accentColor: Color(hex: "#06B6D4"),
                previewType: .welcomeStart
            ),
            
            // SCHERMATA 2: SETTINGS (IMPOSTAZIONI MATCH)
            TutorialStep(
                id: 6,
                screenName: "CONFIGURAZIONE MATCH",
                screenIcon: "gearshape.fill",
                targetName: "SPORT",
                title: "sport_selection".localized,
                message: "tutorial_settings_sport".localized,
                iconName: "sportscourt.fill",
                accentColor: Color(hex: "#06B6D4"),
                previewType: .settingsSport
            ),
            TutorialStep(
                id: 7,
                screenName: "CONFIGURAZIONE MATCH",
                screenIcon: "gearshape.fill",
                targetName: "SQUADRE & LOGHI",
                title: "team_names_logos".localized,
                message: "tutorial_settings_teams".localized,
                iconName: "shield.lefthalf.filled",
                accentColor: Color(hex: "#EC4899"),
                previewType: .settingsTeams
            ),
            TutorialStep(
                id: 8,
                screenName: "CONFIGURAZIONE MATCH",
                screenIcon: "gearshape.fill",
                targetName: "SPONSOR & BANNER",
                title: "sponsors_rotating".localized,
                message: "tutorial_settings_banners".localized,
                iconName: "photo.on.rectangle.angled",
                accentColor: Color(hex: "#38BDF8"),
                previewType: .settingsSponsors
            ),
            TutorialStep(
                id: 9,
                screenName: "CONFIGURAZIONE MATCH",
                screenIcon: "gearshape.fill",
                targetName: "INSTANT REPLAY",
                title: "badge_instant_replay".localized,
                message: "tutorial_settings_replay".localized,
                iconName: "arrow.counterclockwise.circle.fill",
                accentColor: Color(hex: "#FACC15"),
                previewType: .settingsReplay
            ),
            TutorialStep(
                id: 10,
                screenName: "CONFIGURAZIONE MATCH",
                screenIcon: "gearshape.fill",
                targetName: "TESTO SCORREVOLE",
                title: "scrolling_text_title".localized,
                message: "tutorial_settings_scrolling_text".localized,
                iconName: "character.textbox",
                accentColor: Color(hex: "#06B6D4"),
                previewType: .settingsText
            ),
            
            // SCHERMATA 3: LIVE SETUP
            TutorialStep(
                id: 11,
                screenName: "CONFIGURAZIONE LIVE",
                screenIcon: "video.badge.waveform.fill",
                targetName: "PIATTAFORMA",
                title: "YOUTUBE & RTMP",
                message: "tutorial_setup_platform".localized,
                iconName: "play.tv.fill",
                accentColor: Color(hex: "#EF4444"),
                previewType: .setupPlatform
            ),
            TutorialStep(
                id: 12,
                screenName: "CONFIGURAZIONE LIVE",
                screenIcon: "video.badge.waveform.fill",
                targetName: "LOGIN YOUTUBE",
                title: "LOGIN YOUTUBE",
                message: "tutorial_setup_login".localized,
                iconName: "person.badge.shield.checkmark.fill",
                accentColor: Color(hex: "#EF4444"),
                previewType: .setupLogin
            ),
            TutorialStep(
                id: 13,
                screenName: "CONFIGURAZIONE LIVE",
                screenIcon: "video.badge.waveform.fill",
                targetName: "QUALITÀ & RISOLUZIONE",
                title: "1080P HD / 60 FPS",
                message: "tutorial_setup_resolution".localized,
                iconName: "slider.horizontal.3",
                accentColor: Color(hex: "#06B6D4"),
                previewType: .setupQuality
            ),
            TutorialStep(
                id: 14,
                screenName: "CONFIGURAZIONE LIVE",
                screenIcon: "video.badge.waveform.fill",
                targetName: "TEST DI RETE",
                title: "SPEED TEST",
                message: "tutorial_setup_network".localized,
                iconName: "wifi",
                accentColor: Color(hex: "#22C55E"),
                previewType: .setupNetwork
            ),
            
            // SCHERMATA 4: REGIA LIVE
            TutorialStep(
                id: 15,
                screenName: "REGIA LIVE",
                screenIcon: "tv.fill",
                targetName: "TOP BAR REGIA",
                title: "COMANDI RAPIDI",
                message: "tutorial_director_classic_top".localized,
                iconName: "arrow.up.left.and.arrow.down.right",
                accentColor: Color(hex: "#06B6D4"),
                previewType: .directorTopBar
            ),
            TutorialStep(
                id: 16,
                screenName: "REGIA LIVE",
                screenIcon: "tv.fill",
                targetName: "PUNTI IN DIRETTA",
                title: "TABELLONE SEGNAPUNTI",
                message: "tutorial_director_classic_scores".localized,
                iconName: "plus.circle.fill",
                accentColor: Color(hex: "#EC4899"),
                previewType: .directorScores
            ),
            TutorialStep(
                id: 17,
                screenName: "REGIA LIVE",
                screenIcon: "tv.fill",
                targetName: "SET POINT & MATCH POINT",
                title: "ANIMAZIONE BROADCAST",
                message: "Quando una squadra arriva al punto decisivo, il Set Point o Match Point lampeggia bianco e rosso al centro per 4 secondi, proprio come in TV!",
                iconName: "exclamationmark.triangle.fill",
                accentColor: Color(hex: "#EF4444"),
                previewType: .directorSetPoint
            ),
            TutorialStep(
                id: 18,
                screenName: "REGIA LIVE",
                screenIcon: "tv.fill",
                targetName: "REPLAY & HIGHLIGHTS",
                title: "SLOW MOTION & CLIP",
                message: "tutorial_director_replay".localized + "\n\n" + "tutorial_director_highlight".localized,
                iconName: "backward.fill",
                accentColor: Color(hex: "#FACC15"),
                previewType: .directorReplayHL
            ),
            TutorialStep(
                id: 19,
                screenName: "REGIA LIVE",
                screenIcon: "tv.fill",
                targetName: "TIMEOUT, SPONSOR & AUDIO",
                title: "CONTROLLI LIVE",
                message: "tutorial_director_timeout".localized + " " + "tutorial_director_sponsor".localized + " " + "tutorial_director_audio".localized,
                iconName: "slider.vertical.3",
                accentColor: Color(hex: "#38BDF8"),
                previewType: .directorButtons
            ),
            TutorialStep(
                id: 20,
                screenName: "REGIA LIVE",
                screenIcon: "tv.fill",
                targetName: "MODALITÀ GRIGLIA & CLEAN",
                title: "MODALITÀ SCHERMO (L)",
                message: "tutorial_director_grid_mode".localized + " " + "tutorial_director_clean_mode".localized,
                iconName: "square.grid.2x2.fill",
                accentColor: Color(hex: "#A855F7"),
                previewType: .directorGrid
            ),
            TutorialStep(
                id: 21,
                screenName: "REGIA LIVE",
                screenIcon: "tv.fill",
                targetName: "GO LIVE",
                title: "DIRETTA STREAMING",
                message: "tutorial_director_live".localized,
                iconName: "dot.radiowaves.left.and.right",
                accentColor: Color(hex: "#EF4444"),
                previewType: .directorGoLive
            ),
            TutorialStep(
                id: 22,
                screenName: "COMPLETATO",
                screenIcon: "checkmark.seal.fill",
                targetName: "BUON MATCH!",
                title: "btn_finish_tutorial".localized,
                message: "tutorial_director_finish".localized,
                iconName: "trophy.fill",
                accentColor: Color(hex: "#22C55E"),
                previewType: .finish
            )
        ]
    }
    
    var body: some View {
        let step = steps[min(currentStepIndex, steps.count - 1)]
        
        ZStack {
            // Sfondo oscurato con blur
            Color.black.opacity(0.88)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Top Header Tutorial Bar
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "graduationcap.fill")
                            .foregroundColor(Color(hex: "#06B6D4"))
                            .font(.system(size: 16))
                        Text("TUTORIAL INTERATTIVO")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundColor(Color(hex: "#06B6D4"))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(hex: "#06B6D4").opacity(0.15))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "#06B6D4").opacity(0.4), lineWidth: 1)
                    )
                    
                    Spacer()
                    
                    // Indicatore Passaggio
                    Text("\(currentStepIndex + 1) / \(steps.count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "#94a3b8"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#1e293b"))
                        .cornerRadius(6)
                    
                    // Tasto Chiudi
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "#64748b"))
                    }
                    .padding(.leading, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                Spacer(minLength: 8)
                
                // Visual Mockup Preview con Highlight animato
                VStack(spacing: 12) {
                    // Badge sezione attuale
                    HStack(spacing: 6) {
                        Image(systemName: step.screenIcon)
                            .font(.system(size: 11))
                        Text(step.screenName)
                            .font(.system(size: 11, weight: .black))
                    }
                    .foregroundColor(step.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(step.accentColor.opacity(0.15))
                    .cornerRadius(6)
                    
                    // Card Visual Mockup
                    tutorialVisualCard(step: step)
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .background(Color(hex: "#0f172a"))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(step.accentColor.opacity(0.6), lineWidth: 1.5)
                        )
                        .shadow(color: step.accentColor.opacity(0.25), radius: 12)
                        .padding(.horizontal, 20)
                }
                
                Spacer(minLength: 12)
                
                // Fumetto Esplicativo (Coachmark Bubble)
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(step.accentColor.opacity(0.2))
                                .frame(width: 36, height: 36)
                            Image(systemName: step.iconName)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(step.accentColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.targetName)
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundColor(step.accentColor)
                                .tracking(1)
                            Text(step.title)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                    }
                    
                    Text(step.message)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "#cbd5e1"))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: "#0f172a"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(hex: "#334155"), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                
                Spacer(minLength: 16)
                
                // Barra di navigazione in basso
                HStack(spacing: 12) {
                    if currentStepIndex > 0 {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                currentStepIndex -= 1
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 13, weight: .bold))
                                Text("INDIETRO")
                                    .font(.system(size: 13, weight: .heavy))
                            }
                            .foregroundColor(Color(hex: "#94a3b8"))
                            .frame(height: 48)
                            .padding(.horizontal, 16)
                            .background(Color(hex: "#1e293b"))
                            .cornerRadius(12)
                        }
                    }
                    
                    Button(action: {
                        if currentStepIndex < steps.count - 1 {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                currentStepIndex += 1
                            }
                        } else {
                            isPresented = false
                        }
                    }) {
                        HStack(spacing: 6) {
                            Text(currentStepIndex < steps.count - 1 ? "AVANTI" : "FINE TUTORIAL")
                                .font(.system(size: 14, weight: .heavy))
                            Image(systemName: currentStepIndex < steps.count - 1 ? "arrow.right" : "checkmark")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            LinearGradient(
                                colors: currentStepIndex < steps.count - 1 ? [Color(hex: "#06B6D4"), Color(hex: "#3B82F6")] : [Color(hex: "#22C55E"), Color(hex: "#16A34A")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: step.accentColor.opacity(0.4), radius: 6)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
    }
    
    // MARK: - Mini Mockup per ogni passaggio
    @ViewBuilder
    private func tutorialVisualCard(step: TutorialStep) -> some View {
        ZStack {
            switch step.previewType {
            case .welcome, .welcomeLang, .welcomePremium, .welcomeBadges, .welcomeRemote, .welcomeStart:
                welcomeMockup(step: step)
            case .settingsSport, .settingsTeams, .settingsSponsors, .settingsReplay, .settingsText:
                settingsMockup(step: step)
            case .setupPlatform, .setupLogin, .setupQuality, .setupNetwork:
                setupMockup(step: step)
            case .directorTopBar, .directorScores, .directorSetPoint, .directorReplayHL, .directorButtons, .directorGrid, .directorGoLive:
                directorMockup(step: step)
            case .finish:
                finishMockup()
            }
        }
    }
    
    private func welcomeMockup(step: TutorialStep) -> some View {
        VStack(spacing: 8) {
            // Top Bar
            HStack {
                Image(systemName: "line.horizontal.3")
                    .foregroundColor(.white)
                Spacer()
                Text("VOLLEYSTREAM PRO")
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundColor(Color(hex: "#06B6D4"))
                Spacer()
                HStack(spacing: 3) {
                    Image(systemName: "globe")
                    Text("IT")
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(step.previewType == .welcomeLang ? Color(hex: "#FACC15") : Color(hex: "#06B6D4"))
                .padding(4)
                .background(step.previewType == .welcomeLang ? Color(hex: "#FACC15").opacity(0.2) : Color.clear)
                .cornerRadius(4)
            }
            .padding(.horizontal, 12)
            
            // Prova 7 giorni banner
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(Color(hex: "#FACC15"))
                Text("7 GIORNI DI PROVA GRATUITA")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundColor(.white)
            }
            .padding(6)
            .frame(maxWidth: .infinity)
            .background(step.previewType == .welcomePremium ? Color(hex: "#FACC15").opacity(0.3) : Color(hex: "#1e293b"))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(step.previewType == .welcomePremium ? Color(hex: "#FACC15") : Color.clear, lineWidth: 1.5)
            )
            .padding(.horizontal, 12)
            
            // 4 Grid Badges
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                ForEach(["Regia Live", "Tabellone TV", "Replay Slow-Mo", "Sponsor HD"], id: \.self) { item in
                    Text(item)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(step.previewType == .welcomeBadges ? Color(hex: "#EC4899") : Color(hex: "#94a3b8"))
                        .padding(4)
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: "#1e293b"))
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal, 12)
            
            // Bottom button
            HStack {
                Text(step.previewType == .welcomeRemote ? "CONTROLLO REMOTO" : "AVVIA REGIA MATCH")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 28)
            .background(step.previewType == .welcomeRemote ? Color(hex: "#D97706") : Color(hex: "#06B6D4"))
            .cornerRadius(6)
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 8)
    }
    
    private func settingsMockup(step: TutorialStep) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("🏐 VOLLEY")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(step.previewType == .settingsSport ? Color(hex: "#06B6D4") : .white)
                    .padding(4)
                    .background(Color(hex: "#1e293b"))
                    .cornerRadius(4)
                
                Spacer()
                
                Text("TEMA NEON")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(hex: "#94a3b8"))
            }
            .padding(.horizontal, 12)
            
            HStack(spacing: 8) {
                VStack {
                    Text("CASA")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(hex: "#EC4899"))
                    Text("SQUADRA A")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(6)
                .background(Color(hex: "#1e293b"))
                .cornerRadius(6)
                
                Text("VS")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(.white)
                
                VStack {
                    Text("OSPITE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(hex: "#06B6D4"))
                    Text("SQUADRA B")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(6)
                .background(Color(hex: "#1e293b"))
                .cornerRadius(6)
            }
            .padding(.horizontal, 12)
            
            HStack {
                Image(systemName: "photo.stack")
                    .foregroundColor(Color(hex: "#38BDF8"))
                Text("4 SPONSOR + 5 BANNER ROTANTI ATTIVI")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(6)
            .background(step.previewType == .settingsSponsors ? Color(hex: "#38BDF8").opacity(0.2) : Color(hex: "#1e293b"))
            .cornerRadius(6)
            .padding(.horizontal, 12)
        }
    }
    
    private func setupMockup(step: TutorialStep) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "play.rectangle.fill")
                        .foregroundColor(.red)
                    Text("YOUTUBE LIVE")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(.white)
                }
                .padding(6)
                .background(step.previewType == .setupPlatform ? Color.red.opacity(0.2) : Color(hex: "#1e293b"))
                .cornerRadius(6)
                
                HStack(spacing: 4) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .foregroundColor(Color(hex: "#06B6D4"))
                    Text("RTMP SERVER")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(Color(hex: "#94a3b8"))
                }
            }
            
            HStack {
                Text("Risoluzione: 1080p Full HD")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(step.previewType == .setupQuality ? Color(hex: "#06B6D4") : .white)
                Spacer()
                Text("FPS: 60")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(hex: "#22C55E"))
            }
            .padding(8)
            .background(Color(hex: "#1e293b"))
            .cornerRadius(6)
            .padding(.horizontal, 12)
            
            HStack {
                Image(systemName: "wifi")
                    .foregroundColor(Color(hex: "#22C55E"))
                Text("QUALITÀ RETE: ECCELLENTE (50 Mbps)")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Color(hex: "#22C55E"))
            }
            .padding(6)
            .background(step.previewType == .setupNetwork ? Color(hex: "#22C55E").opacity(0.2) : Color(hex: "#1e293b"))
            .cornerRadius(6)
            .padding(.horizontal, 12)
        }
    }
    
    private func directorMockup(step: TutorialStep) -> some View {
        ZStack {
            // Sfondo campo simulato
            Color(hex: "#022c22")
                .opacity(0.4)
            
            VStack {
                // Tabellone TV in alto a sinistra
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("VOLLEY | SET 1")
                                .font(.system(size: 7, weight: .heavy))
                                .foregroundColor(.white)
                        }
                        HStack(spacing: 12) {
                            Text("SQUADRA A")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(Color(hex: "#EC4899"))
                            Text("24")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundColor(.white)
                        }
                        HStack(spacing: 12) {
                            Text("SQUADRA B")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(Color(hex: "#06B6D4"))
                            Text("22")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(6)
                    .background(Color.black.opacity(0.85))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(step.previewType == .directorScores ? Color(hex: "#EC4899") : Color(hex: "#06B6D4"), lineWidth: 1.5)
                    )
                    
                    Spacer()
                    
                    // GO LIVE badge
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                        Text("ON AIR")
                            .font(.system(size: 7, weight: .heavy))
                            .foregroundColor(.white)
                    }
                    .padding(4)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(4)
                }
                .padding(.horizontal, 10)
                .padding(.top, 8)
                
                Spacer()
                
                if step.previewType == .directorSetPoint {
                    // Animazione Set Point
                    VStack(spacing: 2) {
                        Text("SET POINT")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(.white)
                            .shadow(color: .red, radius: 4)
                        Text("SQUADRA A")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.85))
                    .cornerRadius(8)
                    .shadow(color: .red.opacity(0.6), radius: 8)
                }
                
                Spacer()
                
                // Bottom control pills
                HStack(spacing: 6) {
                    Text("+1 A")
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundColor(.black)
                        .padding(4)
                        .background(Color(hex: "#EC4899"))
                        .cornerRadius(4)
                    
                    Text("REPLAY")
                        .font(.system(size: 7, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(step.previewType == .directorReplayHL ? Color(hex: "#FACC15") : Color(hex: "#1e293b"))
                        .cornerRadius(4)
                    
                    Text("HL")
                        .font(.system(size: 7, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color(hex: "#1e293b"))
                        .cornerRadius(4)
                    
                    Text("T.O.")
                        .font(.system(size: 7, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color(hex: "#1e293b"))
                        .cornerRadius(4)
                    
                    Text("+1 B")
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundColor(.black)
                        .padding(4)
                        .background(Color(hex: "#06B6D4"))
                        .cornerRadius(4)
                }
                .padding(.bottom, 8)
            }
        }
    }
    
    private func finishMockup() -> some View {
        VStack(spacing: 10) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "#FACC15"))
                .shadow(color: Color(hex: "#FACC15").opacity(0.5), radius: 10)
            
            Text("SEI PRONTO ALLA DIRETTA!")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(.white)
            
            Text("Tutti i comandi sono pronti per trasmettere le tue partite sportive con qualità televisiva.")
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "#94a3b8"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }
}
