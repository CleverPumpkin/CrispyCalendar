//
//  CPCCalendarUnitBackingType.swift
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

internal protocol CPCCalendarUnitBackingType: Hashable {
	static func getDistanceAs (_ component: Calendar.Component, from: Self, to: Self, using calendar: Calendar) -> Int;
	static func advance (_ backingValue: Self, byAdding component: Calendar.Component, value: Int, using calendar: Calendar) -> Self;
	
	init (date: Date, calendar: Calendar, components: Set <Calendar.Component>);
	func date (using calendar: Calendar) -> Date;
}

extension Date: CPCCalendarUnitBackingType {
	internal static func getDistanceAs (_ component: Calendar.Component, from: Date, to: Date, using calendar: Calendar) -> Int {
		return guarantee (calendar.dateComponents ([component], from: from, to: to).value (for: component));
	}
	
	internal static func advance (_ backingValue: Date, byAdding component: Calendar.Component, value: Int, using calendar: Calendar) -> Date {
		return guarantee (calendar.date (byAdding: component, value: value, to: backingValue));
	}
	
	internal init (date: Date, calendar: Calendar, components: Set <Calendar.Component>) {
		self = date;
	}
	
	internal func date (using calendar: Calendar) -> Date {
		return self;
	}
}

extension Int: CPCCalendarUnitBackingType {
	internal static func getDistanceAs (_ component: Calendar.Component, from: Int, to: Int, using calendar: Calendar) -> Int {
		return to - from;
	}
	
	internal static func advance (_ backingValue: Int, byAdding component: Calendar.Component, value: Int, using calendar: Calendar) -> Int {
		return backingValue + value;
	}

	internal init (date: Date, calendar: Calendar, components: Set <Calendar.Component>) {
		self = calendar.component (guarantee (components.first), from: date);
	}
	
	internal func date (using calendar: Calendar) -> Date {
		return guarantee (DateComponents (calendar: calendar, year: self).date);
	}
}

fileprivate extension DateComponents {
	fileprivate var dayBackingValues: DayBackingValues {
		return DayBackingValues (year: guarantee (self.year), month: guarantee (self.month), day: guarantee (self.day));
	}
	
	fileprivate var monthBackingValues: MonthBackingValues {
		return MonthBackingValues (year: guarantee (self.year), month: guarantee (self.month));
	}
	
	fileprivate init (_ dayBackingValues: DayBackingValues, calendar: Calendar) {
		self.init (calendar: calendar, year: dayBackingValues.year, month: dayBackingValues.month, day: dayBackingValues.day);
	}
	
	fileprivate init (_ monthBackingValues: MonthBackingValues, calendar: Calendar) {
		self.init (calendar: calendar, year: monthBackingValues.year, month: monthBackingValues.month);
	}
}

internal struct DayBackingValues: Equatable {
	internal let year: Int;
	internal let month: Int;
	internal let day: Int;
}

extension DayBackingValues: CPCCalendarUnitBackingType {
	public var hashValue: Int {
		return hashIntegers (self.day, self.month, self.year);
	}
	
	static func getDistanceAs (_ component: Calendar.Component, from: DayBackingValues, to: DayBackingValues, using calendar: Calendar) -> Int {
		let fromComps = DateComponents (from, calendar: calendar), toComps = DateComponents (to, calendar: calendar);
		return guarantee (calendar.dateComponents ([component], from: fromComps, to: toComps).value (for: component));
	}
	
	static func advance (_ backingValue: DayBackingValues, byAdding component: Calendar.Component, value: Int, using calendar: Calendar) -> DayBackingValues {
		var denormalizedComps = DateComponents (backingValue, calendar: calendar);
		denormalizedComps.setValue (guarantee (denormalizedComps.value (for: component)) + value, for: component);
		return calendar.dateComponents (CPCDay.requiredComponents, from: guarantee (denormalizedComps.date)).dayBackingValues;
	}
	
	internal init (date: Date, calendar: Calendar, components: Set <Calendar.Component>) {
		self = calendar.dateComponents (components, from: date).dayBackingValues;
	}
	
	internal func date (using calendar: Calendar) -> Date {
		return guarantee (DateComponents (self, calendar: calendar).date);
	}
}

internal struct MonthBackingValues: Equatable {
	internal let year: Int;
	internal let month: Int;
}

extension MonthBackingValues: CPCCalendarUnitBackingType {
	public var hashValue: Int {
		return hashIntegers (self.month, self.year);
	}
	
	static func getDistanceAs (_ component: Calendar.Component, from: MonthBackingValues, to: MonthBackingValues, using calendar: Calendar) -> Int {
		let fromComps = DateComponents (from, calendar: calendar), toComps = DateComponents (to, calendar: calendar);
		return guarantee (calendar.dateComponents ([component], from: fromComps, to: toComps).value (for: component));
	}
	
	static func advance (_ backingValue: MonthBackingValues, byAdding component: Calendar.Component, value: Int, using calendar: Calendar) -> MonthBackingValues {
		var denormalizedComps = DateComponents (backingValue, calendar: calendar);
		denormalizedComps.setValue (guarantee (denormalizedComps.value (for: component)) + value, for: component);
		return calendar.dateComponents (CPCMonth.requiredComponents, from: guarantee (denormalizedComps.date)).monthBackingValues;
	}
	
	internal init (date: Date, calendar: Calendar, components: Set <Calendar.Component>) {
		self = calendar.dateComponents (components, from: date).monthBackingValues;
	}
	
	internal func date (using calendar: Calendar) -> Date {
		return guarantee (DateComponents (self, calendar: calendar).date);
	}
}
