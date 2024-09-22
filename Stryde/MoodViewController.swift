//
//  ModelViewController.swift
//  Stryde
//
//  Created by Shruti Agarwal on 9/22/24.
//

import UIKit

class MoodViewController: UIViewController {
    
//    / Delegate property
    weak var delegate: MoodSelectionDelegate?
    
    let llmsht = LLMCalls()
    
    var returnMessage: String = ""
    
    // UI Elements
    let genreTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "What kind of music would you like to run to?"
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    let submitButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Submit", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        setupUI()
        
        // Attach action to submit button
        submitButton.addTarget(self, action: #selector(submitGenres), for: .touchUpInside)
    }
    
    func setupUI() {
        view.addSubview(genreTextField)
        view.addSubview(submitButton)
        
        // Setup Auto Layout constraints
        NSLayoutConstraint.activate([
            genreTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            genreTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            genreTextField.widthAnchor.constraint(equalToConstant: 300),
            
            submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            submitButton.topAnchor.constraint(equalTo: genreTextField.bottomAnchor, constant: 20),
        ])
    }
    
    func getMessage(message: String) {
        returnMessage = message
    }
    
    // Action triggered when submit button is pressed
    @objc func submitGenres() {
        guard let genreInput = genreTextField.text, !genreInput.isEmpty else {
            print("Please enter some genres!")
            return
        }
        
        let LLMinput = "This user has given a description of the type of music they would like to run to. Please extract 1-3 keywords from this description that describe music genres. Return just keywords separated by spaces. DO NOT RETURN ANY OTHER TEXT PLEASE. Here is the description: \(genreInput). Sample output is Happy Upbeat. No other text please!"
        
        print("before ", returnMessage)
        
//        
//        llmsht.sendMessage(message: LLMinput, getMessage: getMessage)
//        
//        print(returnMessage)
//        
//        // Split the input text by spaces to create the genres array
//        let genres = returnMessage.split(separator: " ").map { String($0) }
//        print(returnMessage)
        
        
        
//        // Ensure we don't exceed 3 genres
//        guard genres.count <= 3 else {
//            print("Please enter up to 3 genres.")
//            return
//        }
        
        
        llmsht.sendMessage(message: LLMinput) { returnMessage in
            // This code runs after sendMessage completes
            print("Received message: \(returnMessage)")
            
            // Split the input text by spaces to create the genres array
            let genres = returnMessage.split(separator: " ").map { String($0) }
            print("Genres: \(genres)")
            
            // Ensure we don't exceed 3 genres
            guard genres.count <= 3 else {
                print("Please enter up to 3 genres.")
                return
            }
            
            self.delegate?.didSelectGenres(genres)

            
            // Dismiss the MoodViewController and pass the genres back
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: nil)
                // You can now use genres, e.g., pass it to a delegate or another view controller
            }
            
            
        }
        
        // Optionally, dismiss MoodViewController after selection
        self.dismiss(animated: true, completion: nil)
        // Call the fetchMoodMusic method and pass the genres array
        // Use the delegate to pass the genres back to the ViewController
        
    }

}
