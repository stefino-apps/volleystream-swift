import SwiftUI

struct SettingsView: View {
    @State private var teamHome = AppPreferences.shared.teamHome
    @State private var teamAway = AppPreferences.shared.teamAway
    @State private var replayEnabled = AppPreferences.shared.isReplayEnabled
    
    var body: some View {
        Form {
            Section(header: Text("team_a_label".localized)) {
                TextField("team_a_hint".localized, text: $teamHome)
            }
            
            Section(header: Text("team_b_label".localized)) {
                TextField("team_b_hint".localized, text: $teamAway)
            }
            
            Section(header: Text("sponsors".localized)) {
                Button("select_logo".localized) {
                    // Logica ImagePicker iOS
                }
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
        }
    }
}
