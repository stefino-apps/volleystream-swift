import SwiftUI
import AudioToolbox

struct RemoteControlView: View {
    @State private var sessionCode: String = UserDefaults.standard.string(forKey: "incoming_remote_id") ?? ""
    @State private var isConnected = false
    @State private var matchState = RemoteMatchState()
    @State private var isAudioMuted = false
    @State private var selectedSponsorIndex: Int? = nil
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color(red: 7/255, green: 9/255, blue: 14/255)
                .edgesIgnoringSafeArea(.all)
            
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
    
    // MARK: - Setup / Connection View
    var setupView: some View {
        VStack(spacing: 24) {
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                Spacer()
            }
            .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 12) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 56))
                    .foregroundColor(Color(red: 0/255, green: 229/255, blue: 255/255))
                    .shadow(color: Color(red: 0/255, green: 229/255, blue: 255/255).opacity(0.5), radius: 15)
                
                Text("CONTROLLO REMOTO")
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.white)
                
                Text("Inserisci il codice mostrato nella schermata Regia")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            VStack(spacing: 16) {
                TextField("Codice Regia (es. REGIA_01)", text: $sessionCode)
                    .font(.system(size: 18, weight: .bold))
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 0/255, green: 229/255, blue: 255/255).opacity(0.5), lineWidth: 1.5)
                    )
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                
                Button(action: { connectToSession() }) {
                    HStack {
                        Image(systemName: "bolt.fill")
                        Text("CONNETTI TELECOMANDO")
                    }
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0/255, green: 245/255, blue: 155/255), Color(red: 0/255, green: 229/255, blue: 255/255)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                    .shadow(color: Color(red: 0/255, green: 229/255, blue: 255/255).opacity(0.4), radius: 10, y: 4)
                }
                .padding(.horizontal, 32)
            }
            
            Spacer()
        }
        .padding(.vertical)
    }
    
    // MARK: - Active Broadcast Remote View
    var activeRemoteView: some View {
        VStack(spacing: 10) {
            // 1. Top Status & Quick Action Bar
            topBarView
            
            // 2. Center Score Mirror Card
            centerScoreCard
            
            // 3. Sport Controls / Giant Touchpads
            sportMainControls
            
            // 4. Bottom Broadcast Bar (TEXT, HL, REP, Audio, S1-S4)
            bottomBroadcastBar
        }
        .padding(.horizontal, 14)
        .padding(.top, 6)
        .padding(.bottom, 12)
    }
    
    // MARK: - Top Status Bar
    var topBarView: some View {
        HStack(spacing: 8) {
            // Session Badge & Connection Dot
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(red: 0/255, green: 245/255, blue: 155/255))
                    .frame(width: 8, height: 8)
                Text("REGIA: #\(sessionCode)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                Text("• 🔋 85%")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.08))
            .cornerRadius(14)
            
            Spacer()
            
            // UNDO Button
            Button(action: {
                triggerHaptic()
                FirebaseManager.shared.sendCommand("UNDO")
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 11, weight: .bold))
                    Text("UNDO")
                        .font(.system(size: 11, weight: .heavy))
                }
                .foregroundColor(Color(red: 0/255, green: 229/255, blue: 255/255))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(red: 0/255, green: 229/255, blue: 255/255).opacity(0.15))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(red: 0/255, green: 229/255, blue: 255/255).opacity(0.4), lineWidth: 1))
            }
            
            // GO LIVE / Disconnect Button
            Button(action: {
                triggerHaptic()
                FirebaseManager.shared.sendCommand("START_STREAM")
            }) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 6, height: 6)
                    Text("GO LIVE")
                        .font(.system(size: 11, weight: .heavy))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(red: 239/255, green: 68/255, blue: 68/255))
                .cornerRadius(10)
            }
            
            // Close / Disconnect
            Button(action: {
                FirebaseManager.shared.stopListening()
                isConnected = false
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.gray)
                    .padding(6)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
        }
    }
    
    // MARK: - Center Score Mirror Card
    var centerScoreCard: some View {
        VStack(spacing: 4) {
            // Header Info
            HStack {
                Text(matchState.sportType.uppercased())
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(Color(red: 0/255, green: 229/255, blue: 255/255))
                Spacer()
                Text("SET \(matchState.currentSet) (\(matchState.setsA)-\(matchState.setsB))")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(red: 250/255, green: 204/255, blue: 21/255))
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)
            
            // Teams and Score
            HStack {
                // Team Home
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        if matchState.servingTeam == "A" {
                            Circle().fill(Color(red: 250/255, green: 204/255, blue: 21/255)).frame(width: 6, height: 6)
                        }
                        Text(matchState.teamA.isEmpty ? "CASA" : matchState.teamA.uppercased())
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    Text("Set: \(matchState.setsA) | T.O: \(matchState.timeoutA)")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Big Score Display
                HStack(spacing: 8) {
                    Text("\(matchState.scoreA)")
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundColor(Color(red: 255/255, green: 42/255, blue: 133/255))
                    Text("−")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.gray)
                    Text("\(matchState.scoreB)")
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundColor(Color(red: 0/255, green: 229/255, blue: 255/255))
                }
                
                Spacer()
                
                // Team Away
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(matchState.teamB.isEmpty ? "OSPITE" : matchState.teamB.uppercased())
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        if matchState.servingTeam == "B" {
                            Circle().fill(Color(red: 250/255, green: 204/255, blue: 21/255)).frame(width: 6, height: 6)
                        }
                    }
                    Text("Set: \(matchState.setsB) | T.O: \(matchState.timeoutB)")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 6)
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 15/255, green: 23/255, blue: 42/255).opacity(0.85))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.12), lineWidth: 1))
        )
    }
    
    // MARK: - Sport Main Controls
    @ViewBuilder
    var sportMainControls: some View {
        switch matchState.sportType.lowercased() {
        case "basket":
            basketControlsView
        case "soccer", "handball":
            soccerControlsView
        case "tennis", "padel":
            tennisControlsView
        default:
            volleyControlsView
        }
    }
    
    // MARK: - Volley Giant Touchpads & Subactions
    var volleyControlsView: some View {
        VStack(spacing: 8) {
            // Serve Bar
            HStack(spacing: 10) {
                Button(action: {
                    triggerHaptic()
                    matchState.servingTeam = "A"
                    updateState()
                }) {
                    HStack {
                        Image(systemName: "volleyball.fill")
                        Text(matchState.servingTeam == "A" ? "BATTUTA CASA" : "Cambio Palla")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(matchState.servingTeam == "A" ? Color(red: 250/255, green: 204/255, blue: 21/255) : Color.white.opacity(0.08))
                    .foregroundColor(matchState.servingTeam == "A" ? .black : .white)
                    .cornerRadius(8)
                }
                
                Button(action: {
                    triggerHaptic()
                    matchState.servingTeam = "B"
                    updateState()
                }) {
                    HStack {
                        Image(systemName: "volleyball.fill")
                        Text(matchState.servingTeam == "B" ? "BATTUTA OSPITE" : "Cambio Palla")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(matchState.servingTeam == "B" ? Color(red: 250/255, green: 204/255, blue: 21/255) : Color.white.opacity(0.08))
                    .foregroundColor(matchState.servingTeam == "B" ? .black : .white)
                    .cornerRadius(8)
                }
            }
            
            // Giant Touchpads: CASA +1 & OSPITE +1
            HStack(spacing: 12) {
                // CASA Giant Pad (Pink)
                Button(action: {
                    triggerHaptic()
                    matchState.scoreA += 1
                    matchState.servingTeam = "A"
                    updateState()
                }) {
                    VStack(spacing: 4) {
                        Text(matchState.teamA.isEmpty ? "CASA" : matchState.teamA.uppercased())
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(.white.opacity(0.9))
                        Text("+1")
                            .font(.system(size: 54, weight: .black))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 255/255, green: 42/255, blue: 133/255), Color(red: 217/255, green: 27/255, blue: 107/255)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.3), lineWidth: 1.5))
                    .shadow(color: Color(red: 255/255, green: 42/255, blue: 133/255).opacity(0.4), radius: 12, y: 6)
                }
                
                // OSPITE Giant Pad (Cyan)
                Button(action: {
                    triggerHaptic()
                    matchState.scoreB += 1
                    matchState.servingTeam = "B"
                    updateState()
                }) {
                    VStack(spacing: 4) {
                        Text(matchState.teamB.isEmpty ? "OSPITE" : matchState.teamB.uppercased())
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(.white.opacity(0.9))
                        Text("+1")
                            .font(.system(size: 54, weight: .black))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0/255, green: 229/255, blue: 255/255), Color(red: 2/255, green: 132/255, blue: 199/255)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.3), lineWidth: 1.5))
                    .shadow(color: Color(red: 0/255, green: 229/255, blue: 255/255).opacity(0.4), radius: 12, y: 6)
                }
            }
            .frame(height: 140)
            
            // Secondary Sub-Actions (T.O. / -1)
            HStack(spacing: 12) {
                // CASA Sub-actions
                HStack(spacing: 8) {
                    Button(action: {
                        triggerHaptic()
                        matchState.timeoutA = min(2, matchState.timeoutA + 1)
                        updateState()
                    }) {
                        HStack(spacing: 4) {
                            Text("T.O.")
                                .font(.system(size: 12, weight: .bold))
                            HStack(spacing: 3) {
                                Circle().fill(matchState.timeoutA >= 1 ? Color.yellow : Color.gray.opacity(0.5)).frame(width: 5, height: 5)
                                Circle().fill(matchState.timeoutA >= 2 ? Color.yellow : Color.gray.opacity(0.5)).frame(width: 5, height: 5)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        triggerHaptic()
                        if matchState.scoreA > 0 { matchState.scoreA -= 1; updateState() }
                    }) {
                        Text("−1")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(Color(red: 255/255, green: 42/255, blue: 133/255))
                            .frame(width: 44)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(10)
                    }
                }
                .frame(maxWidth: .infinity)
                
                // OSPITE Sub-actions
                HStack(spacing: 8) {
                    Button(action: {
                        triggerHaptic()
                        if matchState.scoreB > 0 { matchState.scoreB -= 1; updateState() }
                    }) {
                        Text("−1")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(Color(red: 0/255, green: 229/255, blue: 255/255))
                            .frame(width: 44)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        triggerHaptic()
                        matchState.timeoutB = min(2, matchState.timeoutB + 1)
                        updateState()
                    }) {
                        HStack(spacing: 4) {
                            Text("T.O.")
                                .font(.system(size: 12, weight: .bold))
                            HStack(spacing: 3) {
                                Circle().fill(matchState.timeoutB >= 1 ? Color.yellow : Color.gray.opacity(0.5)).frame(width: 5, height: 5)
                                Circle().fill(matchState.timeoutB >= 2 ? Color.yellow : Color.gray.opacity(0.5)).frame(width: 5, height: 5)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(10)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Basket Controls
    var basketControlsView: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                // Team Home Basket
                VStack(spacing: 6) {
                    Text(matchState.teamA.isEmpty ? "CASA" : matchState.teamA)
                        .font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                    HStack(spacing: 6) {
                        Button("+1") { triggerHaptic(); matchState.scoreA += 1; updateState() }
                            .font(.system(size: 14, weight: .black)).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 10).background(Color(red: 255/255, green: 42/255, blue: 133/255)).cornerRadius(8)
                        Button("+2") { triggerHaptic(); matchState.scoreA += 2; updateState() }
                            .font(.system(size: 14, weight: .black)).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 10).background(Color(red: 255/255, green: 42/255, blue: 133/255).opacity(0.85)).cornerRadius(8)
                        Button("+3") { triggerHaptic(); matchState.scoreA += 3; updateState() }
                            .font(.system(size: 14, weight: .black)).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 10).background(Color(red: 255/255, green: 42/255, blue: 133/255).opacity(0.7)).cornerRadius(8)
                    }
                    HStack {
                        Button("-1") { triggerHaptic(); if matchState.scoreA > 0 { matchState.scoreA -= 1; updateState() } }
                            .font(.caption).foregroundColor(.gray).padding(4)
                        Spacer()
                        Text("Falli: \(matchState.foulsA)")
                            .font(.system(size: 11, weight: .bold)).foregroundColor(.yellow)
                        Button("+F") { triggerHaptic(); matchState.foulsA += 1; updateState() }
                            .font(.caption).foregroundColor(.white).padding(4).background(Color.white.opacity(0.1)).cornerRadius(4)
                    }
                }
                .padding(10)
                .background(Color.white.opacity(0.06))
                .cornerRadius(12)
                
                // Team Away Basket
                VStack(spacing: 6) {
                    Text(matchState.teamB.isEmpty ? "OSPITE" : matchState.teamB)
                        .font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                    HStack(spacing: 6) {
                        Button("+1") { triggerHaptic(); matchState.scoreB += 1; updateState() }
                            .font(.system(size: 14, weight: .black)).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 10).background(Color(red: 0/255, green: 229/255, blue: 255/255)).cornerRadius(8)
                        Button("+2") { triggerHaptic(); matchState.scoreB += 2; updateState() }
                            .font(.system(size: 14, weight: .black)).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 10).background(Color(red: 0/255, green: 229/255, blue: 255/255).opacity(0.85)).cornerRadius(8)
                        Button("+3") { triggerHaptic(); matchState.scoreB += 3; updateState() }
                            .font(.system(size: 14, weight: .black)).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 10).background(Color(red: 0/255, green: 229/255, blue: 255/255).opacity(0.7)).cornerRadius(8)
                    }
                    HStack {
                        Button("-1") { triggerHaptic(); if matchState.scoreB > 0 { matchState.scoreB -= 1; updateState() } }
                            .font(.caption).foregroundColor(.gray).padding(4)
                        Spacer()
                        Text("Falli: \(matchState.foulsB)")
                            .font(.system(size: 11, weight: .bold)).foregroundColor(.yellow)
                        Button("+F") { triggerHaptic(); matchState.foulsB += 1; updateState() }
                            .font(.caption).foregroundColor(.white).padding(4).background(Color.white.opacity(0.1)).cornerRadius(4)
                    }
                }
                .padding(10)
                .background(Color.white.opacity(0.06))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Soccer / Handball Controls
    var soccerControlsView: some View {
        HStack(spacing: 12) {
            VStack(spacing: 8) {
                Text(matchState.teamA.isEmpty ? "CASA" : matchState.teamA).font(.headline).bold().foregroundColor(.white)
                HStack {
                    Button("−1") { triggerHaptic(); if matchState.scoreA > 0 { matchState.scoreA -= 1; updateState() } }
                        .font(.title3).foregroundColor(.gray).padding(10).background(Color.white.opacity(0.08)).cornerRadius(8)
                    Button("GOL +1") { triggerHaptic(); matchState.scoreA += 1; updateState() }
                        .font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).padding(12).background(Color(red: 255/255, green: 42/255, blue: 133/255)).cornerRadius(10)
                }
            }
            .padding(12).background(Color.white.opacity(0.06)).cornerRadius(14)
            
            VStack(spacing: 8) {
                Text(matchState.teamB.isEmpty ? "OSPITE" : matchState.teamB).font(.headline).bold().foregroundColor(.white)
                HStack {
                    Button("−1") { triggerHaptic(); if matchState.scoreB > 0 { matchState.scoreB -= 1; updateState() } }
                        .font(.title3).foregroundColor(.gray).padding(10).background(Color.white.opacity(0.08)).cornerRadius(8)
                    Button("GOL +1") { triggerHaptic(); matchState.scoreB += 1; updateState() }
                        .font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).padding(12).background(Color(red: 0/255, green: 229/255, blue: 255/255)).cornerRadius(10)
                }
            }
            .padding(12).background(Color.white.opacity(0.06)).cornerRadius(14)
        }
    }
    
    // MARK: - Tennis / Padel Controls
    var tennisControlsView: some View {
        HStack(spacing: 12) {
            VStack(spacing: 6) {
                Text(matchState.teamA.isEmpty ? "CASA" : matchState.teamA).font(.subheadline).bold().foregroundColor(.white)
                Button("PUNTO +") { triggerHaptic(); matchState.tennisPointsA = min(4, matchState.tennisPointsA + 1); updateState() }
                    .font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).padding(10).background(Color(red: 255/255, green: 42/255, blue: 133/255)).cornerRadius(8)
                HStack {
                    Button("+G") { triggerHaptic(); matchState.tennisGamesA += 1; updateState() }.font(.caption).padding(6).background(Color.white.opacity(0.1)).cornerRadius(6)
                    Button("+S") { triggerHaptic(); matchState.setsA += 1; updateState() }.font(.caption).padding(6).background(Color.white.opacity(0.1)).cornerRadius(6)
                }
            }
            .padding(10).background(Color.white.opacity(0.06)).cornerRadius(12)
            
            VStack(spacing: 6) {
                Text(matchState.teamB.isEmpty ? "OSPITE" : matchState.teamB).font(.subheadline).bold().foregroundColor(.white)
                Button("PUNTO +") { triggerHaptic(); matchState.tennisPointsB = min(4, matchState.tennisPointsB + 1); updateState() }
                    .font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).padding(10).background(Color(red: 0/255, green: 229/255, blue: 255/255)).cornerRadius(8)
                HStack {
                    Button("+G") { triggerHaptic(); matchState.tennisGamesB += 1; updateState() }.font(.caption).padding(6).background(Color.white.opacity(0.1)).cornerRadius(6)
                    Button("+S") { triggerHaptic(); matchState.setsB += 1; updateState() }.font(.caption).padding(6).background(Color.white.opacity(0.1)).cornerRadius(6)
                }
            }
            .padding(10).background(Color.white.opacity(0.06)).cornerRadius(12)
        }
    }
    
    // MARK: - Bottom Broadcast Bar (TEXT, HL, REP, Audio, S1-S4)
    var bottomBroadcastBar: some View {
        VStack(spacing: 8) {
            // Row 1: Directing Actions (TEXT, HL, REP, Audio Mute)
            HStack(spacing: 8) {
                // News Ticker / Text
                Button(action: {
                    triggerHaptic()
                    matchState.showScrollText.toggle()
                    updateState()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "character.textbox")
                            .font(.system(size: 11))
                        Text("TEXT")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(matchState.showScrollText ? Color.black : Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(matchState.showScrollText ? Color(red: 250/255, green: 204/255, blue: 21/255) : Color.white.opacity(0.08))
                    .cornerRadius(8)
                }
                
                // Highlight Marker
                Button(action: {
                    triggerHaptic()
                    FirebaseManager.shared.sendCommand("HIGHLIGHT")
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                        Text("HL")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(red: 147/255, green: 51/255, blue: 234/255))
                    .cornerRadius(8)
                }
                
                // Instant Replay
                Button(action: {
                    triggerHaptic()
                    FirebaseManager.shared.sendCommand("INSTANT_REPLAY")
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 11))
                        Text("REP")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(red: 37/255, green: 99/255, blue: 235/255))
                    .cornerRadius(8)
                }
                
                // Audio Toggle
                Button(action: {
                    triggerHaptic()
                    isAudioMuted.toggle()
                    FirebaseManager.shared.sendCommand(isAudioMuted ? "MUTE" : "UNMUTE")
                }) {
                    Image(systemName: isAudioMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(isAudioMuted ? .red : Color(red: 56/255, green: 189/255, blue: 248/255))
                        .frame(width: 42)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(8)
                }
            }
            
            // Row 2: Sponsor Banners (S1, S2, S3, S4)
            HStack(spacing: 8) {
                ForEach(1...4, id: \.self) { index in
                    let isSelected = matchState.showSponsor && (selectedSponsorIndex == index)
                    Button(action: {
                        triggerHaptic()
                        if selectedSponsorIndex == index && matchState.showSponsor {
                            matchState.showSponsor = false
                            selectedSponsorIndex = nil
                        } else {
                            matchState.showSponsor = true
                            selectedSponsorIndex = index
                            FirebaseManager.shared.sendCommand("SPONSOR_\(index)")
                        }
                        updateState()
                    }) {
                        Text("S\(index)")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(isSelected ? .black : Color(red: 250/255, green: 204/255, blue: 21/255))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(isSelected ? Color(red: 250/255, green: 204/255, blue: 21/255) : Color.white.opacity(0.08))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(red: 250/255, green: 204/255, blue: 21/255).opacity(0.4), lineWidth: 1)
                            )
                    }
                }
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.04))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    private func connectToSession() {
        guard !sessionCode.isEmpty else { return }
        FirebaseManager.shared.joinSession(id: sessionCode) { success in
            if success {
                FirebaseManager.shared.onStateUpdated = { state in
                    DispatchQueue.main.async {
                        self.matchState = state
                    }
                }
                DispatchQueue.main.async { self.isConnected = true }
            }
        }
    }
    
    private func updateState() {
        matchState.lastUpdate = Int64(Date().timeIntervalSince1970 * 1000)
        FirebaseManager.shared.updateMatchState(matchState)
    }
    
    private func triggerHaptic() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

