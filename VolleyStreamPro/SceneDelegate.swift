import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        // Usa WelcomeView come root (SwiftUI)
        let welcomeView = WelcomeView()
        window.rootViewController = UIHostingController(rootView: welcomeView)
        self.window = window
        window.makeKeyAndVisible()
    }
}
