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

public struct CPCMonth: CPCCalendarUnit {
	internal typealias UnitBackingType = [Calendar.Component: Int];
	
	internal static let representedUnit = Calendar.Component.month;
	internal static let requiredComponents: Set <Calendar.Component> = [.month, .year];
	
	public let calendar: Calendar;
	public let year: Int;
	public let month: Int;
	private let weeksRange: Range <Int>;

	internal var backingValue: [Calendar.Component: Int] {
		return [
			.year: self.year,
			.month: self.month,
		];
	}
	
	internal init (backedBy value: [Calendar.Component: Int], calendar: Calendar) {
		self.calendar = calendar;
		self.year = guarantee (value [.year]);
		self.month = guarantee (value [.month]);
		self.weeksRange = guarantee (calendar.range (of: .weekOfYear, in: .month, for: value.date (using: calendar)));
	}
}

public extension CPCMonth {
	public static var current: CPCMonth {
		return self.init (containing: Date (), calendar: .current);
	}
	
	public static var next: CPCMonth {
		return self.current.next;
	}
	
	public static var prev: CPCMonth {
		return self.current.prev;
	}
	
	public init (monthsSinceNow: Int) {
		self = CPCMonth.current.advanced (by: monthsSinceNow);
	}
}

extension CPCMonth: Collection {
	public typealias Element = CPCWeek;
	public typealias Index = Int;

	public var startIndex: Int {
		return self.weeksRange.lowerBound
	}
	
	public var endIndex: Index {
		return self.weeksRange.upperBound
	}

	public func index (after i: Int) -> Int {
		return i + 1
	}

	public subscript (position: Int) -> CPCWeek {
		return CPCWeek (containing: self.startDate, calendar: self.calendar).advanced (by: position - self.weeksRange.lowerBound);
	}
}
