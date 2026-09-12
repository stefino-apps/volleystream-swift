import SwiftUI
import AudioToolbox
import UIKit

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
    
    // MARK: - Setup / Connection View (Matching Android Photos 4 & 5)
    var setupView: some View {
        VStack(spacing: 0) {
            // Top Bar with red INDIETRO button and Cyan Title
            HStack(alignment: .center) {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Text("INDIETRO")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(hex: "#EF4444"))
                        .cornerRadius(6)
                }
                
                Spacer()
                
                Text("CONTROLLO\nREMOTO")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "#06B6D4"))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Spacer()
                
                // Invisible placeholder to keep title centered
                Text("INDIETRO")
                    .font(.system(size: 13, weight: .bold))
                    .opacity(0)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            ScrollView {
                VStack(spacing: 16) {
                    // Card 1: Link Troubleshooting
                    VStack(spacing: 12) {
                        Text("Problemi con il link? Clicca\nsul pulsante qui sotto")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            if let url = URL(string: "https://volleystreampro.com/remote") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Text("CLICCA QUI")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 160, height: 38)
                                .background(Color(hex: "#D97706"))
                                .cornerRadius(6)
                        }
                        
                        Text("Se i link non aprono l'app automaticamente: 1. Clicca il pulsante qui sopra 2. Cerca 'Apri per impostazione predefinita' o 'Link supportati' 3. Seleziona la casella 'volleystreampro.com'")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#94a3b8"))
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .padding(.horizontal, 8)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "#09111e"))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "#1e293b"), lineWidth: 1)
                    )
                    
                    // Card 2: How to Use Remote Control
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 8) {
                            Image(systemName: "iphone")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color(hex: "#06B6D4"))
                            
                            Text("COME UTILIZZARE IL\nCONTROLLO REMOTO")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color(hex: "#06B6D4"))
                                .lineLimit(2)
                        }
                        
                        HStack {
                            Spacer()
                            Text("R.C.")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 6)
                                .background(Color(hex: "#050b16"))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(hex: "#1e293b"), lineWidth: 1)
                                )
                            Spacer()
                        }
                        .padding(.vertical, 2)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("1. Dalla schermata di Regia del dispositivo che riprende il match, premi il pulsante [R.C.] e invia il link (es. tramite WhatsApp) al dispositivo che userai come telecomando.")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#cbd5e1"))
                                .lineSpacing(2)
                            
                            Text("2. Installa l'app VolleyStream Pro anche sul secondo dispositivo (non è richiesto alcun abbonamento).")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#cbd5e1"))
                                .lineSpacing(2)
                            
                            Text("3. Clicca sul link ricevuto sul secondo dispositivo: l'app si aprirà all'istante con tutti i comandi per gestire il punteggio a distanza in tempo reale!")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(hex: "#FACC15"))
                                .lineSpacing(2)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "#09111e"))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "#1e293b"), lineWidth: 1)
                    )
                    
                    // Card 3: Session Code Entry
                    VStack(spacing: 16) {
                        // Yellow Remote Icon Badge
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "#FACC15"))
                                .frame(width: 32, height: 44)
                            
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 6, height: 6)
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color.black)
                                    .frame(width: 14, height: 3)
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color.black)
                                    .frame(width: 14, height: 3)
                            }
                        }
                        .padding(.top, 4)
                        
                        VStack(spacing: 4) {
                            Text("Inserisci Codice Sessione")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Inserisci il codice generato dalla\nRegia per collegarti al match")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#94a3b8"))
                                .multilineTextAlignment(.center)
                        }
                        
                        TextField("CODICE", text: $sessionCode)
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .multilineTextAlignment(.center)
                            .autocapitalization(.allCharacters)
                            .disableAutocorrection(true)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(hex: "#050b16"))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(hex: "#06B6D4"), lineWidth: 2)
                            )
                            .padding(.horizontal, 12)
                        
                        Button(action: { connectToSession() }) {
                            HStack(spacing: 8) {
                                Image(systemName: "bolt.fill")
                                Text("CONNETTI TELECOMANDO")
                            }
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color(hex: "#06B6D4"))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 6)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "#09111e"))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "#1e293b"), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationBarHidden(true)
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
        case "darts":
            dartsControlsView
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
                    FirebaseManager.shared.sendCommand("POINT_A")
                }) {
                    HStack {
                        Image(systemName: "volleyball.fill")
                        Text(matchState.servingTeam == "A" ? "BATTUTA CASA" : "Cambio Palla A")
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
                    FirebaseManager.shared.sendCommand("POINT_B")
                }) {
                    HStack {
                        Image(systemName: "volleyball.fill")
                        Text(matchState.servingTeam == "B" ? "BATTUTA OSPITE" : "Cambio Palla B")
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
                    FirebaseManager.shared.sendCommand("POINT_A")
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
                    FirebaseManager.shared.sendCommand("POINT_B")
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
                        FirebaseManager.shared.sendCommand("TIMEOUT_A")
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
                        FirebaseManager.shared.sendCommand("MINUS_A")
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
                        FirebaseManager.shared.sendCommand("MINUS_B")
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
                        FirebaseManager.shared.sendCommand("TIMEOUT_B")
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
                        Button("+1") { triggerHaptic(); FirebaseManager.shared.sendCommand("POINT_A") }
                            .font(.system(size: 14, weight: .black)).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 10).background(Color(red: 255/255, green: 42/255, blue: 133/255)).cornerRadius(8)
                        Button("+2") { triggerHaptic(); FirebaseManager.shared.sendCommand("PLUS_2_A") }
                            .font(.system(size: 14, weight: .black)).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 10).background(Color(red: 255/255, green: 42/255, blue: 133/255).opacity(0.85)).cornerRadius(8)
                        Button("+3") { triggerHaptic(); FirebaseManager.shared.sendCommand("PLUS_3_A") }
                            .font(.system(size: 14, weight: .black)).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 10).background(Color(red: 255/255, green: 42/255, blue: 133/255).opacity(0.7)).cornerRadius(8)
                    }
                    HStack {
                        Button("-1") { triggerHaptic(); FirebaseManager.shared.sendCommand("MINUS_A") }
                            .font(.caption).foregroundColor(.gray).padding(4)
                        Spacer()
                        Text("Falli: \(matchState.foulsA)")
                            .font(.system(size: 11, weight: .bold)).foregroundColor(.yellow)
                        Button("+F") { triggerHaptic(); FirebaseManager.shared.sendCommand("FOUL_A") }
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
                        Button("+1") { triggerHaptic(); FirebaseManager.shared.sendCommand("POINT_B") }
                            .font(.system(size: 14, weight: .black)).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 10).background(Color(red: 0/255, green: 229/255, blue: 255/255)).cornerRadius(8)
                        Button("+2") { triggerHaptic(); FirebaseManager.shared.sendCommand("PLUS_2_B") }
                            .font(.system(size: 14, weight: .black)).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 10).background(Color(red: 0/255, green: 229/255, blue: 255/255).opacity(0.85)).cornerRadius(8)
                        Button("+3") { triggerHaptic(); FirebaseManager.shared.sendCommand("PLUS_3_B") }
                            .font(.system(size: 14, weight: .black)).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 10).background(Color(red: 0/255, green: 229/255, blue: 255/255).opacity(0.7)).cornerRadius(8)
                    }
                    HStack {
                        Button("-1") { triggerHaptic(); FirebaseManager.shared.sendCommand("MINUS_B") }
                            .font(.caption).foregroundColor(.gray).padding(4)
                        Spacer()
                        Text("Falli: \(matchState.foulsB)")
                            .font(.system(size: 11, weight: .bold)).foregroundColor(.yellow)
                        Button("+F") { triggerHaptic(); FirebaseManager.shared.sendCommand("FOUL_B") }
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
                    Button("−1") { triggerHaptic(); FirebaseManager.shared.sendCommand("MINUS_A") }
                        .font(.title3).foregroundColor(.gray).padding(10).background(Color.white.opacity(0.08)).cornerRadius(8)
                    Button("GOL +1") { triggerHaptic(); FirebaseManager.shared.sendCommand("POINT_A") }
                        .font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).padding(12).background(Color(red: 255/255, green: 42/255, blue: 133/255)).cornerRadius(10)
                }
            }
            .padding(12).background(Color.white.opacity(0.06)).cornerRadius(14)
            
            VStack(spacing: 8) {
                Text(matchState.teamB.isEmpty ? "OSPITE" : matchState.teamB).font(.headline).bold().foregroundColor(.white)
                HStack {
                    Button("−1") { triggerHaptic(); FirebaseManager.shared.sendCommand("MINUS_B") }
                        .font(.title3).foregroundColor(.gray).padding(10).background(Color.white.opacity(0.08)).cornerRadius(8)
                    Button("GOL +1") { triggerHaptic(); FirebaseManager.shared.sendCommand("POINT_B") }
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
                Button("PUNTO +") { triggerHaptic(); FirebaseManager.shared.sendCommand("TENNIS_POINT_A") }
                    .font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).padding(10).background(Color(red: 255/255, green: 42/255, blue: 133/255)).cornerRadius(8)
                HStack {
                    Button("-1") { triggerHaptic(); FirebaseManager.shared.sendCommand("TENNIS_MINUS_A") }.font(.caption).padding(6).background(Color.white.opacity(0.1)).cornerRadius(6)
                    Button("+G") { triggerHaptic(); FirebaseManager.shared.sendCommand("TENNIS_GAME_A") }.font(.caption).padding(6).background(Color.white.opacity(0.1)).cornerRadius(6)
                    Button("+S") { triggerHaptic(); FirebaseManager.shared.sendCommand("NEXT_SET") }.font(.caption).padding(6).background(Color.white.opacity(0.1)).cornerRadius(6)
                }
            }
            .padding(10).background(Color.white.opacity(0.06)).cornerRadius(12)
            
            VStack(spacing: 6) {
                Text(matchState.teamB.isEmpty ? "OSPITE" : matchState.teamB).font(.subheadline).bold().foregroundColor(.white)
                Button("PUNTO +") { triggerHaptic(); FirebaseManager.shared.sendCommand("TENNIS_POINT_B") }
                    .font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).padding(10).background(Color(red: 0/255, green: 229/255, blue: 255/255)).cornerRadius(8)
                HStack {
                    Button("-1") { triggerHaptic(); FirebaseManager.shared.sendCommand("TENNIS_MINUS_B") }.font(.caption).padding(6).background(Color.white.opacity(0.1)).cornerRadius(6)
                    Button("+G") { triggerHaptic(); FirebaseManager.shared.sendCommand("TENNIS_GAME_B") }.font(.caption).padding(6).background(Color.white.opacity(0.1)).cornerRadius(6)
                    Button("+S") { triggerHaptic(); FirebaseManager.shared.sendCommand("NEXT_SET") }.font(.caption).padding(6).background(Color.white.opacity(0.1)).cornerRadius(6)
                }
            }
            .padding(10).background(Color.white.opacity(0.06)).cornerRadius(12)
        }
    }
    
    // MARK: - Darts (Freccette) Controls
    var dartsControlsView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                // CASA Darts
                VStack(spacing: 6) {
                    Text(matchState.teamA.isEmpty ? "GIOCATORE 1" : matchState.teamA)
                        .font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                    HStack(spacing: 4) {
                        Button("-20") { triggerHaptic(); FirebaseManager.shared.sendCommand("DARTS_SUB_20_A") }
                            .font(.system(size: 12, weight: .black)).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 8).background(Color(red: 255/255, green: 42/255, blue: 133/255)).cornerRadius(6)
                        Button("-60") { triggerHaptic(); FirebaseManager.shared.sendCommand("DARTS_SUB_60_A") }
                            .font(.system(size: 12, weight: .black)).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 8).background(Color(red: 255/255, green: 42/255, blue: 133/255).opacity(0.85)).cornerRadius(6)
                        Button("-100") { triggerHaptic(); FirebaseManager.shared.sendCommand("DARTS_SUB_100_A") }
                            .font(.system(size: 12, weight: .black)).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 8).background(Color(red: 255/255, green: 42/255, blue: 133/255).opacity(0.7)).cornerRadius(6)
                    }
                    HStack {
                        Button("BUST") { triggerHaptic(); FirebaseManager.shared.sendCommand("DARTS_BUST") }
                            .font(.caption).foregroundColor(.red).padding(4)
                        Spacer()
                        Text("Leg: \(matchState.dartsLegsA)")
                            .font(.system(size: 11, weight: .bold)).foregroundColor(.yellow)
                        Button("+LEG") { triggerHaptic(); FirebaseManager.shared.sendCommand("DARTS_LEG_A") }
                            .font(.caption).foregroundColor(.white).padding(4).background(Color.white.opacity(0.1)).cornerRadius(4)
                    }
                }
                .padding(8)
                .background(Color.white.opacity(0.06))
                .cornerRadius(10)
                
                // OSPITE Darts
                VStack(spacing: 6) {
                    Text(matchState.teamB.isEmpty ? "GIOCATORE 2" : matchState.teamB)
                        .font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                    HStack(spacing: 4) {
                        Button("-20") { triggerHaptic(); FirebaseManager.shared.sendCommand("DARTS_SUB_20_B") }
                            .font(.system(size: 12, weight: .black)).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 8).background(Color(red: 0/255, green: 229/255, blue: 255/255)).cornerRadius(6)
                        Button("-60") { triggerHaptic(); FirebaseManager.shared.sendCommand("DARTS_SUB_60_B") }
                            .font(.system(size: 12, weight: .black)).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 8).background(Color(red: 0/255, green: 229/255, blue: 255/255).opacity(0.85)).cornerRadius(6)
                        Button("-100") { triggerHaptic(); FirebaseManager.shared.sendCommand("DARTS_SUB_100_B") }
                            .font(.system(size: 12, weight: .black)).foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 8).background(Color(red: 0/255, green: 229/255, blue: 255/255).opacity(0.7)).cornerRadius(6)
                    }
                    HStack {
                        Button("BUST") { triggerHaptic(); FirebaseManager.shared.sendCommand("DARTS_BUST") }
                            .font(.caption).foregroundColor(.red).padding(4)
                        Spacer()
                        Text("Leg: \(matchState.dartsLegsB)")
                            .font(.system(size: 11, weight: .bold)).foregroundColor(.yellow)
                        Button("+LEG") { triggerHaptic(); FirebaseManager.shared.sendCommand("DARTS_LEG_B") }
                            .font(.caption).foregroundColor(.white).padding(4).background(Color.white.opacity(0.1)).cornerRadius(4)
                    }
                }
                .padding(8)
                .background(Color.white.opacity(0.06))
                .cornerRadius(10)
            }
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
                    FirebaseManager.shared.sendCommand("TOGGLE_TEXT")
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
                    FirebaseManager.shared.sendCommand("TOGGLE_MUTE")
                }) {
                    Image(systemName: matchState.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(matchState.isMuted ? .red : Color(red: 56/255, green: 189/255, blue: 248/255))
                        .frame(width: 42)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(8)
                }
            }
            
            // Row 2: Sponsor Banners (S1, S2, S3, S4)
            HStack(spacing: 8) {
                ForEach(1...4, id: \.self) { index in
                    let isSelected = matchState.showSponsor && (matchState.currentSponsorIdx == index - 1)
                    Button(action: {
                        triggerHaptic()
                        FirebaseManager.shared.sendCommand("SPONSOR_\(index)")
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
        let clean = sessionCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !clean.isEmpty else { return }
        sessionCode = clean
        print("RemoteControlView: Connecting to session \(clean)...")
        
        FirebaseManager.shared.onStateUpdated = { state in
            DispatchQueue.main.async {
                print("RemoteControlView: State received \(state.scoreA)-\(state.scoreB)")
                self.matchState = state
                self.isConnected = true
            }
        }
        
        FirebaseManager.shared.joinSession(id: clean) { success in
            DispatchQueue.main.async {
                if success {
                    self.isConnected = true
                }
            }
        }
    }
    
    private func triggerHaptic() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

