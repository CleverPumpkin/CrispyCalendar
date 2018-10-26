//
//  CPCYear.swift
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

/// Calendar unit that represents a year.
public struct CPCYear {
	public let indices: CountableRange <Int>;

	internal let calendarWrapper: CalendarWrapper;
	internal let backingValue: BackingStorage;
	
	internal static func indices (for value: BackingStorage, using calendar: Calendar) -> CountableRange <Int> {
		if (calendar.identifier == .chinese) {
			// Chinese calendar is fucking special and does not admit having a leap month in a year (range (of:in:for:) always returns 12),
			// but difference in months between year start and year end is calculated correctly
			let startDate = value.startDate (using: calendar), endDate = guarantee (calendar.date (byAdding: .year, value: 1, to: startDate));
			let firstMonthIndex = CPCMonth.BackingStorage (containing: startDate, calendar: calendar).month;
			let monthsCount = guarantee (calendar.dateComponents ([.month], from: startDate, to: endDate).month);
			return firstMonthIndex ..< (firstMonthIndex + monthsCount);
		} else {
			return guarantee (calendar.range (of: Element.representedUnit, in: self.representedUnit, for: value.startDate (using: calendar)));
		}
	}

	internal init (backedBy value: BackingStorage, calendar: CalendarWrapper) {
		self.calendarWrapper = calendar;
		self.backingValue = value;
		self.indices = CPCYear.indices (for: value, using: calendar.calendar);
	}
}

extension CPCYear: CPCCalendarUnitBase {
	public init (containing date: Date, calendar: Calendar) {
		self.init (containing: date, calendar: calendar.wrapped ());
	}
}

extension CPCYear: CPCCompoundCalendarUnit {
	public typealias Element = CPCMonth;
	internal typealias UnitBackingType = BackingStorage;
	
	internal static let representedUnit = Calendar.Component.year;
	internal static let descriptionDateFormatTemplate = "yyyy";
}

public extension CPCYear {
	/// Value that represents a current year.
	public static var current: CPCYear {
		return self.init (containing: Date (), calendar: .currentUsed);
	}
	
	/// Value that represents next year.
	public static var next: CPCYear {
		return self.current.next;
	}
	
	/// Value that represents previous year.
	public static var prev: CPCYear {
		return self.current.prev;
	}
	
	/// Era of the represented year.
	public var era: Int {
		return self.backingValue.era;
	}

	/// Number of year represented by this value.
	public var year: Int {
		return self.backingValue.year;
	}

	/// Create a new value, corresponding to a year in the future or past.
	///
	/// - Parameter yearsSinceNow: Distance from current year in years.
	public init (yearsSinceNow: Int) {
		self = CPCYear.current.advanced (by: yearsSinceNow);
	}
}
