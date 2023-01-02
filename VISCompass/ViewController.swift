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
    @IBOutlet weak var switchTargetOn: UISwitch!
    @IBOutlet weak var arrowPort: UILabel!
    @IBOutlet weak var arrowStbd: UILabel!
    @IBOutlet weak var btnPort: UIButton!
    @IBOutlet weak var btnStbd: UIButton!
    @IBOutlet weak var segFeedback: ConfigurableUISegmentedControl!
    @IBOutlet weak var segTolerance: ConfigurableUISegmentedControl!
    @IBOutlet weak var segResponsiveness: ConfigurableUISegmentedControl!

    // helper objects
    let model: CompassModel = CompassModel()
    let audioFeedbackController: AudioFeedbackController = AudioFeedbackController()
    
    // static parameters and resources for screen UI
    let noDataText = "---"
    let touchRepeatInterval = 0.2
    let tackDegrees = 100.0
    
    // debouce timer object for screen presses
    var touchTimer: Timer?
    
    // track the selected feedback sound
    var feedbackTypeSelected: feedbackSound = .drum
    
    override func viewDidLoad() {
        setupUI()
        super.viewDidLoad()
        // Update the UI every second to show heading changes
        let _ = Timer.scheduledTimer(timeInterval: 1, target: self,
                                     selector: #selector(ViewController.updateUI),
                                     userInfo: nil,
                                     repeats: true)
    }

    override var shouldAutorotate: Bool {
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
        arrowPort.textColor = UIColor.gray
        arrowStbd.textColor = UIColor.gray
        segTolerance.configure(defaultSegmentIndex: 1, labelSwaps: ["5": "tolerance 5 degrees",
                                   "10": "tolerance 10 degrees",
                                   "15": "tolerance 15 degrees",
                                   "20": "tolerance 20 degrees"])
        segFeedback.configure(defaultSegmentIndex: 0, labelSwaps: ["Drum": "drumming on course feedback",
                                  "Heading": "heading on course feedback",
                                  "None": "on course feedback off"])
        segResponsiveness.configure(defaultSegmentIndex: 2, labelSwaps: ["SS": "very slow responsiveness",
                                        "S": "slow responsiveness",
                                        "M": "medium responsiveness",
                                        "Q": "quick responsiveness",
                                        "QQ": "very quick responsiveness"])
        model.setResponsiveness(segResponsiveness.selectedSegmentIndex)
    }

    //
    // UI management
    //

    @objc func updateUI() {
        updateScreenUI()
        audioFeedbackController.updateAudioFeedback(maybeCorrection: model.correction(),
                                                    heading: model.headingCurrent,
                                                    tolerance: model.diffTolerance,
                                                    feedbackTypeSelected: feedbackTypeSelected)
    }
    
    func updateScreenUI() {
        // Set the current heading text description
        if let headingCurrent = model.smoothedHeading() {
            txtHeading.text = Int(headingCurrent).description
            txtHeading.accessibilityLabel = "heading " + txtHeading.text! + " degrees"
        } else {
            txtHeading.text = noDataText
            txtHeading.accessibilityLabel = "no heading available"
        }

        // Set the target heading text description
        if let headingTarget = model.headingTarget {
            txtTarget.text = Int(headingTarget).description
            txtTarget.accessibilityLabel = "target " + txtTarget.text! + " degrees"
        } else {
            txtTarget.text = noDataText
            txtTarget.accessibilityLabel = "no target set"
        }
        
        // Update difference text, and colour and visibility of indicators
        if let correction = model.correction() {
            // show the correction as whole numbers
            txtDifference.text = abs(Int(correction.amount)).description
            txtDifference.accessibilityLabel = "correction " + txtDifference.text! + "degrees"
            switch correction.direction {
            case Turn.stbd:
                arrowPort.textColor = UIColor.gray
                arrowStbd.textColor = UIColor.green
            case Turn.port:
                arrowPort.textColor = UIColor.red
                arrowStbd.textColor = UIColor.gray
            case Turn.none:
                arrowPort.textColor = UIColor.gray
                arrowStbd.textColor = UIColor.gray
            }
        } else {
            // There is no correction available
            txtDifference.text = noDataText
            txtDifference.accessibilityLabel = "no correction necessary"
            arrowPort.textColor = UIColor.gray
            arrowStbd.textColor = UIColor.gray
        }
    }

    //
    // Heading slider is used when no compass is available, e.g. in simulator
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
        } else {
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
        touchTimer = Timer.scheduledTimer(timeInterval: touchRepeatInterval,
                                          target: self,
                                          selector: #selector(ViewController.changeTargetToPort),
                                          userInfo: nil,
                                          repeats: true)
        touchTimer!.fire()
    }
    
    @IBAction func touchTargetToStbd(_ sender: UIButton) {
        if model.headingTarget == nil {
            return
        }
        touchTimer = Timer.scheduledTimer(timeInterval: touchRepeatInterval,
                                          target: self,
                                          selector: #selector(ViewController.changeTargetToStbd),
                                          userInfo: nil,
                                          repeats: true)
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
            feedbackTypeSelected = .drum
        case 1:
            log.debug("Heading feedback selected")
            feedbackTypeSelected = .heading
        default:
            log.debug("Audio feedback off")
            feedbackTypeSelected = .off
        }
        updateUI()
    }

    @objc func changeTargetToPort() {
        model.modifyTarget(-model.diffTolerance / 2)
        updateUI()
    }

    @objc func changeTargetToStbd() {
        model.modifyTarget(model.diffTolerance / 2)
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
    
    @IBAction func helpButtonPressed(_ sender: Any) {
        guard let docsURL = URL(string: "https://viscompass.org/") else { return }
        UIApplication.shared.open(docsURL)
    }
}



class ConfigurableUISegmentedControl: UISegmentedControl {
    func configure(defaultSegmentIndex: Int, labelSwaps: [String : String]) {
        if self.numberOfSegments > defaultSegmentIndex {
            self.selectedSegmentIndex = defaultSegmentIndex
        }
        for segment in self.subviews {
            log.debug("swapping labels maybe")
            if let currentLabel = segment.accessibilityLabel {
                log.debug("swapping labels for \(currentLabel)")
                if let newLabel = labelSwaps[currentLabel] {
                    log.debug("swapped label \(currentLabel) for \(newLabel)")
                    segment.accessibilityLabel = newLabel
                }
            }
        }
    }
}
