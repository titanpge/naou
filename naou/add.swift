//
//  add.swift
//  naou
//
//  Created by Titan on 8/13/17.
//  Copyright © 2018 Titan. All rights reserved.
//
//  The view controller for adding a new event or reminder
//  Accessible via the + button or long pressing in the todayViewController table
//

import UIKit
import EventKit

class add: UITableViewController {
    
    //  UI elements
    @IBOutlet weak var switcher: UISegmentedControl!
    @IBOutlet weak var newTitle: UITextField!
    @IBOutlet weak var startTime: UIDatePicker!
    @IBOutlet weak var endTime: UIDatePicker!
    @IBOutlet weak var time: UISwitch!
    @IBOutlet weak var remindStart: UITableViewCell!
    @IBOutlet weak var eventStart: UITableViewCell!
    
    //  User settings and general variables
    let userDefaults = UserDefaults.standard
    var topTitle = "New Reminder"
    var adjust = 0
    
    //  Cancel
    @objc func btnCancelAction() {
        dismissKeyboard()
        dismiss(animated: true, completion: nil)
    }
    
    //  Done
    //  Creates new event or reminder
    @objc func btnDoneAction() {
        if ((newTitle.text?.characters.count)! > 0) {
            let eventStore = EKEventStore()
            
            if switcher.selectedSegmentIndex == 0 {
                let newEvent = EKEvent(eventStore: eventStore)
                
                newEvent.calendar = eventStore.defaultCalendarForNewEvents
                newEvent.title = self.newTitle.text
                newEvent.startDate = self.startTime.date
                newEvent.endDate = self.endTime.date
                
                do {
                    try eventStore.save(newEvent, span: .thisEvent, commit: true)
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "tload"), object: nil)
                    self.dismiss(animated: true, completion: nil)
                } catch {
                    let alert = UIAlertController(title: "Event could not save", message: (error as NSError).localizedDescription, preferredStyle: .alert)
                    let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(OKAction)
                    self.present(alert, animated: true, completion: nil)
                }
            } else {
                
                let reminder = EKReminder(eventStore: eventStore)
                
                reminder.title = self.newTitle.text
                reminder.calendar = eventStore.defaultCalendarForNewReminders()
                if !userDefaults.bool(forKey: "untime") {
                    reminder.dueDateComponents = NSCalendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: self.startTime.date)
                    reminder.addAlarm(EKAlarm(absoluteDate: self.startTime.date))
                }
                
