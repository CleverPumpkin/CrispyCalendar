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

/// Calendar unit that represents a single day.
public struct CPCDay {
	internal let calendarWrapper: CalendarWrapper;
	internal let backingValue: BackingStorage;

	internal init (backedBy value: BackingStorage, calendar: CalendarWrapper) {
		self.calendarWrapper = calendar;
		self.backingValue = value;
	}
}

extension CPCDay: CPCDateInterval {
	public var start: Date { return self.startValue }
	public var end: Date { return self.endValue };
}

extension CPCDay {
	public init (containing date: Date, calendar: Calendar) {
		self.init (containing: date, calendar: calendar.wrapped ());
	}
}

extension CPCDay: CPCCalendarUnit {
	internal static let representedUnit = Calendar.Component.day;
	internal static let descriptionDateFormatTemplate = "ddMMyyyy";
}

public extension CPCDay {
	/// Value that represents a current day.
	public static var today: CPCDay {
		if let cachedToday = self.cachedToday {
			return cachedToday;
		}
		let today = CPCDay (containing: Date (), calendar: .current);
		self.cachedToday = today;
		return today;
	}
	
	private static var cachedToday: CPCDay? {
		didSet {
			_ = self.dateChangeObserver;
		}
	}
	private static let dateChangeObserver = NotificationCenter.default.addObserver (forName: .NSCalendarDayChanged, object: nil, queue: nil) { _ in
		CPCDay.cachedToday = nil;
	};
	
	/// Value that represents yesterday.
	public static var yesterday: CPCDay {
		return self.today.next;
	}
	
	/// Value that represents tomorrow.
	public static var tomorrow: CPCDay {
		return self.today.prev;
	}
	
	/// Era of the represented month's year.
	public var era: Int {
		return self.backingValue.era;
	}

	/// Year of represented day.
	public var year: Int {
		return self.backingValue.year;
	}
	
	/// Month of represented day.
	public var month: Int {
		return self.backingValue.month;
	}
	
	/// Week number of represented day.
	public var week: Int {
		return self.calendar.component (.weekOfYear, from: self.start);
	}
	
	/// This day's number.
	public var day: Int {
		return self.backingValue.day;
	}
	
	/// Year that contains represented day.
	public var containingYear: CPCYear {
		return CPCYear (backedBy: self.backingValue.containingYear (self.calendarWrapper), calendar: self.calendarWrapper);
	}
	
	/// Month that contains represented day.
	public var containingMonth: CPCMonth {
		return CPCMonth (backedBy: self.backingValue.containingMonth (self.calendarWrapper), calendar: self.calendarWrapper);
	}
	
	/// Week that contains represented day.
	public var containingWeek: CPCWeek {
		return CPCWeek (containing: self.start, calendarOf: self);
	}
	
	/// Create a new value, corresponding to a day in the future or past.
	///
	/// - Parameter daysSinceNow: Distance from today in days.
	public init (daysSinceNow: Int) {
		self = CPCDay.today.advanced (by: daysSinceNow);
	}
}
