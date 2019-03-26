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
import AVFoundation

class ShowNoteViewController: UIViewController, AlertDisplayable, LoadingDisplayable {

    @IBOutlet private weak var noteTextView: UITextView!
    @IBOutlet private weak var mapView: MKMapView!
    @IBOutlet private weak var cameraButton: UIBarButtonItem!
    @IBOutlet private weak var sketchButton: UIBarButtonItem!
    @IBOutlet private weak var locationButton: UIBarButtonItem!
    @IBOutlet private weak var recordButton: UIBarButtonItem! {
        didSet {
            recordButton.action = #selector(record)
        }
    }

    private var locationManager = CLLocationManager()
    private var recorder: Recorder!

    private var savedStateOfTextView = ""
    private var savedStateOfNote = ""
    private var savedRecordingsCount = 0
    private var savedStateOFLocation: CLLocationCoordinate2D?
    private var location: CLLocationCoordinate2D?

    var note: Note?

    override func viewDidLoad() {
        super.viewDidLoad()
        let showRecordings = UIBarButtonItem(image: UIImage(named: "records_library_icon"),
                                      style: .plain, target: self,
                                      action: #selector(showRecordings(sender:)))
        navigationItem.rightBarButtonItem = showRecordings
        recorder = Recorder(delegate: self)
        let font = UIFont(name: "Futura", size: 17.0)
        self.navigationItem.largeTitleDisplayMode = .never
        mapView.isHidden = true
        if let note = note {
            noteTextView.attributedText = note.details?.replaceImgTagsWithImages()
            savedStateOfNote = note.details ?? ""
            savedRecordingsCount = DataManager.getRecordingsURL(for: note.id!).count
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
        } else if segue.identifier == "showRecordings" {
            if let destination = segue.destination as? RecordingsViewController {
                saveNote()
                destination.note = note
            }
        }
    }

    @IBAction func addPhotoTapped(_ sender: UIBarButtonItem) {
        let takePhoto = UIAlertAction(title: "Take Photo", style: .default, handler: openCamera(action:))
        let openLibrary = UIAlertAction(title: "Open Library", style: .default, handler: openLibrary(action:))
        let cancel = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        displayAlert(with: nil, message: nil, actions: [takePhoto, openLibrary, cancel], style: .actionSheet)
    }

    @objc
    private func showMap(sender: UIBarButtonItem) {
        mapView.isHidden = !mapView.isHidden
    }

    @objc
    private func showRecordings(sender: UIBarButtonItem) {
        performSegue(withIdentifier: "showRecordings", sender: self)
    }

    @objc
    private func record(sender: UIBarButtonItem, for event: UIEvent) {
        if recorder.isRecording {
            stopRecordingUI()
            recorder.finishRecording(success: true)
        } else {
            guard let note = note, let id = note.id else {
                return
            }
            guard DataManager.createRecordingsDirectory(for: id) else {
                return
            }
            startRecordingUI()
            recorder.requestRecordPermission { [unowned self] allowed, error in
                if allowed {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "MM-dd-yy_hh-mm-ss"
                    let date = dateFormatter.string(from: Date())
                    self.recorder.startRecording(to: "\(id)/recordings/\(date)_\(id).m4a") { [unowned self] error in
                        if let error = error {
                            print("[ShowNoteViewController.\(#function)] Error: \(error.localizedDescription)")
                            self.recorder.finishRecording(success: false)
                            DispatchQueue.main.async {
                                self.stopRecordingUI()
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.stopRecordingUI()
                    }
                    self.displayAlert(with: "Please allow recording in order to start recording", message: "You can do it in preferences manually")
                }
                if let error = error {
                    print("[ShowNoteViewController.\(#function)] Error WHILE REQUESTING PERMISSION: \(error.localizedDescription)")
                }
            }
        }
    }

    private func startRecordingUI() {
        recordButton.image = UIImage(named: "stop_icon")
        locationButton.isEnabled = false
        sketchButton.isEnabled = false
        cameraButton.isEnabled = false
        self.noteTextView.addBlurEffect()
    }

    private func stopRecordingUI() {
        self.recordButton.image = UIImage(named: "record_icon")
        self.locationButton.isEnabled = true
        self.sketchButton.isEnabled = true
        self.cameraButton.isEnabled = true
        self.noteTextView.removeBlurEffect()
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
            navigationItem.rightBarButtonItems?.append(showMap)
        }
    }

    private func saveNote() {

        if let text = noteTextView.attributedText,
            text.string != savedStateOfNote ||
            savedStateOFLocation?.longitude != location?.longitude &&
            savedStateOFLocation?.latitude != location?.latitude ||
            savedRecordingsCount != DataManager.getRecordingsURL(for: note?.id ?? "no note").count
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

            new?.recordings = DataManager.getRecordingsURL(for: new!.id!).map({ $0.pathComponents.suffix(3).joined(separator: "/") })
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

extension ShowNoteViewController: AVAudioRecorderDelegate {

}

