//
//  ThirdScreenViewController.swift
//  Stryde
//
//  Created by Steven Chang on 9/22/24.
//

import UIKit
import MediaPlayer

class ThirdScreenViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        style()
        layout()

        // Do any additional setup after loading the view.
    }
    
    // MARK: - Variables
    let accel = Accel()
    
    // MARK: - Subviews
    let stackView = UIStackView()
    let imageView = UIImageView()
    let trackLabel = UILabel()
    let playPauseButton = UIButton()
    let signOutButton = UIButton(type: .system)
    let startRun = UIButton(type: .system)
    let changePlaylist = UIButton(type: .system)
    
    // MARK: - Actions
    @objc func startTrackingBPM(_ button: UIButton) {
        
    }
    
    @objc func reselectPlaylist(_ button:UIButton) {

    }
    
    @objc func didTapPauseOrPlay(_ button: UIButton, inputTempo: Double) {

    }

    @objc func didTapSignOut(_ button: UIButton) {

    }

    @objc func didTapConnect(_ button: UIButton) {

    }
    
    
}

// MARK: - Style & Layout
extension ThirdScreenViewController {
    
    func style() {
        navigationItem.hidesBackButton = true
        
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.alignment = .fill
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit

        trackLabel.translatesAutoresizingMaskIntoConstraints = false
        trackLabel.font = UIFont.preferredFont(forTextStyle: .body)
        trackLabel.textAlignment = .center

        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.addTarget(self, action: #selector(didTapPauseOrPlay), for: .primaryActionTriggered)

        signOutButton.translatesAutoresizingMaskIntoConstraints = false
        signOutButton.setTitle("Sign out", for: .normal)
        signOutButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        signOutButton.addTarget(self, action: #selector(didTapSignOut(_:)), for: .touchUpInside)
        
        startRun.translatesAutoresizingMaskIntoConstraints = false
        startRun.setTitle("Start Run", for: .normal)
        startRun.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        startRun.addTarget(self, action: #selector(startTrackingBPM), for: .touchUpInside)
        
        changePlaylist.translatesAutoresizingMaskIntoConstraints = false
        changePlaylist.setTitle("Change Playlist", for: .normal)
        changePlaylist.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        changePlaylist.addTarget(self, action: #selector(reselectPlaylist), for: .touchUpInside)
    }
    
    func layout() {
        view.addSubview(stackView)
        
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(trackLabel)
        stackView.addArrangedSubview(playPauseButton)
        stackView.addArrangedSubview(startRun)
        stackView.addArrangedSubview(changePlaylist)
        stackView.addArrangedSubview(signOutButton)

        NSLayoutConstraint.activate([
                stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
            ])
            
        // Since imageView might need a fixed height or aspect ratio
        imageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.3).isActive = true
    }
}


