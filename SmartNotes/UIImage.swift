//
//  UIImage.swift
//  SmartNotes
//
//  Created by Daian Aiziatov on 16/03/2019.
//  Copyright © 2019 Daian Aiziatov. All rights reserved.
//

import UIKit

extension UIImage {
    func save(with name: String) -> URL? {
        let imagePath = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/images/\(name).png"
        let imageUrl = URL(fileURLWithPath: imagePath)
        do {
            try self.pngData()?.write(to: imageUrl)
            return imageUrl
        } catch(let error) {
            print("[UIImage.\(#function)] Error while saving image: \(error.localizedDescription)")
            return nil
        }
    }

    static func load(with name: String) -> UIImage? {
        let imagePath = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/images/\(name).png"
        let imageUrl = URL(fileURLWithPath: imagePath)
        if FileManager.default.fileExists(atPath: imagePath),
            let imageData: Data = try? Data(contentsOf: imageUrl),
            let image: UIImage = UIImage(data: imageData, scale: UIScreen.main.scale) {
            return image
        } else {
            return nil
        }
    }
}