                do {
                    try eventStore.save(reminder, commit: true)
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "tload"), object: nil)
                    self.dismiss(animated: true, completion: nil)
                } catch let error {
                    let alert = UIAlertController(title: "Reminder could not save", message: (error as NSError).localizedDescription, preferredStyle: .alert)
                    let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(OKAction)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //  Prevents transparent status bar
        let statusBar: UIView = UIApplication.shared.value(forKey: "statusBar") as! UIView
        if statusBar.responds(to: #selector(setter: UIView.backgroundColor)) {
            statusBar.backgroundColor = UIColor.white
        }
        
        //  Adjusts layout for iOS version
        if !(ProcessInfo().isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 11, minorVersion: 0, patchVersion: 0))) {
            adjust = 20
        }
        
        //  Date formatting
        let formatFull = DateFormatter()
        formatFull.dateFormat = "yyyyMMddhhmmaa"
        let formatDay = DateFormatter()
        formatDay.dateFormat = "yyyyMMdd"
        let formatTime = DateFormatter()
        formatTime.dateFormat = "hh00aa"
        
        //  Set default values
        if userDefaults.bool(forKey: "event") {
            switcher.selectedSegmentIndex = 0
            topTitle = "New Event"
            newTitle.placeholder = "New Event"
        }else{
            switcher.selectedSegmentIndex = 1
            topTitle = "New Reminder"
            newTitle.placeholder = "New Reminder"
        }
        if userDefaults.bool(forKey: "untime") {
            time.setOn(false, animated: false)
        }else{
            time.setOn(true, animated: false)
        }
        let start = formatFull.date(from: formatDay.string(from: refday.date) + formatTime.string(from: Calendar.current.date(byAdding: .hour, value: 1, to: Date())!))
        startTime.setDate(start!, animated: false)
        endTime.setDate(Calendar.current.date(byAdding: .hour, value: 1, to: startTime.date)!, animated: true)
        
        //  Tap to dismiss keyboard
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(add.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    //  Section, header, and rows
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor.white
        let cButton = UIButton()
        cButton.setTitle("Back", for: .normal)
        cButton.setTitleColor(UIColor(red:0.00, green:0.52, blue:1.00, alpha:1.0), for: .normal)
        cButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.regular)
        cButton.frame = CGRect(x: -10, y: (15 + adjust), width: 100, height: 35)
        view.addSubview(cButton)
        let title = UILabel()
        title.text = topTitle
        title.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.medium)
        title.textAlignment = .center
        title.frame = CGRect(x: 0, y: (15 + adjust), width: Int(self.view.frame.size.width), height: 35)
        view.addSubview(title)
        let dButton = UIButton()
        dButton.setTitle("Done", for: .normal)
        dButton.setTitleColor(UIColor(red:0.00, green:0.52, blue:1.00, alpha:1.0), for: .normal)
        dButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.regular)
        dButton.frame = CGRect(x: Int(self.view.frame.size.width - 74), y: (15 + adjust), width: 70, height: 35)
        view.addSubview(dButton)
        cButton.addTarget(self, action: #selector(btnCancelAction), for: .touchUpInside)
        dButton.addTarget(self, action: #selector(btnDoneAction), for: .touchUpInside)
        let borderBottom = UIView(frame: CGRect(x:0, y: (61 + adjust), width: Int(tableView.bounds.size.width), height: 1))
        borderBottom.backgroundColor = UIColor.self.init(red: 188/255, green: 187/255, blue: 193/255, alpha: 0.6)
        view.addSubview(borderBottom)
        return view
    }
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if !(ProcessInfo().isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 11, minorVersion: 0, patchVersion: 0))) {
            adjust = 20
        }
        return CGFloat(65 + adjust)
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if switcher.selectedSegmentIndex == 0 {
            return 10
        }else{
            if userDefaults.bool(forKey: "untime") {
                return 7
            }else{
                return 8
            }
        }
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        /*  Allows for hiding/showing cells  */
        if switcher.selectedSegmentIndex == 1 && userDefaults.bool(forKey: "unscheduled"){
            if indexPath.row == 6 {
                return 0
            }else if indexPath.row == 7 || indexPath.row == 9 {
                return 225
            }else if indexPath.row == 0 || indexPath.row == 2 || indexPath.row == 4 {
                return 15
            }
        }else{
            if indexPath.row == 5 {
                return 0
            }else if indexPath.row == 7 || indexPath.row == 9 {
                return 225
            }else if indexPath.row == 0 || indexPath.row == 2 || indexPath.row == 4 {
                return 15
            }
        }
        return 40
    }
    
    //  Choose whether to create an event or reminder
    @IBAction func switcherAction(_ sender: Any) {
        if switcher.selectedSegmentIndex == 0 {
            newTitle.placeholder = "New Event"
            topTitle = "New Event"
        }else{
            newTitle.placeholder = "New Reminder"
            topTitle = "New Reminder"
        }
        self.tableView.reloadData()
    }
    
    //  Start time option for reminders
    @IBAction func timeSwitch(_ sender: Any) {
        if userDefaults.bool(forKey: "untime") {
            userDefaults.set(false, forKey: "untime")
        }else{
            userDefaults.set(true, forKey: "untime")
        }
        self.tableView.reloadData()
    }
    
    //  If start date changed
    @IBAction func timeChange(_ sender: Any) {
        endTime.setDate(Calendar.current.date(byAdding: .hour, value: 1, to: startTime.date)!, animated: true)
        self.dismissKeyboard()
    }
    
    //  Dismiss keyboard function
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
