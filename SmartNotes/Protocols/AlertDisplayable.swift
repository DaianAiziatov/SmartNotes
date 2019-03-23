//
//  AlertDisplayable.swift
//  SmartNotes
//
//  Created by Daian Aiziatov on 14/03/2019.
//  Copyright © 2019 Daian Aiziatov. All rights reserved.
//

import UIKit

protocol AlertDisplayable {
    func displayAlert(with title: String?, message: String?, actions: [UIAlertAction]?, style: UIAlertController.Style?)
}

extension AlertDisplayable where Self: UIViewController {

    func displayAlert(with title: String?, message: String?, actions: [UIAlertAction]? = nil, style: UIAlertController.Style? = .alert) {
        guard presentedViewController == nil else {
            return
        }
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style!)

        if let title = title {
            let attributedString = NSAttributedString(string: title, attributes: [.foregroundColor : #colorLiteral(red: 0.9022161365, green: 0.7540545464, blue: 0.162062794, alpha: 1) ])
            alertController.setValue(attributedString, forKey: "attributedTitle")
        }

        if let message = message {
            let attributedString = NSAttributedString(string: message, attributes: [.foregroundColor : #colorLiteral(red: 0.9022161365, green: 0.7540545464, blue: 0.162062794, alpha: 1) ])
            alertController.setValue(attributedString, forKey: "attributedMessage")
        }

        if let visualEffectView = alertController.view.searchVisualEffectsSubview()
        {
            visualEffectView.effect = UIBlurEffect(style: .dark)
        }

        alertController.view.tintColor = #colorLiteral(red: 0.9022161365, green: 0.7540545464, blue: 0.162062794, alpha: 1)

        if let actions = actions {
            actions.forEach { action in
                alertController.addAction(action)
            }
        } else {
            let okButton = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(okButton)
        }
        present(alertController, animated: true)
    }
}


extension UIView
{
    func searchVisualEffectsSubview() -> UIVisualEffectView?
    {
        if let visualEffectView = self as? UIVisualEffectView
        {
            return visualEffectView
        }
        else
        {
            for subview in subviews
            {
                if let found = subview.searchVisualEffectsSubview()
                {
                    return found
                }
            }
        }

        return nil
    }
}
