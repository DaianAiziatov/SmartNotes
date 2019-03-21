//
//  UIImage.swift
//  SmartNotes
//
//  Created by Daian Aiziatov on 16/03/2019.
//  Copyright © 2019 Daian Aiziatov. All rights reserved.
//

import UIKit

var imagesCache = NSCache<NSString, UIImage>()

extension UIImage {
    
    func save(with name: String) -> String? {
        let noteID = String(name.split(separator: "_")[0])
        let fileManager = FileManager.default
        let localDoumentsDirectoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let noteDirectoryURL = localDoumentsDirectoryURL.appendingPathComponent(noteID)
        do {
            if !fileManager.fileExists(atPath: noteDirectoryURL.path) {
                try fileManager.createDirectory(atPath: noteDirectoryURL.path, withIntermediateDirectories: true, attributes: nil)
            }
            let imageUrl = noteDirectoryURL.appendingPathComponent(name).appendingPathExtension("png")
            try self.pngData()?.write(to: imageUrl)
            return "\(noteID)/\(name).png"
        } catch(let error) {
            print("[UIImage.\(#function)] Error while saving image: \(error.localizedDescription)")
            return nil
        }
    }

    static func loadFromLocalDocuments(imagePath: String) -> UIImage? {
        let fileManager = FileManager.default
        let localDoumentsDirectoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imageUrl = localDoumentsDirectoryURL.appendingPathComponent(imagePath)
        if FileManager.default.fileExists(atPath: imageUrl.path),
            let imageData: Data = try? Data(contentsOf: imageUrl),
            let image: UIImage = UIImage(data: imageData, scale: UIScreen.main.scale) {
            return image
        } else {
            return nil
        }
    }

    func resizeImage(scale: CGFloat) -> UIImage {
        let newSize = CGSize(width: self.size.width*scale, height: self.size.height*scale)
        let rect = CGRect(origin: CGPoint.zero, size: newSize)

        UIGraphicsBeginImageContext(newSize)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }

    static func load(from url: URL, completion: @escaping (Result<UIImage, NSError>) -> ()) {
        if let cachedImage = imagesCache.object(forKey: url.absoluteString as NSString) {
            completion(Result.success(cachedImage))
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(Result.failure(error as NSError))
                return
            }
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data,
                let image = UIImage(data: data)
                else { return }
            completion(Result.success(image))
            imagesCache.setObject(image, forKey: url.absoluteString as NSString)
        }.resume()
    }
}
