//
//  ViewController.swift
//  easyplay
//
//  Created by jrasmusson on 2022-03-21.
//

import UIKit
import MediaPlayer

protocol PlaylistSelectionDelegate: AnyObject {
    func didSelectPlaylist(_ playlistId: String)
}


class ViewController: UIViewController, PlaylistSelectionDelegate {
    
    let volumeView = MPVolumeView()
    let audioSession = AVAudioSession.sharedInstance()
    
    var vol : Float = 0
    let accel = Accel()
    var trackURIs = [
        "spotify:track:20I6sIOMTCkB6w7ryavxtO",  // Existing URI
        "spotify:track:3n3Ppam7vgaVa1iaRUc9Lp",
        "spotify:track:0VjIjW4GlUZAMYd2vXMi3b",  // Blinding Lights
        "spotify:track:463CkQjx2JchxjALpP59Gt",  // Levitating
        "spotify:track:7qiZfU4dY1lWllzX7mPBI3",  // Shape of You
        "spotify:track:6UelLqGlWMcVH1E5c4H7lY",  // Watermelon Sugar
        "spotify:track:4iJyoBOLtHqaGxP12qzhQI",  // Peaches
        "spotify:track:5QO79kh1waicV47BqGRL3g",  // Save Your Tears
        "spotify:track:3PfIrDoz19wz7qK7tYeu62",  // Don’t Start Now
        "spotify:track:5wANPM4fQCJwkGd4rN57mH",  // drivers license
        "spotify:track:5PjdY0CKGZdEuoNab3yDmX",  // Stay
        "spotify:track:2XU0oxnq2qxCpomAAuJY8K"   // Dance Monkey
    ]
    
    var userPlaylists: [(name: String, id: String, imageURL: String?)] = []
    

    // MARK: - Spotify Authorization & Configuration
    var responseCode: String? {
        didSet {
            fetchAccessToken { (dictionary, error) in
                if let error = error {
                    print("Fetching token request error \(error)")
                    return
                }
                let accessToken = dictionary!["access_token"] as! String
                DispatchQueue.main.async {
                    self.appRemote.connectionParameters.accessToken = accessToken
                    self.appRemote.connect()
                    
                }
            }
        }
    }

    lazy var appRemote: SPTAppRemote = {
        let appRemote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        appRemote.connectionParameters.accessToken = self.accessToken
        appRemote.delegate = self
        return appRemote
    }()

    var accessToken = UserDefaults.standard.string(forKey: accessTokenKey) {
        didSet {
            let defaults = UserDefaults.standard
            defaults.set(accessToken, forKey: accessTokenKey)
        }
    }

    lazy var configuration: SPTConfiguration = {
        let configuration = SPTConfiguration(clientID: spotifyClientId, redirectURL: redirectUri)
        // Set the playURI to a non-nil value so that Spotify plays music after authenticating
        // otherwise another app switch will be required
        configuration.playURI = ""
        // Set these url's to your backend which contains the secret to exchange for an access token
        // You can use the provided ruby script spotify_token_swap.rb for testing purposes
        configuration.tokenSwapURL = URL(string: "http://localhost:1234/swap")
        configuration.tokenRefreshURL = URL(string: "http://localhost:1234/refresh")
        return configuration
    }()

    lazy var sessionManager: SPTSessionManager? = {
        let manager = SPTSessionManager(configuration: configuration, delegate: self)
        return manager
    }()

    private var lastPlayerState: SPTAppRemotePlayerState?
    


    // MARK: - Subviews
    
    // connect view
    let firstNameLabel = UILabel()
    let lastNameLabel = UILabel()
    let moodLabel = UILabel()
    
    let firstNameTextView = UITextView()
    let lastNameTextView = UITextView()
    let moodTextView = UITextView()
    
    let connectButton = UIButton(type: .system)
    
    // song view
    let stackView = UIStackView()
    let imageView = UIImageView()
    let trackLabel = UILabel()
    let playPauseButton = UIButton(type: .system)
    let changePlaylist = UIButton(type: .system)
    
    let durationLabel = UILabel()
    let distanceLabel = UILabel()
    let cadenceLabel = UILabel()
    let paceLabel = UILabel()
    
