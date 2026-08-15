import SwiftUI

struct DirectorView: View {
    @State private var homeScore = 0
    @State private var awayScore = 0
    @State private var homeSets = 0
    @State private var awaySets = 0
    
    // Nomi squadre presi da Preferences
    private let homeName = AppPreferences.shared.teamHome
    private let awayName = AppPreferences.shared.teamAway
    
    // Per nascondere l'interfaccia (Modalità Clean)
    @State private var isUIHidden = false
    
    var body: some View {
        ZStack {
            // 1. Livello inferiore: Fotocamera (UIViewRepresentable)
            CameraPreviewView()
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation { isUIHidden.toggle() }
                }
            
            // 2. Livello intermedio: Grafica TV (Scoreboard) renderizzata sul video
            VStack {
                ScoreboardView(
                    homeName: homeName, 
                    awayName: awayName, 
                    homeScore: homeScore, 
                    awayScore: awayScore,
                    homeSets: homeSets,
                    awaySets: awaySets
                )
                .padding(.top, 20)
                .padding(.leading, 20)
                Spacer()
            }
            
            // 3. Livello superiore: Comandi Touch (Griglia)
            if !isUIHidden {
                VStack {
                    HStack {
                        Spacer()
                        // Pulsanti rapidi in alto a destra
                        HStack(spacing: 15) {
                            Button("btn_replay".localized) { triggerReplay() }
                                .buttonStyle(TopBarButtonStyle(color: .blue))
                            Button("timeout".localized) { /* Timeout Logic */ }
                                .buttonStyle(TopBarButtonStyle(color: .orange))
                            Button("stop_live".localized) { StreamManager.shared.stopStreaming() }
                                .buttonStyle(TopBarButtonStyle(color: .red))
                        }
                        .padding()
                    }
                    
                    Spacer()
                    
                    // Griglia Comandi Punteggio in basso
                    HStack {
                        ScoreControlPanel(team: homeName, score: $homeScore, sets: $homeSets)
                        Spacer()
                        ScoreControlPanel(team: awayName, score: $awayScore, sets: $awaySets)
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func triggerReplay() {
        if AppPreferences.shared.isReplayEnabled {
            // Logica Replay
        }
    }
}

// Stile Pulsante Superiore
struct TopBarButtonStyle: ButtonStyle {
    var color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .bold()
            .foregroundColor(.white)
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
            .background(color.opacity(0.8))
            .cornerRadius(15)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// Pannello di controllo punteggio (CASA / OSPITE)
struct ScoreControlPanel: View {
    var team: String
    @Binding var score: Int
    @Binding var sets: Int
    
    var body: some View {
        VStack(spacing: 10) {
            Text(team)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.5))
                .cornerRadius(10)
            
            HStack {
                Button(action: { if score > 0 { score -= 1 } }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                }
                
                Button(action: { score += 1 }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                }
            }
            
            Button("end_set".localized) {
                sets += 1
                score = 0 // Reset punteggio
            }
            .font(.caption)
            .padding(8)
            .background(Color.blue.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
}

// Wrapper per la Camera di HaishinKit
struct CameraPreviewView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        // StreamManager.shared.attachCamera(to: view) <- HaishinKit MTHKView
        view.backgroundColor = .black
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// Tabellone TV (SwiftUI)
struct ScoreboardView: View {
    var homeName: String
    var awayName: String
    var homeScore: Int
    var awayScore: Int
    var homeSets: Int
    var awaySets: Int
    
    var body: some View {
        HStack(spacing: 0) {
            // Nomi Squadre
            VStack(alignment: .leading, spacing: 0) {
                Text(homeName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .frame(width: 120, alignment: .leading)
                    .background(Color.vspRed)
                
                Text(awayName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .frame(width: 120, alignment: .leading)
                    .background(Color.blue)
            }
            
            // Punti
            VStack(spacing: 0) {
                Text("\(homeScore)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.yellow)
                    .padding(.vertical, 4)
                    .frame(width: 40)
                    .background(Color.vspDark)
                
                Text("\(awayScore)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.yellow)
                    .padding(.vertical, 4)
                    .frame(width: 40)
                    .background(Color.vspDark)
            }
            
            // Set
            VStack(spacing: 0) {
                Text("\(homeSets)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.vertical, 4)
                    .frame(width: 30)
                    .background(Color.gray)
                
                Text("\(awaySets)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.vertical, 4)
                    .frame(width: 30)
                    .background(Color.gray)
            }
        }
        .cornerRadius(6)
        .shadow(radius: 5)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
