import UIKit

class MarqueeOverlayView: UIView {
    private let backgroundView = UIView()
    private let textLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Questa view avra' frame 1920x1080 (o la risoluzione video)
        // Disegniamo la striscia in basso
        backgroundView.frame = CGRect(x: 0, y: 1080 - 60, width: 1920, height: 60)
        backgroundView.backgroundColor = UIColor.blue.withAlphaComponent(0.8)
        backgroundView.isHidden = true
        addSubview(backgroundView)
        
        textLabel.frame = CGRect(x: 1920, y: 0, width: 3000, height: 60)
        textLabel.textColor = .white
        textLabel.font = UIFont.boldSystemFont(ofSize: 32)
        backgroundView.addSubview(textLabel)
    }
    
    func updateMessage(_ message: String, show: Bool) {
        if show {
            backgroundView.isHidden = false
            if textLabel.text != message {
                textLabel.text = message
                startAnimation()
            }
        } else {
            backgroundView.isHidden = true
            textLabel.layer.removeAllAnimations()
            textLabel.text = ""
        }
    }
    
    private func startAnimation() {
        textLabel.layer.removeAllAnimations()
        textLabel.frame.origin.x = 1920
        
        UIView.animate(withDuration: 15.0, delay: 0, options: [.repeat, .curveLinear], animations: {
            self.textLabel.frame.origin.x = -self.textLabel.frame.width
        }, completion: nil)
    }
}

