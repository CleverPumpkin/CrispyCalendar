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

public struct CPCMonth: CPCCompoundCalendarUnit {
	public typealias Element = CPCWeek;
	internal typealias UnitBackingType = MonthBackingValues;
	
	internal static let representedUnit = Calendar.Component.month;
	internal static let requiredComponents: Set <Calendar.Component> = [.month, .year];
	internal static let descriptionDateFormatTemplate = "MMyyyy";

	public let calendar: Calendar;
	public var year: Int {
		return self.backingValue.year;
	}
	public var month: Int {
		return self.backingValue.month;
	}
	
	internal let smallerUnitRange: Range<Int>;
	internal let backingValue: MonthBackingValues;
	
	internal init (backedBy value: MonthBackingValues, calendar: Calendar) {
		self.calendar = calendar;
		self.backingValue = value;
		self.smallerUnitRange = CPCMonth.smallerUnitRange (for: value, using: calendar);
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

extension CPCMonth: CPCCalendarUnitSymbolImpl {
	internal static func unitSymbols (calendar: Calendar, style: CPCCalendarUnitSymbolStyle, standalone: Bool) -> [String] {
		switch (style, standalone) {
		case (.normal, false):
			return calendar.monthSymbols;
		case (.short, false):
			return calendar.shortMonthSymbols;
		case (.veryShort, false):
			return calendar.veryShortMonthSymbols;
		case (.normal, true):
			return calendar.standaloneMonthSymbols;
		case (.short, true):
			return calendar.shortStandaloneMonthSymbols;
		case (.veryShort, true):
			return calendar.veryShortStandaloneMonthSymbols;
		}
	}
	
	internal var unitOrdinalValue: Int {
		return self.month - 1;
	}
}
