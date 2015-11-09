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

func createSound(fileName: String, fileExt: String) -> SystemSoundID {
    var soundID: SystemSoundID = 0
    let soundURL = CFBundleCopyResourceURL(CFBundleGetMainBundle(), fileName, fileExt, nil)
    AudioServicesCreateSystemSoundID(soundURL, &soundID)
    return soundID
}

class ViewController: UIViewController,CLLocationManagerDelegate {

    @IBOutlet weak var txtDifference: UILabel!
    @IBOutlet weak var txtTarget: UILabel!
    @IBOutlet weak var txtHeading: UILabel!
    @IBOutlet weak var sldrHeadingOverride: UISlider!
    @IBOutlet weak var txtHeadingOverrideLabel: UILabel!
    @IBOutlet weak var txtDiffTolerance: UILabel!
    @IBOutlet weak var stepDiffTolerance: UIStepper!
    @IBOutlet weak var stepTargetHeading: UIStepper!
    
    let sndHigh: SystemSoundID = createSound("4k_to_2k_in_20ms", fileExt: "wav")
    let sndLow: SystemSoundID = createSound("1k_to_2k_in_20ms", fileExt: "wav")
    let noDataText = "---"
    let slowest_interval_secs = 2.0
    let fastest_interval_secs = 0.1
    let headingFilter: CLLocationDegrees = 1
    
    var locationManager: CLLocationManager!
    var headingTarget: CLLocationDegrees?
    var headingCurrent: CLLocationDegrees = 150
    var beepTimer: NSTimer?
    var beepSound: SystemSoundID?
    var beepInterval: NSTimeInterval?
    var lastBeepTime: NSDate?
    var diffTolerance: CLLocationDegrees = 5
    
    var headingUpdates: ObservationHistory = ObservationHistory(deltaFunc: ViewController.calcCorrection)
    
    //
    // ViewController overrides
    //
    
