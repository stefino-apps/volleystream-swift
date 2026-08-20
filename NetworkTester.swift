import Foundation
import Network

class NetworkTester {
    static let shared = NetworkTester()
    
    // Ritorna la qualita' stimata
    func runSpeedTest(completion: @escaping (String) -> Void) {
        // In una vera app, scarica un payload e calcola i mbps.
        // Simulazione per scopi di UI:
        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
            let speeds = ["Eccellente (1080p60)", "Buona (1080p30)", "Media (720p)", "Scarsa (480p)"]
            let result = speeds.randomElement() ?? "Sconosciuta"
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
}

