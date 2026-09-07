import SwiftUI

struct RemoteControlView: View {
    @State private var sessionCode: String = UserDefaults.standard.string(forKey: "incoming_remote_id") ?? ""
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
        .onAppear {
            if !sessionCode.isEmpty {
                connectToSession()
                UserDefaults.standard.removeObject(forKey: "incoming_remote_id")
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
            VStack(spacing: 16) {
                // Header Bar
                HStack {
                    VStack(alignment: .leading) {
                        Text("🟢 Connesso: \(sessionCode)")
                            .font(.headline)
                            .foregroundColor(.green)
                        Text("Sport: \(matchState.sportType.uppercased())")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("DISCONNETTI") {
                        FirebaseManager.shared.stopListening()
                        isConnected = false
                    }
                    .font(.caption).bold()
                    .padding(8)
                    .background(Color.red.opacity(0.15))
                    .foregroundColor(.red)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                
                Divider()
                
                // Sport Controls
                Group {
                    switch matchState.sportType {
                    case "volley", "beach_volley":
                        VolleyRemote(state: $matchState, update: updateState)
                    case "basket":
                        BasketRemote(state: $matchState, update: updateState)
                    case "soccer", "handball":
                        SoccerRemote(state: $matchState, update: updateState)
                    case "tennis", "padel":
                        TennisRemote(state: $matchState, update: updateState)
                    case "billiards":
                        BilliardsRemote(state: $matchState, update: updateState)
                    case "cricket":
                        CricketRemote(state: $matchState, update: updateState)
                    case "darts":
                        DartsRemote(state: $matchState, update: updateState)
                    default:
                        VolleyRemote(state: $matchState, update: updateState)
                    }
                }
                .padding(.horizontal)
                
                Divider().padding(.vertical, 8)
                
                // Regia Global Controls
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Button(action: { FirebaseManager.shared.sendCommand("UNDO") }) {
                            HStack {
                                Image(systemName: "arrow.uturn.backward")
                                Text("UNDO")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                        }
                        
                        Button(action: { FirebaseManager.shared.sendCommand("INSTANT_REPLAY") }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                Text("REPLAY")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        Button(action: { FirebaseManager.shared.sendCommand("HIGHLIGHT") }) {
                            HStack {
                                Image(systemName: "star.fill")
                                Text("HL")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    
                    HStack {
                        Toggle("Banner Sponsor", isOn: $matchState.showSponsor)
                            .onChange(of: matchState.showSponsor) { _ in updateState() }
                        Spacer()
                        Toggle("Testo News", isOn: $matchState.showScrollText)
                            .onChange(of: matchState.showScrollText) { _ in updateState() }
                    }
                    .padding(.horizontal, 4)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 30)
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
        FirebaseManager.shared.updateMatchState(matchState)
    }
}

// MARK: - Volley / Beach Volley Remote
struct VolleyRemote: View {
    @Binding var state: RemoteMatchState
    var update: () -> Void
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: { state.servingTeam = "A"; update() }) {
                    Text(state.servingTeam == "A" ? "🏐 BATTUTA CASA" : "Cambio Palla Casa")
                        .font(.caption).bold()
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(state.servingTeam == "A" ? Color.green : Color.gray.opacity(0.3))
                        .foregroundColor(state.servingTeam == "A" ? .white : .primary)
                        .cornerRadius(8)
                }
                Button(action: { state.servingTeam = "B"; update() }) {
                    Text(state.servingTeam == "B" ? "🏐 BATTUTA OSPITE" : "Cambio Palla Ospite")
                        .font(.caption).bold()
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(state.servingTeam == "B" ? Color.green : Color.gray.opacity(0.3))
                        .foregroundColor(state.servingTeam == "B" ? .white : .primary)
                        .cornerRadius(8)
                }
            }
            HStack(spacing: 16) {
                SportTeamBox(team: state.teamA.isEmpty ? "CASA" : state.teamA, score: $state.scoreA, sub: $state.setsA, subName: "Set", onPlus: { state.scoreA += 1; update() }, onMinus: { if state.scoreA > 0 { state.scoreA -= 1 }; update() }, onSubPlus: { state.setsA += 1; update() }, onSubMinus: { if state.setsA > 0 { state.setsA -= 1 }; update() })
                SportTeamBox(team: state.teamB.isEmpty ? "OSPITE" : state.teamB, score: $state.scoreB, sub: $state.setsB, subName: "Set", onPlus: { state.scoreB += 1; update() }, onMinus: { if state.scoreB > 0 { state.scoreB -= 1 }; update() }, onSubPlus: { state.setsB += 1; update() }, onSubMinus: { if state.setsB > 0 { state.setsB -= 1 }; update() })
            }
            HStack {
                Button("TIMEOUT CASA") { state.timeoutA += 1; update() }
                    .font(.caption).bold().padding(8).frame(maxWidth: .infinity).background(Color.yellow.opacity(0.2)).foregroundColor(.orange).cornerRadius(8)
                Button("TIMEOUT OSPITE") { state.timeoutB += 1; update() }
                    .font(.caption).bold().padding(8).frame(maxWidth: .infinity).background(Color.yellow.opacity(0.2)).foregroundColor(.orange).cornerRadius(8)
            }
        }
    }
}

// MARK: - Basket Remote
struct BasketRemote: View {
    @Binding var state: RemoteMatchState
    var update: () -> Void
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                VStack {
                    Text(state.teamA.isEmpty ? "CASA" : state.teamA).font(.headline).bold()
                    Text("\(state.scoreA)").font(.system(size: 50, weight: .bold)).foregroundColor(.red)
                    HStack(spacing: 6) {
                        Button("+1") { state.scoreA += 1; update() }.font(.headline).padding(8).background(Color.green.opacity(0.2)).cornerRadius(6)
                        Button("+2") { state.scoreA += 2; update() }.font(.headline).padding(8).background(Color.blue.opacity(0.2)).cornerRadius(6)
                        Button("+3") { state.scoreA += 3; update() }.font(.headline).padding(8).background(Color.purple.opacity(0.2)).cornerRadius(6)
                        Button("-1") { if state.scoreA > 0 { state.scoreA -= 1 }; update() }.font(.headline).padding(8).background(Color.red.opacity(0.2)).cornerRadius(6)
                    }
                    HStack {
                        Text("Falli: \(state.foulsA)").font(.caption).bold()
                        Button("+") { state.foulsA += 1; update() }.padding(4).background(Color.gray.opacity(0.2)).cornerRadius(4)
                        Button("-") { if state.foulsA > 0 { state.foulsA -= 1 }; update() }.padding(4).background(Color.gray.opacity(0.2)).cornerRadius(4)
                    }
                }.padding().background(Color.gray.opacity(0.1)).cornerRadius(12)
                
                VStack {
                    Text(state.teamB.isEmpty ? "OSPITE" : state.teamB).font(.headline).bold()
                    Text("\(state.scoreB)").font(.system(size: 50, weight: .bold)).foregroundColor(.red)
                    HStack(spacing: 6) {
                        Button("+1") { state.scoreB += 1; update() }.font(.headline).padding(8).background(Color.green.opacity(0.2)).cornerRadius(6)
                        Button("+2") { state.scoreB += 2; update() }.font(.headline).padding(8).background(Color.blue.opacity(0.2)).cornerRadius(6)
                        Button("+3") { state.scoreB += 3; update() }.font(.headline).padding(8).background(Color.purple.opacity(0.2)).cornerRadius(6)
                        Button("-1") { if state.scoreB > 0 { state.scoreB -= 1 }; update() }.font(.headline).padding(8).background(Color.red.opacity(0.2)).cornerRadius(6)
                    }
                    HStack {
                        Text("Falli: \(state.foulsB)").font(.caption).bold()
                        Button("+") { state.foulsB += 1; update() }.padding(4).background(Color.gray.opacity(0.2)).cornerRadius(4)
                        Button("-") { if state.foulsB > 0 { state.foulsB -= 1 }; update() }.padding(4).background(Color.gray.opacity(0.2)).cornerRadius(4)
                    }
                }.padding().background(Color.gray.opacity(0.1)).cornerRadius(12)
            }
            
            Stepper("Quarto / Tempo: \(state.currentSet)", value: $state.currentSet, in: 1...4)
                .padding(.horizontal).onChange(of: state.currentSet) { _ in update() }
        }
    }
}

