import SwiftUI
import PhotosUI

struct SettingsView: View {
    @State private var teamHome = AppPreferences.shared.teamHome
    @State private var teamAway = AppPreferences.shared.teamAway
    @State private var replayEnabled = AppPreferences.shared.isReplayEnabled
    @State private var tickerEnabled = AppPreferences.shared.tickerEnabled
    @State private var tickerText = AppPreferences.shared.tickerText
    @State private var sportType = AppPreferences.shared.sportType
    
    @State private var homeItem: PhotosPickerItem?
    @State private var awayItem: PhotosPickerItem?
    @State private var sp1Item: PhotosPickerItem?
    @State private var sp2Item: PhotosPickerItem?
    @State private var spFSItem: PhotosPickerItem?
    
    let sportOptions = ["volley", "soccer", "tennis", "padel", "darts", "billiards", "handball", "cricket", "basket"]
    
    var body: some View {
        Form {
            Section(header: Text("Sport")) {
                Picker("Seleziona Sport", selection: $sportType) {
                    ForEach(sportOptions, id: \.self) { sport in
                        Text(sport.capitalized).tag(sport)
                    }
                }
            }
            Section(header: Text("team_a_label".localized)) {
                TextField("team_a_hint".localized, text: $teamHome)
                PhotosPicker("Seleziona Logo Casa", selection: $homeItem, matching: .images)
                    .onChange(of: homeItem) { _ in loadImage(item: homeItem) { data in AppPreferences.shared.homeLogoData = data } }
            }
            
            Section(header: Text("team_b_label".localized)) {
                TextField("team_b_hint".localized, text: $teamAway)
                PhotosPicker("Seleziona Logo Ospite", selection: $awayItem, matching: .images)
                    .onChange(of: awayItem) { _ in loadImage(item: awayItem) { data in AppPreferences.shared.awayLogoData = data } }
            }
            
            Section(header: Text("news_ticker".localized)) {
                Toggle("Enable Ticker", isOn: $tickerEnabled)
                if tickerEnabled {
                    TextField("Testo scorrevole...", text: $tickerText)
                }
            }
            
            Section(header: Text("sponsors".localized)) {
                PhotosPicker("Sponsor Rotante 1", selection: $sp1Item, matching: .images)
                    .onChange(of: sp1Item) { _ in loadImage(item: sp1Item) { data in AppPreferences.shared.sponsor1Data = data } }
                
                PhotosPicker("Sponsor Rotante 2", selection: $sp2Item, matching: .images)
                    .onChange(of: sp2Item) { _ in loadImage(item: sp2Item) { data in AppPreferences.shared.sponsor2Data = data } }
                
                PhotosPicker("Sponsor Tutto Schermo", selection: $spFSItem, matching: .images)
                    .onChange(of: spFSItem) { _ in loadImage(item: spFSItem) { data in AppPreferences.shared.sponsorFullScreenData = data } }
            }
            
            Section(header: Text("instant_replay_title".localized), footer: Text("instant_replay_desc".localized)) {
                Toggle("badge_instant_replay".localized, isOn: $replayEnabled)
            }
        }
        .navigationBarTitle("settings_title".localized, displayMode: .inline)
        .onDisappear {
            AppPreferences.shared.teamHome = teamHome
            AppPreferences.shared.teamAway = teamAway
            AppPreferences.shared.isReplayEnabled = replayEnabled
            AppPreferences.shared.tickerEnabled = tickerEnabled
            AppPreferences.shared.tickerText = tickerText
            AppPreferences.shared.sportType = sportType
        }
    }
    
    private func loadImage(item: PhotosPickerItem?, completion: @escaping (Data?) -> Void) {
        Task {
            if let data = try? await item?.loadTransferable(type: Data.self) {
                completion(data)
            }
        }
    }
}
