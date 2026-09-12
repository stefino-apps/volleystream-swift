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
                    print("Firebase Auth Error (using fallback UID): \(error.localizedDescription)")
                    let fallbackUid = UUID().uuidString
                    completion(fallbackUid)
                    return
                }
                let uid = authResult?.user.uid ?? UUID().uuidString
                print("Firebase: Sign-in success with UID \(uid)")
                completion(uid)
            }
        }
    }
    
    // (HOST) Crea o si collega come Director
    func createSession(id: String, initialState: RemoteMatchState = RemoteMatchState(), completion: @escaping (Bool) -> Void) {
        ensureAuth { [weak self] uid in
            guard let self = self else { return }
            let hostUid = uid ?? UUID().uuidString
            self.isHost = true
            self.sessionId = id
            
            print("Firebase HOST: Creating session \(id) with owner \(hostUid)")
            self.stopListening()
            self.ref.child("sessions/\(id)/owner").setValue(hostUid)
            self.ref.child("sessions/\(id)/state").setValue(initialState.dictionary)
            
            // Pulisci comandi pendenti/vecchi nel database prima di ascoltare nuovi comandi
            self.ref.child("sessions/\(id)/commands").removeValue()
            self.ref.child("sessions/\(id)/command").removeValue()
            self.ref.child("sessions/\(id)/action").removeValue()
            
            // L'Host ascolta SOLO i comandi in arrivo dai client (telecomandi)
            self.listenForCommands()
            completion(true)
        }
    }
    
    // (CLIENT) Si unisce come Telecomando
    func joinSession(id: String, completion: @escaping (Bool) -> Void) {
        ensureAuth { [weak self] uid in
            guard let self = self else { return }
            let clientUid = uid ?? UUID().uuidString
            self.isHost = false
            self.sessionId = id
            
            print("Firebase CLIENT: Joining session \(id) with controller UID \(clientUid)")
            self.stopListening()
            self.ref.child("sessions/\(id)/controllers/\(clientUid)").setValue(true)
            self.startListeningToState()
            completion(true)
        }
    }
    
    func stopListening() {
        guard let id = sessionId else { return }
        ref.child("sessions/\(id)/commands").removeAllObservers()
        ref.child("sessions/\(id)/command").removeAllObservers()
        ref.child("sessions/\(id)/action").removeAllObservers()
        ref.child("sessions/\(id)/state").removeAllObservers()
    }
    
    private func startListeningToState() {
        guard let id = sessionId else { return }
        print("Firebase CLIENT: Listening to state for session \(id)...")
        ref.child("sessions/\(id)/state").observe(.value) { [weak self] snapshot in
            guard let self = self else { return }
            if !snapshot.exists() { return }
            if let dict = snapshot.value as? [String: Any] {
                let state = RemoteMatchState(dict: dict)
                self.onStateUpdated?(state)
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
        guard let id = sessionId else { return }
        let cmdId = UUID().uuidString
        print("Firebase CLIENT: Sending command '\(command)' to session '\(id)' (cmdId: \(cmdId))")
        self.ref.child("sessions/\(id)/commands/\(cmdId)").setValue(command)
        self.ref.child("sessions/\(id)/command").setValue(command)
    }
    
    private func listenForCommands() {
        guard let id = sessionId else { return }
        print("Firebase HOST: Listening for commands on session \(id)...")
        
        // 1. Multiple command list: sessions/{id}/commands
        ref.child("sessions/\(id)/commands").observe(.childAdded) { [weak self] snapshot in
            self?.extractAndDispatchCommand(from: snapshot)
            snapshot.ref.removeValue()
        }
        
        // 2. Single command node: sessions/{id}/command
        ref.child("sessions/\(id)/command").observe(.value) { [weak self] snapshot in
            guard snapshot.exists() else { return }
            self?.extractAndDispatchCommand(from: snapshot)
            snapshot.ref.removeValue()
        }
        
        // 3. Action node: sessions/{id}/action
        ref.child("sessions/\(id)/action").observe(.value) { [weak self] snapshot in
            guard snapshot.exists() else { return }
            self?.extractAndDispatchCommand(from: snapshot)
            snapshot.ref.removeValue()
        }
    }
    
    private func extractAndDispatchCommand(from snapshot: DataSnapshot) {
        if let command = snapshot.value as? String, !command.isEmpty {
            print("Firebase HOST: Command received (String): \(command)")
            onCommandReceived?(command)
            return
        }
        if let dict = snapshot.value as? [String: Any] {
            let possibleKeys = ["action", "command", "cmd", "type", "event", "name", "val", "value"]
            for key in possibleKeys {
                if let val = dict[key] as? String, !val.isEmpty {
                    print("Firebase HOST: Command received from key '\(key)': \(val)")
                    onCommandReceived?(val)
                    return
                }
            }
        }
    }
    
    func stopListening() {
        if let id = sessionId {
            ref.child("sessions/\(id)").removeAllObservers()
            ref.child("sessions/\(id)/state").removeAllObservers()
            ref.child("sessions/\(id)/commands").removeAllObservers()
            ref.child("sessions/\(id)/command").removeAllObservers()
            ref.child("sessions/\(id)/action").removeAllObservers()
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

