//
//  RegisterViewController.swift
//  SmartNotes
//
//  Created by Daian Aiziatov on 20/03/2019.
//  Copyright © 2019 Daian Aiziatov. All rights reserved.
//

import UIKit

class RegisterViewController: UIViewController, AlertDisplayable, LoadingDisplayable {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var registerButton: UIButton! {
        didSet {
            registerButton.layer.masksToBounds = true
            registerButton.clipsToBounds = true
            registerButton.layer.cornerRadius = 10.0
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Register"
    }
    
    @IBAction func registerTapped(_ sender: Any) {
        guard let email = emailTextField.text, let password = passwordTextField.text, let _ = confirmPasswordTextField.text else {
            displayAlert(with: "Empty fields", message: "Please fill all field")
            return
        }
        guard isPasswordValid() else {
            displayAlert(with: "Password does not match", message: "Please check passwords fields")
            return
        }
        self.startLoading()
        FirebaseManager.shared.register(withEmail: email, password: password) { error in
            if let error = error {
                self.stopLoading {
                    self.displayAlert(with: "Error", message: error.localizedDescription)
                }
            } else {
                self.stopLoading {
                    self.navigationController?.popViewController(animated: true)
                }
            }

        }
    }

    private func isPasswordValid() -> Bool {
        return passwordTextField.hasText && (passwordTextField.text == confirmPasswordTextField.text)
    }

    private func areFieldsFilled() -> Bool {
        return emailTextField.hasText && passwordTextField.hasText && confirmPasswordTextField.hasText
    }
    
}
