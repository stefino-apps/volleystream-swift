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
    
    public func disconnect() {
        signOut()
    }
    
    public func createLiveEvent(title: String, completion: @escaping (String?, String?, Error?) -> Void) {
        guard let token = accessToken else {
            completion(nil, nil, NSError(domain: "YouTube", code: 401, userInfo: [NSLocalizedDescriptionKey: "Non autenticato"]))
            return
        }
        
        let broadcastUrl = URL(string: "https://youtube.googleapis.com/youtube/v3/liveBroadcasts?part=snippet,status,contentDetails")!
        var bReq = URLRequest(url: broadcastUrl)
        bReq.httpMethod = "POST"
        bReq.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        bReq.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let startTime = Date().addingTimeInterval(300)
        let formatter = ISO8601DateFormatter()
        let bBody: [String: Any] = [
            "snippet": ["title": title, "scheduledStartTime": formatter.string(from: startTime)],
            "status": ["privacyStatus": "unlisted"]
        ]
        bReq.httpBody = try? JSONSerialization.data(withJSONObject: bBody)
        
        URLSession.shared.dataTask(with: bReq) { data, _, err in
            if let err = err { completion(nil, nil, err); return }
            guard let data = data,
                  let bJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let broadcastId = bJson["id"] as? String else {
                completion(nil, nil, NSError(domain: "YouTube", code: 500, userInfo: [NSLocalizedDescriptionKey: "Errore Broadcast"]))
                return
            }
            
            self.createStream(token: token, title: title) { streamId, rtmpUrl, streamKey, sErr in
                if let sErr = sErr { completion(nil, nil, sErr); return }
                guard let streamId = streamId, let rtmpUrl = rtmpUrl, let streamKey = streamKey else {
                    completion(nil, nil, NSError(domain: "YouTube", code: 500, userInfo: [NSLocalizedDescriptionKey: "Errore Stream"]))
                    return
                }
                
                self.bindBroadcast(token: token, broadcastId: broadcastId, streamId: streamId) { bindErr in
                    if let bindErr = bindErr { completion(nil, nil, bindErr); return }
                    completion(rtmpUrl, streamKey, nil)
                }
            }
        }.resume()
    }
    
    private func createStream(token: String, title: String, completion: @escaping (String?, String?, String?, Error?) -> Void) {
        let streamUrl = URL(string: "https://youtube.googleapis.com/youtube/v3/liveStreams?part=snippet,cdn,contentDetails")!
        var sReq = URLRequest(url: streamUrl)
        sReq.httpMethod = "POST"
        sReq.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        sReq.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let sBody: [String: Any] = [
            "snippet": ["title": title],
            "cdn": ["frameRate": "60fps", "ingestionType": "rtmp", "resolution": "1080p"]
        ]
        sReq.httpBody = try? JSONSerialization.data(withJSONObject: sBody)
        
        URLSession.shared.dataTask(with: sReq) { data, _, err in
            if let err = err { completion(nil, nil, nil, err); return }
            guard let data = data,
                  let sJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let streamId = sJson["id"] as? String,
                  let cdn = sJson["cdn"] as? [String: Any],
                  let ingestion = cdn["ingestionInfo"] as? [String: Any],
                  let streamName = ingestion["streamName"] as? String,
                  let ingestionAddress = ingestion["ingestionAddress"] as? String else {
                completion(nil, nil, nil, NSError(domain: "YouTube", code: 500, userInfo: [NSLocalizedDescriptionKey: "Errore creazione Stream"]))
                return
            }
            completion(streamId, ingestionAddress, streamName, nil)
        }.resume()
    }
    
    private func bindBroadcast(token: String, broadcastId: String, streamId: String, completion: @escaping (Error?) -> Void) {
        let bindUrl = URL(string: "https://youtube.googleapis.com/youtube/v3/liveBroadcasts/bind?id=\(broadcastId)&streamId=\(streamId)&part=id,contentDetails")!
        var bReq = URLRequest(url: bindUrl)
        bReq.httpMethod = "POST"
        bReq.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: bReq) { _, _, err in
            completion(err)
        }.resume()
    }
}
