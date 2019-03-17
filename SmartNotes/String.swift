//
//  String.swift
//  SmartNotes
//
//  Created by Daian Aiziatov on 16/03/2019.
//  Copyright © 2019 Daian Aiziatov. All rights reserved.
//

import Foundation

extension String {
    var inImgTag: String {
        return "<img src=\"\(self)\">"
    }

    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return NSAttributedString() }
        do {
            return try NSAttributedString(data: data,
                                          options: [.documentType: NSAttributedString.DocumentType.html,
                                                    .characterEncoding: String.Encoding.utf8.rawValue],
                                          documentAttributes: nil)
        } catch {
            return NSAttributedString()
        }
    }

    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
}
