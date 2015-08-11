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

struct Platform {
    static let isSimulator: Bool = {
        var isSim = false
        #if arch(i386) || arch(x86_64)
            isSim = true
        #endif
        return isSim
    }()
}

class ViewController: UIViewController,CLLocationManagerDelegate {

    @IBOutlet weak var txtDifference: UILabel!
    @IBOutlet weak var txtTarget: UILabel!
    @IBOutlet weak var txtHeading: UILabel!
    @IBOutlet weak var sldrHeadingOverride: UISlider!
    @IBOutlet weak var txtHeadingOverrideLabel: UILabel!
    
    var locationManager: CLLocationManager!
    var headingFilter: CLLocationDegrees!
    var headingTarget: Int?;
    var headingCurrent: Int = 150;
    
    let sndHigh: SystemSoundID = createSound("2000", fileExt: "wav");
    let sndLow: SystemSoundID = createSound("300", fileExt: "wav");
    
    var diffTolerance: Int = 5
    var beepTimer: NSTimer?;
    var beepSound: SystemSoundID?
    let slowest_interval_secs = 2.0;
    let fastest_interval_secs = 0.1;
    
    let noDataText = "---"
    
    
    override func viewDidLoad() {
        locationManager = CLLocationManager();
        if CLLocationManager.headingAvailable() {
            locationManager.delegate = self;
            locationManager.headingFilter = 5;
            locationManager.startUpdatingHeading();
            // hide the manual heading slider
            sldrHeadingOverride.hidden = true;
            txtHeadingOverrideLabel.hidden = true;
        }
        super.viewDidLoad()
        somethingChanged()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //CLLocationManagerDelegate
    func locationManager(manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        headingCurrent = Int(newHeading.magneticHeading)
        somethingChanged();
    }
    
    func beep() {
        if beepSound != nil {
            AudioServicesPlaySystemSound(beepSound!)
        }
    }
    
    func beepInterval(degrees: Int) -> NSTimeInterval {
        let degrees = Double(abs(degrees));
        let numerator = Double(diffTolerance) * slowest_interval_secs;
        let intervalSecs: NSTimeInterval = max(fastest_interval_secs, numerator/degrees);
        return intervalSecs
    }
    
    func somethingChanged() {
        txtHeading.text = String(headingCurrent);
        sldrHeadingOverride.value = Float(headingCurrent);
        if headingTarget == nil {
            // no target set, so no difference to process
            txtTarget.text = noDataText;
            txtDifference.text = noDataText;
            return;
        }
        else {
            txtTarget.text = String(headingTarget!);
            let difference = headingCurrent - headingTarget!;
            updateDifference(difference);
            updateBeepTimer(difference);
        }
    }
    
    func updateDifference(difference: Int) {
        txtDifference.text = String(difference);
        if abs(difference) < diffTolerance {
            txtDifference.textColor = UIColor.whiteColor();
        }
        else if difference < -diffTolerance {
            txtDifference.textColor = UIColor.redColor();
        }
        else if difference > diffTolerance {
            txtDifference.textColor = UIColor.greenColor();
        }
    }
    
    func updateBeepTimer(difference: Int) {
        if beepTimer != nil {
            // always invalidate the current timer
            beepTimer!.invalidate();
        }
        if abs(difference) < diffTolerance {
            // don't set up a new beep timer
            beepSound = nil;
        }
        else if difference < -diffTolerance {
            beepSound = sndHigh;
        }
        else if difference > diffTolerance {
            beepSound = sndLow;
        }
        if beepSound != nil {
            beepTimer = NSTimer.scheduledTimerWithTimeInterval(beepInterval(difference), target: self, selector: "beep", userInfo: nil, repeats: true)
        }
    }
    
    @IBAction func sldrHeadingOverrideValueChanged(sender: AnyObject) {
        headingCurrent = Int(round(sldrHeadingOverride.value))
        somethingChanged()
    }
    
    @IBAction func setTarget(sender: UIButton) {
        headingTarget = Int(round(sldrHeadingOverride.value))
        somethingChanged()
    }
}


