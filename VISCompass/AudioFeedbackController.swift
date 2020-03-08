//
//  AudioFeedbackController.swift
//  VISCompass
//
//  Created by Matt Clark on 08/03/2020.
//  Copyright © 2020 mattclark.net. All rights reserved.
//

import Foundation
import CoreLocation
import AudioToolbox
import AVFoundation


func createSound(_ fileName: String, fileExt: String) -> SystemSoundID {
    var soundID: SystemSoundID = 0
    let soundURL = CFBundleCopyResourceURL(CFBundleGetMainBundle(), fileName as CFString, fileExt as CFString, nil)
    AudioServicesCreateSystemSoundID(soundURL!, &soundID)
    return soundID
}

enum feedbackSound {
    case drum
    case heading
    case off
    case correction
}

class AudioFeedbackController {
    // static parameters
    let slowest_interval_secs = 2.0
    let fastest_interval_secs = 0.1
    
    // static resources
    // static parameters and resources for sound interface
    let speechSynthesiser: AVSpeechSynthesizer = AVSpeechSynthesizer()
    let sndHigh: SystemSoundID = createSound("click_high", fileExt: "wav")
    let sndLow: SystemSoundID = createSound("click_low", fileExt: "wav")
    let sndNeutral: SystemSoundID = createSound("drum200", fileExt: "wav")
    
    // variables needed to manage sound UI
    var beepTimer: Timer?
    var beepInterval: TimeInterval?
    var lastBeepTime: Date?
    var feedbackSoundSelected: feedbackSound = .drum // awkwardly needs coordination with defaultFeedbackAudioChoice in the view controller
    var nextFeedbackSound: feedbackSound = .off
    var nextTurn: Turn = .none
    var nextHeading: CLLocationDegrees?

    func updateAudioFeedback(maybeCorrection: Correction?, heading: CLLocationDegrees?, tolerance: CLLocationDegrees) {
        nextHeading = heading
        if let correction = maybeCorrection {
            // we're navigating
            nextTurn = correction.direction
            switch correction.direction {
            case .none:
                // we're within tolerance, send comforting feedback
                switch feedbackSoundSelected {
                case .drum:
                    beepInterval = 5
                    nextFeedbackSound = .drum
                case .heading:
                    beepInterval = 15
                    nextFeedbackSound = .heading
                default:
                    beepInterval = nil
                }
            case .port, .stbd:
                // we're outside tolerance, send urgent feedback
                let degrees = Double(abs(correction.amount))
                let numerator = Double(tolerance) * slowest_interval_secs
                var intervalSecs: TimeInterval = max(fastest_interval_secs, numerator/degrees)
                if intervalSecs < 0.05 {
                    intervalSecs = 0.05
                }
                beepInterval = intervalSecs
                nextFeedbackSound = .correction
            }
        }
        else {
            // no correction object available, not navigating
            beepInterval = nil
            nextTurn = .none
            nextFeedbackSound = .off
        }
        // don't wait for any current timer to expire, make a quick decision on the next feedback to play
        decideNextAudioFeedback()
    }
    
    @objc func decideNextAudioFeedback() {
        //
        // This method really should be reentrant but is not, so races certainly exist.  Implement locking ASAP.
        //
        if beepInterval == nil {
            return
        }
        if beepTimer == nil || !beepTimer!.isValid || lastBeepTime == nil {
            // No timer exists, or one exists but it is invalidated, or no last beep time is recorded, so go ahead and emit
            // our beep then schedule another beep in beepInterval seconds
            lastBeepTime = Date()
            beepTimer = Timer.scheduledTimer(timeInterval: beepInterval!, target: self, selector: #selector(AudioFeedbackController.decideNextAudioFeedback), userInfo: nil, repeats: false)
            playAudioFeedbackSound()
        }
        else {
            // A timer exists and is valid, and we know when the last beep happened, so we need to decide whether to adjust
            // the timer and whether to emit a sound now
            let timeSinceLastBeep = abs(lastBeepTime!.timeIntervalSinceNow)
            if beepInterval! <= timeSinceLastBeep {
                // The new beep interval must be less than the old one so hurry up and beep now, then schedule another one in
                // beepInterval seconds
                beepTimer!.invalidate()
                lastBeepTime = Date()
                beepTimer = Timer.scheduledTimer(timeInterval: beepInterval!, target: self, selector: #selector(AudioFeedbackController.decideNextAudioFeedback), userInfo: nil, repeats: false)
                playAudioFeedbackSound()
            }
            else {
                // The new beep interval is longer then the time since the last beep.  We need to wait a bit before beeping
                // so schedule a new timer for beepInterval - timeSinceLastBeep seconds
                beepTimer!.invalidate()
                beepTimer = Timer.scheduledTimer(timeInterval: beepInterval! - timeSinceLastBeep, target: self, selector: #selector(AudioFeedbackController.decideNextAudioFeedback), userInfo: nil, repeats: false)
            }
        }
    }
    
    func playAudioFeedbackSound() {
        switch nextFeedbackSound {
        case .off:
            break
        case .drum:
            AudioServicesPlaySystemSound(sndNeutral)
        case .heading:
            if nextHeading != nil {
                let headingStr = String(Int(nextHeading!)) // e.g. '130'
                let headingDigits = headingStr.map({"\($0) "})
                let u = AVSpeechUtterance(string: "heading \(headingDigits)")
                speechSynthesiser.speak(u)
            }
        case .correction:
            switch (nextTurn) {
            case .stbd: AudioServicesPlaySystemSound(sndHigh)
            case .port: AudioServicesPlaySystemSound(sndLow)
            case .none: break
            }
        }
    }

}

