//
//  DataManager.swift
//  SmartNotes
//
//  Created by Daian Aiziatov on 20/03/2019.
//  Copyright © 2019 Daian Aiziatov. All rights reserved.
//

import Foundation
import CoreData

class DataManager {

    private static let fileManager = FileManager.default
    static let localDoumentsDirectoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

    static func loadNotes() -> [Note]? {
        print("[DataManager.\(#function)]: Start load notes from local storage")
        let fetchRequest: NSFetchRequest<Note> = Note.fetchRequest()
        do {
            var notes = try context.fetch(fetchRequest)
            notes.sort(by: {$0.date! > $1.date!})
            print("[DataManager.\(#function)]: Returning notes")
            return notes
        } catch (let error) {
            print("[DataManager.\(#function)]: Cannot fetch from database. Error: \(error.localizedDescription)")
            return nil
        }
    }

    static func save(note: Note) {
        guard
            let id = note.id,
            let date = note.date,
            let details = note.details
            else { return }
        if isExistNote(with: id) {
            print("[DataManager.\(#function)] Already exist \(id)")
        } else {
            print("[DataManager.\(#function)] Saving \(id)")
            let locationLatitude = note.locationLatitude
            let locationLongitude = note.locationLongitude
            let new = Note(context: context)
            new.id = id
            new.date = date
            new.details = details
            new.locationLongitude = locationLongitude
            new.locationLatitude = locationLatitude
            ad.saveContext()
        }
    }

    static func isExistNote(with noteID: String) -> Bool {
        if let localNotes = loadNotes() {
            let noteWithId = localNotes.filter({ $0.id == noteID })
            print(noteWithId)
            if noteWithId.count > 0 {
                return true
            } else {
                return false
            }
        }
        return false
    }

    static func deleteFolderForNote(with noteID: String) {
        let noteDirectoryURL = localDoumentsDirectoryURL.appendingPathComponent(noteID)
        do {
            try fileManager.removeItem(at: noteDirectoryURL)
        } catch(let error) {
            print("[DataManger.\(#function)] Error: \(error.localizedDescription)")
        }
    }
    
    static func clearFolderForNote(with noteID: String) {
        let noteDirectoryURL = localDoumentsDirectoryURL.appendingPathComponent(noteID)
        do {
            let directoryContents = try fileManager.contentsOfDirectory(atPath: noteDirectoryURL.path)
            if !directoryContents.isEmpty {
                for itemName in directoryContents {
                    let itemPath = noteDirectoryURL.appendingPathComponent(itemName)
                    try fileManager.removeItem(at: itemPath)
                }

            }
        } catch(let error) {
            print("[DataManger.\(#function)] Error: \(error.localizedDescription)")
        }
    }

    static func createRecordingsDirectory(for noteID: String) -> Bool {
        let noteRecordingsDirectoryURL = localDoumentsDirectoryURL.appendingPathComponent(noteID).appendingPathComponent("recordings")
        do {
            if !fileManager.fileExists(atPath: noteRecordingsDirectoryURL.path) {
                try fileManager.createDirectory(atPath: noteRecordingsDirectoryURL.path, withIntermediateDirectories: true, attributes: nil)
                return true
            }
            return true
        } catch(let error) {
            print("[DataManager.\(#function)] Error while creating recording directory: \(error.localizedDescription)")
            return false
        }
    }

    static func countRecordings(for noteID: String) -> Int {
        if let directoryContents = fileManager.contents(atPath: "\(noteID)/recordings/") {
            return directoryContents.count
        } else {
            return 0
        }
    }
}