// MARK: - Soccer / Handball Remote
struct SoccerRemote: View {
    @Binding var state: RemoteMatchState
    var update: () -> Void
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                SportTeamBox(team: state.teamA.isEmpty ? "CASA" : state.teamA, score: $state.scoreA, sub: $state.redCardsA, subName: "Cartellini", onPlus: { state.scoreA += 1; update() }, onMinus: { if state.scoreA > 0 { state.scoreA -= 1 }; update() }, onSubPlus: { state.redCardsA += 1; update() }, onSubMinus: { if state.redCardsA > 0 { state.redCardsA -= 1 }; update() })
                SportTeamBox(team: state.teamB.isEmpty ? "OSPITE" : state.teamB, score: $state.scoreB, sub: $state.redCardsB, subName: "Cartellini", onPlus: { state.scoreB += 1; update() }, onMinus: { if state.scoreB > 0 { state.scoreB -= 1 }; update() }, onSubPlus: { state.redCardsB += 1; update() }, onSubMinus: { if state.redCardsB > 0 { state.redCardsB -= 1 }; update() })
            }
            Button(state.timerRunning ? "⏹️ Ferma Cronometro" : "▶️ Avvia Cronometro") {
                state.timerRunning.toggle()
                update()
            }
            .font(.headline).frame(maxWidth: .infinity).padding().background(state.timerRunning ? Color.red : Color.green).foregroundColor(.white).cornerRadius(10)
        }
    }
}

