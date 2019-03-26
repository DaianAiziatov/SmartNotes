//
//  Recorder.swift
//  SmartNotes
//
//  Created by Daian Aiziatov on 23/03/2019.
//  Copyright © 2019 Daian Aiziatov. All rights reserved.
//

import Foundation
import AVFoundation

class Recorder {

    private var recordingSession: AVAudioSession!
    private var audioRecorder: AVAudioRecorder?
    private weak var delegate: AVAudioRecorderDelegate?
    var isSuccessful = true
    var isRecording = false

    init(delegate: AVAudioRecorderDelegate) {
        self.delegate = delegate
        recordingSession = AVAudioSession.sharedInstance()
    }

    func requestRecordPermission(completion: @escaping (Bool, Error?)-> ()) {
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try recordingSession.setActive(true, options: .notifyOthersOnDeactivation)
            recordingSession.requestRecordPermission() { allowed in
                DispatchQueue.main.async {
                    if allowed {
                        completion(true, nil)
                    } else {
                        completion(false, NSError(domain: "Recording not allowed.", code: 0, userInfo: nil))
                    }
                }
            }
        } catch let error {
            print("[Recorder.\(#function)] Error: \(error.localizedDescription)")
            completion(false, error)
        }
    }

    func startRecording(to path: String, completion: @escaping (Error?)-> ()) {
        isSuccessful = true
        isRecording = true
        let audioFilename = DataManager.localDoumentsDirectoryURL.appendingPathComponent(path)
        print(audioFilename.path)

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = delegate
            audioRecorder?.record()

            completion(nil)
        } catch let error {
            print("[Recorder.\(#function)] Error: \(error.localizedDescription)")
            finishRecording(success: false)
            isRecording = false
            completion(error)
        }
    }

    func finishRecording(success: Bool) {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        isSuccessful = success
    }

}

