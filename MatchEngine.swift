import Foundation
import Combine

class MatchEngine: ObservableObject {
    @Published var sportType: String
    
    // Punteggi Universali
    @Published var homeScore = 0
    @Published var awayScore = 0
    
    // Volley, Padel, Tennis
    @Published var homeSets = 0
    @Published var awaySets = 0
    @Published var previousSets: [(Int, Int)] = []
    
    // Tennis / Padel
    @Published var homeGameScore = 0 // 0=0, 1=15, 2=30, 3=40, 4=A
    @Published var awayGameScore = 0
    
    // Calcio, Basket, Pallamano
    @Published var period = 1 // 1 Tempo, 2 Tempo ecc
    @Published var timerSeconds = 0
    @Published var isTimerRunning = false
    
    private var timer: Timer?
    
    init(sportType: String) {
        self.sportType = sportType
    }
    
    func changeSport(_ newSport: String) {
        self.sportType = newSport
        resetMatch()
    }
    
    func resetMatch() {
        homeScore = 0
        awayScore = 0
        homeSets = 0
        awaySets = 0
        previousSets.removeAll()
        homeGameScore = 0
        awayGameScore = 0
        period = 1
        timerSeconds = 0
        stopTimer()
    }
    
    // MARK: - Cronometro
    func toggleTimer() {
        if isTimerRunning {
            stopTimer()
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        isTimerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.timerSeconds += 1
        }
    }
    
    private func stopTimer() {
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Azioni Punteggio
    func addPointHome(points: Int = 1) {
        if sportType == "tennis" || sportType == "padel" {
            advanceTennisGame(isHome: true)
        } else {
            homeScore += points
            checkVolleyLogic()
        }
    }
    
    func subtractPointHome(points: Int = 1) {
        if sportType == "tennis" || sportType == "padel" {
            if homeGameScore > 0 { homeGameScore -= 1 }
        } else {
            if homeScore >= points { homeScore -= points }
        }
    }
    
    func addPointAway(points: Int = 1) {
        if sportType == "tennis" || sportType == "padel" {
            advanceTennisGame(isHome: false)
        } else {
            awayScore += points
            checkVolleyLogic()
        }
    }
    
    func subtractPointAway(points: Int = 1) {
        if sportType == "tennis" || sportType == "padel" {
            if awayGameScore > 0 { awayGameScore -= 1 }
        } else {
            if awayScore >= points { awayScore -= points }
        }
    }
    
    // MARK: - Logiche Specifiche
    
    private func checkVolleyLogic() {
        if sportType != "volley" { return }
        let target = (homeSets + awaySets == 4) ? 15 : 25
        if homeScore >= target && (homeScore - awayScore) >= 2 {
            previousSets.append((homeScore, awayScore))
            homeSets += 1
            homeScore = 0
            awayScore = 0
        } else if awayScore >= target && (awayScore - homeScore) >= 2 {
            previousSets.append((homeScore, awayScore))
            awaySets += 1
            homeScore = 0
            awayScore = 0
        }
    }
    
    private func advanceTennisGame(isHome: Bool) {
        // Logica semplificata Tennis
        if isHome {
            if homeGameScore == 3 && awayGameScore == 3 {
                homeGameScore = 4 // Vantaggio
            } else if homeGameScore == 3 && awayGameScore == 4 {
                awayGameScore = 3 // Parita'
            } else if homeGameScore == 3 || homeGameScore == 4 {
                // Vittoria Game
                homeSets += 1 // In un vero engine si calcolerebbero i set (es. 6-4)
                homeGameScore = 0
                awayGameScore = 0
            } else {
                homeGameScore += 1
            }
        } else {
            if awayGameScore == 3 && homeGameScore == 3 {
                awayGameScore = 4
            } else if awayGameScore == 3 && homeGameScore == 4 {
                homeGameScore = 3
            } else if awayGameScore == 3 || awayGameScore == 4 {
                awaySets += 1
                homeGameScore = 0
                awayGameScore = 0
            } else {
                awayGameScore += 1
            }
        }
    }
    
    func formatTennisScore(_ score: Int) -> String {
        switch score {
        case 0: return "0"
        case 1: return "15"
        case 2: return "30"
        case 3: return "40"
        case 4: return "A"
        default: return "0"
        }
    }
    
    func formatTime() -> String {
        let min = timerSeconds / 60
        let sec = timerSeconds % 60
        return String(format: "%02d:%02d", min, sec)
    }
}
