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

public struct CPCYear: CPCCalendarUnit {
	internal typealias UnitBackingType = Int;
	
	internal static let representedUnit = Calendar.Component.year;
	internal static let requiredComponents: Set <Calendar.Component> = [.year];
	
	public let calendar: Calendar;
	public let year: Int;
	private let monthsRange: Range <Int>;
	
	internal var backingValue: Int {
		return self.year;
	}
	
	internal init (backedBy value: Int, calendar: Calendar) {
		self.calendar = calendar;
		self.year = value;
		self.monthsRange = guarantee (calendar.range (of: .month, in: .year, for: value.date (using: calendar)));
	}
}

public extension CPCYear {
	public static var current: CPCYear {
		return self.init (containing: Date (), calendar: .current);
	}
	
	public static var next: CPCYear {
		return self.current.next;
	}
	
	public static var prev: CPCYear {
		return self.current.prev;
	}
	
	public init (yearsSinceNow: Int) {
		self = CPCYear.current.advanced (by: yearsSinceNow);
	}
}

extension CPCYear: Collection {
	public typealias Element = CPCMonth;
	public typealias Index = Int;
	
	public var startIndex: Int {
		return self.monthsRange.lowerBound
	}
	
	public var endIndex: Int {
		return self.monthsRange.upperBound
	}
	
	public func index (after i: Int) -> Int {
		return i + 1;
	}
	
	public subscript (position: Int) -> CPCMonth {
		return CPCMonth (containing: self.startDate, calendar: self.calendar).advanced (by: position - self.monthsRange.lowerBound);
	}
}