    override func viewDidLoad() {
        locationManager = CLLocationManager()
        if CLLocationManager.headingAvailable() {
            log.debug("Requesting heading updates with headingFilter of \(headingFilter)")
            locationManager.delegate = self
            locationManager.headingFilter = headingFilter
            locationManager.startUpdatingHeading()
            // hide the manual heading slider
            sldrHeadingOverride.hidden = true
            txtHeadingOverrideLabel.hidden = true
        } else {
            log.debug("Heading information not available on this device")
        }
        super.viewDidLoad()
        let _ = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "updateUI", userInfo: nil, repeats: true)
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }

    //
    // Static methods
    //
    
    static func calcCorrection(current: CLLocationDegrees, target: CLLocationDegrees) -> CLLocationDegrees {
        let difference = target - current
        if difference == -180 {
            return 180
        } else if difference > 180 {
            return difference - 360
        } else if difference < -180 {
            return difference + 360
        } else {
            return difference
        }
    }
    
    static func correctionUIColor(correction: CLLocationDegrees, tolerance: CLLocationDegrees) -> UIColor {
        if correction < -tolerance {
            return UIColor.redColor()
        } else if correction > tolerance {
            return UIColor.greenColor()
        } else {
            return UIColor.whiteColor()
        }
    }
    
    //
    // UI management
    //
    
    func updateUI() {
        let h = headingUpdates.smoothed(NSDate())
        if h != nil {
            log.debug("Latest heading: \(headingUpdates.mostRecentObservation!.v), Smoothed heading value \(h!)")
            headingCurrent = h! % 360
        }
        updateScreenUI()
        updateBeepUI()
    }
    
    func updateScreenUI() {
        txtHeading.text = Int(headingCurrent).description
        txtDiffTolerance.text = Int(diffTolerance).description
        if headingTarget == nil {
            // no target set, so no difference to process
            txtTarget.text = noDataText
            txtDifference.text = noDataText
        }
        else {
            stepTargetHeading.value = Double(headingTarget!)
            let correction = ViewController.calcCorrection(headingCurrent, target: headingTarget!)
            txtTarget.text = Int(headingTarget!).description
            txtDifference.text = Int(correction).description
            txtDifference.textColor = ViewController.correctionUIColor(correction, tolerance: diffTolerance)
        }
    }
    
    //
    // Manage the audio UI
    //
    
    func updateBeepUI() {
        if headingTarget == nil {
            beepInterval = nil
            beepSound = nil
        }
        else {
            let correction = ViewController.calcCorrection(headingCurrent, target: headingTarget!)
            setBeepInterval(correction)
            beepMaybe()
        }
    }
    
    func setBeepInterval(correction: CLLocationDegrees) {
        if abs(correction) < diffTolerance {
            beepInterval = nil
            beepSound = nil
        }
        else {
            let degrees = Double(abs(correction))
            let numerator = Double(diffTolerance) * slowest_interval_secs
            var intervalSecs: NSTimeInterval = max(fastest_interval_secs, numerator/degrees)
            if intervalSecs < 0.05 {
                intervalSecs = 0.05
            }
            beepInterval = intervalSecs
            if correction > -diffTolerance {
                beepSound = sndHigh  // a high pitched (rising) chirp means steer to starboard
            }
            else if correction < diffTolerance {
                beepSound = sndLow // a low pitched (falling) chirp means steer to port
            }
        }
    }
    
    func beepMaybe() {
        //
        // This method really should be reentrant but is not, so races certainly exist.  Implement locking ASAP.
        //
        if beepInterval == nil || beepSound == nil {
            return
        }
        if beepTimer == nil || !beepTimer!.valid || lastBeepTime == nil {
            // No timer exists, or one exists but it is invalidated, or no last beep time is recorded, so go ahead and emit
            // our beep then schedule another beep in beepInterval seconds
            lastBeepTime = NSDate()
            beepTimer = NSTimer.scheduledTimerWithTimeInterval(beepInterval!, target: self, selector: "beepMaybe", userInfo: nil, repeats: false)
            AudioServicesPlaySystemSound(beepSound!) // ??? double check this is async
        }
        else {
            // A timer exists and is valid, and we know when the last beep happened, so we need to decide whether to adjust
            // the timer and whether to emit a sound now
            let timeSinceLastBeep = abs(lastBeepTime!.timeIntervalSinceNow)
            if beepInterval! <= timeSinceLastBeep {
                // The new beep interval must be less than the old one so hurry up and beep now, then schedule another one in
                // beepInterval seconds
                beepTimer!.invalidate()
                lastBeepTime = NSDate()
                beepTimer = NSTimer.scheduledTimerWithTimeInterval(beepInterval!, target: self, selector: "beepMaybe", userInfo: nil, repeats: false)
                AudioServicesPlaySystemSound(beepSound!)
            }
            else {
                // The new beep interval is longer then the time since the last beep.  We need to wait a bit before beeping
                // so schedule a new timer for beepInterval - timeSinceLastBeep seconds
                beepTimer!.invalidate()
                beepTimer = NSTimer.scheduledTimerWithTimeInterval(beepInterval! - timeSinceLastBeep, target: self, selector: "beepMaybe", userInfo: nil, repeats: false)
            }
        }
    }
    
    //
    // Functions that mutate model state
    //
    
    //CLLocationManagerDelegate
    func locationManager(manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        updateCurrentHeading(newHeading.magneticHeading)
    }
    
    @IBAction func sldrHeadingOverrideValueChanged(sender: AnyObject) {
        updateCurrentHeading(CLLocationDegrees(round(sldrHeadingOverride.value)))
    }
    
    func updateCurrentHeading(newheading: CLLocationDegrees) {
        log.debug("updateCurrentHeading got: \(newheading)")
        headingUpdates.add_observation(Observation(v: newheading, t: NSDate()))
        // Don't update the UI, wait for the timer to do so
    }
    
    @IBAction func setTarget(sender: UIButton) {
        log.debug("headingTarget set to current heading: \(headingCurrent)")
        headingTarget = headingCurrent
        updateUI()
    }
    
    @IBAction func unsetTarget(sender: UIButton) {
        log.debug("headingTarget unset")
        headingTarget = nil
        updateUI()
    }
    
    @IBAction func stepDiffToleranceChanged(sender: UIStepper) {
        log.debug("stepDiffTolerance changed to \(sender.value)")
        diffTolerance = CLLocationDegrees(sender.value)
        updateUI()
    }
    
    @IBAction func stepTargetChanged(sender: UIStepper) {
        log.debug("stepTarget changed to \(sender.value)")
        if headingTarget != nil {
            headingTarget = CLLocationDegrees(sender.value)
        }
        updateUI()
    }
}

