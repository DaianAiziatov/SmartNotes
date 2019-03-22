//
//  LoadingDisplayable.swift
//  SmartNotes
//
//  Created by Daian Aiziatov on 20/03/2019.
//  Copyright © 2019 Daian Aiziatov. All rights reserved.
//

import UIKit

protocol LoadingDisplayable {
    func startLoading()
    func stopLoading(completion: @escaping ()->())
}

extension LoadingDisplayable where Self: UIViewController  {
    func startLoading() {
        let alert = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .alert)

        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.gray
        loadingIndicator.startAnimating();

        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true, completion: nil)
    }

    func stopLoading(completion: @escaping ()->()) {
        if let vc = self.presentedViewController, vc is UIAlertController {
            dismiss(animated: false, completion: completion)
        }
    }
}

