//
//  CPCMonth.swift
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

/// Calendar unit that represents a month.
public struct CPCMonth {	
	public let indices: CountableRange <Int>;
	internal let calendarWrapper: CalendarWrapper;
	internal let backingValue: BackingStorage;	
}

extension CPCMonth: CPCDateInterval {
	public var start: Date { return self.startValue }
	public var end: Date { return self.endValue };
}

extension CPCMonth: CPCCalendarUnitBase {
	public init (containing date: Date, calendar: Calendar) {
		self.init (containing: date, calendar: calendar.wrapped ());
	}
}

extension CPCMonth: CPCCompoundCalendarUnit {
	public typealias Element = CPCWeek;
	internal typealias UnitBackingType = BackingStorage;
	
	internal static let representedUnit = Calendar.Component.month;
	internal static let descriptionDateFormatTemplate = "LLyyyy";
	
	internal static func indices (for value: BackingStorage, using calendar: Calendar) -> CountableRange <Int> {
		return guarantee (calendar.range (of: Element.representedUnit, in: self.representedUnit, for: value.startDate (using: calendar)));
	}

	internal init (backedBy value: BackingStorage, calendar: CalendarWrapper) {
		self.calendarWrapper = calendar;
		self.backingValue = value;
		self.indices = CPCMonth.indices (for: value, using: calendar.calendar);
	}
}

public extension CPCMonth {
	/// Value that represents a current month.
	public static var current: CPCMonth {
		return self.init (containing: Date (), calendar: .currentUsed);
	}
	
	/// Value that represents a next month.
	public static var next: CPCMonth {
		return self.current.next;
	}
	
	/// Value that represents a previous month.
	public static var prev: CPCMonth {
		return self.current.prev;
	}
	
	/// Era of the represented month's year.
	public var era: Int {
		return self.backingValue.era;
	}

	/// Year of represented month.
	public var year: Int {
		return self.backingValue.year;
	}
	
	/// Month number of represented month.
	public var month: Int {
		return self.backingValue.month;
	}
	
	/// Year that contains represented month.
	public var containingYear: CPCYear {
		return CPCYear (backedBy: self.backingValue.containingYear (self.calendarWrapper), calendar: self.calendarWrapper);
	}
	
	/// Create a new value, corresponding to a month in the future or past.
	///
	/// - Parameter monthsSinceNow: Distance from current month in months.
	public init (monthsSinceNow: Int) {
		self = CPCMonth.current.advanced (by: monthsSinceNow);
	}
}
