import SwiftUI

struct LiveSetupView: View {
    @State private var streamTitle = ""
    @State private var fps60Enabled = false
    
    var body: some View {
        Form {
            Section(header: Text("youtube_config".localized)) {
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
                NavigationLink(destination: DirectorView()) {
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
