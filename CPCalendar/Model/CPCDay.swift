//
//  CPCDay.swift
//  Copyright © 2018 Cleverpumpkin, Ltd. All rights reserved.
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

public struct CPCDay: CPCCalendarUnit {
	internal typealias UnitBackingType = DayBackingValues;
	
	internal static let representedUnit = Calendar.Component.day;
	internal static let requiredComponents: Set <Calendar.Component> = [.day, .month, .year];
	
	public let calendar: Calendar;
	public var year: Int {
		return self.backingValue.year;
	}
	public var month: Int {
		return self.backingValue.month;
	}
	public var day: Int {
		return self.backingValue.day;
	}
	
	internal let backingValue: DayBackingValues;
	
	internal init (backedBy value: DayBackingValues, calendar: Calendar) {
		self.calendar = calendar;
		self.backingValue = value;
	}
}

public extension CPCDay {
	public static var today: CPCDay {
		return CPCDay (containing: Date (), calendar: .current);
	}
	
	public static var yesterday: CPCDay {
		return self.today.next;
	}
	
	public static var tommorow: CPCDay {
		return self.today.prev;
	}
	
	public var weekday: Int {
		return self.calendar.component (.weekday, from: self.startDate);
	}
	
	public var isWeekend: Bool {
		return self.calendar.isDateInWeekend (self.startDate);
	}

	public init (daysSinceNow: Int) {
		self = CPCDay.today.advanced (by: daysSinceNow);
	}
}

extension CPCDay: CPCCalendarUnitSymbolImpl {
	internal static func unitSymbols (calendar: Calendar, style: CPCCalendarUnitSymbolStyle, standalone: Bool) -> [String] {
		switch (style, standalone) {
		case (.normal, false):
			return calendar.weekdaySymbols;
		case (.short, false):
			return calendar.shortWeekdaySymbols;
		case (.veryShort, false):
			return calendar.veryShortWeekdaySymbols;
		case (.normal, true):
			return calendar.standaloneWeekdaySymbols;
		case (.short, true):
			return calendar.shortStandaloneWeekdaySymbols;
		case (.veryShort, true):
			return calendar.veryShortStandaloneWeekdaySymbols;
		}
	}
	
	internal var unitOrdinalValue: Int {
		return self.weekday - 1;
	}
}

