import SwiftUI

struct DirectorView: View {
    @StateObject private var engine = MatchEngine(sportType: AppPreferences.shared.sportType)
    
    // Nomi squadre presi da Preferences
    private let homeName = AppPreferences.shared.teamHome
    private let awayName = AppPreferences.shared.teamAway
    
    // Stato per sponsor a tutto schermo
    @State private var showFullScreenSponsor = false
    
    // Per nascondere l'interfaccia (Modalita Clean)
    @State private var isUIHidden = false
    
    @ObservedObject private var streamManager = StreamManager.shared
    
    // Sponsor rotanti
    @State private var currentSponsorIndex = 0
    let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            CameraPreviewView()
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation { isUIHidden.toggle() }
                }
            
            VStack {
                HStack(alignment: .top) {
                    ScoreboardView(
                        engine: engine,
                        homeName: homeName, 
                        awayName: awayName
                    )
                    .padding(.top, 20)
                    .padding(.leading, 20)
                    
                    Spacer()
                    
                    RotatingSponsorView(currentIndex: currentSponsorIndex)
                        .padding(.top, 20)
                        .padding(.trailing, 20)
                }
                
                Spacer()
                
                if AppPreferences.shared.tickerEnabled {
                    MarqueeText(text: AppPreferences.shared.tickerText, font: .systemFont(ofSize: 18, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                        .background(Color.white.opacity(0.9))
                        .foregroundColor(.black)
                }
            }
            
            if showFullScreenSponsor {
                if let data = AppPreferences.shared.sponsorFullScreenData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .edgesIgnoringSafeArea(.all)
                        .transition(.opacity)
                }
            }
            
            if !isUIHidden {
                VStack {
                    HStack {
                        Spacer()
                        HStack(spacing: 15) {
                            Button("Sponsor FS") { withAnimation { showFullScreenSponsor.toggle() } }
                                .buttonStyle(TopBarButtonStyle(color: showFullScreenSponsor ? .green : .gray))
                            Button(streamManager.isRecording ? "STOP REC" : "REC") {
                                streamManager.toggleRecording()
                            }
                            .buttonStyle(TopBarButtonStyle(color: streamManager.isRecording ? .red : .gray))
                            
                            Button("btn_replay".localized) { streamManager.saveReplayClip() }
                                .buttonStyle(TopBarButtonStyle(color: .blue))
                            Button("stop_live".localized) { streamManager.stopStreaming() }
                                .buttonStyle(TopBarButtonStyle(color: .red))
                        }
                        .padding(.top, 80)
                        .padding(.trailing, 20)
                    }
                    
                    Spacer()
                    
                    HStack {
                        ScoreControlPanel(team: homeName, engine: engine, isHome: true)
                        Spacer()
                        
                        // Controlli Centrali (Timer, ecc)
                        if engine.sportType == "soccer" || engine.sportType == "handball" || engine.sportType == "basket" {
                            VStack {
                                Button(engine.isTimerRunning ? "Pausa Timer" : "Avvia Timer") {
                                    engine.toggleTimer()
                                }
                                .font(.headline)
                                .padding()
                                .background(engine.isTimerRunning ? Color.orange : Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        }
                        
                        Spacer()
                        ScoreControlPanel(team: awayName, engine: engine, isHome: false)
                    }
                    .padding()
                    .padding(.bottom, AppPreferences.shared.tickerEnabled ? 30 : 0)
                }
            }
        }
        .navigationBarHidden(true)
        .onReceive(timer) { _ in
            withAnimation { currentSponsorIndex = (currentSponsorIndex + 1) % 2 }
        }
        .onAppear {
            if engine.sportType != AppPreferences.shared.sportType {
                engine.changeSport(AppPreferences.shared.sportType)
            }
        }
    }
}

struct RotatingSponsorView: View {
    var currentIndex: Int
    var body: some View {
        Group {
            if currentIndex == 0, let data = AppPreferences.shared.sponsor1Data, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage).resizable().scaledToFit().frame(height: 50).transition(.opacity)
            } else if currentIndex == 1, let data = AppPreferences.shared.sponsor2Data, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage).resizable().scaledToFit().frame(height: 50).transition(.opacity)
            }
        }
    }
}

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

struct ScoreControlPanel: View {
    var team: String
    @ObservedObject var engine: MatchEngine
    var isHome: Bool
    
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
                Button(action: { 
                    withAnimation { isHome ? engine.subtractPointHome() : engine.subtractPointAway() }
                }) {
                    Image(systemName: "minus.circle.fill").font(.system(size: 40)).foregroundColor(.gray)
                }
                
                Button(action: { 
                    withAnimation { isHome ? engine.addPointHome() : engine.addPointAway() }
                }) {
                    Image(systemName: "plus.circle.fill").font(.system(size: 60)).foregroundColor(.green)
                }
            }
        }
    }
}

