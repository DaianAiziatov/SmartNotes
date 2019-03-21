//
//  DataManager.swift
//  SmartNotes
//
//  Created by Daian Aiziatov on 20/03/2019.
//  Copyright © 2019 Daian Aiziatov. All rights reserved.
//

import Foundation

class DataManager {

    private static let fileManager = FileManager.default
    static let localDoumentsDirectoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

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
}
