//
//  SyncManager.swift
//  SmartNotes
//
//  Created by Daian Aiziatov on 21/03/2019.
//  Copyright © 2019 Daian Aiziatov. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class SyncManager {

    static func sync(completion: @escaping (Error?) -> ()) {
        print("[SyncManager.\(#function)] Start syncing")
        self.saveAllLocalNotesToCloud { error in
            if let error = error {
                print("[SyncManager.\(#function)] End syncing with error: \(error.localizedDescription)")
                completion(error)
            } else {
                self.getDifferenceBetweenLocalAndCloud { error in
                    if let error = error {
                        print("[SyncManager.\(#function)] End syncing with error: \(error.localizedDescription)")
                        completion(error)
                    } else {
                        print("[SyncManager.\(#function)] End syncing succesfully")
                        completion(nil)
                    }
                }
            }
        }
    }

    static func loadCloudNotesToLocalStorage(completion: @escaping (Error?) -> ()) {
        print("[SyncManager.\(#function)] Start loading notes")
        FirebaseManager.shared.loadNotes{ result in
            print("[SyncManager.\(#function)] Inside fetched result")
            switch result {
            case .success(let cloudNotes):
                for note in cloudNotes {
                    DataManager.save(note: note)
                    FirebaseManager.shared.loadAttachmentsURL(for: note) { result in
                        switch result {
                        case .failure(let error):
                            print("[SyncManager.\(#function)] Error while loading url attachments: \(error.localizedDescription)")
                            completion(error)
                        case .success(let urls):
                            for url in urls {
                                DataManager.downloadData(from: url) { result in
                                    switch result {
                                    case .failure(let error):
                                        print("[SyncManager.\(#function)] Error while loading image: \(error.localizedDescription)")
                                    case .success(let data):
                                        DataManager.saveDataIntoDocuments(with: url.path, data: data)
                                        print("[SyncManager.\(#function)] Data saved")
                                    }
                                }
                            }
                            print("[SyncManager.\(#function)] Successfully load attachments")
                            completion(nil)
                        }
                    }
                }
                print("[SyncManager.\(#function)] Success")
                completion(nil)
            case .failure(let error):
                print("[SyncManager.\(#function)] Error: \(error.localizedDescription)")
                completion(error)
            }
        }
    }

    private static func saveAllLocalNotesToCloud(completion: @escaping (Error?) -> ()) {
        guard let localNotes = DataManager.loadNotes() else {
            print("[SyncManager.\(#function)] No local notes. END.")
            completion(nil)
            return
        }
        print("[SyncManager.\(#function)] Get notes")
        guard localNotes.count > 0 else {
            completion(nil)
            return
        }
        for note in localNotes {
            print("[SyncManager.\(#function)] Saving \(note.id!)")
            FirebaseManager.shared.save(note: note) { error in
                print("[SyncManager.\(#function)] Result about saving \(note.id!)")
                if let error = error {
                    print("[SyncManager.\(#function)] Error while saving: \(error.localizedDescription)")
                    completion(error)
                } else {
                    print("[SyncManager.\(#function)] Saved \(note.id!)")
                    FirebaseManager.shared.saveAttachments(for: note) { errors in
                        print("[SyncManager.\(#function)] Result about saving attachments \(note.id!)")
                        if errors.count > 0 {
                            for error in errors {
                                print("[SyncManager.\(#function)] Error: \(error.localizedDescription)")
                                completion(error)
                            }
                        } else {
                            print("[SyncManager.\(#function)] Success")
                            completion(nil)
                        }
                    }
                }
            }
        }
    }

    private static func getDifferenceBetweenLocalAndCloud(completion: @escaping (Error?) -> ()) {
        guard let localNotes = DataManager.loadNotes() else {
            print("[SyncManager.\(#function)] No local notes. END.")
            completion(nil)
            return
        }
        FirebaseManager.shared.loadNotes{ result in
            switch result {
            case .success(let cloudNotes):
                let difference = localNotes.difference(from: cloudNotes)
                for note in difference {
                    DataManager.save(note: note)
                    FirebaseManager.shared.loadAttachmentsURL(for: note) { result in
                        switch result {
                        case .failure(let error):
                            print("[SyncManager.\(#function)] Error while loading url attachments: \(error.localizedDescription)")
                            completion(error)
                        case .success(let urls):
                            for url in urls {

                                DataManager.downloadData(from: url) { result in
                                    switch result {
                                    case .failure(let error):
                                        print("[SyncManager.\(#function)] Error while loading data: \(error.localizedDescription)")
                                    case .success(let data):
                                        DataManager.saveDataIntoDocuments(with: url.pathComponents.suffix(3).joined(separator: "/"), data: data)
                                        print("[SyncManager.\(#function)] Data saved")
                                    }

                                }
                            }
                            print("[SyncManager.\(#function)] Successfully load attachments")
                            completion(nil)
                        }
                    }
                }
                print("[SyncManager.\(#function)] Success")
                completion(nil)
            case .failure(let error):
                print("[SyncManager.\(#function)] Error: \(error.localizedDescription)")
                completion(error)
            }
        }
    }

}
