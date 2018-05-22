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

/// Calendar unit that repsesents a year.
public struct CPCYear: CPCCompoundCalendarUnit {
	public typealias Element = CPCMonth;
	internal typealias UnitBackingType = BackingStorage;
	
	internal struct BackingStorage: Hashable {
		internal let year: Int;
	}
	internal static let representedUnit = Calendar.Component.year;
	internal static let descriptionDateFormatTemplate = "yyyy";

	/// Number of year represented by this value.
	public var year: Int {
		return self.backingValue.year;
	}
	public let indices: CountableRange <Int>;

	internal let calendarWrapper: CalendarWrapper;
	internal let backingValue: BackingStorage;
	
	internal init (backedBy value: BackingStorage, calendar: CalendarWrapper) {
		self.calendarWrapper = calendar;
		self.backingValue = value;
		self.indices = CPCYear.indices (for: value, using: calendar.calendar);
	}
}

extension CPCYear.BackingStorage: ExpressibleByDateComponents {
	internal static let requiredComponents: Set <Calendar.Component> = [.year];

	internal init (_ dateComponents: DateComponents) {
		self.year = guarantee (dateComponents.year);
	}
}

extension CPCYear.BackingStorage: DateComponentsConvertible {
	internal func dateComponents (_ calendar: Calendar) -> DateComponents {
		return DateComponents (calendar: calendar, year: self.year);
	}
}

extension CPCYear.BackingStorage: CPCCalendarUnitBackingType {
	internal typealias BackedType = CPCYear;
}

public extension CPCYear {
	/// Value that represents a current year.
	public static var current: CPCYear {
		return self.init (containing: Date (), calendar: .current);
	}
	
	/// Value that represents next year.
	public static var next: CPCYear {
		return self.current.next;
	}
	
	/// Value that represents previous year.
	public static var prev: CPCYear {
		return self.current.prev;
	}
	
	/// Create a new value, corresponding to a year in the future or past.
	///
	/// - Parameter yearsSinceNow: Distance from current year in years.
	public init (yearsSinceNow: Int) {
		self = CPCYear.current.advanced (by: yearsSinceNow);
	}
}
