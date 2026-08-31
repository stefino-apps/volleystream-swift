import SwiftUI
import PhotosUI

struct SettingsView: View {
    @State private var selectedSport = AppPreferences.shared.selectedSport
    @State private var selectedTheme = AppPreferences.shared.selectedTheme
    @State private var teamHome = AppPreferences.shared.teamHome
    @State private var teamAway = AppPreferences.shared.teamAway
    
    @State private var scrollTextEnabled = false
    @State private var scrollText = "NOTIZIE: La partita proceda con regolarita' e le squadre sono in campo."
    @State private var scrollTextColor = Color.white
    
    @AppStorage("punto_de_oro") private var puntoDeOro: Bool = false
    
    let sports = ["volley", "basket", "soccer", "tennis", "darts", "cricket", "padel", "pallamano", "beach volley", "biliardo"]
    let themes = ["neon", "classic", "dark", "light"]
    
    @AppStorage("remote_session_id") private var remoteSessionId: String = "REGIA_01"
    
    // Image Pickers state
    @State private var logoHomeItem: PhotosPickerItem?
    @State private var logoAwayItem: PhotosPickerItem?
    @State private var sponsorItem: PhotosPickerItem?
    @State private var rotatingSponsorsItems: [PhotosPickerItem] = []
    
    @State private var homeImageSelected = false
    @State private var awayImageSelected = false
    @State private var sponsorSelected = false
    @State private var rotatingSponsorsSelected = false
    
    var body: some View {
        Form {
            Section(header: Text("Connessione Remota")) {
                TextField("ID Telecomando (es. REGIA_01)", text: $remoteSessionId)
                    .autocapitalization(.allCharacters)
            }
            
            Section(header: Text("Sport & Tema Tabellone")) {
                Picker("Seleziona Sport", selection: $selectedSport) {
                    ForEach(sports, id: \.self) { sport in
                        Text(sport.capitalized).tag(sport)
                    }
                }
                if selectedSport == "padel" {
                    Toggle("Punto de Oro", isOn: $puntoDeOro)
                }
                Picker("Stile Tabellone", selection: $selectedTheme) {
                    ForEach(themes, id: \.self) { theme in
                        Text(theme.capitalized).tag(theme)
                    }
                }
            }
            
            Section(header: Text("Squadre e Loghi")) {
                TextField("Nome Squadra Casa", text: $teamHome)
                PhotosPicker(selection: $logoHomeItem, matching: .images) {
                    Text(homeImageSelected ? "Logo Casa Selezionato ✓" : "Seleziona Logo Casa")
                        .foregroundColor(homeImageSelected ? .green : .blue)
                }
                .onChange(of: logoHomeItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            AppPreferences.shared.saveImage(data, name: "logoHome.png")
                            homeImageSelected = true
                        }
                    }
                }
                
                TextField("Nome Squadra Ospite", text: $teamAway)
                PhotosPicker(selection: $logoAwayItem, matching: .images) {
                    Text(awayImageSelected ? "Logo Ospite Selezionato ✓" : "Seleziona Logo Ospite")
                        .foregroundColor(awayImageSelected ? .green : .blue)
                }
                .onChange(of: logoAwayItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            AppPreferences.shared.saveImage(data, name: "logoAway.png")
                            awayImageSelected = true
                        }
                    }
                }
            }
            
            Section(header: Text("Sponsor a Tutto Schermo")) {
                PhotosPicker(selection: $sponsorItem, matching: .images) {
                    Text(sponsorSelected ? "Sponsor Selezionato ✓" : "Seleziona Immagine Sponsor")
                        .foregroundColor(sponsorSelected ? .green : .blue)
                }
                .onChange(of: sponsorItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            AppPreferences.shared.saveImage(data, name: "sponsorFull.png")
                            sponsorSelected = true
                        }
                    }
                }
            }
            
            Section(header: Text("Banner Sponsor Rotanti (In alto a destra)")) {
                PhotosPicker(selection: $rotatingSponsorsItems, maxSelectionCount: 5, matching: .images) {
                    Text(rotatingSponsorsSelected ? "Banner Rotanti Selezionati (\(rotatingSponsorsItems.count)) ✓" : "Seleziona fino a 5 Banner")
                        .foregroundColor(rotatingSponsorsSelected ? .green : .blue)
                }
                .onChange(of: rotatingSponsorsItems) { newItems in
                    Task {
                        var index = 0
                        for item in newItems {
                            if let data = try? await item.loadTransferable(type: Data.self) {
                                AppPreferences.shared.saveImage(data, name: "sponsorRotating_\(index).png")
                                index += 1
                            }
                        }
                        UserDefaults.standard.set(index, forKey: "rotating_sponsors_count")
                        rotatingSponsorsSelected = index > 0
                    }
                }
            }
            
            Section(header: Text("Testo Scorrevole in Sovrimpressione")) {
                Toggle("Abilita Testo Scorrevole", isOn: $scrollTextEnabled)
                if scrollTextEnabled {
                    TextField("Inserisci testo", text: $scrollText)
                    ColorPicker("Colore del testo", selection: $scrollTextColor)
                }
            }
            
            Section {
                NavigationLink(destination: LiveSetupView()) {
                    Text("btn_next".localized)
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationBarTitle("settings_title".localized, displayMode: .inline)
        .onAppear {
            homeImageSelected = AppPreferences.shared.loadImage(name: "logoHome.png") != nil
            awayImageSelected = AppPreferences.shared.loadImage(name: "logoAway.png") != nil
            sponsorSelected = AppPreferences.shared.loadImage(name: "sponsorFull.png") != nil
            rotatingSponsorsSelected = UserDefaults.standard.integer(forKey: "rotating_sponsors_count") > 0
        }
        .onDisappear {
            AppPreferences.shared.selectedSport = selectedSport
            AppPreferences.shared.selectedTheme = selectedTheme
            AppPreferences.shared.teamHome = teamHome
            AppPreferences.shared.teamAway = teamAway
        }
    }
}
