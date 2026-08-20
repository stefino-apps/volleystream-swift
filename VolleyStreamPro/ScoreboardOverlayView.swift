import UIKit

class ScoreboardOverlayView: UIView {
    
    private let backgroundView = UIView()
    private let homeNameLabel = UILabel()
    private let awayNameLabel = UILabel()
    private let scoreLabel = UILabel()
    private let setsLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Sfondo semi-trasparente scuro
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        backgroundView.layer.cornerRadius = 10
        backgroundView.frame = bounds
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(backgroundView)
        
        // Font in stile sportivo
        let boldFont = UIFont.boldSystemFont(ofSize: 24)
        
        homeNameLabel.frame = CGRect(x: 10, y: 10, width: 120, height: 30)
        homeNameLabel.textColor = .white
        homeNameLabel.font = boldFont
        homeNameLabel.text = "HOME"
        addSubview(homeNameLabel)
        
        awayNameLabel.frame = CGRect(x: 10, y: 40, width: 120, height: 30)
        awayNameLabel.textColor = .white
        awayNameLabel.font = boldFont
        awayNameLabel.text = "AWAY"
        addSubview(awayNameLabel)
        
        scoreLabel.frame = CGRect(x: 140, y: 10, width: 80, height: 60)
        scoreLabel.textColor = .yellow
        scoreLabel.font = UIFont.boldSystemFont(ofSize: 32)
        scoreLabel.textAlignment = .center
        scoreLabel.numberOfLines = 2
        scoreLabel.text = "0\n0"
        addSubview(scoreLabel)
        
        setsLabel.frame = CGRect(x: 230, y: 10, width: 80, height: 60)
        setsLabel.textColor = .red
        setsLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        setsLabel.textAlignment = .center
        setsLabel.numberOfLines = 2
        setsLabel.text = "Set: 0\nSet: 0"
        addSubview(setsLabel)
    }
    
    func updateScore(home: Int, away: Int) {
        scoreLabel.text = "\(home)\n\(away)"
    }
    
    func updateSets(home: Int, away: Int) {
        setsLabel.text = "Set: \(home)\nSet: \(away)"
    }
    
    func updateTeams(home: String, away: String) {
        homeNameLabel.text = home
        awayNameLabel.text = away
    }
}
