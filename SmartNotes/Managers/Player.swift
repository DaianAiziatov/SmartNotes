//
//  Player.swift
//  SmartNotes
//
//  Created by Daian Aiziatov on 25/03/2019.
//  Copyright © 2019 Daian Aiziatov. All rights reserved.
//

import Foundation
import AVFoundation

class Player {

    private var audioPlayer: AVAudioPlayer?
    private var delegate: AVAudioPlayerDelegate?

    var isPlaying: Bool {
        guard let audioPlayer = audioPlayer else {
            return false
        }
        return audioPlayer.isPlaying
    }

    var duration: TimeInterval {
        guard let audioPlayer = audioPlayer else {
            return 0
        }
        return audioPlayer.duration
    }

    var currentTime: TimeInterval {
        guard let audioPlayer = audioPlayer else {
            return 0
        }
        return audioPlayer.currentTime
    }

    init(delegate: AVAudioPlayerDelegate) {
        self.delegate = delegate
    }

    func play(from url: URL, completion: @escaping (Error?) -> Void) {
        if (FileManager.default.fileExists(atPath: url.path)) {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.delegate = delegate
                audioPlayer?.play()
                completion(nil)
            } catch let error {
                completion(error)
            }
        } else {
            completion(NSError(domain: "File not found", code: 404, userInfo: nil))
        }
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        audioPlayer = nil
    }

    func pause() {
        audioPlayer?.pause()
    }

    func release() {
        audioPlayer?.play()
    }

    func currentTimeFormat() -> String {
        guard let audioPlayer = audioPlayer else {
            return "00:00"
        }
        let currentTime = Int(audioPlayer.currentTime)
        let minutes = currentTime/60
        let seconds = currentTime - minutes * 60

        return String(format: "%02d:%02d", minutes, seconds)
    }
}
