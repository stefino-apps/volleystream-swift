import SwiftUI

struct DirectorView: UIViewControllerRepresentable {
    var sport: String = "volley"
    var theme: String = "neon"

    func makeUIViewController(context: Context) -> MainViewController {
        let vc = MainViewController()
        vc.initialSport = sport
        vc.initialTheme = theme
        return vc
    }

    func updateUIViewController(_ uiViewController: MainViewController, context: Context) {
        // Aggiorna parametri se necessario
    }
}

