//
//  RecordingsViewController.swift
//  SmartNotes
//
//  Created by Daian Aiziatov on 26/03/2019.
//  Copyright © 2019 Daian Aiziatov. All rights reserved.
//

import UIKit
import AVFoundation

class RecordingsViewController: UIViewController, AlertDisplayable {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var nameButton: UIBarButtonItem! {
        didSet {
            nameButton.title = "No record"
        }
    }
    @IBOutlet private weak var playAndPauseButton: UIBarButtonItem!
    @IBOutlet private weak var progressView: UIProgressView!
    
    var note: Note? {
        didSet {
            recordings = DataManager.getRecordingsURL(for: note!.id!)
        }
    }
    private var recordings = [URL]()
    private var player: Player!
    private var playbackTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.title = "Recordings"
        player = Player(delegate: self)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "recordingsCell")
    }

    override func viewWillDisappear(_ animated: Bool) {
        player.stop()
    }

    @IBAction func playAndPauseTapped(_ sender: UIBarButtonItem) {
        if player.isPlaying {
            player.pause()
            sender.image = UIImage(named: "play_icon")
            playbackTimer = nil
        } else {
            player.release()
            sender.image = UIImage(named: "pause_icon")
            playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { timer in
                let total = self.player.duration
                let progress = Float(self.player!.currentTime / total)
                self.progressView.progress = progress
            })
        }
    }
    @IBAction func stopTapped(_ sender: UIBarButtonItem) {
        player.stop()
        playbackTimer = nil
    }

}

extension RecordingsViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        nameButton.title = "No record"
        playAndPauseButton.image = UIImage(named: "play_icon")
        playbackTimer = nil
    }
}

extension RecordingsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let confirm = UIAlertAction(title: "Confirm", style: .default, handler: ({ [unowned self] action in
                let recording = self.recordings.remove(at: indexPath.row)
                self.note?.recordings = self.recordings.map({ $0.pathComponents.suffix(3).joined(separator: "/") })
                if let _ = FirebaseManager.shared.getUser() {
                    FirebaseManager.shared.deleteAttachment(with: URL(string: recording.pathComponents.suffix(3).joined(separator: "/"))!) { error in
                        if let error = error {
                            print("[\(#function)] Error while deleting note from cloud: \(error.localizedDescription)")
                        } else {
                            FirebaseManager.shared.update(note: self.note!) { error in
                                if let error = error {
                                    print("[\(#function)] Error while deleting attachments for note from cloud: \(error.localizedDescription)")
                                }
                            }
                        }
                    }

                }
                ad.saveContext()
                DataManager.deleteFile(with: recording)
                tableView.reloadData()
            }))
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            displayAlert(with: "Are you sure to delete this recording?", message: "This action can't be undone", actions: [confirm, cancel])
        }
    }
}

extension RecordingsViewController: UITableViewDataSource {
    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recordings.count
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "recordingsCell", for: indexPath)

        let dateFromName = recordings[indexPath.row].pathComponents.last?.split(separator: "_").prefix(2).joined(separator: "_")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yy_hh-mm-ss"
        let date = dateFormatter.date(from: dateFromName!)
        dateFormatter.dateFormat = "hh:mm:ss dd MMM YYYY"
        cell.textLabel?.text = dateFormatter.string(from: date!)
        cell.backgroundColor = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if player.isPlaying {
            player.stop()
            playbackTimer = nil
        } else {
            player.play(from: recordings[indexPath.row]) { [unowned self] error in
                if let error = error {
                    print("[RecordingsTableViewController.\(#function)] Error: \(error.localizedDescription)")
                } else {
                    print("[RecordingsTableViewController.\(#function)] Playing..")
                    self.playAndPauseButton.image = UIImage(named: "pause_icon")
                    self.nameButton.title = tableView.cellForRow(at: indexPath)?.textLabel?.text
                    self.playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { timer in
                        let total = self.player.duration
                        let progress = Float(self.player!.currentTime / total)
                        self.progressView.progress = progress
                    })
                }
            }
        }
    }

    
}


