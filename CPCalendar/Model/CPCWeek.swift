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

/// Calendar unit that repsesents a week.
public struct CPCWeek: CPCCompoundCalendarUnit {
	public typealias Element = CPCDay;
	internal typealias UnitBackingType = BackingStorage;
	
	internal struct BackingStorage: Hashable {
		fileprivate let date: Date;
		
		fileprivate init (_ date: Date) {
			self.date = date;
		}
	}

	internal static let representedUnit = Calendar.Component.weekOfYear;
	internal static let descriptionDateFormatTemplate = "wddMM";

	public let indices: CountableRange <Int>;

	public var startDate: Date {
		return self.backingValue.date;
	}
	
	internal let backingValue: UnitBackingType;
	internal let calendarWrapper: CalendarWrapper;
	
	internal static func indices (for value: BackingStorage, using calendar: Calendar) -> Range <Int> {
		return guarantee (calendar.range (of: .weekday, in: self.representedUnit, for: value.date));
	}

	internal init (backedBy value: UnitBackingType, calendar: CalendarWrapper) {
		self.calendarWrapper = calendar;
		self.backingValue = value;
		self.indices = CPCWeek.indices (for: value, using: calendar.calendar);
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
	
public extension CPCWeek {
	/// Value that represents a current week.
	public static var current: CPCWeek {
		return self.init (containing: Date (), calendar: .current);
	}
	
	/// Value that represents next week.
	public static var next: CPCWeek {
		return self.current.next;
	}
	
	/// Value that represents previous week.
	public static var prev: CPCWeek {
		return self.current.prev;
	}
	
	/// Create a new value, corresponding to a week in the future or past.
	///
	/// - Parameter weeksSinceNow: Distance from current week in weeks.
	public init (weeksSinceNow: Int) {
		self = CPCWeek.current.advanced (by: weeksSinceNow);
	}
}
