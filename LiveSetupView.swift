import SwiftUI

struct LiveSetupView: View {
    @State private var streamTitle = ""
    @State private var fps60Enabled = false
    @State private var isYouTubeLoggedIn = false
    @State private var networkStatus = "Non testata"
    
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
            
            Section(header: Text("youtube_config".localized)) {
                if isYouTubeLoggedIn {
                    Text("? Collegato al tuo canale YouTube").foregroundColor(.green)
                } else {
                    Button("login_youtube".localized) {
                        // Richiede il ViewController corrente per il login
                        if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                            YouTubeManager.shared.signIn(presentingViewController: rootVC) { success in
                                if success { isYouTubeLoggedIn = true }
                            }
                        }
                    }
                }
            }
            
            Section(header: Text("Rete e Qualità")) {
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

                Button("login_youtube".localized) {
                    // Chiamata a YouTubeManager.shared.signIn
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

