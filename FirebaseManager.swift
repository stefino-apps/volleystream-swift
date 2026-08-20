import Foundation
import FirebaseDatabase
import FirebaseAuth

class FirebaseManager {
    static let shared = FirebaseManager()
    
    private var ref: DatabaseReference!
    var sessionId: String?
    var isHost: Bool = true
    
    // Callbacks
    var onStateUpdated: ((RemoteMatchState) -> Void)?
    var onCommandReceived: ((String) -> Void)?
    var onError: ((String) -> Void)?
    
    private init() {
        ref = Database.database().reference()
    }
    
    func ensureAuth(completion: @escaping (String?) -> Void) {
        if let user = Auth.auth().currentUser {
            completion(user.uid)
        } else {
            Auth.auth().signInAnonymously { authResult, error in
                if let error = error {
                    print("Firebase Auth Error: \(error.localizedDescription)")
                    self.onError?(error.localizedDescription)
                    completion(nil)
                    return
                }
                completion(authResult?.user.uid)
            }
        }
    }
    
    // (HOST) Crea o si collega come Director
    func createSession(id: String, completion: @escaping (Bool) -> Void) {
        ensureAuth { uid in
            guard let uid = uid else {
                completion(false)
                return
            }
            self.isHost = true
            self.sessionId = id
            
            self.ref.child("sessions/\(id)/owner").setValue(uid) { error, _ in
                if error == nil {
                    let initialState = RemoteMatchState()
                    self.ref.child("sessions/\(id)/state").setValue(initialState.dictionary)
                    self.listenForCommands()
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }
    
    // (CLIENT) Si unisce come Telecomando
    func joinSession(id: String, completion: @escaping (Bool) -> Void) {
        ensureAuth { uid in
            guard let uid = uid else {
                completion(false)
                return
            }
            self.isHost = false
            self.sessionId = id
            
            self.ref.child("sessions/\(id)/controllers/\(uid)").setValue(true) { error, _ in
                if error == nil {
                    self.startListeningToState()
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }
    
    private func startListeningToState() {
        guard let id = sessionId else { return }
        ref.child("sessions/\(id)/state").observe(.value) { snapshot in
            if let dict = snapshot.value as? [String: Any] {
                do {
                    let data = try JSONSerialization.data(withJSONObject: dict)
                    let state = try JSONDecoder().decode(RemoteMatchState.self, from: data)
                    self.onStateUpdated?(state)
                } catch {
                    print("Error decoding state: \(error)")
                }
            }
        }
    }
    
    // (HOST) Aggiorna lo stato sul server
    func updateMatchState(_ state: RemoteMatchState) {
        guard isHost, let id = sessionId else { return }
        self.ref.child("sessions/\(id)/state").setValue(state.dictionary)
    }
    
    // (CLIENT) Invia un comando all Host
    func sendCommand(_ command: String) {
        guard !isHost, let id = sessionId else { return }
        let cmdId = UUID().uuidString
        self.ref.child("sessions/\(id)/commands/\(cmdId)").setValue(command)
    }
    
    private func listenForCommands() {
        guard let id = sessionId else { return }
        ref.child("sessions/\(id)/commands").observe(.childAdded) { snapshot in
            if let command = snapshot.value as? String {
                self.onCommandReceived?(command)
                snapshot.ref.removeValue()
            }
        }
    }
    
    func stopListening() {
        if let id = sessionId {
            ref.child("sessions/\(id)").removeAllObservers()
            ref.child("sessions/\(id)/state").removeAllObservers()
            ref.child("sessions/\(id)/commands").removeAllObservers()
        }
    }
}

// Extension per convertire struct in dictionary per Firebase
extension Encodable {
    var dictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] }
    }
}

