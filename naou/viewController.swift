//
//  viewController.swift
//  naou
//
//  Created by Titan on 9/2/17.
//  Copyright © 2018 Titan. All rights reserved.
//
//  Scroll view containing yesterdayViewController, todayViewController, and tomorrowViewController
//

import UIKit
import EventKit

class viewController: UIViewController {
    
    //  UI scroll view
    @IBOutlet weak var mainScrollView: UIScrollView!
    
    //  Check access and set up trigger for gesture
    override func viewDidLoad() {
        super.viewDidLoad()
        checkAccess()
        NotificationCenter.default.addObserver(self, selector: #selector(self.back), name: NSNotification.Name(rawValue: "back"), object: nil)
    }
    
    //  Load views
    func setup() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        self.mainScrollView.contentSize = CGSize(width: self.view.frame.size.width * 3, height: self.view.frame.size.height)
        
        let ydViewController = storyboard.instantiateViewController(withIdentifier: "yesterdayView") as! yesterdayViewController
        self.addChildViewController(ydViewController)
        self.mainScrollView.addSubview(ydViewController.view)
        ydViewController.didMove(toParentViewController: self)
        
        let tdViewController = storyboard.instantiateViewController(withIdentifier: "todayView") as! todayViewController
        self.addChildViewController(tdViewController)
        self.mainScrollView.addSubview(tdViewController.view)
        tdViewController.didMove(toParentViewController: self)
        var tdViewControllerFrame: CGRect = tdViewController.view.frame
        tdViewControllerFrame.origin.x = self.view.frame.width
        tdViewController.view.frame = tdViewControllerFrame
        
        let tmViewController = storyboard.instantiateViewController(withIdentifier: "tomorrowView") as! tomorrowViewController
        self.addChildViewController(tmViewController)
        self.mainScrollView.addSubview(tmViewController.view)
        tmViewController.didMove(toParentViewController: self)
        var tmViewControllerFrame: CGRect = tmViewController.view.frame
        tmViewControllerFrame.origin.x = 2 * self.view.frame.width
        tmViewController.view.frame = tmViewControllerFrame
        
        /*  Note that the viewController starts on yesterdayView and then reloads to todayView to keep the layout of the views consistent   */
        
        refday.date = Date()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
        self.mainScrollView.setContentOffset(CGPoint(x: self.view.frame.width, y: 0), animated: false)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "tload"), object: nil)
    }
    
    //  Check access to reminders and calendar
    func checkAccess() {
        EKEventStore().requestAccess(to: .reminder, completion: {
            (accessGranted: Bool, error: Error?) in
            
            if accessGranted == true {
                EKEventStore().requestAccess(to: .event, completion: {
                    (accessGranted: Bool, error: Error?) in
                    if accessGranted == true {
                        /*  This slight delay allows for asynchronous data fetching  */
                        let when = DispatchTime.now() + 0.1
                        DispatchQueue.main.asyncAfter(deadline: when) {
                            self.setup()
                        }
                    } else {
                        let when = DispatchTime.now() + 0.1
                        DispatchQueue.main.asyncAfter(deadline: when) {
                            self.setup()
                        }
                    }
                })
            } else {
                let when = DispatchTime.now() + 0.1
                DispatchQueue.main.asyncAfter(deadline: when) {
                    self.setup()
                }
            }
        })
    }
    
    //  Gestures
    /*  The asyncAfter delays allow for updating data invisibly */
    @IBAction func swipeLeft(_ sender: Any) {
        if EKEventStore.authorizationStatus(for: EKEntityType.event) != EKAuthorizationStatus.authorized {
            if EKEventStore.authorizationStatus(for: EKEntityType.reminder) != EKAuthorizationStatus.authorized {
                return
            }
        }
        
        mainScrollView.setContentOffset(CGPoint(x: 2 * self.view.frame.width, y: 0), animated: true)
        refday.date = Calendar.current.date(byAdding: .day, value: 1, to: refday.date)!
        let when = DispatchTime.now() + 0.3
        DispatchQueue.main.asyncAfter(deadline: when) {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
        }
        let when1 = DispatchTime.now() + 0.35
        DispatchQueue.main.asyncAfter(deadline: when1) {
            self.mainScrollView.setContentOffset(CGPoint(x: self.view.frame.width, y: 0), animated: false)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "tload"), object: nil)
        }
    }
    @IBAction func swipeRight(_ sender: Any) {
        if EKEventStore.authorizationStatus(for: EKEntityType.event) != EKAuthorizationStatus.authorized {
            if EKEventStore.authorizationStatus(for: EKEntityType.reminder) != EKAuthorizationStatus.authorized {
                return
            }
        }
        mainScrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
        refday.date = Calendar.current.date(byAdding: .day, value: -1, to: refday.date)!
        let when = DispatchTime.now() + 0.3
        DispatchQueue.main.asyncAfter(deadline: when) {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
        }
        let when1 = DispatchTime.now() + 0.35
        DispatchQueue.main.asyncAfter(deadline: when1) {
            self.mainScrollView.setContentOffset(CGPoint(x: self.view.frame.width, y: 0), animated: false)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "tload"), object: nil)
        }
    }
    @objc func back() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if dateFormatter.string(from: refday.date) == dateFormatter.string(from: Date()) {
            return
        }else if refday.date < Date() {
            refday.date = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "tload"), object: nil)
            mainScrollView.setContentOffset(CGPoint(x: 2 * self.view.frame.width, y: 0), animated: true)
        }else{
            refday.date = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "tload"), object: nil)
            mainScrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
        }
        refday.date = Date()
        let when = DispatchTime.now() + 0.3
        DispatchQueue.main.asyncAfter(deadline: when) {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
        }
        let when1 = DispatchTime.now() + 0.35
        DispatchQueue.main.asyncAfter(deadline: when1) {
            self.mainScrollView.setContentOffset(CGPoint(x: self.view.frame.width, y: 0), animated: false)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "tload"), object: nil)
        }
    }
}
