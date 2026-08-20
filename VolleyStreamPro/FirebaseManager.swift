import Foundation
import FirebaseDatabase
import FirebaseAuth

class FirebaseManager {
    static let shared = FirebaseManager()
    
    private var ref: DatabaseReference!
    
    // Callbacks per aggiornare la UI
    var onScoreUpdate: ((Int, Int) -> Void)?
    var onSetsUpdate: ((Int, Int) -> Void)?
    var onTeamNamesUpdate: ((String, String) -> Void)?
    var onShowReplay: (() -> Void)?
    
    private init() {
        ref = Database.database().reference()
    }
    
    func authenticateAnonymously(completion: @escaping (Bool) -> Void) {
        Auth.auth().signInAnonymously { authResult, error in
            if let error = error {
                print("Firebase Auth Error: \(error.localizedDescription)")
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    func startListeningToMatch(matchId: String) {
        let matchRef = ref.child("matches").child(matchId)
        
        // Ascolta Punti
        matchRef.child("score").observe(.value) { snapshot in
            if let value = snapshot.value as? [String: Int],
               let home = value["home"], let away = value["away"] {
                self.onScoreUpdate?(home, away)
            }
        }
        
        // Ascolta Set
        matchRef.child("sets").observe(.value) { snapshot in
            if let value = snapshot.value as? [String: Int],
               let home = value["home"], let away = value["away"] {
                self.onSetsUpdate?(home, away)
            }
        }
        
        // Ascolta Nomi Squadre
        matchRef.child("teams").observe(.value) { snapshot in
            if let value = snapshot.value as? [String: String],
               let home = value["home"], let away = value["away"] {
                self.onTeamNamesUpdate?(home, away)
            }
        }
        
        // Ascolta trigger Replay
        matchRef.child("actions").child("triggerReplay").observe(.value) { snapshot in
            if let trigger = snapshot.value as? Bool, trigger == true {
                self.onShowReplay?()
                // Resetta il trigger
                matchRef.child("actions").child("triggerReplay").setValue(false)
            }
        }
    }
    
    func stopListening(matchId: String) {
        ref.child("matches").child(matchId).removeAllObservers()
    }
}
