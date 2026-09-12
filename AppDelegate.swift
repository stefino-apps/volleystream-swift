import UIKit
import FirebaseDatabase
import FirebaseAuth
import GoogleSignIn
import SwiftUI

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    // Default: allow portrait and landscape for menus, locked to landscape in Regia
    static var orientationLock = UIInterfaceOrientationMask.allButUpsideDown

    func application(_ application: UIApplication, 
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }

    func application(_ application: UIApplication, 
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Inizializza Firebase
        FirebaseApp.configure()
        
        // Ripristina sessione YouTube / Google persistente
        YouTubeManager.shared.restoreSession()
        
        // Fallback per iOS che non carica SceneDelegate
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIHostingController(rootView: WelcomeView())
        window.makeKeyAndVisible()
        self.window = window
        
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
        let config = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
    
    // MARK: - Orientation Lock Helper
    static func setOrientationLock(_ orientation: UIInterfaceOrientationMask, rotateTo: UIInterfaceOrientation = .landscapeRight) {
        AppDelegate.orientationLock = orientation
        
        DispatchQueue.main.async {
            if #available(iOS 16.0, *) {
                let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
                let activeScene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first
                
                if let scene = activeScene {
                    let geometryPref = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: orientation)
                    scene.requestGeometryUpdate(geometryPref) { error in
                        print("Failed to request geometry update: \(error.localizedDescription)")
                    }
                }
                
                scenes.forEach { scene in
                    scene.windows.forEach { window in
                        window.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
                        window.rootViewController?.presentedViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
                    }
                }
            } else {
                UIDevice.current.setValue(rotateTo.rawValue, forKey: "orientation")
                UIViewController.attemptRotationToDeviceOrientation()
            }
        }
    }
}