    let durationAmountLabel = UILabel()
    let distanceAmountLabel = UILabel()
    let cadenceAmountLabel = UILabel()
    let paceAmountLabel = UILabel()
    
    let runningNote = UIImageView()
    let spacerView = UIView()
    var tempoTrackDictionary: [Double: String] = [:]
    
    let heartButton = UIButton(type: .system)
    let aiButton = UIButton(type: .system)
    
    var tempo: Double? {
        didSet {
            // Whenever the tempo changes, play the song with the closest tempo
            if let newTempo = tempo {
                playSongClosestTo(tempo: newTempo)
            }
        }
    }
    
    var tempoIncrementTimer: Timer?
    var updateTimer: Timer?
    var secondsElapsed = 0

    func didSelectPlaylist(_ playlistId: String) {
            // Fetch and sort tracks by tempo when the playlist is selected
        fetchTracksFromPlaylist(playlistId: playlistId)
    }
    
    func showPlaylistSelection() {
        Task {
            let playlistVC = PlaylistsTableViewController()
            do {
                playlistVC.playlists = try await fetchUserPlaylists()
            } catch {
                print("unable to get the playlists sadly")
            }
             // Pass the playlist data
            playlistVC.delegate = self // Set the delegate
            present(playlistVC, animated: true, completion: nil)
        }
        
    }

    // MARK: App Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        style()
        layout()
        do {
            try audioSession.setCategory(.playback, options: .mixWithOthers)
            try audioSession.setActive(true)
        } catch {
            print("tff")
        }
        
        // Bottom Curve Shape
        let bottomCurveView = UIView()
        bottomCurveView.backgroundColor = UIColor(red: 212/255, green: 224/255, blue: 155/255, alpha: 1.0)  // #D4E09B
        bottomCurveView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomCurveView)
        view.sendSubviewToBack(bottomCurveView)
        
        NSLayoutConstraint.activate([
            bottomCurveView.heightAnchor.constraint(equalToConstant: 300),  // Increased height for full oval
            bottomCurveView.widthAnchor.constraint(equalToConstant: view.frame.width * 2),  // Make it twice the screen width for the oval effect
            bottomCurveView.centerXAnchor.constraint(equalTo: view.centerXAnchor),  // Center it horizontally
            bottomCurveView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
                
        // Apply corner rounding to create the curved effect
        bottomCurveView.layer.cornerRadius = 400
        bottomCurveView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        bottomCurveView.layer.masksToBounds = true
        
        setupKeyboardDismissRecognizer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateViewBasedOnConnected()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateViewBasedOnConnected()
    }

    func update(playerState: SPTAppRemotePlayerState) {
        if lastPlayerState?.track.uri != playerState.track.uri {
            fetchArtwork(for: playerState.track)
        }
        
        lastPlayerState = playerState
        trackLabel.text = truncateTextIfNeeded(playerState.track.name, maxLength: 27)

        let configuration = UIImage.SymbolConfiguration(pointSize: 40, weight: .bold, scale: .large)
        if playerState.isPaused {
            playPauseButton.setImage(UIImage(systemName: "play.circle.fill", withConfiguration: configuration), for: .normal)
        } else {
            playPauseButton.setImage(UIImage(systemName: "pause.circle.fill", withConfiguration: configuration), for: .normal)
        }
    }

    // MARK: - Actions
    @objc func startTrackingBPM() {
        accel.startTracking()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.appRemote.playerAPI?.resume(nil)
            self.startIncreasingTempo()
        }
    }
    
    @objc func reselectPlaylist(_ button:UIButton) {
        showPlaylistSelection()
    }
    
    @objc func updateDurationLabel() {
        secondsElapsed += 1
        let minutes = secondsElapsed / 60
        let seconds = secondsElapsed % 60
        durationAmountLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    @objc func didTapPauseOrPlay(_ button: UIButton) {
        startTrackingBPM()
        
        if let lastPlayerState = lastPlayerState, lastPlayerState.isPaused {
            appRemote.playerAPI?.resume(nil)
            startIncreasingTempo()
            startTimer()
        } else {
            appRemote.playerAPI?.pause(nil)
            stopIncreasingTempo()
            stopTimer()
        }
    }

    @objc func didTapSignOut(_ button: UIButton) {
        if appRemote.isConnected == true {
            appRemote.disconnect()
        }
    }

    @objc func didTapConnect(_ button: UIButton) {
        guard let sessionManager = sessionManager else { return }
        sessionManager.initiateSession(with: scopes, options: .clientOnly, campaign: nil)
    }
    
    @objc func didTapHeart() {
        // Implement what happens when previous is tapped
        print("Previous track")
    }

    @objc func didTapAI() {
        // Implement what happens when next is tapped
        print("Next track")
    }

    // MARK: - Private Helpers
    private func presentAlertController(title: String, message: String, buttonTitle: String) {
        DispatchQueue.main.async {
            let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let action = UIAlertAction(title: buttonTitle, style: .default, handler: nil)
            controller.addAction(action)
            self.present(controller, animated: true)
        }
    }
    
    private func truncateTextIfNeeded(_ text: String, maxLength: Int) -> String {
        if text.count > maxLength {
            let index = text.index(text.startIndex, offsetBy: maxLength - 3) // Adjust for ellipses
            let truncated = text.prefix(upTo: index)
            return "\(truncated)..."
        }
        return text
    }
}

