//
//  CPCDay+Date.swift
//  Copyright © 2021 Cleverpumpkin, Ltd. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

public extension CPCDay {
	
	var calendarDate: Date {
		let calendar = Calendar(identifier: .gregorian)
		var dateComponents = DateComponents()
		dateComponents.timeZone = TimeZone.current
		dateComponents.year = year
		dateComponents.month = month
		dateComponents.day = day
		dateComponents.hour = 12
		dateComponents.minute = 00
		return calendar.date(from: dateComponents) ?? Date()
	}
}

public extension Date {
	
	var crispyDay: CPCDay {
		var calendar = Calendar(identifier: .gregorian)
		calendar.locale = Locale(identifier: "ru-RU")
		return CPCDay(containing: self, calendar: calendar)
	}
}
