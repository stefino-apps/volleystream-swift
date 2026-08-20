import SwiftUI

struct RemoteControlView: View {
    @State private var sessionCode: String = ""
    @State private var isConnected = false
    @State private var matchState = RemoteMatchState()
    
    var body: some View {
        VStack {
            if !isConnected {
                setupView
            } else {
                activeRemoteView
            }
        }
    }
    
    var setupView: some View {
        VStack(spacing: 20) {
            Text("Inserisci Codice Regia").font(.title).bold()
            TextField("Codice...", text: $sessionCode)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.title2).multilineTextAlignment(.center).padding()
            Button("CONNETTI") { connectToSession() }
                .font(.headline).foregroundColor(.white).padding()
                .frame(maxWidth: .infinity).background(Color.blue).cornerRadius(10)
        }.padding()
    }
    
    var activeRemoteView: some View {
        ScrollView {
            VStack {
                HStack {
                    Text("Connesso a: \(sessionCode) [\(matchState.sportType)]")
                        .foregroundColor(.green).bold()
                    Spacer()
                    Button("DISCONNETTI") {
                        FirebaseManager.shared.stopListening()
                        isConnected = false
                    }.foregroundColor(.red)
                }.padding()
                
                // Controlli specifici per sport
                if matchState.sportType == "volley" {
                    VolleyRemote(state: $matchState, update: updateState)
                } else if matchState.sportType == "basket" {
                    BasketRemote(state: $matchState, update: updateState)
                } else if matchState.sportType == "soccer" {
                    SoccerRemote(state: $matchState, update: updateState)
                } else if matchState.sportType == "tennis" {
                    TennisRemote(state: $matchState, update: updateState)
                } else {
                    Text("Controlli per \(matchState.sportType) in arrivo...")
                }
                
                Divider().padding()
                
                // Controlli globali (Regia)
                HStack {
                    Toggle("Sponsor Rotanti", isOn: $matchState.showSponsor)
                    .onChange(of: matchState.showSponsor) { _ in updateState() }

                Toggle("Sponsor FullScreen", isOn: $matchState.fullScreenSponsor)
                    .onChange(of: matchState.fullScreenSponsor) { _ in updateState() }

                Toggle("Testo Scorrevole", isOn: $matchState.showScrollText)
                        .onChange(of: matchState.showSponsor) { _ in updateState() }
                    
                    Button("REPLAY") { FirebaseManager.shared.sendCommand("TRIGGER_REPLAY") }
                        .padding().background(Color.orange).foregroundColor(.white).cornerRadius(8)
                    
                    Button("HIGHLIGHT") { FirebaseManager.shared.sendCommand("TRIGGER_HIGHLIGHT") }
                        .padding().background(Color.purple).foregroundColor(.white).cornerRadius(8)
                }.padding()
            }
        }
    }
    
    private func connectToSession() {
        guard !sessionCode.isEmpty else { return }
        FirebaseManager.shared.joinSession(id: sessionCode) { success in
            if success {
                FirebaseManager.shared.onStateUpdated = { state in self.matchState = state }
                DispatchQueue.main.async { self.isConnected = true }
            }
        }
    }
    
    private func updateState() {
        matchState.lastUpdate = Int64(Date().timeIntervalSince1970 * 1000)
        // Simulazione
    }
}

// MARK: - Volley Remote
struct VolleyRemote: View {
    @Binding var state: RemoteMatchState
    var update: () -> Void
    var body: some View {
        HStack {
            TeamPanel(team: state.teamA, score: $state.scoreA, subValue: $state.setsA, subLabel: "Set", update: update)
            TeamPanel(team: state.teamB, score: $state.scoreB, subValue: $state.setsB, subLabel: "Set", update: update)
        }
    }
}

// MARK: - Basket Remote
struct BasketRemote: View {
    @Binding var state: RemoteMatchState
    var update: () -> Void
    var body: some View {
        VStack {
            HStack {
                TeamPanel(team: state.teamA, score: $state.scoreA, subValue: $state.foulsA, subLabel: "Falli", update: update)
                TeamPanel(team: state.teamB, score: $state.scoreB, subValue: $state.foulsB, subLabel: "Falli", update: update)
            }
            Stepper("Quarto: \(state.currentSet)", value: $state.currentSet, in: 1...4)
                .padding().onChange(of: state.currentSet) { _ in update() }
        }
    }
}

// MARK: - Soccer Remote
struct SoccerRemote: View {
    @Binding var state: RemoteMatchState
    var update: () -> Void
    var body: some View {
        VStack {
            HStack {
                TeamPanel(team: state.teamA, score: $state.scoreA, subValue: $state.redCardsA, subLabel: "Rossi", update: update)
                TeamPanel(team: state.teamB, score: $state.scoreB, subValue: $state.redCardsB, subLabel: "Rossi", update: update)
            }
            HStack {
                Button(state.timerRunning ? "Ferma Tempo" : "Avvia Tempo") {
                    state.timerRunning.toggle()
                    update()
                }.padding().background(state.timerRunning ? Color.red : Color.green).foregroundColor(.white).cornerRadius(10)
            }
        }
    }
}

// MARK: - Tennis Remote
struct TennisRemote: View {
    @Binding var state: RemoteMatchState
    var update: () -> Void
    var body: some View {
        HStack {
            TeamPanel(team: state.teamA, score: $state.tennisPointsA, subValue: $state.tennisGamesA, subLabel: "Games", update: update)
            TeamPanel(team: state.teamB, score: $state.tennisPointsB, subValue: $state.tennisGamesB, subLabel: "Games", update: update)
        }
    }
}

// MARK: - Componente Base
struct TeamPanel: View {
    var team: String
    @Binding var score: Int
    @Binding var subValue: Int
    var subLabel: String
    var update: () -> Void
    
    var body: some View {
        VStack {
            Text(team).font(.title3).bold()
            Text("\(score)").font(.system(size: 60, weight: .bold)).foregroundColor(.red)
            HStack {
                Button("-") { if score > 0 { score -= 1; update() } }.font(.title).padding().background(Color.gray.opacity(0.3)).cornerRadius(10)
                Button("+") { score += 1; update() }.font(.title).padding().background(Color.green.opacity(0.3)).cornerRadius(10)
            }
            Text("\(subLabel): \(subValue)").padding(.top)
            HStack {
                Button("-") { if subValue > 0 { subValue -= 1; update() } }.padding().background(Color.gray.opacity(0.3)).cornerRadius(8)
                Button("+") { subValue += 1; update() }.padding().background(Color.blue.opacity(0.3)).cornerRadius(8)
            }
        }.padding()
    }
}