// MARK: Style & Layout
extension ViewController {
    func style() {
        view.backgroundColor = UIColor(red: 246/255.0, green: 244/255.0, blue: 210/255.0, alpha: 1.0)
        
        navigationItem.hidesBackButton = true
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .center
        
        // MARK: - Connect View
        firstNameLabel.translatesAutoresizingMaskIntoConstraints = false
        firstNameLabel.text = "First Name"
        firstNameLabel.font = UIFont.systemFont(ofSize: 16)
        
        lastNameLabel.translatesAutoresizingMaskIntoConstraints = false
        lastNameLabel.text = "Last Name"
        lastNameLabel.font = UIFont.systemFont(ofSize: 16)
        
        moodLabel.translatesAutoresizingMaskIntoConstraints = false
        moodLabel.text = "Mood"
        moodLabel.font = UIFont.systemFont(ofSize: 16)
        
        firstNameTextView.translatesAutoresizingMaskIntoConstraints = false
        firstNameTextView.layer.borderWidth = 1
        firstNameTextView.layer.borderColor = UIColor.gray.cgColor
        firstNameTextView.layer.cornerRadius = 5
        firstNameTextView.font = UIFont.systemFont(ofSize: 18)
        
        lastNameTextView.translatesAutoresizingMaskIntoConstraints = false
        lastNameTextView.layer.borderWidth = 1
        lastNameTextView.layer.borderColor = UIColor.gray.cgColor
        lastNameTextView.layer.cornerRadius = 5
        lastNameTextView.font = UIFont.systemFont(ofSize: 18)
        
        moodTextView.translatesAutoresizingMaskIntoConstraints = false
        moodTextView.layer.borderWidth = 1
        moodTextView.layer.borderColor = UIColor.gray.cgColor
        moodTextView.layer.cornerRadius = 5
        moodTextView.font = UIFont.systemFont(ofSize: 18)

        connectButton.translatesAutoresizingMaskIntoConstraints = false
        connectButton.setTitle("Connect to Spotify", for: .normal)
        connectButton.titleLabel?.font = UIFont.systemFont(ofSize: 19)
        connectButton.backgroundColor = UIColor(red: 106/255, green: 176/255, blue: 76/255, alpha: 1.0)
        connectButton.layer.cornerRadius = 8
        connectButton.addTarget(self, action: #selector(didTapConnect), for: .touchUpInside)
        connectButton.setTitleColor(.white, for: .normal)
        
        spacerView.translatesAutoresizingMaskIntoConstraints = false
        spacerView.backgroundColor = .clear

        // MARK: - Song View
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit

        trackLabel.translatesAutoresizingMaskIntoConstraints = false
        trackLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        trackLabel.textAlignment = .center
        trackLabel.textColor = UIColor(red: 164/255, green: 74/255, blue: 63/255, alpha: 1)

        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.addTarget(self, action: #selector(didTapPauseOrPlay), for: .primaryActionTriggered)
        playPauseButton.tintColor = UIColor(red: 164/255, green: 74/255, blue: 63/255, alpha: 1)
        
        changePlaylist.translatesAutoresizingMaskIntoConstraints = false
        changePlaylist.setImage(UIImage(systemName: "ellipsis.circle"), for: .normal)
        changePlaylist.tintColor = UIColor(red: 164/255, green: 74/255, blue: 63/255, alpha: 1)
        changePlaylist.addTarget(self, action: #selector(reselectPlaylist), for: .touchUpInside)
        
        durationLabel.text = "Duration"
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        durationLabel.textColor = UIColor(red: 164/255, green: 74/255, blue: 63/255, alpha: 1)
        durationLabel.textAlignment = .center
        
        distanceLabel.text = "Distance"
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false
        distanceLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        distanceLabel.textColor = UIColor(red: 164/255, green: 74/255, blue: 63/255, alpha: 1)
        distanceLabel.textAlignment = .center
        
        cadenceLabel.text = "Cadence"
        cadenceLabel.translatesAutoresizingMaskIntoConstraints = false
        cadenceLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        cadenceLabel.textColor = UIColor(red: 164/255, green: 74/255, blue: 63/255, alpha: 1)
        cadenceLabel.textAlignment = .center
        
        paceLabel.text = "Pace"
        paceLabel.translatesAutoresizingMaskIntoConstraints = false
        paceLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        paceLabel.textColor = UIColor(red: 164/255, green: 74/255, blue: 63/255, alpha: 1)
        paceLabel.textAlignment = .center
        
        durationAmountLabel.text = "00:00"
        durationAmountLabel.translatesAutoresizingMaskIntoConstraints = false
        durationAmountLabel.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        durationAmountLabel.textColor = UIColor(red: 164/255, green: 74/255, blue: 63/255, alpha: 1)
        durationAmountLabel.textAlignment = .center
        
        distanceAmountLabel.text = "1.87 mi"
        distanceAmountLabel.translatesAutoresizingMaskIntoConstraints = false
        distanceAmountLabel.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        distanceAmountLabel.textColor = UIColor(red: 164/255, green: 74/255, blue: 63/255, alpha: 1)
        distanceAmountLabel.textAlignment = .center
        
        cadenceAmountLabel.text = "--"
        cadenceAmountLabel.translatesAutoresizingMaskIntoConstraints = false
        cadenceAmountLabel.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        cadenceAmountLabel.textColor = UIColor(red: 164/255, green: 74/255, blue: 63/255, alpha: 1)
        cadenceAmountLabel.textAlignment = .center
        
        paceAmountLabel.text = "6:07"
        paceAmountLabel.translatesAutoresizingMaskIntoConstraints = false
        paceAmountLabel.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        paceAmountLabel.textColor = UIColor(red: 164/255, green: 74/255, blue: 63/255, alpha: 1)
        paceAmountLabel.textAlignment = .center
        
        runningNote.image = UIImage(named: "music-note")
        runningNote.contentMode = .scaleAspectFit
        runningNote.translatesAutoresizingMaskIntoConstraints = false
        
        heartButton.setImage(UIImage(systemName: "heart"), for: .normal)
        heartButton.tintColor = UIColor(red: 164/255, green: 74/255, blue: 63/255, alpha: 1)
        heartButton.addTarget(self, action: #selector(didTapHeart), for: .touchUpInside)

        aiButton.setImage(UIImage(systemName: "music.note.list"), for: .normal)
        aiButton.tintColor = UIColor(red: 164/255, green: 74/255, blue: 63/255, alpha: 1)
        aiButton.addTarget(self, action: #selector(didTapAI), for: .touchUpInside)
    }

    func layout() {
        // connect view
        view.addSubview(firstNameLabel)
        view.addSubview(firstNameTextView)
        view.addSubview(lastNameLabel)
        view.addSubview(lastNameTextView)
        view.addSubview(moodLabel)
        view.addSubview(moodTextView)
        view.addSubview(connectButton)
        view.addSubview(runningNote)
        
        NSLayoutConstraint.activate([
            runningNote.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            runningNote.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -240),
            runningNote.widthAnchor.constraint(equalToConstant: 200),
            runningNote.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        // song view
        view.addSubview(stackView)
        stackView.addArrangedSubview(imageView)
        
        let horizontalStackView = UIStackView()
        horizontalStackView.axis = .horizontal
        horizontalStackView.distribution = .fillProportionally
        horizontalStackView.alignment = .center
        horizontalStackView.spacing = 10

        // Add elements to the horizontal stackView
        horizontalStackView.addArrangedSubview(trackLabel)
        horizontalStackView.addArrangedSubview(changePlaylist)
        
        let controlButtonsStack = UIStackView(arrangedSubviews: [aiButton, playPauseButton, heartButton])
        controlButtonsStack.axis = .horizontal
        controlButtonsStack.distribution = .equalSpacing
        controlButtonsStack.alignment = .center
        controlButtonsStack.spacing = 60 // Maintain spacing as per your design requirement

        stackView.addArrangedSubview(horizontalStackView)
        stackView.addArrangedSubview(controlButtonsStack)

        // Ensure proper layout constraints for the new stack view
        NSLayoutConstraint.activate([
            controlButtonsStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            controlButtonsStack.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor)
        ])
                
        stackView.addArrangedSubview(spacerView)
        NSLayoutConstraint.activate([
            spacerView.heightAnchor.constraint(equalToConstant: 60) // Adjust this constant to increase or decrease the space
        ])

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 30),
            
            firstNameLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            firstNameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            firstNameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            firstNameTextView.topAnchor.constraint(equalTo: firstNameLabel.bottomAnchor, constant: 8),
            firstNameTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            firstNameTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            firstNameTextView.heightAnchor.constraint(equalToConstant: 40),
            
            lastNameLabel.topAnchor.constraint(equalTo: firstNameTextView.bottomAnchor, constant: 20),
            lastNameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            lastNameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            lastNameTextView.topAnchor.constraint(equalTo: lastNameLabel.bottomAnchor, constant: 8),
            lastNameTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            lastNameTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            lastNameTextView.heightAnchor.constraint(equalToConstant: 40),
            
            moodLabel.topAnchor.constraint(equalTo: lastNameTextView.bottomAnchor, constant: 20),
            moodLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            moodLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            moodTextView.topAnchor.constraint(equalTo: moodLabel.bottomAnchor, constant: 8),
            moodTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            moodTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            moodTextView.heightAnchor.constraint(equalToConstant: 40),
            
            connectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            connectButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            connectButton.widthAnchor.constraint(equalToConstant: 225),
            connectButton.heightAnchor.constraint(equalToConstant: 50),
        ])
        
        // Create stack views for each pair
        let durationStack = UIStackView(arrangedSubviews: [durationLabel, durationAmountLabel])
        let distanceStack = UIStackView(arrangedSubviews: [distanceLabel, distanceAmountLabel])
        let cadenceStack = UIStackView(arrangedSubviews: [cadenceLabel, cadenceAmountLabel])
        let paceStack = UIStackView(arrangedSubviews: [paceLabel, paceAmountLabel])

        // Configure stack views
        [durationStack, distanceStack, cadenceStack, paceStack].forEach {
            $0.axis = .vertical
            $0.distribution = .fillEqually
            $0.alignment = .fill
            $0.spacing = 1
        }

        // Create row stack views to hold each pair
        let topRowStack = UIStackView(arrangedSubviews: [durationStack, distanceStack])
        let bottomRowStack = UIStackView(arrangedSubviews: [cadenceStack, paceStack])

        // Configure row stack views
        [topRowStack, bottomRowStack].forEach {
            $0.axis = .horizontal
            $0.distribution = .fillEqually
            $0.alignment = .fill
            $0.spacing = 110
        }

        // Add rows to the main stack view
        stackView.addArrangedSubview(topRowStack)
        stackView.addArrangedSubview(bottomRowStack)

        // Ensure the stack views take up an appropriate amount of space
        NSLayoutConstraint.activate([
            topRowStack.heightAnchor.constraint(equalToConstant: 80),
            bottomRowStack.heightAnchor.constraint(equalToConstant: 80)
        ])
    }

    func updateViewBasedOnConnected() {
        if appRemote.isConnected == true {
            // connect view
            firstNameLabel.isHidden = true
            lastNameLabel.isHidden = true
            moodLabel.isHidden = true
            firstNameTextView.isHidden = true
            lastNameTextView.isHidden = true
            moodTextView.isHidden = true
            connectButton.isHidden = true
            runningNote.isHidden = true
            
            // song view
            title = ""
            imageView.isHidden = false
            trackLabel.isHidden = false
            playPauseButton.isHidden = false
            changePlaylist.isHidden = false // this retrieves your songs
            durationLabel.isHidden = false
            distanceLabel.isHidden = false
            cadenceLabel.isHidden = false
            paceLabel.isHidden = false
            durationAmountLabel.isHidden = false
            distanceAmountLabel.isHidden = false
            cadenceAmountLabel.isHidden = false
            paceAmountLabel.isHidden = false
            heartButton.isHidden = false
            aiButton.isHidden = false
            
            fetchAndSortTracksByTempo(uris: trackURIs)
        } else { // show login
            // connect view
            firstNameLabel.isHidden = false
            lastNameLabel.isHidden = false
            moodLabel.isHidden = false
            firstNameTextView.isHidden = false
            lastNameTextView.isHidden = false
            moodTextView.isHidden = false
            connectButton.isHidden = false
            runningNote.isHidden = false
            
            // song view
            title = "Sign Up"
            imageView.isHidden = true
            trackLabel.isHidden = true
            playPauseButton.isHidden = true
            changePlaylist.isHidden = true // this retrieves your songs
            durationLabel.isHidden = true
            distanceLabel.isHidden = true
            cadenceLabel.isHidden = true
            paceLabel.isHidden = true
            durationAmountLabel.isHidden = true
            distanceAmountLabel.isHidden = true
            cadenceAmountLabel.isHidden = true
            paceAmountLabel.isHidden = true
            heartButton.isHidden = true
            aiButton.isHidden = true
            
            fetchAndSortTracksByTempo(uris: trackURIs)
        }
    }
}

// MARK: - SPTAppRemoteDelegate
extension ViewController: SPTAppRemoteDelegate {
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        updateViewBasedOnConnected()
        appRemote.playerAPI?.delegate = self
        appRemote.playerAPI?.subscribe(toPlayerState: { (success, error) in
            if let error = error {
                print("Error subscribing to player state:" + error.localizedDescription)
            }
        })
        
        self.appRemote.playerAPI?.pause(nil)
        
        fetchPlayerState()
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        updateViewBasedOnConnected()
        lastPlayerState = nil
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        updateViewBasedOnConnected()
        lastPlayerState = nil
    }
}

// MARK: - SPTAppRemotePlayerAPIDelegate
extension ViewController: SPTAppRemotePlayerStateDelegate {
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        debugPrint("Spotify Track name:", playerState.track.name)
        update(playerState: playerState)
    }
}

