//
//  UserProfileTableViewController.swift
//  SmartNotes
//
//  Created by Daian Aiziatov on 21/03/2019.
//  Copyright © 2019 Daian Aiziatov. All rights reserved.
//

import UIKit

class UserProfileTableViewController: UITableViewController, AlertDisplayable, LoadingDisplayable {

    @IBOutlet weak var oldPasswordTextField: UITextField!
    @IBOutlet weak var newPasswordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var userEmailLabel: UILabel! {
        didSet {
            userEmailLabel.text = FirebaseManager.shared.getUser()?.email
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = false
        self.navigationItem.hidesBackButton = true
    }

    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        self.navigationController?.dismiss(animated: true)
    }
    

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            switch indexPath.row {
            case 0: oldPasswordTextField.becomeFirstResponder()
            case 1: newPasswordTextField.becomeFirstResponder()
            default: confirmPasswordTextField.becomeFirstResponder()
            }
        } else if indexPath.section == 2 && indexPath.row == 0 {
            changePassword()
        } else if indexPath.section == 3 && indexPath.row == 0 {
            FirebaseManager.shared.logout()
            self.navigationController?.dismiss(animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    private func changePassword() {
        guard let oldPassword = oldPasswordTextField.text, let newPassword = newPasswordTextField.text, let _ = confirmPasswordTextField.text else {
            displayAlert(with: "Empty fields", message: "Please fill all field")
            return
        }
        guard isPasswordValid() else {
            displayAlert(with: "Password does not match", message: "Please check passwords fields")
            return
        }
        self.startLoading()
        FirebaseManager.shared.update(oldPassword: oldPassword, with: newPassword) { error in
            if let error = error {
                self.stopLoading {
                    self.displayAlert(with: "Error", message: error.localizedDescription)
                }
            } else {
                self.stopLoading {
                    self.clearTextField()
                }
            }
        }
    }

    private func isPasswordFieldsFilled() -> Bool {
        return oldPasswordTextField.hasText && newPasswordTextField.hasText && confirmPasswordTextField.hasText
    }

    private func isPasswordValid() -> Bool {
        return newPasswordTextField.hasText && (newPasswordTextField.text == confirmPasswordTextField.text)
    }

    private func clearTextField() {
        oldPasswordTextField.text = ""
        newPasswordTextField.text = ""
        confirmPasswordTextField.text = ""
    }

}
