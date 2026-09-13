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
    
    var sessionStartTime: TimeInterval = 0
    private var lastDispatchedCommand: String = ""
    private var lastDispatchedTime: TimeInterval = 0
    private var processedCommandKeys = Set<String>()
    
    // (HOST) Crea o si collega come Director
    func createSession(id: String, initialState: RemoteMatchState = RemoteMatchState(), completion: @escaping (Bool) -> Void) {
        let cleanId = id.trimmingCharacters(in: .whitespacesAndNewlines).uppercased().replacingOccurrences(of: "#", with: "")
        ensureAuth { [weak self] uid in
            guard let self = self else { return }
            let hostUid = uid ?? UUID().uuidString
            self.isHost = true
            self.sessionId = cleanId
            self.sessionStartTime = Date().timeIntervalSince1970
            
            print("Firebase HOST: Creating session \(cleanId) with owner \(hostUid) at timestamp \(self.sessionStartTime)")
            self.stopListening()
            self.processedCommandKeys.removeAll()
            
            let sessionRef = self.ref.child("sessions/\(cleanId)")
            
            // Pulisci completamente la sessione prima di scrivere per evitare replay di match precedenti
            sessionRef.removeValue { _, _ in
                sessionRef.child("owner").setValue(hostUid)
                sessionRef.child("state").setValue(initialState.toDictionary()) { _, _ in
                    self.listenForCommands()
                    completion(true)
                }
            }
        }
    }
    
    // (CLIENT) Si unisce come Telecomando
    func joinSession(id: String, completion: @escaping (Bool) -> Void) {
        let cleanId = id.trimmingCharacters(in: .whitespacesAndNewlines).uppercased().replacingOccurrences(of: "#", with: "")
        ensureAuth { [weak self] uid in
            guard let self = self else { return }
            let clientUid = uid ?? UUID().uuidString
            self.isHost = false
            self.sessionId = cleanId
            
            print("Firebase CLIENT: Joining session \(cleanId) with controller UID \(clientUid)")
            self.stopListening()
            self.ref.child("sessions/\(cleanId)/controllers/\(clientUid)").setValue(true)
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
        let dict = state.toDictionary()
        self.ref.child("sessions/\(id)/state").setValue(dict)
    }
    
    // (CLIENT) Invia un comando all'Host
    func sendCommand(_ command: String) {
        guard let id = sessionId else { return }
        let cmdId = UUID().uuidString
        let clean = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        print("Firebase CLIENT: Sending command '\(clean)' to session '\(id)' (cmdId: \(cmdId))")
        
        // 1. Android expects plain String at sessions/$sessionId/commands/$cmdId
        self.ref.child("sessions/\(id)/commands/\(cmdId)").setValue(clean)
        // 2. Also set command and action for Web remote and legacy listeners
        self.ref.child("sessions/\(id)/command").setValue(clean)
        self.ref.child("sessions/\(id)/action").setValue(clean)
    }
    
    private func listenForCommands() {
        guard let id = sessionId else { return }
        print("Firebase HOST: Listening for commands on session \(id) from start time \(sessionStartTime)...")
        self.processedCommandKeys.removeAll()
        
        // 1. Ascolta sulla lista commands (standard Android & iOS Remote)
        ref.child("sessions/\(id)/commands").observe(.childAdded) { [weak self] snapshot in
            guard let self = self else { return }
            let key = snapshot.key
            if self.processedCommandKeys.contains(key) {
                snapshot.ref.removeValue()
                return
            }
            self.processedCommandKeys.insert(key)
            if self.processedCommandKeys.count > 200 {
                self.processedCommandKeys.removeFirst()
            }
            self.extractAndDispatchCommand(from: snapshot)
            snapshot.ref.removeValue()
        }
        
        // 2. Ascolta su command singolo (per telecomando Web)
        ref.child("sessions/\(id)/command").observe(.value) { [weak self] snapshot in
            guard let self = self else { return }
            guard let val = snapshot.value as? String, !val.isEmpty else { return }
            self.dispatchCommandIfNew(val)
            snapshot.ref.removeValue()
        }
        
        // 3. Ascolta su action singolo
        ref.child("sessions/\(id)/action").observe(.value) { [weak self] snapshot in
            guard let self = self else { return }
            guard let val = snapshot.value as? String, !val.isEmpty else { return }
            self.dispatchCommandIfNew(val)
            snapshot.ref.removeValue()
        }
    }
    
    private func extractAndDispatchCommand(from snapshot: DataSnapshot) {
        if let command = snapshot.value as? String, !command.isEmpty {
            dispatchCommandIfNew(command)
            return
        }
        if let dict = snapshot.value as? [String: Any] {
            // Anti-replay check: se presente timestamp, scarta se anteriore alla sessione
            if let ts = dict["timestamp"] as? TimeInterval, ts < (self.sessionStartTime - 2.0) {
                print("Firebase HOST: Discarding stale pre-session command (timestamp: \(ts))")
                return
            }
            let possibleKeys = ["action", "command", "cmd", "type", "event", "name", "val", "value"]
            for key in possibleKeys {
                if let val = dict[key] as? String, !val.isEmpty {
                    dispatchCommandIfNew(val)
                    return
                }
            }
        }
    }
    
    private func dispatchCommandIfNew(_ command: String) {
        let now = Date().timeIntervalSince1970
        let clean = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        
        if clean == lastDispatchedCommand && (now - lastDispatchedTime) < 0.25 {
            print("Firebase HOST: Ignoring duplicate bounce command '\(clean)'")
            return
        }
        lastDispatchedCommand = clean
        lastDispatchedTime = now
        print("Firebase HOST: Dispatching command: \(clean)")
        onCommandReceived?(clean)
    }
}

// Extension per convertire struct in dictionary per Firebase
extension Encodable {
    var dictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] }
    }
}

