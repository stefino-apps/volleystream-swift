import UIKit
import FirebaseCore
import GoogleSignIn

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, 
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Inizializza Firebase
        FirebaseApp.configure()
        return true
    }

    func application(_ app: UIApplication, 
                     open url: URL, 
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Gestione del redirect per il login Google
        return GIDSignIn.sharedInstance.handle(url)
    }

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, 
                     configurationForConnecting connectingSceneSession: UISceneSession, 
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
