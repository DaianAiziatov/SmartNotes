//
//  ShowNoteViewController.swift
//  SmartNotes
//
//  Created by Daian Aiziatov on 14/03/2019.
//  Copyright © 2019 Daian Aiziatov. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class ShowNoteViewController: UIViewController, AlertDisplayable {

    @IBOutlet private weak var noteTextView: UITextView!
    @IBOutlet private weak var mapView: MKMapView!
    @IBOutlet private weak var locationButton: UIBarButtonItem!
    
    private var locationManager = CLLocationManager()

    private var savedStateOfNote: NSAttributedString?
    private var savedStateOFLocation: CLLocationCoordinate2D?
    private var location: CLLocationCoordinate2D?

    var note: Note?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.largeTitleDisplayMode = .never
        mapView.isHidden = true
        if let note = note {
            noteTextView.attributedText = note.details as? NSAttributedString
            savedStateOfNote = note.details as? NSAttributedString
            savedStateOFLocation = CLLocationCoordinate2D(latitude: note.locationLatitude, longitude: note.locationLongitude)
            if note.locationLatitude != 0.0 && note.locationLongitude != 0.0 {
                location = CLLocationCoordinate2D(latitude: note.locationLatitude, longitude: note.locationLongitude)
                pinMapView()
            }
        } else {
            noteTextView.text = ""
            savedStateOfNote = NSAttributedString(string: "")
        }

    }

    override func viewWillDisappear(_ animated: Bool) {
        saveNote()
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showMap" {
            if let destination = segue.destination as? MapViewController {
                destination.delegate = self
                destination.location = location
            }
        }
    }

    @IBAction func addPhotoTapped(_ sender: UIBarButtonItem) {
        let takePhoto = UIAlertAction(title: "Take Photo", style: .default, handler: openCamera(action:))
        let openLibrary = UIAlertAction(title: "Open Library", style: .default, handler: openLibrary(action:))
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        displayAlert(with: nil, message: nil, actions: [takePhoto, openLibrary, cancel], style: .actionSheet)
    }

    @objc
    private func showMap(sender: UIBarButtonItem) {
        mapView.isHidden = !mapView.isHidden
    }

    private func openCamera(action: UIAlertAction) -> Void {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .camera;
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
    }

    private func openLibrary(action: UIAlertAction) -> Void {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary;
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    private func pinMapView() {
        if let location = location {
            mapView.isHidden = false
            let annotation = MKPointAnnotation()
            annotation.coordinate = location
            let region = MKCoordinateRegion(center: location, span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002))
            mapView.addAnnotation(annotation)
            mapView.setRegion(region, animated: true)
            let showMap = UIBarButtonItem(image: UIImage(named: "map_icon"),
                                          style: .plain, target: self,
                                          action: #selector(showMap(sender:)))
            navigationItem.rightBarButtonItem = showMap
        }
    }

    private func saveNote() {
        if let text = noteTextView.attributedText,
            !text.string.isEmpty,
            let savedStateOfNote = savedStateOfNote,
            text != savedStateOfNote ||
            savedStateOFLocation?.longitude != location?.longitude &&
            savedStateOFLocation?.latitude != location?.latitude {

            var new: Note?
            
            if let note = note {
                new = note
            } else {
                new = Note(context: context)
                note = new
            }
            if let location = location {
                new?.locationLongitude = location.longitude
                new?.locationLatitude = location.latitude
            }
            new?.details = text
            new?.date = NSDate() as Date

            ad.saveContext()
        }
    }

    private func append(image: UIImage) {
        let fullString = NSMutableAttributedString(attributedString: noteTextView.attributedText)
        let image1Attachment = NSTextAttachment()
        let oldWidth = image.size.width
        let scaleFactor = oldWidth / (view.frame.size.width - 10)
        image1Attachment.image = UIImage(cgImage: image.cgImage!, scale: scaleFactor, orientation: .up)
        let image1String = NSAttributedString(attachment: image1Attachment)
        fullString.append(image1String)
        noteTextView.attributedText = fullString
        let font = UIFont(name: "Futura", size: 17.0)
        noteTextView.typingAttributes = [.font: font!,
                                         .foregroundColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)]
    }
}

extension ShowNoteViewController: MapViewControllerDelegate {
    
    func saveCoordinates(coordinates: CLLocationCoordinate2D) {
        self.location = coordinates
        pinMapView()
    }
}

extension ShowNoteViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[.originalImage] as! UIImage
        append(image: image)
        dismiss(animated:true, completion: nil)
    }
}
