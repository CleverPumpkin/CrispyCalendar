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
	@usableFromInline
	internal let calendarWrapper: CalendarWrapper;
	@usableFromInline
	internal let backingValue: BackingStorage;
	@usableFromInline
	internal let indicesCache: ContiguousArray <Int>;

	internal static func indices (for value: BackingStorage, using calendar: Calendar) -> ContiguousArray <Int> {
		return ContiguousArray (sequence (state: CPCMonth (containing: value.startDate (using: calendar), calendar: calendar)) {
			guard $0.year == value.year else {
				return nil;
			}
			let result = $0.month;
			$0 = $0.advanced (by: 1);
			return result;
		});
	}

	internal init (backedBy value: BackingStorage, calendar: CalendarWrapper) {
		self.calendarWrapper = calendar;
		self.backingValue = value;
		self.indicesCache = CPCYear.indices (for: value, using: calendar.calendar);
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

	internal func componentValue (of element: Element) -> Int {
		return abs (element.month);
	}
}

/* public */ extension CPCYear {
	/// Value that represents a current year.
	public static var current: CPCYear {
		return self.current  (using: CalendarWrapper.currentUsed);
	}
	
	/// Value that represents next year.
	public static var next: CPCYear {
		return self.next (using: CalendarWrapper.currentUsed);
	}
	
	/// Value that represents previous year.
	public static var prev: CPCYear {
		return self.prev (using: CalendarWrapper.currentUsed);
	}
	
	/// Era of the represented year.
	public var era: Int {
		return self.backingValue.era;
	}

	/// Number of year represented by this value.
	public var year: Int {
		return self.backingValue.year;
	}
	
	/// Value that represents a current year in the specified calendar.
	///
	/// - Parameter calendar: Calendar to use.
	public static func current (using calendar: Calendar) -> CPCYear {
		return self.current (using: calendar.wrapped ());
	}
	
	/// Value that represents next year in the specified calendar.
	///
	/// - Parameter calendar: Calendar to use.
	public static func next (using calendar: Calendar) -> CPCYear {
		return self.next (using: calendar.wrapped ());
	}

	/// Value that represents previous year in the specified calendar.
	///
	/// - Parameter calendar: Calendar to use.
	public static func prev (using calendar: Calendar) -> CPCYear {
		return self.prev (using: calendar.wrapped ());
	}

	/// Create a new value, corresponding to a year in the future or past.
	///
	/// - Parameter yearsSinceNow: Distance from current year in years.
	public init (yearsSinceNow: Int) {
		self = CPCYear.current.advanced (by: yearsSinceNow);
	}
}

/* internal */ extension CPCYear {
	/// Value that represents a current year in the specified calendar.
	///
	/// - Parameter calendar: Calendar to use.
	internal static func current (using calendar: CalendarWrapper) -> CPCYear {
		return self.cachedCommonUnit (for: .current, calendar: calendar);
	}
	
	/// Value that represents next year in the specified calendar.
	///
	/// - Parameter calendar: Calendar to use.
	internal static func next (using calendar: CalendarWrapper) -> CPCYear {
		return self.cachedCommonUnit (for: .following, calendar: calendar);
	}

	/// Value that represents previous year in the specified calendar.
	///
	/// - Parameter calendar: Calendar to use.
	internal static func prev (using calendar: CalendarWrapper) -> CPCYear {
		return self.cachedCommonUnit (for: .previous, calendar: calendar);
	}
}
