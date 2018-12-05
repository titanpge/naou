//
//  global.swift
//  naou
//
//  Created by Titan on 9/2/17.
//  Copyright © 2018 Titan. All rights reserved.
//
//  Global date variable
//  Allows for data syncing/reloading without inconsistencies across view controllers
//

import UIKit

class Main {
    var date:Date
    init(date:Date) {
        self.date = date
    }
}
/*  Initial value is tomorrow's date because yesterdayViewController is seen first  */
var refday = Main(date:Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
