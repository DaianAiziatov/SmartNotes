//
//  Note.swift
//  SmartNotes
//
//  Created by Daian Aiziatov on 21/03/2019.
//  Copyright © 2019 Daian Aiziatov. All rights reserved.
//

import Foundation
import CoreData

extension Note: DictionaryConvertible {

    var dict: [String : Any] {
        return [
            "id"               : self.id ?? "No ID",
            "date"             : self.date?.timeIntervalSince1970 ?? 0.0,
            "details"          : self.details ?? "No details",
            "locationLatitude" : self.locationLatitude,
            "locationLongitude": self.locationLongitude
        ]
    }

    static func fromDict(_ note: [String: Any]) -> Note? {
        if let id = note["id"] as? String,
            let date = note["date"] as? TimeInterval,
            let details = note["details"] as? String,
            let locationLatitude = note["locationLatitude"] as? Double,
            let locationLongitude = note["locationLongitude"] as? Double
        {
            let newNote = Note(context: context)
            newNote.id = id
            newNote.date = Date(timeIntervalSince1970: date)
            newNote.details = details
            newNote.locationLatitude = locationLatitude
            newNote.locationLongitude = locationLongitude
            return newNote
        } else {
            return nil
        }
    }
}