// MARK: - SPTSessionManagerDelegate
extension ViewController: SPTSessionManagerDelegate {
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        if error.localizedDescription == "The operation couldn’t be completed. (com.spotify.sdk.login error 1.)" {
            print("AUTHENTICATE with WEBAPI")
        } else {
            presentAlertController(title: "Authorization Failed", message: error.localizedDescription, buttonTitle: "Bummer")
        }
    }

    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        presentAlertController(title: "Session Renewed", message: session.description, buttonTitle: "Sweet")
    }

    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        appRemote.connectionParameters.accessToken = session.accessToken
        appRemote.connect()
    }
}

// MARK: - Networking
extension ViewController {

    func fetchAccessToken(completion: @escaping ([String: Any]?, Error?) -> Void) {
        let url = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let spotifyAuthKey = "Basic \((spotifyClientId + ":" + spotifyClientSecretKey).data(using: .utf8)!.base64EncodedString())"
        request.allHTTPHeaderFields = ["Authorization": spotifyAuthKey,
                                       "Content-Type": "application/x-www-form-urlencoded"]

        var requestBodyComponents = URLComponents()
        let scopeAsString = stringScopes.joined(separator: " ")

        requestBodyComponents.queryItems = [
            URLQueryItem(name: "client_id", value: spotifyClientId),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: responseCode!),
            URLQueryItem(name: "redirect_uri", value: redirectUri.absoluteString),
            URLQueryItem(name: "code_verifier", value: ""), // not currently used
            URLQueryItem(name: "scope", value: scopeAsString),
        ]

