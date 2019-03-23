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

    private var savedStateOfTextView = ""
    private var savedStateOfNote = ""
    private var savedStateOFLocation: CLLocationCoordinate2D?
    private var location: CLLocationCoordinate2D?

    var note: Note?

    override func viewDidLoad() {
        super.viewDidLoad()
        let font = UIFont(name: "Futura", size: 17.0)
        self.navigationItem.largeTitleDisplayMode = .never
        mapView.isHidden = true
        if let note = note {
            noteTextView.attributedText = note.details?.replaceImgTagsWithImages()
            savedStateOfNote = note.details ?? ""
            savedStateOFLocation = CLLocationCoordinate2D(latitude: note.locationLatitude, longitude: note.locationLongitude)
            if note.locationLatitude != 0.0 && note.locationLongitude != 0.0 {
                location = CLLocationCoordinate2D(latitude: note.locationLatitude, longitude: note.locationLongitude)
                pinMapView()
            } else {
                location = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
            }
        } else {
            noteTextView.text = ""
        }
        noteTextView.typingAttributes = [.font: font!,
                                         .foregroundColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)]

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
        } else if segue.identifier == "showDrawer" {
            if let destination = segue.destination as? DrawViewController {
                destination.delegate = self
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
            text.string != savedStateOfNote ||
            savedStateOFLocation?.longitude != location?.longitude &&
            savedStateOFLocation?.latitude != location?.latitude
        {

            var new: Note?
            var isNew = true
            if let note = note {
                new = note
                isNew = false
            } else {
                new = Note(context: context)
                new?.id = UUID().uuidString
                note = new
            }
            if let location = location {
                new?.locationLongitude = location.longitude
                new?.locationLatitude = location.latitude
            }

            new?.details = text.replaceImagesWithTags(for: (new?.id)!)
            new?.date = Date()
            if let _ = FirebaseManager.shared.getUser() {
                if isNew {
                    FirebaseManager.shared.save(note: new!) { error in
                        if let error = error {
                            print("[\(#function)] Error while saving note: \(error.localizedDescription)")
                        } else {
                            FirebaseManager.shared.saveAttachments(for: new!) { error in
                                if error.count > 0 {
                                    print("[\(#function)] Error while saving attachments: \(error[0].localizedDescription)")
                                }
                            }
                        }
                    }
                } else {
                    FirebaseManager.shared.update(note: new!)  { error in
                        if let error = error {
                            print("[\(#function)] Error while updating note: \(error.localizedDescription)")
                        } else {
                            FirebaseManager.shared.saveAttachments(for: new!) { error in
                                if error.count > 0 {
                                    print("[\(#function)] Error while saving attachments: \(error[0].localizedDescription)")
                                }
                            }
                        }
                    }
                }
            }
            ad.saveContext()
        }
    }

    private func append(image: UIImage) {
        let fullString = NSMutableAttributedString(attributedString: noteTextView.attributedText)
        let image1Attachment = NSTextAttachment()
        let oldWidth = image.size.width
        image1Attachment.image = image.resizeImage(scale: (UIScreen.main.bounds.width - 10)/oldWidth)
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
        if let image = info[.originalImage] as? UIImage {
            append(image: image)
            dismiss(animated:true, completion: nil)
        }
    }
}

extension ShowNoteViewController: DrawViewControllerDelegate {
    func saveSketch(image: UIImage) {
        append(image: image)
        dismiss(animated:true, completion: nil)
    }
}


