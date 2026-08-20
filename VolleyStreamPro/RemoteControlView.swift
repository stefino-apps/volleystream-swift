import SwiftUI

struct RemoteControlView: View {
    @State private var sessionCode: String = ""
    @State private var isConnected = false
    
    // Dati sincronizzati
    @State private var homeScore = 0
    @State private var awayScore = 0
    @State private var homeSets = 0
    @State private var awaySets = 0
    @State private var homeName = "CASA"
    @State private var awayName = "OSPITE"
    
    var body: some View {
        VStack {
            if !isConnected {
                // Schermata Inserimento Codice Sessione
                VStack(spacing: 20) {
                    Text("remote_enter_code_title".localized)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    TextField("remote_code_hint".localized, text: $sessionCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .padding()
                        .textInputAutocapitalization(.characters)
                    
                    Button("remote_connect_btn".localized) {
                        connectToSession()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    Text("remote_app_required_info".localized)
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .padding()
            } else {
                // Schermata Telecomando Attivo
                VStack {
                    HStack {
                        Text(String(format: "remote_connected_to".localized, sessionCode))
                            .foregroundColor(.green)
                            .bold()
                        Spacer()
                        Button("disconnect".localized) {
                            FirebaseManager.shared.stopListening(matchId: sessionCode)
                            isConnected = false
                        }
                        .foregroundColor(.red)
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Griglia Pulsanti (come in DirectorView, ma questi inviano a Firebase)
                    HStack {
                        RemoteScorePanel(team: homeName, score: homeScore, sets: homeSets) { newScore in
                            // Update Firebase home score
                        } onSet: {
                            // Update Firebase home sets
                        }
                        
                        Spacer()
                        
                        RemoteScorePanel(team: awayName, score: awayScore, sets: awaySets) { newScore in
                            // Update Firebase away score
                        } onSet: {
                            // Update Firebase away sets
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Pulsante Azioni Rapide (Replay)
                    Button("btn_replay".localized) {
                        // Trigger Replay via Firebase
                    }
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(15)
                    .padding()
                }
            }
        }
        .navigationBarTitle("badge_remote_control".localized, displayMode: .inline)
    }
    
    private func connectToSession() {
        guard !sessionCode.isEmpty else { return }
        
        FirebaseManager.shared.authenticateAnonymously { success in
            if success {
                FirebaseManager.shared.startListeningToMatch(matchId: sessionCode)
                
                // Aggiorniamo la UI quando i dati cambiano su Firebase
                FirebaseManager.shared.onScoreUpdate = { home, away in
                    self.homeScore = home
                    self.awayScore = away
                }
                
                FirebaseManager.shared.onSetsUpdate = { home, away in
                    self.homeSets = home
                    self.awaySets = away
                }
                
                FirebaseManager.shared.onTeamNamesUpdate = { home, away in
                    self.homeName = home
                    self.awayName = away
                }
                
                DispatchQueue.main.async {
                    self.isConnected = true
                }
            }
        }
    }
}

// Pannello Remoto per inviare i comandi (a differenza del director che li riceve o gestisce localmente)
struct RemoteScorePanel: View {
    var team: String
    var score: Int
    var sets: Int
    
    var onScoreChanged: (Int) -> Void
    var onSet: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text(team)
                .font(.title2)
                .bold()
            
            Text("\(score)")
                .font(.system(size: 80, weight: .bold))
                .foregroundColor(.vspRed)
            
            HStack {
                Button("-") { if score > 0 { onScoreChanged(score - 1) } }
                    .font(.largeTitle)
                    .padding()
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(10)
                
                Button("+") { onScoreChanged(score + 1) }
                    .font(.largeTitle)
                    .padding()
                    .background(Color.green.opacity(0.3))
                    .cornerRadius(10)
            }
            
            Text("Set: \(sets)")
                .font(.headline)
            
            Button("remote_set".localized) {
                onSet()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
}
