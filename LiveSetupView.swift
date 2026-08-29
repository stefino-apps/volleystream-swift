import SwiftUI

struct LiveSetupView: View {
    @State private var streamTitle = ""
    @State private var fps60Enabled = false
    @State private var isYouTubeLoggedIn = false
    @State private var networkStatus = "Non testata"
    @State private var recordLocally = false
    @State private var replayDuration = 5
    @State private var replaySpeed = 0.5
    
    // Nuove impostazioni per sport e tema
    @State private var selectedSport = "volley"
    @State private var selectedTheme = "neon"
    
    let sports = ["volley", "basket", "soccer", "tennis", "darts", "cricket"]
    let themes = ["neon", "classic", "dark", "light"]
    
    var body: some View {
        Form {
            Section(header: Text("Impostazioni Partita")) {
                Picker("Sport", selection: $selectedSport) {
                    ForEach(sports, id: \.self) { sport in
                        Text(sport.capitalized).tag(sport)
                    }
                }
                
                Picker("Tema Grafico", selection: $selectedTheme) {
                    ForEach(themes, id: \.self) { theme in
                        Text(theme.capitalized).tag(theme)
                    }
                }
            }
            
            Section(header: Text("Opzioni Replay e Registrazione")) {
                Toggle("Salva copia in HD sul dispositivo", isOn: $recordLocally)
                
                let hasEnoughRAM = ProcessInfo.processInfo.physicalMemory >= 5_500_000_000
                if !hasEnoughRAM {
                    Text("Replay non supportato su questo dispositivo (richiesti iPhone 12 Pro o superiori con 6GB+ RAM)").font(.caption).foregroundColor(.red)
                } else {
                    Picker("Durata Replay", selection: $replayDuration) {
                        Text("5 Secondi").tag(5)
                        Text("7 Secondi").tag(7)
                        Text("10 Secondi").tag(10)
                    }.pickerStyle(SegmentedPickerStyle())
                    
                    Picker("Velocita' Replay", selection: $replaySpeed) {
                        Text("Normale (1x)").tag(1.0)
                        Text("Rallenty (0.75x)").tag(0.75)
                        Text("Slow Mo (0.5x)").tag(0.5)
                    }
                }
            }
            
            Section(header: Text("youtube_config".localized)) {
                if isYouTubeLoggedIn {
                    Text("? Collegato al tuo canale YouTube").foregroundColor(.green)
                } else {
                    Button("login_youtube".localized) {
                        if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                            YouTubeManager.shared.signIn(presentingViewController: rootVC) { success in
                                if success { isYouTubeLoggedIn = true }
                            }
                        }
                    }
                }
            }
            
            Section(header: Text("Rete e Qualita'")) {
                HStack {
                    Text("Stato Connessione:")
                    Spacer()
                    Text(networkStatus).foregroundColor(.gray)
                }
                Button("Esegui Speed Test") {
                    networkStatus = "Testing..."
                    NetworkTester.shared.runSpeedTest { result in
                        networkStatus = result
                    }
                }
            }
            
            Section(header: Text("stream_details".localized)) {
                TextField("stream_title_hint".localized, text: $streamTitle)
            }
            
            Section(header: Text("fps_mode_title".localized), footer: Text("fps_info_desc".localized)) {
                Toggle("fps_60_auto_title".localized, isOn: $fps60Enabled)
            }
            
            Section {
                NavigationLink(destination: DirectorView(sport: selectedSport, theme: selectedTheme)) {
                    Text("start_live".localized)
                        .foregroundColor(.vspRed)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationBarTitle("streaming_live".localized, displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gear")
                }
            }
        }
    }
}