        request.httpBody = requestBodyComponents.query?.data(using: .utf8)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,                              // is there data
                  let response = response as? HTTPURLResponse,  // is there HTTP response
                  (200 ..< 300) ~= response.statusCode,         // is statusCode 2XX
                  error == nil else {                           // was there no error, otherwise ...
                      print("Error fetching token \(error?.localizedDescription ?? "")")
                      return completion(nil, error)
                  }
            let responseObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            print("Access Token Dictionary=", responseObject ?? "")
            completion(responseObject, nil)
        }
        task.resume()
    }

    func fetchArtwork(for track: SPTAppRemoteTrack) {
        appRemote.imageAPI?.fetchImage(forItem: track, with: CGSize.zero, callback: { [weak self] (image, error) in
            if let error = error {
                print("Error fetching track image: " + error.localizedDescription)
            } else if let image = image as? UIImage {
                self?.imageView.image = image
            }
        })
    }

    func fetchPlayerState() {
        appRemote.playerAPI?.getPlayerState({ [weak self] (playerState, error) in
            if let error = error {
                print("Error getting player state:" + error.localizedDescription)
            } else if let playerState = playerState as? SPTAppRemotePlayerState {
                self?.update(playerState: playerState)
            }
        })
    }
}


// MARK: ~ Get Track Information
extension ViewController {
    
    
    func fetchAudioFeatures(for trackId: String, completion: @escaping ([String: Any]?, Error?) -> Void) {
        let url = URL(string: "https://api.spotify.com/v1/audio-features/\(trackId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Set the Authorization header with the access token
        guard let accessToken = appRemote.connectionParameters.accessToken else {
            completion(nil, NSError(domain: "com.easyplay", code: 401, userInfo: [NSLocalizedDescriptionKey: "Access token is missing."]))
            return
        }
        
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,                              // Ensure there is data
                  let response = response as? HTTPURLResponse,  // Ensure we have a valid HTTP response
                  (200 ..< 300) ~= response.statusCode,         // Ensure status code is 2XX
                  error == nil else {                           // Ensure no error occurred
                completion(nil, error)
                return
            }
            
            // Try to decode the JSON response
            if let audioFeatures = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                completion(audioFeatures, nil)
            } else {
                completion(nil, NSError(domain: "com.easyplay", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse audio features."]))
            }
        }
        task.resume()
    }
    
    // Fetch audio features for multiple tracks and sort by tempo
    func fetchAndSortTracksByTempo(uris: [String]) {
        let dispatchGroup = DispatchGroup()
        
        var tempDict: [Double: String] = [:]
        
       for uri in uris {
            dispatchGroup.enter()
            let trackId = uri.replacingOccurrences(of: "spotify:track:", with: "")
            fetchAudioFeatures(for: trackId) { audioFeatures, error in
                if let error = error {
                    print("Error fetching audio features for URI \(uri): \(error.localizedDescription)")
                } else if let audioFeatures = audioFeatures, let tempo = audioFeatures["tempo"] as? Double {
                    tempDict[tempo] = uri
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            // Sort the dictionary by tempo and store it in the class property
            self.tempoTrackDictionary = tempDict.sorted(by: { $0.key < $1.key }).reduce(into: [:]) { $0[$1.key] = $1.value }
            print("Sorted tempo track dictionary: \(self.tempoTrackDictionary)")
        }
        
        
    }
    
    // Use this method to call the sorted tracks
    func getSortedTracks() {

        fetchAndSortTracksByTempo(uris: trackURIs)
    }
    
    func playSongClosestTo(tempo inputTempo: Double) {
        guard let lastPlayerState = lastPlayerState else {
            print("No player state available.")
            return
        }

        // Check if the music is paused
        if lastPlayerState.isPaused {
            print("Music is paused, not playing a new song.")
            return
        }
        
        if let closestTempo = tempoTrackDictionary.keys.min(by: { abs($0 - inputTempo) < abs($1 - inputTempo) }),
           let uriForClosestTempo = tempoTrackDictionary[closestTempo] {
            
            print("Input tempo: ", inputTempo)
            print("Closest tempp: ", closestTempo)
            
            // Check if the new song is the same as the currently playing song
            if lastPlayerState.track.uri == uriForClosestTempo {
                print("The song is already playing, not restarting.")
                return
            }
            
            vol = audioSession.outputVolume
            // Fade out
            let duration=2.5
            let incrementDuration=0.1
            let steps=Int(duration/incrementDuration)
            let start_volume = vol
            var end_volume = vol - Float(0.5)
            if (end_volume < 0.1) {
                end_volume = 0.1
            }
            let timm :DispatchTime = .now()
            var volumeIncrement=(start_volume - end_volume)/Float(steps)
            for step in 0...steps{
                DispatchQueue.main.asyncAfter(deadline: timm + incrementDuration * Double(step)){
                    if let view = self.volumeView.subviews.first as? UISlider {
                        view.value = Float(step) * -volumeIncrement + start_volume
                    }
                }
                
            }
            
            DispatchQueue.main.asyncAfter(deadline: timm + incrementDuration * Double(steps)) {
                self.appRemote.playerAPI?.play(uriForClosestTempo, callback: { (success, error) in
                    if let error = error {
                        print("Error playing track: \(error.localizedDescription)")
                    }
                })
                self.appRemote.playerAPI?.seek(toPosition: 15000, callback: { (success, error) in
                    if let error = error {
                        print("Error seeking: \(error.localizedDescription) ")
                    }
                })
            }

            // Fade in
            for step in 0...steps{
                DispatchQueue.main.asyncAfter(deadline: timm + incrementDuration * Double(step) + 2.0) {
                    if let view = self.volumeView.subviews.first as? UISlider {
                        view.value = Float(step) * volumeIncrement + end_volume
                    }
                }
            }

        } else {
            print("No track found with a tempo close to \(inputTempo)")
        }
    }
    
    func startIncreasingTempo() {
        // Invalidate any existing timer
        tempoIncrementTimer?.invalidate()

        // Schedule a timer to increase tempo every 10 seconds
        tempoIncrementTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.tempo = Double(accel.tempo)
            self.cadenceAmountLabel.text = "\(String(accel.tempo)) BPM"
        }
    }
    
    func stopIncreasingTempo() {
        tempoIncrementTimer?.invalidate()
        tempoIncrementTimer = nil
    }
    
    func startTimer() {
        stopTimer() // Make sure to stop any existing timer
        updateTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateDurationLabel), userInfo: nil, repeats: true)
        RunLoop.main.add(updateTimer!, forMode: .common)
    }

    
    func stopTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
}


