import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let url = connectionOptions.urlContexts.first?.url {
            handleURL(url)
        }
        if let userActivity = connectionOptions.userActivities.first,
           userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL {
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
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL {
            handleURL(url)
        }
    }
    
    private func handleURL(_ url: URL) {
        print("SceneDelegate handling URL: \(url.absoluteString)")
        var extractedCode: String?
        
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            extractedCode = components.queryItems?.first(where: { $0.name == "code" || $0.name == "id" })?.value
        }
        
        if extractedCode == nil || extractedCode?.isEmpty == true {
            let lastSegment = url.lastPathComponent
            if !lastSegment.isEmpty && lastSegment != "remote" && lastSegment != "/" {
                extractedCode = lastSegment
            }
        }
        
        if let code = extractedCode, !code.isEmpty {
            let cleanCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            print("SceneDelegate extracted remote code: \(cleanCode)")
            UserDefaults.standard.set(cleanCode, forKey: "incoming_remote_id")
            NotificationCenter.default.post(name: NSNotification.Name("OpenRemoteControl"), object: nil)
        }
    }
}
