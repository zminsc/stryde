//
//  SecondScreenViewController.swift
//  Stryde
//
//  Created by Steven Chang on 9/21/24.
//

import UIKit

class SecondScreenViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        style()
        layout()
        
        setupKeyboardDismissRecognizer()
    }
    
    // MARK: - Subviews
    let firstNameLabel = UILabel()
    let lastNameLabel = UILabel()
    let moodLabel = UILabel()
    
    let firstNameTextView = UITextView()
    let lastNameTextView = UITextView()
    let moodTextView = UITextView()
    
    let connectToSpotifyButton = UIButton()
    
    // MARK: - App Life Cycle
    @objc func goToNextScreen() {
        if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
            let rootViewController = sceneDelegate.rootViewController
            navigationController?.pushViewController(rootViewController, animated: true)
        }
    }
}

// MARK: - Style & Layout
extension SecondScreenViewController {
    func style() {
        view.backgroundColor = UIColor(red: 246/255.0, green: 244/255.0, blue: 210/255.0, alpha: 1.0)
        
        navigationItem.hidesBackButton = true
        
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

        connectToSpotifyButton.translatesAutoresizingMaskIntoConstraints = false
        connectToSpotifyButton.setTitle("Connect to Spotify", for: .normal)
        connectToSpotifyButton.backgroundColor = UIColor(red: 106/255, green: 176/255, blue: 76/255, alpha: 1.0)
        connectToSpotifyButton.layer.cornerRadius = 8
        connectToSpotifyButton.addTarget(self, action: #selector(goToNextScreen), for: .touchUpInside)
    }
    
    func layout() {
        view.addSubview(firstNameLabel)
        view.addSubview(firstNameTextView)
        view.addSubview(lastNameLabel)
        view.addSubview(lastNameTextView)
        view.addSubview(moodLabel)
        view.addSubview(moodTextView)
        view.addSubview(connectToSpotifyButton)
        
        NSLayoutConstraint.activate([
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
            
            connectToSpotifyButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            connectToSpotifyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 100),
            connectToSpotifyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -100),
            connectToSpotifyButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
}

extension SecondScreenViewController {
    private func setupKeyboardDismissRecognizer() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
