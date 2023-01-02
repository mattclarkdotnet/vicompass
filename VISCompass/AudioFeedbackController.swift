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
    case to_stbd
    case to_port
}

let feedbackIntervals = [2.0, 1.0, 0.5]

class AudioFeedbackController {
    // static parameters and resources for sound interface
    let speechSynthesiser: AVSpeechSynthesizer = AVSpeechSynthesizer()
    let sndHigh: SystemSoundID = createSound("click_high", fileExt: "wav")
    let sndLow: SystemSoundID = createSound("click_low", fileExt: "wav")
    let sndNeutral: SystemSoundID = createSound("drum200", fileExt: "wav")
    
    // variables needed to manage sound UI
    var beepTimer: Timer?
    var beepInterval: TimeInterval?
    
    var nextFeedbackSound: feedbackSound = .off
    var lastFeedbackSound: feedbackSound = .off
    
    var nextHeading: CLLocationDegrees?

    func updateAudioFeedback(maybeCorrection: Correction?, heading: CLLocationDegrees?, tolerance: CLLocationDegrees, feedbackTypeSelected: feedbackSound) {
        nextHeading = heading
        if let correction = maybeCorrection {
            // we're navigating
            let error = Int(abs(correction.amount) / tolerance)
            if error == 0 {
                // we're within tolerance, send comforting feedback
                switch feedbackTypeSelected {
                case .drum:
                    beepInterval = 5
                    nextFeedbackSound = .drum
                case .heading:
                    beepInterval = 15
                    nextFeedbackSound = .heading
                default:
                    beepInterval = nil
                    nextFeedbackSound = .off
                }
            }
            else {
                // we're outside tolerance, send correction feedback, with frequency related to the amount of variation
                if correction.direction == .port {
                    nextFeedbackSound = .to_port
                }
                else {
                    nextFeedbackSound = .to_stbd
                }
                if error >= feedbackIntervals.count {
                    beepInterval = feedbackIntervals.last
                }
                else {
                    beepInterval = feedbackIntervals[error-1]
                }
                
            }
        }
        else {
            // no correction object available, not navigating, suppress all feedback sounds
            beepInterval = nil
            nextFeedbackSound = .off
        }
        // If the feedback type has changed, don't wait for any current timer to expire, invalidate it and play the new feedback sound immediately
        if nextFeedbackSound != lastFeedbackSound {
            if beepTimer != nil {
                beepTimer?.invalidate()
            }
            playAudioFeedbackSound()
        }
    }
    
    @objc func playAudioFeedbackSound() {
        lastFeedbackSound = nextFeedbackSound
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
        case .to_stbd:
            AudioServicesPlaySystemSound(sndHigh)
        case .to_port:
            AudioServicesPlaySystemSound(sndLow)
        }
        if beepInterval != nil {
            beepTimer = Timer.scheduledTimer(timeInterval: beepInterval!, target: self, selector: #selector(AudioFeedbackController.playAudioFeedbackSound), userInfo: nil, repeats: false)
        }
    }

}

