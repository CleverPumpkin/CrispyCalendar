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
	@usableFromInline
	internal let calendarWrapper: CalendarWrapper;
	@usableFromInline
	internal let backingValue: BackingStorage;
	@usableFromInline
	internal let indicesCache: ContiguousArray <Int>;
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
	
	internal static func indices (for value: BackingStorage, using calendar: Calendar) -> ContiguousArray <Int> {
		return ContiguousArray (guarantee (calendar.range (of: Element.representedUnit, in: self.representedUnit, for: value.startDate (using: calendar))));
	}

	internal init (backedBy value: BackingStorage, calendar: CalendarWrapper) {
		self.calendarWrapper = calendar;
		self.backingValue = value;
		self.indicesCache = CPCMonth.indices (for: value, using: calendar.calendar);
	}

	internal func componentValue (of element: Element) -> Int {
		return element.weekNumber;
	}
}

public extension CPCMonth {
	/// Value that represents a current month.
	public static var current: CPCMonth {
		return self.current (using: CalendarWrapper.currentUsed);
	}
	
	/// Value that represents a next month.
	public static var next: CPCMonth {
		return self.next (using: CalendarWrapper.currentUsed);
	}
	
	/// Value that represents a previous month.
	public static var prev: CPCMonth {
		return self.prev (using: CalendarWrapper.currentUsed);
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
	
	/// Value that represents a current month in the specified calendar.
	///
	/// - Parameter calendar: Calendar to use.
	public static func current (using calendar: Calendar) -> CPCMonth {
		return self.current (using: calendar.wrapped ());
	}
	
	/// Value that represents next month in the specified calendar.
	///
	/// - Parameter calendar: Calendar to use.
	public static func next (using calendar: Calendar) -> CPCMonth {
		return self.next (using: calendar.wrapped ());
	}
	
	/// Value that represents previous month in the specified calendar.
	///
	/// - Parameter calendar: Calendar to use.
	public static func prev (using calendar: Calendar) -> CPCMonth {
		return self.prev (using: calendar.wrapped ());
	}
	
	/// Create a new value, corresponding to a month in the future or past.
	///
	/// - Parameter monthsSinceNow: Distance from current month in months.
	public init (monthsSinceNow: Int) {
		self = CPCMonth.current.advanced (by: monthsSinceNow);
	}
}

internal extension CPCMonth {
	/// Value that represents a current month in the specified calendar.
	///
	/// - Parameter calendar: Calendar to use.
	internal static func current (using calendar: CalendarWrapper) -> CPCMonth {
		return self.cachedCommonUnit (for: .current, calendar: calendar);
	}
	
	/// Value that represents next month in the specified calendar.
	///
	/// - Parameter calendar: Calendar to use.
	internal static func next (using calendar: CalendarWrapper) -> CPCMonth {
		return self.cachedCommonUnit (for: .following, calendar: calendar);
	}
	
	/// Value that represents previous month in the specified calendar.
	///
	/// - Parameter calendar: Calendar to use.
	internal static func prev (using calendar: CalendarWrapper) -> CPCMonth {
		return self.cachedCommonUnit (for: .previous, calendar: calendar);
	}
}
