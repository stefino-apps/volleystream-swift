import SwiftUI
import AudioToolbox
import UIKit

struct RemoteControlView: View {
    @State private var sessionCode: String = UserDefaults.standard.string(forKey: "incoming_remote_id") ?? ""
    @State private var isConnected = false
    @State private var matchState = RemoteMatchState()
    @State private var isAudioMuted = false
    @State private var selectedSponsorIndex: Int? = nil
    @State private var dartsInput: String = ""
    @State private var selectedDartsPlayer: String = "A"
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
                                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                            }
                        }) {
                            Text("CLICCA QUI")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 160, height: 38)
                                .background(Color(hex: "#D97706"))
                                .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
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
        VStack(spacing: 6) {
            // 1. Top Status & Quick Action Bar
            topBarView
            
            // 2. Center Score Mirror Card
            centerScoreCard
            
            // 3. Sport Controls / Giant Touchpads (Takes all available vertical space)
            sportMainControls
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // 4. Bottom Broadcast Bar (TEXT, HL, REP, Audio, S1-S4)
            bottomBroadcastBar
        }
        .padding(.horizontal, 10)
        .padding(.top, 4)
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Top Status Bar (1:1 with Android Photo 2)
    var topBarView: some View {
        VStack(spacing: 6) {
            // 1. Header: Connection + Streaming Status
            HStack(alignment: .center) {
                // Connection indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: "#10b981"))
                        .frame(width: 8, height: 8)
                    Text("Connesso a: \(sessionCode)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "#94a3b8"))
                }
                
                Spacer()
                
                // Status Pill (LIVE / STANDBY + Battery)
                HStack(spacing: 6) {
                    Circle()
                        .fill(matchState.isStreaming ? Color.red : Color.gray)
                        .frame(width: 7, height: 7)
                    Text(matchState.isStreaming ? "DIRETTA: LIVE" : "LIVE NON ATTIVA")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(matchState.isStreaming ? Color.red : Color(hex: "#06B6D4"))
                    
                    if matchState.batteryLevel > 0 {
                        Text("🔋 \(matchState.batteryLevel)%")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(hex: "#06B6D4"))
                    }
                    
                    Button(action: {
                        FirebaseManager.shared.stopListening()
                        isConnected = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "#1e293b"))
                .cornerRadius(10)
            }
            .padding(.horizontal, 2)
            
            // 2. Command Row: GO LIVE / STOP LIVE + ANNULLA (UNDO)
            HStack(spacing: 8) {
                Button(action: {
                    triggerHaptic()
                    FirebaseManager.shared.sendCommand(matchState.isStreaming ? "STOP_STREAM" : "START_STREAM")
                }) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                        Text(matchState.isStreaming ? "ARRESTA DIRETTA" : "GO LIVE")
                            .font(.system(size: 14, weight: .black))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(matchState.isStreaming ? Color(hex: "#991B1B") : Color(hex: "#DC2626"))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red, lineWidth: 2))
                }
                
                Button(action: {
                    triggerHaptic()
                    FirebaseManager.shared.sendCommand("UNDO")
                }) {
                    HStack(spacing: 6) {
                        Text("↩")
                            .font(.system(size: 16, weight: .bold))
                        Text("ANNULLA")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(hex: "#2A2A2A"))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.4), lineWidth: 1))
                }
            }
        }
    }
    
    // MARK: - Center Score Mirror Card (1:1 with Android Photo 2)
    var centerScoreCard: some View {
        VStack(spacing: 2) {
            // Row 1: Team names
            HStack {
                Text(matchState.teamA.isEmpty ? "CASA" : matchState.teamA.uppercased())
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "#ec4899"))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .lineLimit(1)
                
                Text("VS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "#64748b"))
                    .frame(width: 32)
                
                Text(matchState.teamB.isEmpty ? "OSPITE" : matchState.teamB.uppercased())
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "#06b6d4"))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)
            
            // Row 2: Scores
            HStack(spacing: 16) {
                Text("\(matchState.scoreA)")
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundColor(Color(hex: "#ec4899"))
                
                Text("−")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                
                Text("\(matchState.scoreB)")
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundColor(Color(hex: "#06b6d4"))
            }
            
            // Row 3: Set Status
            Text("SET \(matchState.currentSet) (\(matchState.setsA)-\(matchState.setsB))")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color(hex: "#facc15"))
                .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#0f172a"))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: "#facc15"), lineWidth: 2)
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
    
    // MARK: - Volley Giant Touchpads & Subactions (1:1 with Android Photo 2)
    var volleyControlsView: some View {
        HStack(spacing: 8) {
            // LEFT PANEL: CASA
            VStack(spacing: 6) {
                // Giant +1 Touchpad
                Button(action: {
                    triggerHaptic()
                    FirebaseManager.shared.sendCommand("POINT_A")
                }) {
                    VStack(spacing: 4) {
                        Text(matchState.teamA.isEmpty ? "CASA" : matchState.teamA.uppercased())
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        
                        Text("+1")
                            .font(.system(size: 38, weight: .black))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(hex: "#ec4899"))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white, lineWidth: 2)
                    )
                }
                
                // Timeout indicator
                Text("T.O.: \(getTimeoutDots(matchState.timeoutA))")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "#ffd000"))
                    .padding(.vertical, 2)
                
                // Subactions: -1 and T.O.
                HStack(spacing: 6) {
                    Button(action: {
                        triggerHaptic()
                        FirebaseManager.shared.sendCommand("MINUS_A")
                    }) {
                        Text("-1")
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color(hex: "#2A2A2A"))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(hex: "#ec4899"), lineWidth: 2)
                            )
                    }
                    
                    Button(action: {
                        triggerHaptic()
                        FirebaseManager.shared.sendCommand("TIMEOUT_A")
                    }) {
                        Text("T.O.")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color(hex: "#2A2A2A"))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(hex: "#ec4899"), lineWidth: 2)
                            )
                    }
                }
            }
            .padding(6)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "#0f172a"))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(hex: "#ec4899"), lineWidth: 2)
            )
            
            // RIGHT PANEL: OSPITE
            VStack(spacing: 6) {
                // Giant +1 Touchpad
                Button(action: {
                    triggerHaptic()
                    FirebaseManager.shared.sendCommand("POINT_B")
                }) {
                    VStack(spacing: 4) {
                        Text(matchState.teamB.isEmpty ? "OSPITE" : matchState.teamB.uppercased())
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        
                        Text("+1")
                            .font(.system(size: 38, weight: .black))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(hex: "#06b6d4"))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white, lineWidth: 2)
                    )
                }
                
                // Timeout indicator
                Text("T.O.: \(getTimeoutDots(matchState.timeoutB))")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "#ffd000"))
                    .padding(.vertical, 2)
                
                // Subactions: -1 and T.O.
                HStack(spacing: 6) {
                    Button(action: {
                        triggerHaptic()
                        FirebaseManager.shared.sendCommand("MINUS_B")
                    }) {
                        Text("-1")
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color(hex: "#2A2A2A"))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(hex: "#06b6d4"), lineWidth: 2)
                            )
                    }
                    
                    Button(action: {
                        triggerHaptic()
                        FirebaseManager.shared.sendCommand("TIMEOUT_B")
                    }) {
                        Text("T.O.")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color(hex: "#2A2A2A"))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(hex: "#06b6d4"), lineWidth: 2)
                            )
                    }
                }
            }
            .padding(6)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "#0f172a"))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(hex: "#06b6d4"), lineWidth: 2)
            )
        }
    }
    
    // MARK: - Basket Controls
    var basketControlsView: some View {
        HStack(spacing: 8) {
            // Team Home Basket
            VStack(spacing: 6) {
                VStack(spacing: 4) {
                    Button("+1") { triggerHaptic(); FirebaseManager.shared.sendCommand("POINT_A") }
                        .font(.system(size: 18, weight: .black)).foregroundColor(.white).frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(hex: "#ec4899")).cornerRadius(8).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white, lineWidth: 1))
                    Button("+2") { triggerHaptic(); FirebaseManager.shared.sendCommand("PLUS_2_A") }
                        .font(.system(size: 18, weight: .black)).foregroundColor(.white).frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(hex: "#ec4899")).cornerRadius(8).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white, lineWidth: 1))
                    Button("+3") { triggerHaptic(); FirebaseManager.shared.sendCommand("PLUS_3_A") }
                        .font(.system(size: 18, weight: .black)).foregroundColor(.white).frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(hex: "#ec4899")).cornerRadius(8).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white, lineWidth: 1))
                }
                
                Text("FALLI: \(matchState.foulsA)")
                    .font(.system(size: 14, weight: .bold)).foregroundColor(.red)
                
                Text("T.O.: \(getTimeoutDots(matchState.timeoutA))")
                    .font(.system(size: 11, weight: .bold)).foregroundColor(Color(hex: "#ffd000"))
                
                HStack(spacing: 4) {
                    Button("-1") { triggerHaptic(); FirebaseManager.shared.sendCommand("MINUS_A") }
                        .font(.system(size: 14, weight: .bold)).foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 44).background(Color(hex: "#2A2A2A")).cornerRadius(8).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#ec4899"), lineWidth: 1))
                    Button("T.O.") { triggerHaptic(); FirebaseManager.shared.sendCommand("TIMEOUT_A") }
                        .font(.system(size: 12, weight: .bold)).foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 44).background(Color(hex: "#2A2A2A")).cornerRadius(8).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#facc15"), lineWidth: 1))
                    Button("+F") { triggerHaptic(); FirebaseManager.shared.sendCommand("FOUL_A") }
                        .font(.system(size: 12, weight: .bold)).foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 44).background(Color(hex: "#2A2A2A")).cornerRadius(8).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red, lineWidth: 1))
                }
            }
            .padding(6)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "#0f172a"))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#ec4899"), lineWidth: 2))
            
            // Center Period
            VStack(spacing: 4) {
                Button(action: {
                    triggerHaptic()
                    FirebaseManager.shared.sendCommand("NEXT_SET")
                }) {
                    Text("FINE\nPERIODO")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .frame(width: 58, height: 64)
                        .background(Color(hex: "#facc15"))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white, lineWidth: 1.5))
                }
            }
            
            // Team Away Basket
            VStack(spacing: 6) {
                VStack(spacing: 4) {
                    Button("+1") { triggerHaptic(); FirebaseManager.shared.sendCommand("POINT_B") }
                        .font(.system(size: 18, weight: .black)).foregroundColor(.white).frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(hex: "#06b6d4")).cornerRadius(8).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white, lineWidth: 1))
                    Button("+2") { triggerHaptic(); FirebaseManager.shared.sendCommand("PLUS_2_B") }
                        .font(.system(size: 18, weight: .black)).foregroundColor(.white).frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(hex: "#06b6d4")).cornerRadius(8).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white, lineWidth: 1))
                    Button("+3") { triggerHaptic(); FirebaseManager.shared.sendCommand("PLUS_3_B") }
                        .font(.system(size: 18, weight: .black)).foregroundColor(.white).frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(hex: "#06b6d4")).cornerRadius(8).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white, lineWidth: 1))
                }
                
                Text("FALLI: \(matchState.foulsB)")
                    .font(.system(size: 14, weight: .bold)).foregroundColor(.red)
                
                Text("T.O.: \(getTimeoutDots(matchState.timeoutB))")
                    .font(.system(size: 11, weight: .bold)).foregroundColor(Color(hex: "#ffd000"))
                
                HStack(spacing: 4) {
                    Button("-1") { triggerHaptic(); FirebaseManager.shared.sendCommand("MINUS_B") }
                        .font(.system(size: 14, weight: .bold)).foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 44).background(Color(hex: "#2A2A2A")).cornerRadius(8).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#06b6d4"), lineWidth: 1))
                    Button("T.O.") { triggerHaptic(); FirebaseManager.shared.sendCommand("TIMEOUT_B") }
                        .font(.system(size: 12, weight: .bold)).foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 44).background(Color(hex: "#2A2A2A")).cornerRadius(8).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#facc15"), lineWidth: 1))
                    Button("+F") { triggerHaptic(); FirebaseManager.shared.sendCommand("FOUL_B") }
                        .font(.system(size: 12, weight: .bold)).foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 44).background(Color(hex: "#2A2A2A")).cornerRadius(8).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red, lineWidth: 1))
                }
            }
            .padding(6)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "#0f172a"))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#06b6d4"), lineWidth: 2))
        }
    }
    
    // MARK: - Soccer / Handball Controls
    
    private var soccerTimerButtonConfig: (title: String, icon: String, bg: Color) {
        let halfDurMin = (matchState.soccerHalfDuration > 0) ? matchState.soccerHalfDuration : 45
        let halfDurSec = halfDurMin * 60
        let regulationSec = halfDurSec * max(1, matchState.currentSet)
        
        if !matchState.timerRunning {
            let icon = "play.fill"
            let bg = Color(hex: "#10b981")
            if matchState.currentSet == 1 && matchState.timerSeconds == 0 {
                return ("AVVIA 1° TEMPO", icon, bg)
            } else if matchState.currentSet == 2 && matchState.timerSeconds == halfDurSec {
                return ("AVVIA 2° TEMPO", icon, bg)
            } else {
                return ("RIPRENDI TIMER", icon, bg)
            }
        } else {
            if matchState.timerSeconds >= regulationSec {
                let icon = "flag.checkered"
                if matchState.currentSet == 1 {
                    return ("FINE 1° TEMPO", icon, Color(hex: "#f59e0b"))
                } else {
                    return ("FINE PARTITA", icon, Color(hex: "#ef4444"))
                }
            } else {
                return ("PAUSA", "pause.fill", Color(hex: "#ef4444"))
            }
        }
    }
    
    var soccerControlsView: some View {
        let timerConfig = soccerTimerButtonConfig
        return VStack(spacing: 6) {
            // Timer Control Bar
            HStack(spacing: 8) {
                Button(action: {
                    triggerHaptic()
                    FirebaseManager.shared.sendCommand("SOCCER_TIMER_TOGGLE")
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: timerConfig.icon)
                        Text(timerConfig.title)
                            .font(.system(size: 13, weight: .black))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(timerConfig.bg)
                    .cornerRadius(8)
                }
                
                Button(action: {
                    triggerHaptic()
                    FirebaseManager.shared.sendCommand("SOCCER_TIMER_RESET")
                }) {
                    Text("🔄 RESET")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 80, height: 42)
                        .background(Color.white.opacity(0.12))
                        .cornerRadius(8)
                }
            }
            
            HStack(spacing: 8) {
                // Team A Goal
                VStack(spacing: 6) {
                    Button(action: {
                        triggerHaptic()
                        FirebaseManager.shared.sendCommand("POINT_A")
                    }) {
                        VStack(spacing: 4) {
                            Text("GOAL")
                                .font(.system(size: 16, weight: .bold))
                            Text("+1")
                                .font(.system(size: 32, weight: .black))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(hex: "#ec4899"))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white, lineWidth: 2))
                    }
                    
                    HStack(spacing: 6) {
                        Button("-1") { triggerHaptic(); FirebaseManager.shared.sendCommand("MINUS_A") }
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color(hex: "#2A2A2A"))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#ec4899"), lineWidth: 2))
                        
                        Button("RED") { triggerHaptic(); FirebaseManager.shared.sendCommand("RED_CARD_A") }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color(hex: "#CC0000"))
                            .cornerRadius(8)
                    }
                }
                .padding(6)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(hex: "#0f172a"))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#ec4899"), lineWidth: 2))
                
                // Team B Goal
                VStack(spacing: 6) {
                    Button(action: {
                        triggerHaptic()
                        FirebaseManager.shared.sendCommand("POINT_B")
                    }) {
                        VStack(spacing: 4) {
                            Text("GOAL")
                                .font(.system(size: 16, weight: .bold))
                            Text("+1")
                                .font(.system(size: 32, weight: .black))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(hex: "#06b6d4"))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white, lineWidth: 2))
                    }
                    
                    HStack(spacing: 6) {
                        Button("-1") { triggerHaptic(); FirebaseManager.shared.sendCommand("MINUS_B") }
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color(hex: "#2A2A2A"))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#06b6d4"), lineWidth: 2))
                        
                        Button("RED") { triggerHaptic(); FirebaseManager.shared.sendCommand("RED_CARD_B") }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color(hex: "#CC0000"))
                            .cornerRadius(8)
                    }
                }
                .padding(6)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(hex: "#0f172a"))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#06b6d4"), lineWidth: 2))
            }
        }
    }
    
    // MARK: - Tennis / Padel Controls
    var tennisControlsView: some SwiftUI.View {
        HStack(spacing: 8) {
            VStack(spacing: 6) {
                Button(action: { triggerHaptic(); FirebaseManager.shared.sendCommand("TENNIS_POINT_A") }) {
                    VStack(spacing: 4) {
                        Text(matchState.teamA.isEmpty ? "CASA" : matchState.teamA)
                            .font(.system(size: 16, weight: .bold))
                        Text("PUNTO +")
                            .font(.system(size: 20, weight: .black))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(hex: "#ec4899"))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white, lineWidth: 2))
                }
                
                HStack(spacing: 4) {
                    Button("-1") { triggerHaptic(); FirebaseManager.shared.sendCommand("TENNIS_MINUS_A") }
                        .font(.system(size: 14, weight: .bold)).foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 44).background(Color(hex: "#2A2A2A")).cornerRadius(8).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#ec4899"), lineWidth: 1))
                    Button("+G") { triggerHaptic(); FirebaseManager.shared.sendCommand("TENNIS_GAME_A") }
                        .font(.system(size: 14, weight: .bold)).foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 44).background(Color(hex: "#2A2A2A")).cornerRadius(8).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#facc15"), lineWidth: 1))
                    Button("+S") { triggerHaptic(); FirebaseManager.shared.sendCommand("NEXT_SET") }
                        .font(.system(size: 14, weight: .bold)).foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 44).background(Color(hex: "#2A2A2A")).cornerRadius(8).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#06b6d4"), lineWidth: 1))
                }
            }
            .padding(6)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "#0f172a"))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#ec4899"), lineWidth: 2))
            
            VStack(spacing: 6) {
                Button(action: { triggerHaptic(); FirebaseManager.shared.sendCommand("TENNIS_POINT_B") }) {
                    VStack(spacing: 4) {
                        Text(matchState.teamB.isEmpty ? "OSPITE" : matchState.teamB)
                            .font(.system(size: 16, weight: .bold))
                        Text("PUNTO +")
                            .font(.system(size: 20, weight: .black))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(hex: "#06b6d4"))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white, lineWidth: 2))
                }
                
                HStack(spacing: 4) {
                    Button("-1") { triggerHaptic(); FirebaseManager.shared.sendCommand("TENNIS_MINUS_B") }
                        .font(.system(size: 14, weight: .bold)).foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 44).background(Color(hex: "#2A2A2A")).cornerRadius(8).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#06b6d4"), lineWidth: 1))
                    Button("+G") { triggerHaptic(); FirebaseManager.shared.sendCommand("TENNIS_GAME_B") }
                        .font(.system(size: 14, weight: .bold)).foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 44).background(Color(hex: "#2A2A2A")).cornerRadius(8).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#facc15"), lineWidth: 1))
                    Button("+S") { triggerHaptic(); FirebaseManager.shared.sendCommand("NEXT_SET") }
                        .font(.system(size: 14, weight: .bold)).foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 44).background(Color(hex: "#2A2A2A")).cornerRadius(8).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "#06b6d4"), lineWidth: 1))
                }
            }
            .padding(6)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "#0f172a"))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#06b6d4"), lineWidth: 2))
        }
    }
    
    // MARK: - Darts (Freccette) Controls con Tastierino Calcolatrice
    var dartsControlsView: some View {
        VStack(spacing: 6) {
            // Player Switcher & Current Scores
            HStack(spacing: 8) {
                // Giocatore CASA
                Button(action: {
                    triggerHaptic()
                    selectedDartsPlayer = "A"
                    FirebaseManager.shared.sendCommand("DARTS_SET_PLAYER_A")
                }) {
                    VStack(spacing: 2) {
                        Text(matchState.teamA.isEmpty ? "GIOCATORE 1" : matchState.teamA)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text("\(matchState.scoreA)")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(Color(hex: "#ec4899"))
                        Text("Legs: \(matchState.dartsLegsA)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.yellow)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(4)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke((matchState.dartsActivePlayer == "A" || selectedDartsPlayer == "A") ? Color(hex: "#ec4899") : Color.clear, lineWidth: 2))
                }
                
                // Giocatore OSPITE
                Button(action: {
                    triggerHaptic()
                    selectedDartsPlayer = "B"
                    FirebaseManager.shared.sendCommand("DARTS_SET_PLAYER_B")
                }) {
                    VStack(spacing: 2) {
                        Text(matchState.teamB.isEmpty ? "GIOCATORE 2" : matchState.teamB)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text("\(matchState.scoreB)")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(Color(hex: "#06b6d4"))
                        Text("Legs: \(matchState.dartsLegsB)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.yellow)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(4)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke((matchState.dartsActivePlayer == "B" || selectedDartsPlayer == "B") ? Color(hex: "#06b6d4") : Color.clear, lineWidth: 2))
                }
            }
            
            // Display Valore Calcolatrice
            HStack {
                Text("Punti lancio:")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "#94a3b8"))
                Spacer()
                Text(dartsInput.isEmpty ? "0" : dartsInput)
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(6)
            }
            
            // Tastiera Calcolatrice (1-9, C, 0, Canc)
            VStack(spacing: 3) {
                let rows = [
                    ["1", "2", "3"],
                    ["4", "5", "6"],
                    ["7", "8", "9"],
                    ["C", "0", "⌫"]
                ]
                ForEach(rows, id: \.self) { row in
                    HStack(spacing: 3) {
                        ForEach(row, id: \.self) { key in
                            Button(action: {
                                triggerHaptic()
                                if key == "C" {
                                    dartsInput = ""
                                } else if key == "⌫" {
                                    if !dartsInput.isEmpty { dartsInput.removeLast() }
                                } else {
                                    if dartsInput.count < 3 {
                                        let candidate = dartsInput + key
                                        if let val = Int(candidate), val <= 180 {
                                            dartsInput = candidate
                                        }
                                    }
                                }
                            }) {
                                Text(key)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(key == "C" ? .red : (key == "⌫" ? .yellow : .white))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 32)
                                    .background(Color.white.opacity(0.12))
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
            }
            
            // Tasti Azione: SOTTRAI, BUST, +LEG
            HStack(spacing: 4) {
                Button(action: {
                    triggerHaptic()
                    let pts = Int(dartsInput) ?? 0
                    if pts > 0 {
                        let player = (selectedDartsPlayer == "B" || matchState.dartsActivePlayer == "B") ? "B" : "A"
                        FirebaseManager.shared.sendCommand("DARTS_SUB_\(pts)_\(player)")
                        dartsInput = ""
                    }
                }) {
                    Text("🎯 SOTTRAI \(dartsInput.isEmpty ? "" : dartsInput)")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Color(hex: "#06B6D4"))
                        .cornerRadius(8)
                }
                
                Button(action: {
                    triggerHaptic()
                    FirebaseManager.shared.sendCommand("DARTS_BUST")
                    dartsInput = ""
                }) {
                    Text("BUST")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .frame(height: 36)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                }
                
                Button(action: {
                    triggerHaptic()
                    let player = (selectedDartsPlayer == "B" || matchState.dartsActivePlayer == "B") ? "B" : "A"
                    FirebaseManager.shared.sendCommand("DARTS_LEG_\(player)")
                }) {
                    Text("+LEG")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .frame(height: 36)
                        .background(Color.yellow)
                        .cornerRadius(8)
                }
            }
        }
        .padding(6)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Bottom Broadcast Bar (TEXT, HL, REP, Audio, S1-S4) (1:1 with Android Photo 2)
    var bottomBroadcastBar: some View {
        VStack(spacing: 6) {
            // Row 1: Directing Actions (TEXT, HL, REP, Audio Mute)
            HStack(spacing: 6) {
                // News Ticker / Text
                Button(action: {
                    triggerHaptic()
                    FirebaseManager.shared.sendCommand("TOGGLE_TEXT")
                }) {
                    Text("TEXT")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(matchState.showScrollText ? Color.black : Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(matchState.showScrollText ? Color(hex: "#facc15") : Color(hex: "#2A2A2A"))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "#06b6d4"), lineWidth: 2)
                        )
                }
                
                // Highlight Marker
                Button(action: {
                    triggerHaptic()
                    FirebaseManager.shared.sendCommand("HIGHLIGHT")
                }) {
                    Text("HL")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "#facc15"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color(hex: "#2A2A2A"))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "#facc15"), lineWidth: 2)
                        )
                }
                
                // Instant Replay (Always visible)
                Button(action: {
                    triggerHaptic()
                    FirebaseManager.shared.sendCommand("INSTANT_REPLAY")
                }) {
                    Text("REP")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color(hex: "#2563eb"))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white, lineWidth: 2)
                        )
                }
                
                // Audio Toggle
                Button(action: {
                    triggerHaptic()
                    FirebaseManager.shared.sendCommand("TOGGLE_MUTE")
                }) {
                    Text(matchState.isMuted ? "🔇" : "🔊")
                        .font(.system(size: 20))
                        .frame(width: 48, height: 48)
                        .background(Color(hex: "#2A2A2A"))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(matchState.isMuted ? Color.red : Color(hex: "#facc15"), lineWidth: 2)
                        )
                }
            }
            
            // Row 2: Sponsor Banners (S1, S2, S3, S4)
            HStack(spacing: 6) {
                ForEach(1...4, id: \.self) { index in
                    let isSelected = matchState.showSponsor && (matchState.currentSponsorIdx == index - 1)
                    Button(action: {
                        triggerHaptic()
                        if isSelected {
                            FirebaseManager.shared.sendCommand("TOGGLE_SPONSOR")
                        } else {
                            FirebaseManager.shared.sendCommand("SPONSOR_\(index)")
                        }
                    }) {
                        Text("S\(index)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(isSelected ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(isSelected ? Color(hex: "#facc15") : Color(hex: "#2A2A2A"))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(hex: "#facc15"), lineWidth: 2)
                            )
                    }
                }
            }
        }
        .padding(6)
        .background(Color(hex: "#0f172a"))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: "#facc15"), lineWidth: 2)
        )
    }
    
    // MARK: - Helper Methods
    private func getTimeoutDots(_ count: Int) -> String {
        switch count {
        case 2:
            return "● ●"
        case 1:
            return "● ○"
        default:
            return "○ ○"
        }
    }
    
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

