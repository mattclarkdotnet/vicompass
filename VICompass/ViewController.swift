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
    
    let sndHigh: SystemSoundID = createSound("2000", fileExt: "wav")
    let sndLow: SystemSoundID = createSound("300", fileExt: "wav")
    let noDataText = "---"
    let slowest_interval_secs = 2.0
    let fastest_interval_secs = 0.1
    let diffTolerance: CLLocationDegrees = 5
    let headingFilter: CLLocationDegrees = 1
    
    var locationManager: CLLocationManager!
    var headingTarget: CLLocationDegrees?
    var headingCurrent: CLLocationDegrees = 150
    var beepTimer: NSTimer?
    var beepSound: SystemSoundID?
    
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
    
    func updateUI() {
        var difference: CLLocationDegrees?
        if headingTarget != nil {
            difference = headingCurrent - headingTarget!
        } else {
            difference = nil
        }
        updateScreenUI(difference)
        updateBeepUI(difference)
    }
    
    func updateScreenUI(difference: CLLocationDegrees?) {
        txtHeading.text = String(Int(headingCurrent))
        sldrHeadingOverride.value = Float(headingCurrent)
        if difference == nil {
            // no target set, so no difference to process
            txtTarget.text = noDataText
            txtDifference.text = noDataText
        }
        else {
            txtTarget.text = String(Int(headingTarget!))
            txtDifference.text = String(Int(difference!))
            txtDifference.textColor = differenceUIColor(difference!, tolerance: diffTolerance)
        }
    }
    
    func differenceUIColor(difference: CLLocationDegrees, tolerance: CLLocationDegrees) -> UIColor {
        if difference < -tolerance {
            return UIColor.redColor()
        } else if difference > tolerance {
            return UIColor.greenColor()
        } else {
            return UIColor.whiteColor()
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
}


