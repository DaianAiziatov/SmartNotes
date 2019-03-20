//
//  String.swift
//  SmartNotes
//
//  Created by Daian Aiziatov on 16/03/2019.
//  Copyright © 2019 Daian Aiziatov. All rights reserved.
//

import Foundation
import UIKit

extension String {

    subscript(bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }

    subscript(bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }

    subscript(bounds: PartialRangeFrom<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        return String(self[start...])
    }

    subscript(bounds: PartialRangeUpTo<Int>) -> String {
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[..<end])
    }

    func replaceImgTagsWithImages() -> NSAttributedString {
        let font = UIFont(name: "Futura", size: 17.0)
        let attributes: [NSAttributedString.Key: Any] = [.font: font!, .foregroundColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)]
        let attributedString = NSMutableAttributedString(string: self, attributes: attributes)
        do {
            let regex = try NSRegularExpression(pattern: "<img>(.*?)</img>", options: [])
            let matchesCount = regex.matches(in: attributedString.string,
                                        options: [],
                                        range: NSRange(location: 0, length: attributedString.string.utf16.count)).count
            for _ in 0..<matchesCount {
                let match = regex.matches(in: attributedString.string,
                                          options: [],
                                          range: NSRange(location: 0, length: attributedString.string.utf16.count))[0]
                if let rangeForURL = Range(match.range(at: 1), in: attributedString.string) {
                    let imageLocalURL = String(attributedString.string[rangeForURL])

                    let lowerBoundForImageLocalURLwrappedInTags = self.distance(from: self.startIndex, to: rangeForURL.lowerBound) - 5
                    let upperBoundForImageLocalURLwrappedInTags = self.distance(from: self.startIndex, to: rangeForURL.upperBound) + 6
                    if let localImage = UIImage.loadFromLocalDocuments(imagePath: imageLocalURL) {
                        let imageAttachment = NSTextAttachment()
                        let oldWidth = localImage.size.width
                        imageAttachment.image = localImage.resizeImage(scale: (UIScreen.main.bounds.width - 10)/oldWidth)
                        let imageString = NSMutableAttributedString(attachment: imageAttachment)
                        imageString.addAttributes(attributes, range: NSRange(location: 0, length: imageString.length))
                        let rangeForImageLocalURLwrappedInTags = NSMakeRange(lowerBoundForImageLocalURLwrappedInTags, upperBoundForImageLocalURLwrappedInTags - lowerBoundForImageLocalURLwrappedInTags)
                        attributedString.beginEditing()
                        attributedString.replaceCharacters(in: rangeForImageLocalURLwrappedInTags,
                                                           with: imageString)
                        attributedString.endEditing()
                    }
                }
            }
        } catch(let error) {
            print(error.localizedDescription)
        }
        return attributedString
    }

    var inImgTag: String {
        return "<img>\(self)</img>"
    }

    func indicesOf(string: String) -> [Int] {
        var indices = [Int]()
        var searchStartIndex = self.startIndex

        while searchStartIndex < self.endIndex,
            let range = self.range(of: string, range: searchStartIndex..<self.endIndex),
            !range.isEmpty
        {
            let index = distance(from: self.startIndex, to: range.lowerBound)
            indices.append(index)
            searchStartIndex = range.upperBound
        }

        return indices
    }
}
