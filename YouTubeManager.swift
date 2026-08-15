import Foundation
import UIKit
import GoogleSignIn

public class YouTubeManager: NSObject {
    public static let shared = YouTubeManager()
    
    public var userEmail: String?
    public var accessToken: String?
    
    private override init() {
        super.init()
    }
    
    public func signIn(presentingViewController: UIViewController, completion: @escaping (Bool, Error?) -> Void) {
        let scopes = [
            "https://www.googleapis.com/auth/youtube",
            "https://www.googleapis.com/auth/youtube.force-ssl",
            "https://www.googleapis.com/auth/youtube.readonly"
        ]
        
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController, hint: nil, additionalScopes: scopes) { result, error in
            if let error = error {
                completion(false, error)
                return
            }
            
            guard let result = result else {
                completion(false, nil)
                return
            }
            
            self.userEmail = result.user.profile?.email
            self.accessToken = result.user.accessToken.tokenString
            completion(true, nil)
        }
    }
    
    public func signOut() {
        GIDSignIn.sharedInstance.signOut()
        self.userEmail = nil
        self.accessToken = nil
    }
}
