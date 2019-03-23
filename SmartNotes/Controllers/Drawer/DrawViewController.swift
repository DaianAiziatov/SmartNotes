//
//  DrawViewController.swift
//  SmartNotes
//
//  Created by Daian Aiziatov on 22/03/2019.
//  Copyright © 2019 Daian Aiziatov. All rights reserved.
//

import UIKit

protocol DrawViewControllerDelegate: class {
    func saveSketch(image: UIImage)
}

class DrawViewController: UIViewController {

    @IBOutlet weak var navigationBar: UINavigationBar! {
        didSet {
            navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationBar.shadowImage = UIImage()
            navigationBar.isTranslucent = true
            navigationBar.backgroundColor = .clear
        }
    }
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var tempImageView: UIImageView!
    @IBOutlet weak var toolbar: UIToolbar! {
        didSet {
            toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
            toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
            toolbar.isTranslucent = true
            toolbar.backgroundColor = .clear
        }
    }

    weak var delegate: DrawViewControllerDelegate?

    private var lastPoint = CGPoint.zero
    private var red: CGFloat = 0.0
    private var green: CGFloat = 0.0
    private var blue: CGFloat = 0.0
    private var brushWidth: CGFloat = 10.0
    private var opacity: CGFloat = 1.0
    private var swiped = false
    private var isErase = false

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        swiped = false
        if let touch = touches.first {
            lastPoint = touch.location(in: self.view)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        swiped = true
        if let touch = touches.first {
            let currentPoint = touch.location(in: view)
            drawLineFrom(from: lastPoint, to: currentPoint)
            lastPoint = currentPoint
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !swiped {
            drawLineFrom(from: lastPoint, to: lastPoint)
        }

        // Merge tempImageView into mainImageView
        UIGraphicsBeginImageContext(mainImageView.frame.size)
        mainImageView.image?.draw(in: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height), blendMode: .normal, alpha: 1.0)
        tempImageView.image?.draw(in: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height), blendMode: .normal, alpha: opacity)
        mainImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        tempImageView.image = nil
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let settingsViewController = segue.destination as? SettingsViewController {
            settingsViewController.delegate = self
            settingsViewController.brush = brushWidth
            settingsViewController.opacity = opacity
            settingsViewController.red = red
            settingsViewController.green = green
            settingsViewController.blue = blue
        }
    }

    @IBAction func eraserChoosen(_ sender: UIBarButtonItem) {
        isErase = true
    }
    
    @IBAction func pencilChossen(_ sender: UIBarButtonItem) {
        isErase = false
    }

    @IBAction func reset(_ sender: UIBarButtonItem) {
        mainImageView.image = nil
    }

    @IBAction func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }

    @IBAction func shareSketch(_ sender: UIBarButtonItem) {
        if let image = saveSketch() {
            let activity = UIActivityViewController(activityItems: [image], applicationActivities: nil)
            present(activity, animated: true, completion: nil)
        }
    }

    @IBAction func save(_ sender: UIBarButtonItem) {
        if let image = saveSketch() {
            delegate?.saveSketch(image: image)
            print("SAVE")
        }
        dismiss(animated: true)
    }

    private func drawLineFrom(from: CGPoint, to: CGPoint) {

        UIGraphicsBeginImageContext(view.frame.size)
        if let context = UIGraphicsGetCurrentContext() {
            tempImageView.image?.draw(in: CGRect(x: 0, y: 0, width: view.frame.size.width, height: tempImageView.frame.size.height))

            context.move(to: CGPoint(x: from.x, y: from.y))
            context.addLine(to: CGPoint(x: to.x, y: to.y))

            context.setLineCap(.round)
            context.setLineWidth(brushWidth)
            if isErase {
                context.setStrokeColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            } else {
                context.setStrokeColor(red: red, green: green, blue: blue, alpha: 1.0)
            }
            context.setBlendMode(.normal)

            context.strokePath()

            tempImageView.image = UIGraphicsGetImageFromCurrentImageContext()
            tempImageView.alpha = opacity
            UIGraphicsEndImageContext()

        }
    }

    private func saveSketch() -> UIImage? {
        UIGraphicsBeginImageContext(mainImageView.bounds.size)
        mainImageView.image?.draw(in: CGRect(x: 0, y: 0,
                                               width: mainImageView.frame.size.width, height: mainImageView.frame.size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

}

extension DrawViewController: SettingsViewControllerDelegate {
    func settingsViewControllerFinished(settingsViewController: SettingsViewController) {
        self.brushWidth = settingsViewController.brush
        self.opacity = settingsViewController.opacity
        self.red = settingsViewController.red
        self.green = settingsViewController.green
        self.blue = settingsViewController.blue
    }
}
