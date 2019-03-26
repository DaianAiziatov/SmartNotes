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
        auth.signIn(withEmail: email, password: password) { _, error in
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
        auth.createUser(withEmail: withEmail, password: password) { _, error in
            if let error = error {
                completion(error)
            } else {
                completion(nil)
            }
        }
    }

    func update(oldPassword: String, with newPassword: String, completion: @escaping (Error?) -> ()) {
        guard let user = user, let email = user.email else {
            completion(NSError.init(domain: "[FirebaseManager.\(#function)] Failed to fetch user", code: 404, userInfo: nil))
            return
        }
        let credential = EmailAuthProvider.credential(withEmail: email, password: oldPassword)
        user.reauthenticateAndRetrieveData(with: credential, completion: { _, error in
            if let error = error {
                completion(error)
            } else {
                user.updatePassword(to: newPassword)
                completion(nil)
        }})
    }

    func loadNotes(completion: @escaping (Result<[Note], NSError>) -> ()) {
        guard let user = user else {
            completion(Result.failure(NSError.init(domain: "[FirebaseManager.\(#function)] Failed to fetch user", code: 404, userInfo: nil)))
            return
        }
        var notes = [Note]()
        let notesRef = userRef.child("users").child(user.uid).child("notes")
        notesRef.observeSingleEvent(of: .value, with: { snapshot in
            for case let noteSnapshot as DataSnapshot in snapshot.children {
                if let values = noteSnapshot.value as? [String: Any],
                    let note = Note.fromDict(values)
                {
                    notes.append(note)
                }
            }
            completion(Result.success(notes))
        }) { error in
            completion(Result.failure(error as NSError))
        }
    }

    func save(note: Note, completion: @escaping (Error?) -> ()) {
        guard let user = user, let id = note.id else {
            completion(NSError.init(domain: "[FirebaseManager.\(#function)] Failed to fetch user", code: 404, userInfo: nil))
            return
        }
        let noteRef = userRef.child("users").child(user.uid).child("notes").child(id)
        let noteDict = note.dict
        noteRef.setValue(noteDict) { error, _ in
            if let error = error {
                completion(error)
            } else {
                completion(nil)
            }
        }
    }

    func deleteNote(with id: String, completion: @escaping (Error?) -> ()) {
        guard let user = user else {
            completion(NSError.init(domain: "[FirebaseManager.\(#function)] Failed to fetch user", code: 404, userInfo: nil))
            return
        }
        let noteRef = userRef.child("users").child(user.uid).child("notes").child(id)
        noteRef.removeValue { error, _  in
            if error == nil {
                completion(nil)
            } else {
                completion(error)
            }
        }
    }

    func update(note: Note, completion: @escaping (Error?) -> ()) {
        guard let user = user, let id = note.id else {
            completion(NSError.init(domain: "[FirebaseManager.\(#function)] Failed to fetch user", code: 404, userInfo: nil))
            return
        }
        let noteDict = note.dict
        let noteRef = userRef.child("users").child(user.uid).child("notes").child(id)
        noteRef.updateChildValues(noteDict) { error, _ in
            if let error = error {
                completion(error)
            } else {
                completion(nil)
            }
        }
    }

    func saveAttachments(for note: Note, completion: @escaping ([Error]) -> ()) {
        print("[FirebaseManager.\(#function)] Start saving attachments")
        guard let user = user, let id = note.id else {
            print("[FirebaseManager.\(#function)] Failed to fetch user")
            var errors =  [Error]()
            errors.append(NSError.init(domain: "[FirebaseManager.\(#function)] Failed to fetch user", code: 404, userInfo: nil))
            completion(errors)
            return
        }
        let imageURLs = DataManager.getImagesURL(for: id)
        let recordingsURLs = DataManager.getRecordingsURL(for: id)
        let urls = imageURLs + recordingsURLs
        print("[FirebaseManager.\(#function)] Fetched \(urls.count) urls inside note")
        guard urls.count > 0 else {
            completion([Error]())
            return
        }
        let errors = Atomic<[Error]>([Error]())
        let count = Atomic<Int>(0)
        for url in urls {
            let localPath = url.pathComponents.suffix(3).joined(separator: "/")
            print("[FirebaseManager.\(#function)] localPath: \(localPath)")
            let attachmentRef = storageRef.child(user.uid).child(localPath)
            attachmentRef.putFile(from: url, metadata: nil) { metadata, error in
                count.mutate { $0 += 1 }
                if let error = error {
                    errors.mutate { $0.append(error)}
                }
                if count.value == urls.count {
                    completion(errors.value)
                }
            }
        }
    }

    func loadAttachmentsURL(for note: Note, completion: @escaping (Result<[URL], NSError>) -> ()) {
        guard let user = user, let details = note.details, let recordings = note.recordings else {
            completion(Result.failure(NSError.init(domain: "[FirebaseManager.\(#function)] Failed to fetch user", code: 404, userInfo: nil)))
            return
        }
        let imagesURLs = details.getLocalURLsOfAttachments()
        let recordingsURLs = recordings.compactMap({ URL(string: $0) })
        let urls = imagesURLs + recordingsURLs
        let fetchedURLs = Atomic<[URL]>([URL]())
        let count = Atomic<Int>(0)
        for url in urls {
            let attachmentRef = storageRef.child(user.uid).child(url.path)
            attachmentRef.downloadURL { url, error in
                count.mutate { $0 += 1 }
                if let error = error {
                    print("[FirebaseManager.\(#function)] Error: \(error.localizedDescription)")
                    completion(Result.failure(error as NSError))
                } else {
                    fetchedURLs.mutate { $0.append(url!) }
                }
                if count.value == urls.count {
                    completion(Result.success(fetchedURLs.value))
                }
            }
        }
    }

    func deleteAttachments(for note: Note, completion: @escaping (Error?) -> ()) {
        guard let _ = user, let details = note.details else {
            completion(NSError.init(domain: "[FirebaseManager.\(#function)] Failed to fetch user", code: 404, userInfo: nil))
            return
        }
        let attachmentsURLS = details.getLocalURLsOfAttachments()
        let count = Atomic<Int>(0)
        for url in attachmentsURLS {
            deleteAttachment(with: url) { error in
                count.mutate { $0 += 1 }
                if let error = error {
                    print("[FirebaseManager.\(#function)] Error: \(error.localizedDescription)")
                    completion(error)
                }
                if count.value == attachmentsURLS.count {
                    completion(nil)
                }
            }
        }
    }

    func deleteAttachment(with localURL: URL, completion: @escaping (Error?) -> ()) {
        guard let user = user else {
            completion(NSError.init(domain: "[FirebaseManager.\(#function)] Failed to fetch user", code: 404, userInfo: nil))
            return
        }
        let attachmentsRef = storageRef.child(user.uid).child(localURL.path)
        attachmentsRef.delete { error in
            if let error = error {
                completion(error)
            }
            completion(nil)
        }
    }

}
