//
//  ViewController.swift
//  VI Compass
//
//  Created by Matt Clark on 09/08/2015.
//  Copyright © 2015 mattclark.net. All rights reserved.
//

import UIKit
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
}

class ViewController: UIViewController {

    @IBOutlet weak var txtDifference: UILabel!
    @IBOutlet weak var txtTarget: UILabel!
    @IBOutlet weak var txtHeading: UILabel!
    @IBOutlet weak var sldrHeadingOverride: UISlider!
    @IBOutlet weak var segResponsiveness: UISegmentedControl!
    @IBOutlet weak var switchTargetOn: UISwitch!
    @IBOutlet weak var arrowPort: UILabel!
    @IBOutlet weak var arrowStbd: UILabel!
    @IBOutlet weak var btnPort: UIButton!
    @IBOutlet weak var btnStbd: UIButton!
    @IBOutlet weak var feedbackAudioChoice: UISegmentedControl!
    @IBOutlet weak var segTolerance: UISegmentedControl!
    
    let sndHigh: SystemSoundID = createSound("click_high", fileExt: "wav")
    let sndLow: SystemSoundID = createSound("click_low", fileExt: "wav")
    let sndNeutral: SystemSoundID = createSound("drum200", fileExt: "wav")
    let noDataText = "---"
    let slowest_interval_secs = 2.0
    let fastest_interval_secs = 0.1
    let defaultResponsivenessIndex = 2 // M
    let defaultToleranceIndex = 1 // 10 degrees
    let touchRepeatInterval = 0.2
    let speechSynthesiser: AVSpeechSynthesizer = AVSpeechSynthesizer()
    
    var model: CompassModel = CompassModel()
    var touchTimer: Timer?
    var beepTimer: Timer?
    var beepInterval: TimeInterval?
    var lastBeepTime: Date?
    var feedbackSoundSelected: feedbackSound = .drum
    
    //
    // ViewController overrides
    //
    
