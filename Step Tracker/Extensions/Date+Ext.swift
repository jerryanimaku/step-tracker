//
//  Date+Ext.swift
//  Step Tracker
//
//  Created by Jeremiah Animaku on 11/16/26.
//

import Foundation

extension Date {
    var weekdayInt: Int {
        Calendar.current.component(.weekday, from: self)
    }
}