// MARK: - Tennis / Padel Remote
struct TennisRemote: View {
    @Binding var state: RemoteMatchState
    var update: () -> Void
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                VStack {
                    Text(state.teamA.isEmpty ? "CASA" : state.teamA).font(.headline).bold()
                    Text(tennisPointStr(state.tennisPointsA)).font(.system(size: 50, weight: .bold)).foregroundColor(.green)
                    HStack {
                        Button("+P") { state.tennisPointsA = min(4, state.tennisPointsA + 1); update() }.font(.headline).padding(8).background(Color.green.opacity(0.2)).cornerRadius(6)
                        Button("-P") { state.tennisPointsA = max(0, state.tennisPointsA - 1); update() }.font(.headline).padding(8).background(Color.red.opacity(0.2)).cornerRadius(6)
                    }
                    Text("Games: \(state.tennisGamesA) | Sets: \(state.setsA)").font(.caption).padding(.top, 4)
                    HStack {
                        Button("+G") { state.tennisGamesA += 1; update() }.padding(4).background(Color.gray.opacity(0.2)).cornerRadius(4)
                        Button("-G") { if state.tennisGamesA > 0 { state.tennisGamesA -= 1 }; update() }.padding(4).background(Color.gray.opacity(0.2)).cornerRadius(4)
                    }
                }.padding().background(Color.gray.opacity(0.1)).cornerRadius(12)
                
                VStack {
                    Text(state.teamB.isEmpty ? "OSPITE" : state.teamB).font(.headline).bold()
                    Text(tennisPointStr(state.tennisPointsB)).font(.system(size: 50, weight: .bold)).foregroundColor(.green)
                    HStack {
                        Button("+P") { state.tennisPointsB = min(4, state.tennisPointsB + 1); update() }.font(.headline).padding(8).background(Color.green.opacity(0.2)).cornerRadius(6)
                        Button("-P") { state.tennisPointsB = max(0, state.tennisPointsB - 1); update() }.font(.headline).padding(8).background(Color.red.opacity(0.2)).cornerRadius(6)
                    }
                    Text("Games: \(state.tennisGamesB) | Sets: \(state.setsB)").font(.caption).padding(.top, 4)
                    HStack {
                        Button("+G") { state.tennisGamesB += 1; update() }.padding(4).background(Color.gray.opacity(0.2)).cornerRadius(4)
                        Button("-G") { if state.tennisGamesB > 0 { state.tennisGamesB -= 1 }; update() }.padding(4).background(Color.gray.opacity(0.2)).cornerRadius(4)
                    }
                }.padding().background(Color.gray.opacity(0.1)).cornerRadius(12)
            }
        }
    }
    
    private func tennisPointStr(_ p: Int) -> String {
        switch p {
        case 0: return "0"
        case 1: return "15"
        case 2: return "30"
        case 3: return "40"
        case 4: return "AD"
        default: return "\(p)"
        }
    }
}

