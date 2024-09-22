//
//  SecondScreen.swift
//  Stryde
//
//  Created by George Xue on 9/21/24.
//

import UIKit

class FirstScreen: UIViewController {
    
    let nextButton = UIButton()
    let titleLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTitleLabel()
        setupButton()
        navigationController?.navigationBar.prefersLargeTitles = true
        
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
        
        
        // Background
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 246/255, green: 244/255, blue: 210/255, alpha: 1.0).cgColor,  // #F6F4D2
            UIColor(red: 203/255, green: 223/255, blue: 189/255, alpha: 1.0).cgColor   // #CBDFBD
        ]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)

        // Do any additional setup after loading the view.
    }
    
    func setupTitleLabel() {
        view.addSubview(titleLabel)
        
        titleLabel.text = "STRYDE"
        titleLabel.font = UIFont.systemFont(ofSize: 40, weight: .bold)
        titleLabel.textColor = UIColor(red: 139/255, green: 69/255, blue: 19/255, alpha: 1.0) // Custom brown
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50)
        ])
    }
    
    
    func setupButton() {
            view.addSubview(nextButton)
            
            nextButton.configuration = .filled()
            nextButton.configuration?.baseBackgroundColor = UIColor(red: 106/255, green: 176/255, blue: 76/255, alpha: 1.0)  // Matching green
            nextButton.configuration?.title = "Sign Up"
            nextButton.layer.cornerRadius = 10
            nextButton.clipsToBounds = true
            
            nextButton.addTarget(self, action: #selector(goToNextScreen), for: .touchUpInside)
            
            nextButton.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
                nextButton.widthAnchor.constraint(equalToConstant: 200),
                nextButton.heightAnchor.constraint(equalToConstant: 50),
            ])
        }
    
    @objc func goToNextScreen() {
        let nextScreen = SecondScreen()
        nextScreen.title = "Second Screen"
        navigationController?.pushViewController(nextScreen, animated: true)
    }

}
