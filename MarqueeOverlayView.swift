import UIKit

class MarqueeOverlayView: UIView {
    private let backgroundView = UIView()
    private let liveBadge = UILabel()
    private let textLabel = UILabel()
    private let topBorder = UIView()
    private let bottomBorder = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        clipsToBounds = true
        isUserInteractionEnabled = false
        
        backgroundView.backgroundColor = UIColor(red: 2/255, green: 6/255, blue: 23/255, alpha: 0.94)
        backgroundView.clipsToBounds = true
        backgroundView.isHidden = true
        addSubview(backgroundView)
        
        topBorder.backgroundColor = UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1.0)
        bottomBorder.backgroundColor = UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1.0)
        backgroundView.addSubview(topBorder)
        backgroundView.addSubview(bottomBorder)
        
        liveBadge.text = "LIVE"
        liveBadge.textColor = .white
        liveBadge.font = UIFont.systemFont(ofSize: 11, weight: .black)
        liveBadge.textAlignment = .center
        liveBadge.backgroundColor = UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1.0)
        liveBadge.layer.cornerRadius = 4
        liveBadge.clipsToBounds = true
        backgroundView.addSubview(liveBadge)
        
        textLabel.textColor = .white
        textLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        backgroundView.addSubview(textLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let barH: CGFloat = bounds.height > 600 ? 44 : 32
        let bottomOffset: CGFloat = bounds.height > 600 ? 40 : max(safeAreaInsets.bottom, 8)
        let barY = bounds.height - barH - bottomOffset
        
        backgroundView.frame = CGRect(x: 0, y: barY, width: bounds.width, height: barH)
        topBorder.frame = CGRect(x: 0, y: 0, width: bounds.width, height: 1.5)
        bottomBorder.frame = CGRect(x: 0, y: barH - 1.5, width: bounds.width, height: 1.5)
        
        let badgeW: CGFloat = 42
        let badgeH: CGFloat = barH - 12
        liveBadge.frame = CGRect(x: 10, y: 6, width: badgeW, height: badgeH)
        
        textLabel.font = UIFont.systemFont(ofSize: bounds.height > 600 ? 18 : 13, weight: .bold)
        textLabel.sizeToFit()
        textLabel.frame.size.height = barH
        textLabel.frame.origin.y = 0
    }
    
    func updateMessage(_ message: String, show: Bool) {
        var msg = message.trimmingCharacters(in: .whitespacesAndNewlines)
        if msg.isEmpty && show {
            msg = UserDefaults.standard.string(forKey: "scrolling_text_content") ?? UserDefaults.standard.string(forKey: "saved_scrolling_text_slot_1") ?? "VOLLEYSTREAM PRO • DIRETTA STREAMING"
        }
        
        if show && !msg.isEmpty {
            backgroundView.isHidden = false
            if textLabel.text != msg.uppercased() {
                textLabel.text = msg.uppercased()
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
        let textW = textLabel.intrinsicContentSize.width > 0 ? textLabel.intrinsicContentSize.width : 1000
        textLabel.frame = CGRect(x: w, y: 0, width: textW, height: backgroundView.frame.height)
        
        let duration = Double(w + textW) / 80.0
        UIView.animate(withDuration: max(duration, 6.0), delay: 0, options: [.repeat, .curveLinear], animations: {
            self.textLabel.frame.origin.x = -textW
        }, completion: nil)
    }
}