// MARK: - Billiards Remote
struct BilliardsRemote: View {
    @Binding var state: RemoteMatchState
    var update: () -> Void
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                VStack {
                    Text(state.teamA.isEmpty ? "GIOCATORE 1" : state.teamA).font(.headline).bold()
                    Text("\(state.scoreA)").font(.system(size: 50, weight: .bold)).foregroundColor(.blue)
                    HStack(spacing: 6) {
                        Button("+1") { state.scoreA += 1; update() }.font(.headline).padding(6).background(Color.green.opacity(0.2)).cornerRadius(6)
                        Button("+2") { state.scoreA += 2; update() }.font(.headline).padding(6).background(Color.blue.opacity(0.2)).cornerRadius(6)
                        Button("+5") { state.scoreA += 5; update() }.font(.headline).padding(6).background(Color.purple.opacity(0.2)).cornerRadius(6)
                        Button("+10") { state.scoreA += 10; update() }.font(.headline).padding(6).background(Color.orange.opacity(0.2)).cornerRadius(6)
                    }
                    Button("-1") { if state.scoreA > 0 { state.scoreA -= 1 }; update() }.font(.caption).padding(4).foregroundColor(.red)
                }.padding().background(Color.gray.opacity(0.1)).cornerRadius(12)
                
                VStack {
                    Text(state.teamB.isEmpty ? "GIOCATORE 2" : state.teamB).font(.headline).bold()
                    Text("\(state.scoreB)").font(.system(size: 50, weight: .bold)).foregroundColor(.blue)
                    HStack(spacing: 6) {
                        Button("+1") { state.scoreB += 1; update() }.font(.headline).padding(6).background(Color.green.opacity(0.2)).cornerRadius(6)
                        Button("+2") { state.scoreB += 2; update() }.font(.headline).padding(6).background(Color.blue.opacity(0.2)).cornerRadius(6)
                        Button("+5") { state.scoreB += 5; update() }.font(.headline).padding(6).background(Color.purple.opacity(0.2)).cornerRadius(6)
                        Button("+10") { state.scoreB += 10; update() }.font(.headline).padding(6).background(Color.orange.opacity(0.2)).cornerRadius(6)
                    }
                    Button("-1") { if state.scoreB > 0 { state.scoreB -= 1 }; update() }.font(.caption).padding(4).foregroundColor(.red)
                }.padding().background(Color.gray.opacity(0.1)).cornerRadius(12)
            }
            
            Stepper("Frame: \(state.setsA + state.setsB + 1)", value: $state.setsA, in: 0...50)
                .padding(.horizontal).onChange(of: state.setsA) { _ in update() }
        }
    }
}

// MARK: - Cricket Remote
struct CricketRemote: View {
    @Binding var state: RemoteMatchState
    var update: () -> Void
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                VStack {
                    Text(state.teamA.isEmpty ? "TEAM A" : state.teamA).font(.headline).bold()
                    Text("\(state.scoreA)").font(.system(size: 45, weight: .bold)).foregroundColor(.orange)
                    HStack(spacing: 6) {
                        Button("+1") { state.scoreA += 1; update() }.font(.subheadline).padding(6).background(Color.green.opacity(0.2)).cornerRadius(6)
                        Button("+4") { state.scoreA += 4; update() }.font(.subheadline).padding(6).background(Color.blue.opacity(0.2)).cornerRadius(6)
                        Button("+6") { state.scoreA += 6; update() }.font(.subheadline).padding(6).background(Color.purple.opacity(0.2)).cornerRadius(6)
                        Button("W") { state.cricketWicketsA += 1; update() }.font(.subheadline).padding(6).background(Color.red.opacity(0.2)).cornerRadius(6)
                    }
                    Text("Wickets: \(state.cricketWicketsA)").font(.caption).bold()
                }.padding().background(Color.gray.opacity(0.1)).cornerRadius(12)
                
