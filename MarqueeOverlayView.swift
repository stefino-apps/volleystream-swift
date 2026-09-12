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
        clipsToBounds = true
        backgroundView.backgroundColor = UIColor(red: 10/255, green: 22/255, blue: 48/255, alpha: 0.92)
        backgroundView.isHidden = true
        addSubview(backgroundView)
        
        textLabel.textColor = .white
        textLabel.font = UIFont.boldSystemFont(ofSize: 18)
        backgroundView.addSubview(textLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let barH: CGFloat = bounds.height > 600 ? 54 : 36
        backgroundView.frame = CGRect(x: 0, y: bounds.height - barH, width: bounds.width, height: barH)
        textLabel.font = UIFont.boldSystemFont(ofSize: bounds.height > 600 ? 24 : 15)
        textLabel.sizeToFit()
        textLabel.frame.size.height = barH
    }
    
    func updateMessage(_ message: String, show: Bool) {
        if show && !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            backgroundView.isHidden = false
            if textLabel.text != message {
                textLabel.text = message
                layoutSubviews()
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
        let w = bounds.width > 0 ? bounds.width : 1920
        let textW = textLabel.frame.width > 0 ? textLabel.frame.width : 1000
        textLabel.frame.origin.x = w
        
        let duration = Double(w + textW) / 100.0
        UIView.animate(withDuration: max(duration, 8.0), delay: 0, options: [.repeat, .curveLinear], animations: {
            self.textLabel.frame.origin.x = -textW
        }, completion: nil)
    }
}

