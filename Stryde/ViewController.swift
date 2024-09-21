//
//  ViewController.swift
//  Stryde
//
//  Created by Steven Chang on 9/21/24.
//

import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func connectToSpotify(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyboard.instantiateViewController(withIdentifier: "NewViewController")
        
        newViewController.modalPresentationStyle = .fullScreen
        newViewController.modalTransitionStyle = .coverVertical
        present(newViewController, animated: true, completion: nil)
    }
}

class NewViewController: UIViewController {
    @IBOutlet weak var startRunButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startRunButton.setTitle("Start Run", for: .normal)
        startRunButton.backgroundColor = .tintColor
        startRunButton.layer.cornerRadius = startRunButton.frame.size.width / 2
    }
    
    @IBAction func toggleStartRunButton(_ sender: UIButton) {
            if sender.title(for: .normal) == "Start Run" {
                sender.setTitle("End Run", for: .normal)
                sender.backgroundColor = .red
                sender.layer.cornerRadius = sender.frame.size.width / 2
            } else {
                sender.setTitle("Start Run", for: .normal)
                sender.backgroundColor = .tintColor
                sender.layer.cornerRadius = sender.frame.size.width / 2
            }
        }
}
