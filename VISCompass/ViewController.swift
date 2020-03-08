//
//  ViewController.swift
//  VI Compass
//
//  Created by Matt Clark on 09/08/2015.
//  Copyright © 2015 mattclark.net. All rights reserved.
//

import UIKit
import CoreLocation

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
    
    // helper objects
    let model: CompassModel = CompassModel()
    let audioFeedbackController: AudioFeedbackController = AudioFeedbackController()
    
    // static parameters and resources for screen UI
    let noDataText = "---"
    let defaultResponsivenessIndex = 2 // M
    let defaultToleranceIndex = 1 // 10 degrees
    let defaultFeedbackAudioChoice = 0 // .drum, be sure to change the default for feedbackSoundSelected in the AudioFeedbackController class if you change this
    let touchRepeatInterval = 0.2
    let tackDegrees = 100.0
    
    // debouce timer object for screen presses
    var touchTimer: Timer?
    
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
        feedbackAudioChoice.selectedSegmentIndex = defaultFeedbackAudioChoice
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
        audioFeedbackController.updateAudioFeedback(maybeCorrection: model.correction(), heading: model.headingCurrent, tolerance: model.diffTolerance)
    }
    
    func updateScreenUI() {
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
            if abs(correction.amount) < 2 {
                arrowPort.isHidden = true
                arrowStbd.isHidden = true
            }
            else if correction.amount >= 2 {
                arrowPort.isHidden = true
                arrowStbd.isHidden = false
            }
            else if correction.amount <= -2 {
                arrowPort.isHidden = false
                arrowStbd.isHidden = true
            }
            
            switch correction.direction {
            case Turn.stbd:
                txtDifference.textColor = UIColor.green
                arrowStbd.textColor = UIColor.green
            case Turn.port:
                txtDifference.textColor = UIColor.red
                arrowPort.textColor = UIColor.red
            case Turn.none:
                txtDifference.textColor = UIColor.label
                arrowPort.textColor = UIColor.label
                arrowStbd.textColor = UIColor.label
            }
        } else {
            // There is no correction available
            txtDifference.text = noDataText
            txtDifference.textColor = UIColor.label
            arrowPort.isHidden = true
            arrowStbd.isHidden = true
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
        updateUI()
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
            audioFeedbackController.feedbackSoundSelected = feedbackSound.drum
        case 1:
            log.debug("Heading feedback selected")
            audioFeedbackController.feedbackSoundSelected = feedbackSound.heading
        default:
            log.debug("Audio feedback off")
            audioFeedbackController.feedbackSoundSelected = feedbackSound.off
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
    
    @IBAction func swipeStbd(_ sender: UISwipeGestureRecognizer) {
        model.modifyTarget(tackDegrees)
        updateUI()
    }
    
    @IBAction func swipePort(_ sender: UISwipeGestureRecognizer) {
        model.modifyTarget(-tackDegrees)
        updateUI()
    }
    
    
}


