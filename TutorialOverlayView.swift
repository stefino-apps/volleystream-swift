import UIKit

class TutorialOverlayView: UIView {
    private let maskLayer = CAShapeLayer()
    private let textLabel = UILabel()
    private let tapGesture = UITapGestureRecognizer()
    
    private var steps: [(view: UIView?, text: String)] = []
    private var currentStep = 0
    
    init() {
        super.init(frame: UIScreen.main.bounds)
        self.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        self.alpha = 0
        
        maskLayer.fillRule = .evenOdd
        self.layer.mask = maskLayer
        
        textLabel.textColor = .white
        textLabel.font = UIFont.boldSystemFont(ofSize: 20)
        textLabel.textAlignment = .center
        textLabel.numberOfLines = 0
        self.addSubview(textLabel)
        
        tapGesture.addTarget(self, action: #selector(nextStep))
        self.addGestureRecognizer(tapGesture)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func startTutorial(in view: UIView, steps: [(view: UIView?, text: String)]) {
        self.steps = steps
        self.currentStep = 0
        self.frame = view.bounds
        view.addSubview(self)
        
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1.0
        }
        
        showStep()
    }
    
    private func showStep() {
        guard currentStep < steps.count else {
            UIView.animate(withDuration: 0.3, animations: {
                self.alpha = 0
            }) { _ in
                self.removeFromSuperview()
            }
            UserDefaults.standard.set(true, forKey: "has_seen_tutorial")
            return
        }
        
        let step = steps[currentStep]
        
        let path = UIBezierPath(rect: self.bounds)
        
        var labelY: CGFloat = self.bounds.midY
        
        if let targetView = step.view {
            let targetFrame = targetView.convert(targetView.bounds, to: self)
            let highlightPath = UIBezierPath(roundedRect: targetFrame.insetBy(dx: -10, dy: -10), cornerRadius: 8)
            path.append(highlightPath)
            
            if targetFrame.minY > self.bounds.midY {
                labelY = targetFrame.minY - 60
            } else {
                labelY = targetFrame.maxY + 60
            }
        }
        
        maskLayer.path = path.cgPath
        
        textLabel.text = step.text
        textLabel.frame = CGRect(x: 20, y: labelY - 40, width: self.bounds.width - 40, height: 80)
    }
    
    @objc private func nextStep() {
        currentStep += 1
        showStep()
    }
}
