import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Usa questa classe per configurare la finestra (Window) e il View Controller iniziale.
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        // Imposta MainViewController come root (Regia Principale)
        window.rootViewController = MainViewController()
        self.window = window
        window.makeKeyAndVisible()
    }
}
