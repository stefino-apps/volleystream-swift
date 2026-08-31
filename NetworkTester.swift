import Foundation
import Network

class NetworkTester {
    static let shared = NetworkTester()
    
    func runSpeedTest(completion: @escaping (String) -> Void) {
        // Usa un file di test per misurare la banda (es. 5MB)
        guard let url = URL(string: "https://speed.cloudflare.com/__down?bytes=5242880") else {
            completion("Errore URL")
            return
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            
            DispatchQueue.main.async {
                guard error == nil, let data = data else {
                    completion("Connessione Assente")
                    return
                }
                
                let bytes = Double(data.count)
                let bits = bytes * 8
                let megabits = bits / 1_000_000
                let mbps = megabits / elapsed
                
                let resultStr: String
                if mbps > 10 {
                    resultStr = String(format: "Eccellente (%.1f Mbps) - 1080p60", mbps)
                } else if mbps > 5 {
                    resultStr = String(format: "Buona (%.1f Mbps) - 1080p30", mbps)
                } else if mbps > 2 {
                    resultStr = String(format: "Media (%.1f Mbps) - 720p", mbps)
                } else {
                    resultStr = String(format: "Scarsa (%.1f Mbps) - 480p", mbps)
                }
                completion(resultStr)
            }
        }
        task.resume()
    }
}