// MARK: Playlist Selection
extension ViewController {
    
    func fetchUserPlaylists() async throws -> [(name: String, id: String, imageURL: String?)] {
        let url = URL(string: "https://api.spotify.com/v1/me/playlists")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Set the Authorization header with the access token
        guard let accessToken = appRemote.connectionParameters.accessToken else {
            throw NSError(domain: "com.easyplay", code: 401, userInfo: [NSLocalizedDescriptionKey: "Access token is missing."])
        }
        
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "com.easyplay", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])
        }
        
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        guard let items = json?["items"] as? [[String: Any]] else {
            throw NSError(domain: "com.easyplay", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid data format"])
        }
        
        // Create the playlist array in [(name: String, id: String)] format
        var playlists: [(name: String, id: String, imageURL: String?)] = []
        for item in items {
            if let name = item["name"] as? String, let id = item["id"] as? String {
                let images = item["images"] as? [[String: Any]]
                let imageURL = images?.first?["url"] as? String // Get the first image's URL
                playlists.append((name: name, id: id, imageURL: imageURL))
            }
        }
        
        self.userPlaylists = playlists
        print(playlists)
        return playlists
    }
    
    func fetchTracksFromPlaylist(playlistId: String) {
        let urlString = "https://api.spotify.com/v1/playlists/\(playlistId)/tracks"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        guard let accessToken = appRemote.connectionParameters.accessToken else {
            print("Access token error!")
            return
        }
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Error fetching tracks: \(error)")
                return
            }

            guard let data = data else { return }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let items = json["items"] as? [[String: Any]] {
                    var trackURIsLocal: [String] = []
                    for item in items {
                        if let track = item["track"] as? [String: Any],
                           let uri = track["uri"] as? String {
                            trackURIsLocal.append(uri)
                        }
                    }
                    // Sort tracks based on tempo
                    DispatchQueue.main.async {
                        self?.trackURIs = trackURIsLocal
                        self?.fetchAndSortTracksByTempo(uris: trackURIsLocal)
                    }
                    
                    
                }
            } catch {
                print("Error parsing track data: \(error)")
            }
        }
        task.resume()
    }
    
    
}

extension ViewController {
    private func setupKeyboardDismissRecognizer() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
