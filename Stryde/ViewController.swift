//
//  ViewController.swift
//  easyplay
//
//  Created by jrasmusson on 2022-03-21.
//

import UIKit

class ViewController: UIViewController {
    
    let accel = Accel()

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
    let stackView = UIStackView()
    let connectLabel = UILabel()
    let connectButton = UIButton(type: .system)
    let imageView = UIImageView()
    let trackLabel = UILabel()
    let playPauseButton = UIButton(type: .system)
    let signOutButton = UIButton(type: .system)
    let startRun = UIButton(type: .system)
    
    var tempoTrackDictionary: [Double: String] = [:]
    
    var tempo: Double? {
        didSet {
            // Whenever the tempo changes, play the song with the closest tempo
            if let newTempo = tempo {
                playSongClosestTo(tempo: newTempo)
            }
        }
    }
    
    var tempoIncrementTimer: Timer?
        


    // MARK: App Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBlue
        style()
        layout()
        
        navigationItem.hidesBackButton = true

        
        // MARK: Background
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 246/255, green: 244/255, blue: 210/255, alpha: 1.0).cgColor,  // #F6F4D2
            UIColor(red: 203/255, green: 223/255, blue: 189/255, alpha: 1.0).cgColor   // #CBDFBD
        ]
            gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
            gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
            gradientLayer.frame = view.bounds
            view.layer.insertSublayer(gradientLayer, at: 0)
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
        trackLabel.text = playerState.track.name

        let configuration = UIImage.SymbolConfiguration(pointSize: 50, weight: .bold, scale: .large)
        if playerState.isPaused {
            playPauseButton.setImage(UIImage(systemName: "play.circle.fill", withConfiguration: configuration), for: .normal)
        } else {
            playPauseButton.setImage(UIImage(systemName: "pause.circle.fill", withConfiguration: configuration), for: .normal)
        }
    }

    // MARK: - Actions
    @objc func startTrackingBPM(_ button:UIButton) {
        accel.startTracking()
    }
    
    
    
    @objc func didTapPauseOrPlay(_ button: UIButton, inputTempo: Double) {
        if let lastPlayerState = lastPlayerState, lastPlayerState.isPaused {
            appRemote.playerAPI?.resume(nil)
            startIncreasingTempo()
            
        } else {
            appRemote.playerAPI?.pause(nil)
            stopIncreasingTempo()
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

    // MARK: - Private Helpers
    private func presentAlertController(title: String, message: String, buttonTitle: String) {
        DispatchQueue.main.async {
            let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let action = UIAlertAction(title: buttonTitle, style: .default, handler: nil)
            controller.addAction(action)
            self.present(controller, animated: true)
        }
    }
}

// MARK: Style & Layout
extension ViewController {
    func style() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .center

        connectLabel.translatesAutoresizingMaskIntoConstraints = false
        connectLabel.text = "STRYDE"
        connectLabel.font = UIFont.preferredFont(forTextStyle: .title3)
        connectLabel.textColor = .black

        connectButton.translatesAutoresizingMaskIntoConstraints = false
        connectButton.configuration = .filled()
        connectButton.setTitle("Continue with Spotify", for: [])
        connectButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title3)
        connectButton.addTarget(self, action: #selector(didTapConnect), for: .primaryActionTriggered)

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
        
    }

    func layout() {

        stackView.addArrangedSubview(connectLabel)
        stackView.addArrangedSubview(connectButton)
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(trackLabel)
        stackView.addArrangedSubview(playPauseButton)
        stackView.addArrangedSubview(signOutButton)
        stackView.addArrangedSubview(startRun)

        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    func updateViewBasedOnConnected() {
        if appRemote.isConnected == true {
            connectButton.isHidden = true
            signOutButton.isHidden = false
            connectLabel.isHidden = true
            imageView.isHidden = false
            trackLabel.isHidden = false
            playPauseButton.isHidden = false
            startRun.isHidden = false
            getSortedTracks()
            tempo = 90
            startIncreasingTempo()
            
        }
        else { // show login
            signOutButton.isHidden = true
            connectButton.isHidden = false
            connectLabel.isHidden = false
            imageView.isHidden = true
            trackLabel.isHidden = true
            playPauseButton.isHidden = true
            startRun.isHidden = true
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
        let trackURIs = [
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

            
            appRemote.playerAPI?.play(uriForClosestTempo, callback: { (success, error) in
                if let error = error {
                    print("Error playing track: \(error.localizedDescription)")
                }
            })
        } else {
            print("No track found with a tempo close to \(inputTempo)")
        }
    }
    
    func startIncreasingTempo() {
        // Invalidate any existing timer
        tempoIncrementTimer?.invalidate()

        // Schedule a timer to increase tempo every 10 seconds
        tempoIncrementTimer = Timer.scheduledTimer(withTimeInterval: 6.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            // Increase tempo by 20
//            if let currentTempo = self.tempo {
//                self.tempo = currentTempo + 5
//                print("Increased tempo to: \(self.tempo!)")
//            }
            self.tempo = Double(accel.tempo)
        }
    }
    
    func stopIncreasingTempo() {
        tempoIncrementTimer?.invalidate()
        tempoIncrementTimer = nil
    }
}
