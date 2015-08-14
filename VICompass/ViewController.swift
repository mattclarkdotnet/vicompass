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
    
    let sndHigh: SystemSoundID = createSound("2000", fileExt: "wav")
    let sndLow: SystemSoundID = createSound("300", fileExt: "wav")
    let noDataText = "---"
    let slowest_interval_secs = 2.0
    let fastest_interval_secs = 0.1
    let headingFilter: CLLocationDegrees = 1
    
    var locationManager: CLLocationManager!
    var headingTarget: CLLocationDegrees?
    var headingCurrent: CLLocationDegrees = 150
    var beepTimer: NSTimer?
    var beepSound: SystemSoundID?
    var diffTolerance: CLLocationDegrees = 5
    
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
        updateUI()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //
    // Static methods
    //
    
    func differenceUIColor(difference: CLLocationDegrees, tolerance: CLLocationDegrees) -> UIColor {
        if difference < -tolerance {
            return UIColor.redColor()
        } else if difference > tolerance {
            return UIColor.greenColor()
        } else {
            return UIColor.whiteColor()
        }
    }
    
    func beep() {
        if beepSound != nil {
            AudioServicesPlaySystemSound(beepSound!)
        }
    }
    
    func beepInterval(degrees: CLLocationDegrees) -> NSTimeInterval {
        let degrees = Double(abs(degrees))
        let numerator = Double(diffTolerance) * slowest_interval_secs
        let intervalSecs: NSTimeInterval = max(fastest_interval_secs, numerator/degrees)
        return intervalSecs
    }
    
    func calcDifference(current: CLLocationDegrees, target: CLLocationDegrees?) -> CLLocationDegrees? {
        if target == nil {
            return nil
        } else {
            let difference = current - target!
            if difference > 180 {
                return difference - 180
            } else {
                return difference
            }
        }
    }
    
    //
    // UI management
    //
    
    func updateUI() {
        let difference = calcDifference(headingCurrent, target: headingTarget)
        updateScreenUI(difference)
        updateBeepUI(difference)
    }
    
    func updateScreenUI(difference: CLLocationDegrees?) {
        txtHeading.text = Int(headingCurrent).description
        txtDiffTolerance.text = Int(diffTolerance).description
        sldrHeadingOverride.value = Float(headingCurrent)
        if headingTarget != nil {
            stepTargetHeading.value = Double(headingTarget!)
        }
        if difference == nil {
            // no target set, so no difference to process
            txtTarget.text = noDataText
            txtDifference.text = noDataText
        }
        else {
            txtTarget.text = Int(headingTarget!).description
            txtDifference.text = Int(difference!).description
            txtDifference.textColor = differenceUIColor(difference!, tolerance: diffTolerance)
        }
    }
    
    func updateBeepUI(difference: CLLocationDegrees?) {
        if beepTimer != nil {
            // always invalidate the current timer
            beepTimer!.invalidate()
        }
        if difference != nil {
            if abs(difference!) < diffTolerance {
                // don't set up a new beep timer
                beepSound = nil
            }
            else if difference! < -diffTolerance {
                beepSound = sndHigh
            }
            else if difference! > diffTolerance {
                beepSound = sndLow
            }
            if beepSound != nil {
                beepTimer = NSTimer.scheduledTimerWithTimeInterval(beepInterval(difference!), target: self, selector: "beep", userInfo: nil, repeats: true)
            }
        }
    }
    
    //
    // Functions that mutate heading and target state
    //
    
    //CLLocationManagerDelegate
    func locationManager(manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        log.debug("headingCurrent set to new magnetic heading from CLLocationManager: \(newHeading.magneticHeading)")
        headingCurrent = newHeading.magneticHeading
        updateUI()
    }
    
    @IBAction func sldrHeadingOverrideValueChanged(sender: AnyObject) {
        log.debug("headingCurrent set to new heading from manual slider: \(sldrHeadingOverride.value)")
        headingCurrent = CLLocationDegrees(round(sldrHeadingOverride.value))
        updateUI()
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


