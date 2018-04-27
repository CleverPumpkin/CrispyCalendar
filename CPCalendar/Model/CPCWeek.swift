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

public struct CPCWeek: CPCCalendarUnit {
	internal typealias UnitBackingType = Date;
	
	internal static let representedUnit = Calendar.Component.weekOfYear;
	internal static let requiredComponents: Set <Calendar.Component> = [.weekOfYear, .year];
	
	public let calendar: Calendar;
	public let startDate: Date;
	
	internal var backingValue: Date {
		return self.startDate;
	}
	
	private let weekdaysRange: Range <Int>;

	internal init (backedBy value: Date, calendar: Calendar) {
		self.calendar = calendar;
		self.startDate = value;
		self.weekdaysRange = guarantee (calendar.range (of: .weekday, in: .weekOfYear, for: value));
	}
}
	
public extension CPCWeek {
	public static var current: CPCWeek {
		return self.init (containing: Date (), calendar: .current);
	}
	
	public static var next: CPCWeek {
		return self.current.next;
	}
	
	public static var prev: CPCWeek {
		return self.current.prev;
	}
	
	public init (weeksSinceNow: Int) {
		self = CPCWeek.current.advanced (by: weeksSinceNow);
	}
}

extension CPCWeek: Collection {
	public typealias Element = CPCDay;
	public typealias Index = Int;
	
	public var startIndex: Int {
		return self.weekdaysRange.lowerBound;
	}
	
	public var endIndex: Int {
		return self.weekdaysRange.upperBound;
	}

	public func index (after i: Int) -> Int {
		return i + 1;
	}

	public subscript (position: Int) -> CPCDay {
		return CPCDay (containing: self.startDate, calendar: self.calendar).advanced (by: position - self.weekdaysRange.lowerBound);
	}
}
