//
//  todayViewController.swift
//  naou
//
//  Created by Titan on 8/13/17.
//  Copyright © 2018 Titan. All rights reserved.
//
//  The main view controller the user sees
//  Embedded in viewController along with yesterdayViewController and tomorrowViewController
//

import UIKit
import EventKit

class todayViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    //  UI table and title
    @IBOutlet weak var tblEvents: UITableView!
    @IBOutlet weak var topLabel: UILabel!
    
    //  Arrays and event store for events and reminders
    //  User Settings
    var events: [EKEvent]?
    var reminders: [EKReminder]?
    let eventStore = EKEventStore()
    let userDefaults = UserDefaults.standard
    
    // Title bar
    func titleSetup() {
        let titleFormatter = DateFormatter()
        titleFormatter.dateFormat = "EEEE, MMMM d"
        var titleString: String
        if userDefaults.bool(forKey: "dotw") {
            titleFormatter.dateFormat = "EEEE"
            titleString = titleFormatter.string(from: self.day)
            self.topLabel.text = titleString
        
        }else{
            if UIScreen.main.bounds.width < 375 {
                /*  Allows for a better fit on smaller devices  */
                titleFormatter.dateFormat = "MMMM d"
            }
            titleString = titleFormatter.string(from: self.day)
            self.topLabel.text = titleString + (daySuffix(from: self.day))
        }
        if formatFullDate(self.day) == formatFullDate(Date()) {
            self.topLabel.text = "Now"
        }
    }
    
    //  Load events
    func loadEvents() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let date = self.day
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: self.day)!
        let todaydate = dateFormatter.string(from: date)
        let tomorrowdate = dateFormatter.string(from: tomorrow)
        let startDate = dateFormatter.date(from: todaydate)
        let endDate = dateFormatter.date(from: tomorrowdate)
        
        if let startDate = startDate, let endDate = endDate {
            let eventsPredicate = self.eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
            self.events = self.eventStore.events(matching: eventsPredicate).sorted {
                (e1: EKEvent, e2: EKEvent) in
                return e1.startDate.compare(e2.startDate) == ComparisonResult.orderedAscending
            }
        }
    }
    
    //  Load reminders
    func loadReminders() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: self.day)!
        let todayDate = dateFormatter.string(from: self.day)
        let startDate = dateFormatter.date(from: todayDate)
        let tomorrowdate = dateFormatter.string(from: tomorrow)
        let endDate = dateFormatter.date(from: tomorrowdate)
        
        let emptyPredicate = eventStore.predicateForIncompleteReminders(withDueDateStarting: Date(timeIntervalSinceReferenceDate: -999999999.0), ending: Date(timeIntervalSinceReferenceDate: -999999999.0), calendars: nil)
        var remindersPredicate = emptyPredicate
        var unscheduledPredicate = emptyPredicate
        
        if formatFullDate(self.day) == formatFullDate(Date()) {
            remindersPredicate = eventStore.predicateForIncompleteReminders(withDueDateStarting: nil, ending: endDate, calendars: nil)
            unscheduledPredicate = eventStore.predicateForReminders(in: nil)
        }else if self.day > Date(){
            remindersPredicate = eventStore.predicateForIncompleteReminders(withDueDateStarting: startDate, ending: endDate, calendars: nil)
        }
        eventStore.fetchReminders(matching: remindersPredicate, completion: { (reminders: [EKReminder]?) -> Void in
            self.reminders = reminders?.sorted {
                (e1: EKReminder, e2: EKReminder) in
                return e1.dueDateComponents?.date?.compare((e2.dueDateComponents?.date)!) == ComparisonResult.orderedAscending
            }
            DispatchQueue.main.async {
                self.tblEvents.reloadData()
            }
        })
        eventStore.fetchReminders(matching: unscheduledPredicate, completion: { (reminders: [EKReminder]?) -> Void in
            if self.userDefaults.bool(forKey: "unscheduled") {
                if let reminders = reminders {
                    for reminder in reminders {
                        if !(reminder.hasAlarms) {
                            if !(reminder.isCompleted) {
                                self.reminders?.append(reminder)
                            }
                        }
                    }
                }
                DispatchQueue.main.async {
                    self.tblEvents.reloadData()
                }
            }
        })
    }
    
    //  Sections, headers, and rows
    func numberOfSections(in tableView: UITableView) -> Int {
        //  "Reminders" header in its own section due to swiping bug in iOS 11
        return 3
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        let label = UILabel()
        view.backgroundColor = UIColor.groupTableViewBackground
        label.textAlignment = NSTextAlignment.center
        label.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.semibold)
        label.frame = CGRect(x: 0, y: 5, width: self.view.frame.size.width, height: 38)
        if section == 0 {
            label.text = "Events"
            if events?.count == 0 && reminders?.count == 0 {
                view.backgroundColor = UIColor.white
                label.text = "You're done for the day!"
                if EKEventStore.authorizationStatus(for: EKEntityType.event) != EKAuthorizationStatus.authorized {
                   if EKEventStore.authorizationStatus(for: EKEntityType.reminder) != EKAuthorizationStatus.authorized {
                    label.text = "Unable to access data."
                    }
                }
                label.font = UIFont.systemFont(ofSize: 21, weight: UIFont.Weight.regular)
                label.frame = CGRect(x: 0, y: self.tblEvents.frame.size.height/3.5, width: self.view.frame.size.width, height: 38)
            }
        }else{
            label.text = "Reminders"
        }
        view.addSubview(label)
        return view
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            if events?.count == 0 && reminders?.count == 0 {
                return self.tblEvents.frame.size.height
            }
            else if events?.count == 0 {
                return 0
            }else{
                return 48
            }
        }
        else if section == 1{
            if reminders?.count == 0 {
                return 0
            }else{
                return 48
            }
        }else{
            return 0
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if let events = events {
                return events.count
            }
        }
        if section == 2 {
            if let reminders = reminders {
                return reminders.count
            }
        }
        return 0
    }
    
    //  Cell Data
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if indexPath.section == 0 {
            cell?.textLabel?.text = events?[indexPath.row].title
            if (events?[indexPath.row].isAllDay)! {
                cell?.detailTextLabel?.text = "All Day"
            }else{
                cell?.detailTextLabel?.text = formatTime(events?[indexPath.row].startDate)
            }
        }else{
            cell?.textLabel?.text = reminders?[indexPath.row].title
            if (reminders?[indexPath.row].hasAlarms)! {
                let date = (Calendar.current).date(from:(reminders?[indexPath.row].dueDateComponents)!)!
                cell?.detailTextLabel?.text = formatDueDate(date) + daySuffix(from: date)
                if formatFullDate((Calendar.current).date(from:(reminders?[indexPath.row].dueDateComponents)!)) == formatFullDate(self.day) {
                    cell?.detailTextLabel?.text = formatTime(date)
                }
                if formatFullDate((Calendar.current).date(from:(reminders?[indexPath.row].dueDateComponents)!)) == formatFullDate(Calendar.current.date(byAdding: .day, value: -1, to: self.day)) {
                    cell?.detailTextLabel?.text = "Yesterday"
                }
            }else{
                cell?.detailTextLabel?.text = ""
            }
        }
        cell?.selectionStyle = UITableViewCellSelectionStyle.none
        return cell!
    }
    
    //  Due date format
    func formatDueDate(_ date: Date?) -> String {
        if let date = date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM d"
            return dateFormatter.string(from: date)
        }
        return ""
    }
    
    //  Due time format
    func formatTime(_ date: Date?) -> String {
        if let date = date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "h:mm a"
            return dateFormatter.string(from: date)
        }
        return ""
    }
    
    // Date format for comparisons
    func formatFullDate(_ date: Date?) -> String {
        if let date = date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd-MM-YYYY"
            return dateFormatter.string(from: date)
        }
        return ""
    }
    
    //  Suffix for days (July 19 --> July 19th)
    func daySuffix(from date: Date) -> String {
        let dayOfMonth = Calendar.current.component(.day, from: date)
        switch dayOfMonth {
            case 1, 21, 31: return "st"
            case 2, 22: return "nd"
            case 3, 23: return "rd"
            default: return "th"
        }
    }
    
    /////////////////////////////////////////////////////// UNIQUE TO TODAYVIEWCONTROLLER
    
    //  Day to be displayed
    var day = refday.date
    
    //  Load data and set up triggers for data reloads
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(self.initialize), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.open), name: NSNotification.Name(rawValue: "load"), object: nil)
    }
    
    // Set day to today and load data
    @objc func initialize() {
        refday.date = Date()
        self.open()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "tload"), object: nil)
    }
    
    //  Load all data
    @objc func open() {
        day = refday.date
        titleSetup()
        loadReminders()
        loadEvents()
    }
    
    //  Gestures
    @IBAction func tap(_ sender: Any) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "back"), object: nil)
    }
    @IBAction func holdTop(_ sender: Any) {
        performSegue(withIdentifier: "setSomething", sender: nil)
    }
    @IBAction func holdAll(_ sender: Any) {
        performSegue(withIdentifier: "addSomething", sender: nil)
    }
    
    //  Cell editing
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteEvent = UITableViewRowAction(style: .normal, title: "Delete") { (action, indexPath) in
            let event: EKEvent = (self.events?[indexPath.row])!
            do {
                self.events?.remove(at: indexPath.row)
                try self.eventStore.remove(event, span: .thisEvent, commit: true)
            }catch{
                print("Error removing event : \(error)")
            }
            if self.events?.count == 0 {
                self.tblEvents.reloadSections(IndexSet(integer: indexPath.section), with: UITableViewRowAnimation.fade)
            }else{
                self.tblEvents.deleteRows(at: [indexPath], with: UITableViewRowAnimation.none)
            }
        }
        
        let done = UITableViewRowAction(style: .normal, title: "Done") { (action, indexPath) in
            let reminder: EKReminder = (self.reminders?[indexPath.row])!
            reminder.isCompleted = true
            do {
                try self.eventStore.save(reminder, commit: true)
                self.reminders?.remove(at: indexPath.row)
            }catch{
                print("Error completing new reminder : \(error)")
            }
            if self.reminders?.count == 0 {
                if self.events?.count == 0 {
                    self.tblEvents.reloadSections([0,1,2], with: UITableViewRowAnimation.fade)
                }else{
                    self.tblEvents.reloadSections([1,2], with: UITableViewRowAnimation.fade)
                }
            }else{
                self.tblEvents.deleteRows(at: [indexPath], with: UITableViewRowAnimation.none)
            }
        }
        
        let snooze = UITableViewRowAction(style: .normal, title: "Snooze") { (action, indexPath) in
            let reminder: EKReminder = (self.reminders?[indexPath.row])!
            reminder.removeAlarm((reminder.alarms?[0])!)
            reminder.dueDateComponents?.day = (NSCalendar.current.dateComponents([.day], from: self.day)).day! + 1
            let time: Date = (reminder.dueDateComponents?.date)!
            reminder.addAlarm(EKAlarm(absoluteDate: time))
            do {
                try self.eventStore.save(reminder, commit: true)
                self.reminders?.remove(at: indexPath.row)
            }catch{
                print("Error moving reminder : \(error)")
            }
            if self.reminders?.count == 0 {
                if self.events?.count == 0 {
                    self.tblEvents.reloadSections([0,1,2], with: UITableViewRowAnimation.fade)
                }else{
                    self.tblEvents.reloadSections([1,2], with: UITableViewRowAnimation.fade)
                }
            }else{
                self.tblEvents.deleteRows(at: [indexPath], with: UITableViewRowAnimation.none)
            }
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "tload"), object: nil)
        }
        
        let deleteReminder = UITableViewRowAction(style: .normal, title: "Delete") { (action, indexPath) in
            let reminder: EKReminder = (self.reminders?[indexPath.row])!
            do {
                self.reminders?.remove(at: indexPath.row)
                try self.eventStore.remove(reminder, commit: true)
            }catch{
                print("Error removing reminder : \(error)")
            }
            if self.reminders?.count == 0 {
                if self.events?.count == 0 {
                    self.tblEvents.reloadSections([0,1,2], with: UITableViewRowAnimation.fade)
                }else{
                    self.tblEvents.reloadSections([1,2], with: UITableViewRowAnimation.fade)
                }
            }else{
                self.tblEvents.deleteRows(at: [indexPath], with: UITableViewRowAnimation.none)
            }
        }
        
        deleteEvent.backgroundColor = UIColor(red:0.00, green:0.52, blue:1.00, alpha:1.0)
        done.backgroundColor = UIColor(red:0.00, green:0.52, blue:1.00, alpha:1.0)
        snooze.backgroundColor = UIColor(red:0.35, green:0.66, blue:1.00, alpha:1.0)
        deleteReminder.backgroundColor = UIColor(red:0.55, green:0.76, blue:1.00, alpha:1.0)
        
        if indexPath.section == 0 {
            return [deleteEvent]
        }else{
            if (reminders?[indexPath.row].hasAlarms)! {
                return [done, snooze, deleteReminder]
            }else{
                deleteReminder.backgroundColor = UIColor(red:0.35, green:0.66, blue:1.00, alpha:1.0)
                return [done, deleteReminder]
            }
        }
    }
}

