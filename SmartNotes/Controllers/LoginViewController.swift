//
//  LoginViewController.swift
//  SmartNotes
//
//  Created by Daian Aiziatov on 20/03/2019.
//  Copyright © 2019 Daian Aiziatov. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, AlertDisplayable, LoadingDisplayable {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton! {
        didSet {
            loginButton.layer.masksToBounds = true
            loginButton.clipsToBounds = true
            loginButton.layer.cornerRadius = 10.0
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Login"
    }

    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        self.navigationController?.dismiss(animated: true)
    }

    @IBAction func loginTapped(_ sender: UIButton) {
        if areFieldsFilled() {
            login()
        } else {
            displayAlert(with: "Error", message:  "Please fill login information")
        }
    }

    private func login() {
        self.startLoading()
        guard let email = emailTextField.text, let password = passwordTextField.text else {
            return
        }
        FirebaseManager.shared.login(with: email, password: password) { error in
            if let error = error {
                self.stopLoading {
                    self.displayAlert(with: "Error", message:  error.localizedDescription)
                }
            } else {
                self.stopLoading { self.goToUserProfile() }
            }
        }
    }

    private func areFieldsFilled() -> Bool {
        return emailTextField.hasText && passwordTextField.hasText
    }

    private func goToUserProfile() {
        self.performSegue(withIdentifier: "showProfile", sender: self)
    }

}
