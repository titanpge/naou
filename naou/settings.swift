//
//  settings.swift
//  naou
//
//  Created by Titan on 8/13/17.
//  Copyright © 2018 Titan. All rights reserved.
//
//  The view controller for changing settings
//  Accessible via long pressing the todayViewController top bar
//

import UIKit

class settings: UITableViewController {
    
    //  UI Switches
    @IBOutlet weak var usSwitchSet: UISwitch!
    @IBOutlet weak var dotwSwitchSet: UISwitch!
    @IBOutlet weak var eventSwitchSet: UISwitch!
    
    //  User settings
    let userDefaults = UserDefaults.standard
    
    //  Number of rows = number of settings + 1 for header
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    //  Set switches
    override func viewDidLoad() {
        super.viewDidLoad()
        if userDefaults.bool(forKey: "unscheduled") {
            usSwitchSet.setOn(true, animated: false)
        }
        if userDefaults.bool(forKey: "dotw") {
            dotwSwitchSet.setOn(true, animated: false)
        }
        if userDefaults.bool(forKey: "event") {
            eventSwitchSet.setOn(true, animated: false)
        }
    }
    
    //  Change settings with switches
    @IBAction func usSwitch(_ sender: Any) {
        if userDefaults.bool(forKey: "unscheduled") {
            userDefaults.set(false, forKey: "unscheduled")
            userDefaults.set(false, forKey: "untime")
        }else{
            userDefaults.set(true, forKey: "unscheduled")
        }
    }
    @IBAction func dotwSwitch(_ sender: Any) {
        if userDefaults.bool(forKey: "dotw") {
            userDefaults.set(false, forKey: "dotw")
        }else{
            userDefaults.set(true, forKey: "dotw")
        }
    }
    @IBAction func eventSwitch(_ sender: Any) {
        if userDefaults.bool(forKey: "event") {
            userDefaults.set(false, forKey: "event")
        }else{
            userDefaults.set(true, forKey: "event")
        }
    }
    
    //  Gestures
    @IBAction func swipeDown(_ sender: Any) {
        leave()
    }
    @IBAction func hold(_ sender: Any) {
        leave()
    }
    
    //  Save settings, reload main view controllers, and dismiss view controller
    func leave() {
        userDefaults.synchronize()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "tload"), object: nil)
        dismiss(animated: true, completion: nil)
    }
}
