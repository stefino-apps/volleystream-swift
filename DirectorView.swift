import SwiftUI

struct DirectorView: UIViewControllerRepresentable {
    var sport: String = AppPreferences.shared.selectedSport
    var theme: String = AppPreferences.shared.selectedTheme
    var onDismiss: (() -> Void)? = nil

    func makeUIViewController(context: Context) -> MainViewController {
        let vc = MainViewController()
        vc.initialSport = AppPreferences.shared.selectedSport
        vc.initialTheme = AppPreferences.shared.selectedTheme
        vc.onDismissRequested = onDismiss
        return vc
    }

    func updateUIViewController(_ uiViewController: MainViewController, context: Context) {
        if uiViewController.isViewLoaded {
            uiViewController.refreshMatchState()
        }
    }
}

