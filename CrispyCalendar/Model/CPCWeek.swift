//
//  CPCWeek.swift
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

/// Calendar unit that represents a week.
public struct CPCWeek {
	internal struct BackingStorage: Hashable {
		fileprivate let date: Date;
		
		fileprivate init (_ date: Date) {
			self.date = date;
		}
	}

	@usableFromInline
	internal let backingValue: UnitBackingType;
	@usableFromInline
	internal let calendarWrapper: CalendarWrapper;
	@usableFromInline
	internal let indicesCache: ContiguousArray <Int>;

	internal init (backedBy value: UnitBackingType, calendar: CalendarWrapper) {
		self.calendarWrapper = calendar;
		self.backingValue = value;
		self.indicesCache = CPCWeek.indices (for: value, using: calendar.calendar);
	}
}

extension CPCWeek: CPCCalendarUnitBase {
	public init (containing date: Date, calendar: Calendar) {
		self.init (containing: date, calendar: calendar.wrapped ());
	}
}

extension CPCWeek: CPCCompoundCalendarUnit {
	public typealias Element = CPCDay;
	internal typealias UnitBackingType = BackingStorage;
	
	internal static let representedUnit = Calendar.Component.weekOfYear;
	internal static let descriptionDateFormatTemplate = "wddMMyyyy";
	
	internal static func indices (for value: BackingStorage, using calendar: Calendar) -> ContiguousArray <Int> {
		return ContiguousArray (guarantee (calendar.range (of: .weekday, in: self.representedUnit, for: value.date)));
	}

	internal func componentValue (of element: Element) -> Int {
		return element.weekday.weekday;
	}
}

extension CPCWeek.BackingStorage: CPCCalendarUnitBackingType {
	internal typealias BackedType = CPCWeek;
	
	internal init (containing date: Date, calendar: Calendar) {
		self.init (guarantee (calendar.dateInterval (of: .weekOfYear, for: date)).start);
	}
	
	internal func startDate (using calendar: Calendar) -> Date {
		return self.date;
	}
	
	internal func distance (to other: CPCWeek.BackingStorage, using calendar: Calendar) -> Int {
		return guarantee (calendar.dateComponents ([.weekOfYear], from: self.date, to: other.date).value (for: .weekOfYear));
	}
	
	internal func advanced (by value: Int, using calendar: Calendar) -> CPCWeek.BackingStorage {
		guard (value != 0) else {
			return self;
		}

		return CPCWeek.BackingStorage (guarantee (calendar.date (byAdding: .weekOfYear, value: value, to: self.date)));
	}
}
	
/* public */ extension CPCWeek {
	/// Value that represents a current week.
	public static var current: CPCWeek {
		return self.current (using: CalendarWrapper.currentUsed);
	}
	
	/// Value that represents next week.
	public static var next: CPCWeek {
		return self.next (using: CalendarWrapper.currentUsed);
	}
	
	/// Value that represents previous week.
	public static var prev: CPCWeek {
		return self.prev (using: CalendarWrapper.currentUsed);
	}
	
	/// Week number in the year.
	public var weekNumber: Int {
		return self.calendar.component (.weekOfYear, from: self.backingValue.date);
	}
	
	/// Value that represents a current week in the specified calendar.
	///
	/// - Parameter calendar: Calendar to use.
	public static func current (using calendar: Calendar) -> CPCWeek {
		return self.current (using: calendar.wrapped ());
	}
	
	/// Value that represents next week in the specified calendar.
	///
	/// - Parameter calendar: Calendar to use.
	public static func next (using calendar: Calendar) -> CPCWeek {
		return self.next (using: calendar.wrapped ());
	}
	
	/// Value that represents previous week in the specified calendar.
	///
	/// - Parameter calendar: Calendar to use.
	public static func prev (using calendar: Calendar) -> CPCWeek {
		return self.prev (using: calendar.wrapped ());
	}
	
	/// Create a new value, corresponding to a week in the future or past.
	///
	/// - Parameter weeksSinceNow: Distance from current week in weeks.
	public init (weeksSinceNow: Int) {
		self = CPCWeek.current.advanced (by: weeksSinceNow);
	}
}

/* internal */ extension CPCWeek {
	/// Value that represents a current week in the specified calendar.
	///
	/// - Parameter calendar: Calendar to use.
	internal static func current (using calendar: CalendarWrapper) -> CPCWeek {
		return self.cachedCommonUnit (for: .current, calendar: calendar);
	}
	
	/// Value that represents next week in the specified calendar.
	///
	/// - Parameter calendar: Calendar to use.
	internal static func next (using calendar: CalendarWrapper) -> CPCWeek {
		return self.cachedCommonUnit (for: .following, calendar: calendar);
	}
	
	/// Value that represents previous week in the specified calendar.
	///
	/// - Parameter calendar: Calendar to use.
	internal static func prev (using calendar: CalendarWrapper) -> CPCWeek {
		return self.cachedCommonUnit (for: .previous, calendar: calendar);
	}
}
