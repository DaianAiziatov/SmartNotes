//
//  DictionaryConvertiable.swift
//  SmartNotes
//
//  Created by Daian Aiziatov on 21/03/2019.
//  Copyright © 2019 Daian Aiziatov. All rights reserved.
//

import Foundation

protocol DictionaryConvertible {
    static func fromDict(_ note: [String: Any]) -> Note?
    var dict: [String: Any] { get }
}