    override func viewDidLoad() {
        setupUI()
        super.viewDidLoad()
        // Update the UI every second to show heading changes
        let _ = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ViewController.updateUI), userInfo: nil, repeats: true)
    }

    override var shouldAutorotate : Bool {
        return false
    }
    
    //
    // One-time UI setup
    //
    
    func setupUI() {
        if model.isUsingCompass() {
            // hide the manual heading slider
            sldrHeadingOverride.isHidden = true
        }
        segResponsiveness.selectedSegmentIndex = defaultResponsivenessIndex
        model.setResponsiveness(defaultResponsivenessIndex)
        segTolerance.selectedSegmentIndex = defaultToleranceIndex // 10 degrees
        model.diffTolerance = 10
        arrowPort.isHidden = true
        arrowStbd.isHidden = true
        btnPort.layer.borderWidth = 0.8
        btnPort.layer.borderColor = UIColor.red.cgColor
        btnPort.layer.cornerRadius = 4.0
        btnStbd.layer.borderWidth = 0.8
        btnStbd.layer.borderColor = UIColor.green.cgColor
        btnStbd.layer.cornerRadius = 4.0
    }

    //
    // UI management
    //
    
    @objc func updateUI() {
        updateScreenUI()
        updateBeepUI()
    }
    
    func updateScreenUI() {
        // Display the current tolerance
        // Display the current heading
        if let headingCurrent = model.smoothedHeading() {
            txtHeading.text = Int(headingCurrent).description
        } else {
            txtHeading.text = noDataText
        }
        
        // Display the target heading
        if let headingTarget = model.headingTarget {
            txtTarget.text = Int(headingTarget).description
        } else {
            txtTarget.text = noDataText
        }
        
        if let correction = model.correction() {
            // show the correction as whole numbers
            txtDifference.text = abs(Int(correction.amount)).description
            
            // display the appropriate direction indicator arrows
            if  abs(correction.amount) < 1.0 {
                arrowPort.isHidden = true
                arrowStbd.isHidden = true
            } else {
                arrowPort.isHidden = correction.direction == Turn.stbd
                arrowStbd.isHidden = correction.direction == Turn.port
            }
            
            // set the colour of the direction indicator arrows and correction value
            if correction.required {
                if correction.direction == Turn.stbd {
                    txtDifference.textColor = UIColor.green
                    arrowStbd.textColor = UIColor.green
                    
                } else if correction.direction == Turn.port {
                    txtDifference.textColor = UIColor.red
                    arrowPort.textColor = UIColor.red
                }
            } else {
                txtDifference.textColor = UIColor.white
                arrowPort.textColor = UIColor.white
                arrowStbd.textColor = UIColor.white
            }
        } else {
            // There is no correction available
            txtDifference.text = noDataText
            txtDifference.textColor = UIColor.white
            arrowPort.isHidden = true
            arrowStbd.isHidden = true
        }
    }
    
    //
    // Manage the audio UI
    //
    
    func updateBeepUI() {
        let correction = model.correction()
        if correction == nil {
            // we're not navigating
            beepInterval = nil
        }
        else if !correction!.required {
            // we're navigating and within tolerance, send comforting feedback
            if feedbackSoundSelected == feedbackSound.off {
                beepInterval = nil
            }
            else {
                if feedbackSoundSelected == feedbackSound.drum {
                    beepInterval = 5
                }
                else if feedbackSoundSelected == feedbackSound.heading {
                    beepInterval = 15
                }
            }
        }
        else {
            // we're navigating and outside tolerance, send urgent feedback
            let degrees = Double(abs(correction!.amount))
            let numerator = Double(model.diffTolerance) * slowest_interval_secs
            var intervalSecs: TimeInterval = max(fastest_interval_secs, numerator/degrees)
            if intervalSecs < 0.05 {
                intervalSecs = 0.05
            }
            beepInterval = intervalSecs
        }
        beepMaybe()
    }
    
    @objc func beepMaybe() {
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
            beepTimer = Timer.scheduledTimer(timeInterval: beepInterval!, target: self, selector: #selector(ViewController.beepMaybe), userInfo: nil, repeats: false)
            playFeedbackSound()
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
                beepTimer = Timer.scheduledTimer(timeInterval: beepInterval!, target: self, selector: #selector(ViewController.beepMaybe), userInfo: nil, repeats: false)
                playFeedbackSound()
            }
            else {
                // The new beep interval is longer then the time since the last beep.  We need to wait a bit before beeping
                // so schedule a new timer for beepInterval - timeSinceLastBeep seconds
                beepTimer!.invalidate()
                beepTimer = Timer.scheduledTimer(timeInterval: beepInterval! - timeSinceLastBeep, target: self, selector: #selector(ViewController.beepMaybe), userInfo: nil, repeats: false)
            }
        }
    }
    
    func playFeedbackSound() {
        let correction = model.correction()
        if correction == nil { return }
        if correction!.required {
            switch (correction!.direction) {
            case Turn.stbd:
                AudioServicesPlaySystemSound(sndHigh)
            case Turn.port:
                AudioServicesPlaySystemSound(sndLow)
            }
        }
        else {
            // no correction required
            if feedbackSoundSelected == feedbackSound.heading {
                let h = Int(model.headingCurrent!)
                let u = AVSpeechUtterance(string: "heading \(h) degrees")
                speechSynthesiser.speak(u)
            }
            else {
                AudioServicesPlaySystemSound(sndNeutral)
            }
        }
    }
    
    //
    // Handle changes in heading
    //
    
    @IBAction func sldrHeadingOverrideValueChanged(_ sender: AnyObject) {
        model.updateCurrentHeading(CLLocationDegrees(round(sldrHeadingOverride.value)))
    }
    
    //
    // Turn target heading tracking on and off
    //
    
    @IBAction func switchTargetOn(_ sender: UISwitch) {
        if sender.isOn {
            if model.headingTarget == nil {
                model.headingTarget = model.smoothedHeading()
            }
        }
        else {
            model.headingTarget = nil
        }
        updateUI()
    }
    
    //
    // Modify the tolerance range
    //
    @IBAction func segToleranceChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            model.diffTolerance = 5
        case 1:
            model.diffTolerance = 10
        case 2:
            model.diffTolerance = 15
        case 3:
            model.diffTolerance = 20
        default:
            model.diffTolerance = 5
        }
    }
    //
    // Change the responsiveness of the heading detection given changing compass input
    //
    
    @IBAction func setResponsiveness(_ sender: UISegmentedControl) {
        log.debug("setResponsiveness changed to index \(sender.selectedSegmentIndex)")
        model.setResponsiveness(sender.selectedSegmentIndex)
        updateUI()
    }

    //
    // Change the target heading (single taps, sustained presses and swipes all supported)
    //
    
    @IBAction func touchTargetToPort(_ sender: UIButton) {
        if model.headingTarget == nil {
            return
        }
        touchTimer = Timer.scheduledTimer(timeInterval: touchRepeatInterval, target: self, selector: #selector(ViewController.changeTargetToPort), userInfo: nil, repeats: true)
        touchTimer!.fire()
    }
    
    @IBAction func touchTargetToStbd(_ sender: UIButton) {
        if model.headingTarget == nil {
            return
        }
        touchTimer = Timer.scheduledTimer(timeInterval: touchRepeatInterval, target: self, selector: #selector(ViewController.changeTargetToStbd), userInfo: nil, repeats: true)
        touchTimer!.fire()
    }
    
    @IBAction func swipeStbd(_ sender: UISwipeGestureRecognizer) {
        model.tackStbd()
        updateUI()
    }
    
    @IBAction func swipePort(_ sender: UISwipeGestureRecognizer) {
        model.tackPort()
        updateUI()
    }
    
    @IBAction func touchTargetStop(_ sender: UIButton) {
        if touchTimer != nil {
            touchTimer!.invalidate()
            touchTimer = nil
        }
    }
    
    @IBAction func steadyFeedBackAudioChoiceChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            log.debug("Drumming feedback selected")
            feedbackSoundSelected = feedbackSound.drum
        case 1:
            log.debug("Heading feedback selected")
            feedbackSoundSelected = feedbackSound.heading
        default:
            log.debug("Audio feedback off")
            feedbackSoundSelected = feedbackSound.off
        }
        updateUI()
    }
    
    @objc func changeTargetToPort() {
        model.modifyTarget(-1)
        updateUI()
    }
    
    @objc func changeTargetToStbd() {
        model.modifyTarget(1)
        updateUI()
    }
}


