import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let url = connectionOptions.urlContexts.first?.url {
            handleURL(url)
        }
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        let welcomeView = WelcomeView()
        window.rootViewController = UIHostingController(rootView: welcomeView)
        self.window = window
        window.makeKeyAndVisible()
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            handleURL(url)
        }
    }
    
    private func handleURL(_ url: URL) {
        guard url.scheme == "volleypro", url.host == "remote" else { return }
        
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let code = components.queryItems?.first(where: { $0.name == "code" })?.value {
            UserDefaults.standard.set(code, forKey: "incoming_remote_id")
            // Notifica l'app del cambiamento per navigare al telecomando
            NotificationCenter.default.post(name: NSNotification.Name("OpenRemoteControl"), object: nil)
        }
    }
}
