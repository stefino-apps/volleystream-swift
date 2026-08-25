(Get-Content MainViewController.swift -Raw) -replace '(?s)    private func setupControls\(\) \{.*?\}', '    private func setupControls() {
        let safeY = view.bounds.height - 80
        let centerX = view.bounds.width / 2
        startStreamButton = UIButton(frame: CGRect(x: centerX - 90, y: safeY, width: 180, height: 50))
        startStreamButton.setTitle("start_live".localized, for: .normal)
        startStreamButton.backgroundColor = .red
        startStreamButton.layer.cornerRadius = 25
        startStreamButton.addTarget(self, action: #selector(startLive), for: .touchUpInside)
        view.addSubview(startStreamButton)
        
        modeButton = UIButton(frame: CGRect(x: 20, y: safeY, width: 120, height: 50))
        modeButton.setTitle("Normale", for: .normal)
        modeButton.backgroundColor = .darkGray
        modeButton.layer.cornerRadius = 10
        modeButton.addTarget(self, action: #selector(toggleMode), for: .touchUpInside)
        view.addSubview(modeButton)
        
        shareLiveButton = UIButton(frame: CGRect(x: centerX + 110, y: safeY, width: 150, height: 50))
        shareLiveButton.setTitle("Share Live", for: .normal)
        shareLiveButton.backgroundColor = .systemBlue
        shareLiveButton.layer.cornerRadius = 10
        shareLiveButton.addTarget(self, action: #selector(shareLive), for: .touchUpInside)
        view.addSubview(shareLiveButton)
        
        shareRemoteButton = UIButton(frame: CGRect(x: centerX + 280, y: safeY, width: 150, height: 50))
        shareRemoteButton.setTitle("Share Remote", for: .normal)
        shareRemoteButton.backgroundColor = .systemGreen
        shareRemoteButton.layer.cornerRadius = 10
        shareRemoteButton.addTarget(self, action: #selector(shareRemote), for: .touchUpInside)
        view.addSubview(shareRemoteButton)

        muteButton = UIButton(frame: CGRect(x: centerX - 210, y: safeY, width: 100, height: 50))
        muteButton.setTitle("MUTO", for: .normal)
        muteButton.backgroundColor = .orange
        muteButton.layer.cornerRadius = 10
        muteButton.addTarget(self, action: #selector(toggleMute), for: .touchUpInside)
        view.addSubview(muteButton)
        
        replayButton = UIButton(frame: CGRect(x: centerX - 330, y: safeY, width: 100, height: 50))
        replayButton.setTitle("REPLAY", for: .normal)
        replayButton.backgroundColor = .purple
        replayButton.layer.cornerRadius = 10
        replayButton.addTarget(self, action: #selector(triggerReplay), for: .touchUpInside)
        view.addSubview(replayButton)
        
        highlightButton = UIButton(frame: CGRect(x: centerX - 470, y: safeY, width: 120, height: 50))
        highlightButton.setTitle("HIGHLIGHT", for: .normal)
        highlightButton.backgroundColor = .systemPink
        highlightButton.layer.cornerRadius = 10
        highlightButton.addTarget(self, action: #selector(triggerHighlight), for: .touchUpInside)
        view.addSubview(highlightButton)
    }' | Set-Content MainViewController.swift
