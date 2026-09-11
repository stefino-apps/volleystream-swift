import Foundation
import FirebaseDatabase
import FirebaseAuth

class FirebaseManager {
    static let shared = FirebaseManager()
    
    private let databaseURL = "https://volleypro-50d56-default-rtdb.europe-west1.firebasedatabase.app"
    private var ref: DatabaseReference!
    var sessionId: String?
    var isHost: Bool = true
    
    // Callbacks
    var onStateUpdated: ((RemoteMatchState) -> Void)?
    var onCommandReceived: ((String) -> Void)?
    var onError: ((String) -> Void)?
    
    private init() {
        ref = Database.database(url: databaseURL).reference()
    }
    
    func ensureAuth(completion: @escaping (String?) -> Void) {
        if let user = Auth.auth().currentUser {
            completion(user.uid)
        } else {
            print("Firebase: Signing in anonymously...")
            Auth.auth().signInAnonymously { authResult, error in
                if let error = error {
                    print("Firebase Auth Error: \(error.localizedDescription)")
                    self.onError?(error.localizedDescription)
                    completion(nil)
                    return
                }
                let uid = authResult?.user.uid
                print("Firebase: Anonymous sign-in success with UID \(uid ?? "")")
                completion(uid)
            }
        }
    }
    
    // (HOST) Crea o si collega come Director
    func createSession(id: String, initialState: RemoteMatchState = RemoteMatchState(), completion: @escaping (Bool) -> Void) {
        ensureAuth { uid in
            guard let uid = uid else {
                completion(false)
                return
            }
            self.isHost = true
            self.sessionId = id
            
            print("Firebase HOST: Creating session \(id) with owner \(uid)")
            self.ref.child("sessions/\(id)/owner").setValue(uid) { error, _ in
                if error == nil {
                    self.ref.child("sessions/\(id)/state").setValue(initialState.dictionary)
                    self.listenForCommands()
                    self.startListeningToState()
                    completion(true)
                } else {
                    print("Firebase HOST: Error creating session owner: \(error?.localizedDescription ?? "")")
                    completion(false)
                }
            }
        }
    }
    
    // (CLIENT) Si unisce come Telecomando
    func joinSession(id: String, completion: @escaping (Bool) -> Void) {
        ensureAuth { uid in
            guard let uid = uid else {
                print("Firebase CLIENT: Auth failed on joinSession")
                completion(false)
                return
            }
            self.isHost = false
            self.sessionId = id
            
            print("Firebase CLIENT: Joining session \(id) with controller UID \(uid)")
            self.ref.child("sessions/\(id)/controllers/\(uid)").setValue(true) { error, _ in
                if let error = error {
                    print("Firebase CLIENT: Warning on controller registration: \(error.localizedDescription)")
                } else {
                    print("Firebase CLIENT: Successfully registered as authorized controller")
                }
                self.startListeningToState()
                completion(true)
            }
        }
    }
    
    private func startListeningToState() {
        guard let id = sessionId else { return }
        print("Firebase: Listening to state for session \(id)...")
        ref.child("sessions/\(id)/state").observe(.value) { [weak self] snapshot in
            guard let self = self else { return }
            if !snapshot.exists() {
                print("Firebase: Session \(id) state does not exist in DB yet")
                return
            }
            if let dict = snapshot.value as? [String: Any] {
                print("Firebase: Received state update for session \(id): score \(dict["scoreA"] ?? 0) - \(dict["scoreB"] ?? 0)")
                let state = RemoteMatchState(dict: dict)
                self.onStateUpdated?(state)
            } else {
                print("Firebase: Snapshot value is not a dictionary: \(String(describing: snapshot.value))")
            }
        }
    }
    
    // Aggiorna lo stato sul server (Solo Host)
    func updateMatchState(_ state: RemoteMatchState) {
        guard let id = sessionId else { return }
        self.ref.child("sessions/\(id)/state").setValue(state.dictionary)
    }
    
    // (CLIENT) Invia un comando all'Host
    func sendCommand(_ command: String) {
        guard let id = sessionId else {
            print("Firebase CLIENT: Cannot send command \(command), sessionId is nil")
            return
        }
        let cmdId = UUID().uuidString
        print("Firebase CLIENT: Sending command '\(command)' to session '\(id)' (cmdId: \(cmdId))")
        self.ref.child("sessions/\(id)/commands/\(cmdId)").setValue(command) { error, _ in
            if let error = error {
                print("Firebase CLIENT: Error sending command \(command): \(error.localizedDescription)")
            } else {
                print("Firebase CLIENT: Command \(command) delivered to database")
            }
        }
    }
    
    private func listenForCommands() {
        guard let id = sessionId else { return }
        print("Firebase HOST: Listening for commands on session \(id)...")
        ref.child("sessions/\(id)/commands").observe(.childAdded) { [weak self] snapshot in
            if let command = snapshot.value as? String {
                print("Firebase HOST: Command received: \(command)")
                self?.onCommandReceived?(command)
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

