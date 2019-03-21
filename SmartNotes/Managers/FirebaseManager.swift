//
//  FirebaseManager.swift
//  SmartNotes
//
//  Created by Daian Aiziatov on 20/03/2019.
//  Copyright © 2019 Daian Aiziatov. All rights reserved.
//

import Foundation
import Firebase

class FirebaseManager {

    static let shared = FirebaseManager()

    private let storageRef: StorageReference
    private let auth: Auth
    private let userRef: DatabaseReference
    private var user: User? {
        if let user = Auth.auth().currentUser {
            return user
        }
        return nil
    }

    private init() {
        storageRef = Storage.storage().reference()
        userRef = Database.database().reference()
        auth = Auth.auth()
    }

    func getUser() -> User? {
        return user
    }

    func login(with email: String, password: String, completion: @escaping (Error?) -> ()) {
        auth.signIn(withEmail: email, password: password) { (userData, error) in
            if let error = error {
                completion(error)
            } else {
                completion(nil)
            }
        }
    }

    func logout() {
        do {
            try Auth.auth().signOut()
        }
        catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }

    func register(withEmail: String, password: String, completion: @escaping (Error?) -> ()) {
        auth.createUser(withEmail: withEmail, password: password) { (user, error) in
            if let error = error {
                completion(error)
            } else {
                completion(nil)
            }
        }
    }

    func update(oldPassword: String, with newPassword: String, completion: @escaping (Error?) -> ()) {
        guard let user = user, let email = user.email else {
            return
        }
        let credential = EmailAuthProvider.credential(withEmail: email, password: oldPassword)
        user.reauthenticateAndRetrieveData(with: credential, completion: { (_, error) in
            if let error = error {
                completion(error)
            } else {
                user.updatePassword(to: newPassword)
                completion(nil)
            }})
    }

}