struct CameraPreviewView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .black
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct ScoreboardView: View {
    @ObservedObject var engine: MatchEngine
    var homeName: String
    var awayName: String
    
    var body: some View {
        HStack(spacing: 0) {
            // Nomi
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    if let data = AppPreferences.shared.homeLogoData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage).resizable().scaledToFit().frame(width: 20, height: 20)
                    }
                    Text(homeName).font(.system(size: 16, weight: .bold)).foregroundColor(.white).lineLimit(1)
                }
                .padding(.vertical, 4).padding(.horizontal, 8).frame(width: 150, alignment: .leading).background(Color.vspRed)
                
                HStack(spacing: 4) {
                    if let data = AppPreferences.shared.awayLogoData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage).resizable().scaledToFit().frame(width: 20, height: 20)
                    }
                    Text(awayName).font(.system(size: 16, weight: .bold)).foregroundColor(.white).lineLimit(1)
                }
                .padding(.vertical, 4).padding(.horizontal, 8).frame(width: 150, alignment: .leading).background(Color.blue)
            }
            
            // Logica Punteggio per Sport
            if engine.sportType == "soccer" || engine.sportType == "handball" || engine.sportType == "basket" {
                // Calcio/Basket: Mostra Punteggio Centrale e Timer
                VStack(spacing: 0) {
                    Text("\(engine.homeScore)").font(.system(size: 16, weight: .bold)).foregroundColor(.yellow).padding(.vertical, 4).frame(width: 40).background(Color.vspDark)
                    Text("\(engine.awayScore)").font(.system(size: 16, weight: .bold)).foregroundColor(.yellow).padding(.vertical, 4).frame(width: 40).background(Color.vspDark)
                }
                VStack(spacing: 0) {
                    Text(engine.formatTime())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 4)
                        .frame(width: 60)
                        .background(Color.gray)
                }
                
            } else if engine.sportType == "tennis" || engine.sportType == "padel" {
                // Tennis: Mostra Set vinti e Game Score (15, 30, 40)
                VStack(spacing: 0) {
                    Text("\(engine.homeSets)").font(.system(size: 16, weight: .bold)).foregroundColor(.white).padding(.vertical, 4).frame(width: 30).background(Color.gray)
                    Text("\(engine.awaySets)").font(.system(size: 16, weight: .bold)).foregroundColor(.white).padding(.vertical, 4).frame(width: 30).background(Color.gray)
                }
                VStack(spacing: 0) {
                    Text(engine.formatTennisScore(engine.homeGameScore)).font(.system(size: 16, weight: .bold)).foregroundColor(.yellow).padding(.vertical, 4).frame(width: 40).background(Color.vspDark)
                    Text(engine.formatTennisScore(engine.awayGameScore)).font(.system(size: 16, weight: .bold)).foregroundColor(.yellow).padding(.vertical, 4).frame(width: 40).background(Color.vspDark)
                }
                
            } else {
                // Volley: Mostra Storico Set, Punti Correnti e Set Vinti
                ForEach(engine.previousSets, id: \.self.0) { set in
                    VStack(spacing: 0) {
                        Text("\(set.0)").font(.system(size: 16, weight: .bold)).foregroundColor(.gray).padding(.vertical, 4).frame(width: 30).background(Color.black.opacity(0.8))
                        Text("\(set.1)").font(.system(size: 16, weight: .bold)).foregroundColor(.gray).padding(.vertical, 4).frame(width: 30).background(Color.black.opacity(0.8))
                    }
                }
                
                VStack(spacing: 0) {
                    Text("\(engine.homeScore)").font(.system(size: 16, weight: .bold)).foregroundColor(.yellow).padding(.vertical, 4).frame(width: 40).background(Color.vspDark)
                    Text("\(engine.awayScore)").font(.system(size: 16, weight: .bold)).foregroundColor(.yellow).padding(.vertical, 4).frame(width: 40).background(Color.vspDark)
                }
                
                VStack(spacing: 0) {
                    Text("\(engine.homeSets)").font(.system(size: 16, weight: .bold)).foregroundColor(.white).padding(.vertical, 4).frame(width: 30).background(Color.gray)
                    Text("\(engine.awaySets)").font(.system(size: 16, weight: .bold)).foregroundColor(.white).padding(.vertical, 4).frame(width: 30).background(Color.gray)
                }
            }
        }
        .cornerRadius(6)
        .shadow(radius: 5)
    }
}

struct MarqueeText: View {
    let text: String
    let font: UIFont
    @State private var offsetX: CGFloat = 0
    var body: some View {
        GeometryReader { geometry in
            Text(text)
                .font(Font(font))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .offset(x: offsetX)
                .onAppear {
                    let textWidth = text.size(withAttributes: [.font: font]).width
                    let containerWidth = geometry.size.width
                    if textWidth > containerWidth {
                        offsetX = containerWidth
                        withAnimation(Animation.linear(duration: Double(textWidth) / 30.0).repeatForever(autoreverses: false)) {
                            offsetX = -textWidth
                        }
                    } else {
                        offsetX = (containerWidth - textWidth) / 2
                    }
                }
        }
        .clipped()
    }
}
