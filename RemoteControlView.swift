import SwiftUI

struct RemoteControlView: View {
    @State private var sessionCode: String = ""
    @State private var isConnected = false
    
    @State private var matchState = RemoteMatchState()
    
    var body: some View {
        VStack {
            if !isConnected {
                // Schermata Inserimento Codice
                VStack(spacing: 20) {
                    Text("Inserisci Codice Regia")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    TextField("Codice...", text: $sessionCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .padding()
                        .textInputAutocapitalization(.characters)
                    
                    Button("CONNETTI") {
                        connectToSession()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                .padding()
            } else {
                // Schermata Telecomando Attivo
                VStack {
                    HStack {
                        Text("Connesso a: \(sessionCode)")
                            .foregroundColor(.green)
                            .bold()
                        Spacer()
                        Button("DISCONNETTI") {
                            FirebaseManager.shared.stopListening()
                            isConnected = false
                        }
                        .foregroundColor(.red)
                    }
                    .padding()
                    
                    Spacer()
                    
                    HStack {
                        RemoteScorePanel(
                            team: matchState.teamA,
                            score: matchState.scoreA,
                            sets: matchState.setsA,
                            timeouts: matchState.timeoutA,
                            onScoreChanged: { newScore in
                                matchState.scoreA = newScore
                                updateState()
                            },
                            onSet: {
                                matchState.setsA += 1
                                updateState()
                            },
                            onTimeout: {
                                matchState.timeoutA += 1
                                updateState()
                            }
                        )
                        
                        Spacer()
                        
                        RemoteScorePanel(
                            team: matchState.teamB,
                            score: matchState.scoreB,
                            sets: matchState.setsB,
                            timeouts: matchState.timeoutB,
                            onScoreChanged: { newScore in
                                matchState.scoreB = newScore
                                updateState()
                            },
                            onSet: {
                                matchState.setsB += 1
                                updateState()
                            },
                            onTimeout: {
                                matchState.timeoutB += 1
                                updateState()
                            }
                        )
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Extra Controls
                    HStack {
                        Toggle("Mostra Sponsor", isOn: $matchState.showSponsor)
                            .onChange(of: matchState.showSponsor) { _ in updateState() }
                            .padding()
                        
                        Button("REPLAY") {
                            FirebaseManager.shared.sendCommand("TRIGGER_REPLAY")
                        }
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        
                        Button("HIGHLIGHT") {
                            FirebaseManager.shared.sendCommand("TRIGGER_HIGHLIGHT")
                        }
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    private func connectToSession() {
        guard !sessionCode.isEmpty else { return }
        FirebaseManager.shared.joinSession(id: sessionCode) { success in
            if success {
                FirebaseManager.shared.onStateUpdated = { state in
                    self.matchState = state
                }
                DispatchQueue.main.async {
                    self.isConnected = true
                }
            }
        }
    }
    
    private func updateState() {
        // Usa il server timestamp e aggiorna
        matchState.lastUpdate = Int64(Date().timeIntervalSince1970 * 1000)
        // Ma poichè il remote control non è l'host, in un'app reale dovrebbe mandare 
        // i comandi o avere i permessi. Per semplicità usiamo un comando per lo stato o forziamo.
        // Simulazione (In Android c'è updateMatchState se si è HOST)
        // FirebaseManager.shared.updateMatchState(matchState)
    }
}

struct RemoteScorePanel: View {
    var team: String
    var score: Int
    var sets: Int
    var timeouts: Int
    
    var onScoreChanged: (Int) -> Void
    var onSet: () -> Void
    var onTimeout: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text(team).font(.title2).bold()
            
            Text("\(score)")
                .font(.system(size: 80, weight: .bold))
                .foregroundColor(.red)
            
            HStack {
                Button("-") { if score > 0 { onScoreChanged(score - 1) } }
                    .font(.largeTitle).padding().background(Color.gray.opacity(0.3)).cornerRadius(10)
                Button("+") { onScoreChanged(score + 1) }
                    .font(.largeTitle).padding().background(Color.green.opacity(0.3)).cornerRadius(10)
            }
            
            Text("Set: \(sets)")
            Button("Vinci Set") { onSet() }.padding().background(Color.blue).foregroundColor(.white).cornerRadius(10)
            
            Text("Timeout: \(timeouts)")
            Button("Chiama Timeout") { onTimeout() }.padding().background(Color.orange).foregroundColor(.white).cornerRadius(10)
        }
    }
}

