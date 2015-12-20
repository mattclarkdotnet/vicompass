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

func modifyDegrees(value: Double?=nil, delta: Double) -> Double? {
    if value == nil { return nil }
    return (value! + delta) % 360.0
}



class ViewController: UIViewController,CLLocationManagerDelegate {

    @IBOutlet weak var txtDifference: UILabel!
    @IBOutlet weak var txtTarget: UILabel!
    @IBOutlet weak var txtHeading: UILabel!
    @IBOutlet weak var sldrHeadingOverride: UISlider!
    @IBOutlet weak var txtDiffTolerance: UILabel!
    @IBOutlet weak var stepDiffTolerance: UIStepper!
    @IBOutlet weak var segResponsiveness: UISegmentedControl!
    @IBOutlet weak var switchTargetOn: UISwitch!
    @IBOutlet weak var arrowPort: UILabel!
    @IBOutlet weak var arrowStbd: UILabel!
    @IBOutlet weak var btnPort: UIButton!
    @IBOutlet weak var btnStbd: UIButton!
    
    let sndHigh: SystemSoundID = createSound("4k_to_2k_in_20ms", fileExt: "wav")
    let sndLow: SystemSoundID = createSound("1k_to_2k_in_20ms", fileExt: "wav")
    let noDataText = "---"
    let slowest_interval_secs = 2.0
    let fastest_interval_secs = 0.1
    let headingFilter: CLLocationDegrees = 1
    let defaultResponsivenessIndex = 2
    let touchRepeatInterval = 0.2
    let tackDegrees = 100.0
    var diffTolerance: CLLocationDegrees = 5
    
    var locationManager: CLLocationManager!
    var headingTarget: CLLocationDegrees?
    var headingCurrent: CLLocationDegrees = 150
    var touchTimer: NSTimer?
    var beepTimer: NSTimer?
    var beepSound: SystemSoundID?
    var beepInterval: NSTimeInterval?
    var lastBeepTime: NSDate?
    
    let headingUpdates: ObservationHistory = ObservationHistory(deltaFunc: ViewController.calcCorrection, window_secs: 10)
    
    //
    // ViewController overrides
    //
    
    override func viewDidLoad() {
        locationManager = CLLocationManager()
        setupUI()
        if CLLocationManager.headingAvailable() {
            log.debug("Requesting heading updates with headingFilter of \(headingFilter)")
            locationManager.delegate = self
            locationManager.headingFilter = headingFilter
            locationManager.startUpdatingHeading()
            // hide the manual heading slider
            sldrHeadingOverride.hidden = true
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
    // One-time UI setup
    //
    
    func setupUI() {
        segResponsiveness.selectedSegmentIndex = defaultResponsivenessIndex
        updateResponsiveness(defaultResponsivenessIndex)
        arrowPort.hidden = true
        arrowStbd.hidden = true
        btnPort.layer.borderWidth = 0.8
        btnPort.layer.borderColor = UIColor.redColor().CGColor
        btnPort.layer.cornerRadius = 4.0
        btnStbd.layer.borderWidth = 0.8
        btnStbd.layer.borderColor = UIColor.greenColor().CGColor
        btnStbd.layer.cornerRadius = 4.0

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
            txtDifference.textColor = UIColor.whiteColor()
            arrowPort.hidden = true
            arrowStbd.hidden = true
        }
        else {
            let correction = ViewController.calcCorrection(headingCurrent, target: headingTarget!)
            txtTarget.text = Int(headingTarget!).description
            txtDifference.text = Int(correction).description
            txtDifference.textColor = ViewController.correctionUIColor(correction, tolerance: diffTolerance)
            if correction < -diffTolerance {
                arrowPort.hidden = false
                arrowStbd.hidden = true
            } else if correction > diffTolerance {
                arrowPort.hidden = true
                arrowStbd.hidden = false
            } else {
                arrowPort.hidden = true
                arrowStbd.hidden = true
            }
        }
    }
    
    //
    // Manage the audio UI
    //
    
    func updateBeepUI() {
        if headingTarget == nil || !switchTargetOn.on {
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
    // Handle changes in heading
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
    
    //
    // Turn target heading racking on and off
    //
    
    @IBAction func switchTargetOn(sender: UISwitch) {
        if sender.on {
            log.debug("headingTarget set to current heading: \(headingCurrent)")
            if headingTarget == nil {
                headingTarget = headingCurrent
            }
        }
        else {
            log.debug("headingTarget set to nil")
            headingTarget = nil
        }
    }
    
    //
    // Modify the tolerance range
    //
    
    @IBAction func stepDiffToleranceChanged(sender: UIStepper) {
        log.debug("stepDiffTolerance changed to \(sender.value)")
        diffTolerance = CLLocationDegrees(sender.value)
        updateUI()
    }
    
    //
    // Change the responsiveness of the heading detection given changing compass input
    //
    
    func updateResponsiveness(index: Int) {
        switch(index) {
        case 0:
            headingUpdates.window_secs = 10.0
        case 1:
            headingUpdates.window_secs = 6.0
        case 3:
            headingUpdates.window_secs = 2.0
        case 4:
            headingUpdates.window_secs = 1.0
        default:
            headingUpdates.window_secs = 3.5
        }
    }
    
    @IBAction func setResponsiveness(sender: UISegmentedControl) {
        log.debug("setResponsiveness changed to index \(sender.selectedSegmentIndex)")
        self.updateResponsiveness(sender.selectedSegmentIndex)
    }

    //
    // Change the target heading (single taps, sustained presses and swipes all supported)
    //
    
    @IBAction func touchTargetToPort(sender: UIButton) {
        if headingTarget == nil {
            return
        }
        touchTimer = NSTimer.scheduledTimerWithTimeInterval(touchRepeatInterval, target: self, selector: "changeTargetToPort", userInfo: nil, repeats: true)
        touchTimer!.fire()
    }
    
    @IBAction func touchTargetToStbd(sender: UIButton) {
        if headingTarget == nil {
            return
        }
        touchTimer = NSTimer.scheduledTimerWithTimeInterval(touchRepeatInterval, target: self, selector: "changeTargetToStbd", userInfo: nil, repeats: true)
        touchTimer!.fire()
    }
    
    @IBAction func swipeStbd(sender: UISwipeGestureRecognizer) {
        tackToStarboard()
    }
    
    @IBAction func swipePort(sender: UISwipeGestureRecognizer) {
        tackToPort()
    }
    
    @IBAction func touchTargetStop(sender: UIButton) {
        if touchTimer != nil {
            touchTimer!.invalidate()
            touchTimer = nil
        }
    }
        
    func changeTargetToPort() {
        headingTarget = modifyDegrees(headingTarget, delta: -1)
        updateUI()
    }
    
    func changeTargetToStbd() {
        headingTarget = modifyDegrees(headingTarget, delta: 1)
        updateUI()
    }
    
    func tackToPort() {
        headingTarget = modifyDegrees(headingTarget, delta: -tackDegrees)
        updateUI()
    }
    
    func tackToStarboard() {
        headingTarget = modifyDegrees(headingTarget, delta: tackDegrees)
        updateUI()
    }
    
    
}