                VStack {
                    Text(state.teamB.isEmpty ? "TEAM B" : state.teamB).font(.headline).bold()
                    Text("\(state.scoreB)").font(.system(size: 45, weight: .bold)).foregroundColor(.orange)
                    HStack(spacing: 6) {
                        Button("+1") { state.scoreB += 1; update() }.font(.subheadline).padding(6).background(Color.green.opacity(0.2)).cornerRadius(6)
                        Button("+4") { state.scoreB += 4; update() }.font(.subheadline).padding(6).background(Color.blue.opacity(0.2)).cornerRadius(6)
                        Button("+6") { state.scoreB += 6; update() }.font(.subheadline).padding(6).background(Color.purple.opacity(0.2)).cornerRadius(6)
                        Button("W") { state.cricketWicketsB += 1; update() }.font(.subheadline).padding(6).background(Color.red.opacity(0.2)).cornerRadius(6)
                    }
                    Text("Wickets: \(state.cricketWicketsB)").font(.caption).bold()
                }.padding().background(Color.gray.opacity(0.1)).cornerRadius(12)
            }
        }
    }
}

// MARK: - Darts Remote
struct DartsRemote: View {
    @Binding var state: RemoteMatchState
    var update: () -> Void
    @State private var throwInput: String = ""
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                SportTeamBox(team: state.teamA.isEmpty ? "P1" : state.teamA, score: $state.scoreA, sub: $state.setsA, subName: "Legs", onPlus: { state.scoreA += 1; update() }, onMinus: { if state.scoreA > 0 { state.scoreA -= 1 }; update() }, onSubPlus: { state.setsA += 1; update() }, onSubMinus: { if state.setsA > 0 { state.setsA -= 1 }; update() })
                SportTeamBox(team: state.teamB.isEmpty ? "P2" : state.teamB, score: $state.scoreB, sub: $state.setsB, subName: "Legs", onPlus: { state.scoreB += 1; update() }, onMinus: { if state.scoreB > 0 { state.scoreB -= 1 }; update() }, onSubPlus: { state.setsB += 1; update() }, onSubMinus: { if state.setsB > 0 { state.setsB -= 1 }; update() })
            }
            HStack {
                Button("Reset 301") { state.scoreA = 301; state.scoreB = 301; update() }.font(.caption).padding(6).background(Color.gray.opacity(0.2)).cornerRadius(6)
                Button("Reset 501") { state.scoreA = 501; state.scoreB = 501; update() }.font(.caption).padding(6).background(Color.gray.opacity(0.2)).cornerRadius(6)
                Button("Reset 701") { state.scoreA = 701; state.scoreB = 701; update() }.font(.caption).padding(6).background(Color.gray.opacity(0.2)).cornerRadius(6)
            }
        }
    }
}

// MARK: - Generic Sport Team Box
struct SportTeamBox: View {
    var team: String
    @Binding var score: Int
    @Binding var sub: Int
    var subName: String
    var onPlus: () -> Void
    var onMinus: () -> Void
    var onSubPlus: () -> Void
    var onSubMinus: () -> Void
    
    var body: some View {
        VStack {
            Text(team).font(.headline).bold().lineLimit(1)
            Text("\(score)").font(.system(size: 50, weight: .bold)).foregroundColor(.red)
            HStack {
                Button("-") { onMinus() }.font(.title).padding(.horizontal, 16).padding(.vertical, 4).background(Color.gray.opacity(0.2)).cornerRadius(8)
                Button("+") { onPlus() }.font(.title).padding(.horizontal, 16).padding(.vertical, 4).background(Color.green.opacity(0.2)).cornerRadius(8)
            }
            Text("\(subName): \(sub)").font(.caption).bold().padding(.top, 4)
            HStack {
                Button("-") { onSubMinus() }.padding(.horizontal, 10).padding(.vertical, 2).background(Color.gray.opacity(0.2)).cornerRadius(6)
                Button("+") { onSubPlus() }.padding(.horizontal, 10).padding(.vertical, 2).background(Color.blue.opacity(0.2)).cornerRadius(6)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

