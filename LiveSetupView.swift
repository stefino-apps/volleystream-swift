import SwiftUI

struct LiveSetupView: View {
    @State private var streamPlatform = "YouTube"
    @State private var streamVisibility = "Pubblico"
    @State private var streamResolution = "1080p"
    @State private var streamFPS = 60
    
    @State private var streamTitle = "\(AppPreferences.shared.teamHome) vs \(AppPreferences.shared.teamAway)"
    @State private var streamDescription = ""
    
    @State private var isYouTubeLoggedIn = false
    @State private var networkStatus = "Non testata"
    
    @State private var recordLocally = false
    @State private var replayDuration = 5
    @State private var replaySpeed = 0.5
    
    @State private var rtmpUrl = ""
    @State private var streamKey = ""
    @State private var isCreatingEvent = false
    @State private var navigateToDirector = false
    @State private var accettaTermini = true
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        Form {
            Section(header: Text("Piattaforma di Streaming")) {
                Picker("Piattaforma", selection: $streamPlatform) {
                    Text("YouTube").tag("YouTube")
                    Text("RTMP Personalizzato").tag("RTMP")
                }.pickerStyle(SegmentedPickerStyle())
                
                if streamPlatform == "YouTube" {
                    if isYouTubeLoggedIn {
                        Text("✅ Collegato al canale YouTube").foregroundColor(.green)
                        Picker("Visibilità Video", selection: $streamVisibility) {
                            Text("Pubblico").tag("Pubblico")
                            Text("Non in elenco").tag("Non in elenco")
                            Text("Privato").tag("Privato")
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Button("Collega Canale YouTube") {
                                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                      let rootVC = windowScene.windows.first?.rootViewController else { return }
                                YouTubeManager.shared.signIn(presentingViewController: rootVC) { success, _ in
                                    isYouTubeLoggedIn = success
                                }
                            }.foregroundColor(.red)
                            
                            Text("⚠️ Attenzione: Assicurati di aver abilitato lo streaming dal vivo nelle impostazioni del tuo canale YouTube (l'abilitazione richiede 24 ore dal primo avvio via browser).")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                } else {
                    TextField("URL Server RTMP", text: $rtmpUrl)
                    TextField("Chiave Stream", text: $streamKey)
                }
            }
            
            Section(header: Text("Termini d'uso e Privacy")) {
                Toggle(isOn: $accettaTermini) {
                    Text("Dichiaro di aver raccolto le necessarie autorizzazioni e liberatorie per la ripresa di minorenni, manlevando gli sviluppatori da ogni responsabilità.")
                        .font(.caption)
                }
            }
            
            Section(header: Text("Qualità Video e Rete")) {
                Picker("Risoluzione", selection: $streamResolution) {
                    Text("480p").tag("480p")
                    Text("720p").tag("720p")
                    Text("1080p (HD)").tag("1080p")
                }.pickerStyle(SegmentedPickerStyle())
                
                Picker("FPS", selection: $streamFPS) {
                    Text("30 FPS").tag(30)
                    Text("60 FPS").tag(60)
                }.pickerStyle(SegmentedPickerStyle())
                
                HStack {
                    Text("Stato Rete:")
                    Spacer()
                    Text(networkStatus).foregroundColor(.gray)
                }
                Button("Esegui Test Connessione") {
                    networkStatus = "Calcolo in corso..."
                    NetworkTester.shared.runSpeedTest { result in
                        networkStatus = result
                    }
                }
            }
            
            Section(header: Text("Dettagli Stream")) {
                TextField("Titolo Video", text: $streamTitle)
                TextField("Descrizione (Opzionale)", text: $streamDescription)
            }
            
            Section(header: Text("Registrazione e Replay")) {
                Toggle("Registra match in locale (MP4)", isOn: $recordLocally)
                
                let hasEnoughRAM = ProcessInfo.processInfo.physicalMemory >= 5_500_000_000
                if !hasEnoughRAM {
                    Text("Replay non supportato (richiesti 6GB+ RAM)").font(.caption).foregroundColor(.red)
                } else {
                    Toggle("Abilita Instant Replay", isOn: .constant(true))
                }
            }
            
            Section {
                Button(action: startLiveAction) {
                    HStack {
                        if isCreatingEvent {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text(" Creazione in corso...")
                        } else {
                            Text("start_live".localized)
                        }
                    }
                    .foregroundColor(.white)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(isCreatingEvent ? Color.gray : Color.red)
                    .cornerRadius(8)
                }
                .disabled(isCreatingEvent)
            }
            .listRowBackground(Color.clear)
        }
        .navigationBarTitle("Impostazioni Diretta", displayMode: .inline)
        .background(
            NavigationLink(
                destination: DirectorView(sport: AppPreferences.shared.selectedSport, theme: AppPreferences.shared.selectedTheme).navigationBarHidden(true),
                isActive: $navigateToDirector
            ) {
                EmptyView()
            }
            .hidden()
        )
        .fullScreenCover(isPresented: $navigateToDirector) {
            DirectorView(sport: AppPreferences.shared.selectedSport, theme: AppPreferences.shared.selectedTheme)
                .edgesIgnoringSafeArea(.all)
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Attenzione"),
                message: Text(alertMessage),
                primaryButton: .default(Text("Entra comunque in Regia")) {
                    proceedToDirector(rtmp: rtmpUrl.isEmpty ? "rtmp://a.rtmp.youtube.com/live2" : rtmpUrl, key: streamKey.isEmpty ? "offline_test" : streamKey)
                },
                secondaryButton: .cancel(Text("Annulla"))
            )
        }
        .onAppear {
            isYouTubeLoggedIn = YouTubeManager.shared.accessToken != nil
        }
    }
    
    private func proceedToDirector(rtmp: String, key: String) {
        UserDefaults.standard.set(rtmp, forKey: "rtmp_url")
        UserDefaults.standard.set(key, forKey: "rtmp_key")
        UserDefaults.standard.set(recordLocally, forKey: "record_locally")
        navigateToDirector = true
    }
    
    private func startLiveAction() {
        if !accettaTermini {
            alertMessage = "Devi accettare i termini relativi alle riprese prima di iniziare."
            showAlert = true
            return
        }
        
        if streamPlatform == "YouTube" && isYouTubeLoggedIn {
            isCreatingEvent = true
            YouTubeManager.shared.createLiveEvent(title: streamTitle) { rtmp, key, err in
                DispatchQueue.main.async {
                    isCreatingEvent = false
                    if err == nil, let rtmp = rtmp, let key = key {
                        proceedToDirector(rtmp: rtmp, key: key)
                    } else {
                        alertMessage = "Impossibile creare la diretta YouTube automatica (\(err?.localizedDescription ?? "Errore sconosciuto")).\nVuoi comunque accedere alla Regia?"
                        showAlert = true
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

