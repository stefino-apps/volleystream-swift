import SwiftUI

struct AppTheme {
    static let primaryRed = Color(red: 0.85, green: 0.15, blue: 0.15)
    static let darkBackground = Color(red: 0.1, green: 0.1, blue: 0.12)
    static let panelBackground = Color(red: 0.15, green: 0.15, blue: 0.18)
    static let textHighlight = Color.yellow
    
    // Gradienti usati in Android
    static let neonGradient = LinearGradient(
        gradient: Gradient(colors: [primaryRed, Color.orange]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension Color {
    static let vspRed = AppTheme.primaryRed
    static let vspDark = AppTheme.darkBackground
    static let vspPanel = AppTheme.panelBackground
}

// Utility per localizzazione rapida nelle view SwiftUI
extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}
