//
//  CPCCalendarUnit.swift
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

internal protocol CPCCalendarUnitBackingType {
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

extension Dictionary: CPCCalendarUnitBackingType where Key == Calendar.Component, Value == Int {
	private func dateComponents (for calendar: Calendar) -> DateComponents {
		var result = DateComponents ();
		result.calendar = calendar;
		for (unit, value) in self {
			result.setValue (value, for: unit);
		}
		return result;
	}
	
	internal static func getDistanceAs (_ component: Calendar.Component, from: Dictionary, to: Dictionary, using calendar: Calendar) -> Int {
		let fromComponents = from.dateComponents (for: calendar), toComponents = to.dateComponents (for: calendar);
		return guarantee (calendar.dateComponents ([component], from: fromComponents, to: toComponents).value (for: component));
	}
	
	internal static func advance (_ backingValue: Dictionary, byAdding component: Calendar.Component, value: Int, using calendar: Calendar) -> Dictionary {
		var advancedValue = backingValue;
		advancedValue [component] = guarantee (backingValue [component]) + value;
		
		let advancedDate = guarantee (advancedValue.dateComponents (for: calendar).date);
		return Dictionary (date: advancedDate, calendar: calendar, components: Set (backingValue.keys));
	}
	
	internal init (date: Date, calendar: Calendar, components: Set <Calendar.Component>) {
		let advancedDateComponents = calendar.dateComponents (components, from: date);
		self.init (uniqueKeysWithValues: components.map { ($0, guarantee (advancedDateComponents.value (for: $0))) });
	}
	
	internal func date (using calendar: Calendar) -> Date {
		return guarantee (self.dateComponents (for: calendar).date);
	}
}

internal protocol CPCCalendarUnit: CPCDatesRange {
	associatedtype UnitBackingType where UnitBackingType: CPCCalendarUnitBackingType;
	
	static var representedUnit: Calendar.Component { get };
	static var requiredComponents: Set <Calendar.Component> { get };
	
	var calendar: Calendar { get };
	var backingValue: UnitBackingType { get };
	
	init (backedBy value: UnitBackingType, calendar: Calendar);
}

extension CPCCalendarUnit {
	public var startDate: Date {
		return self.backingValue.date (using: self.calendar);
	}
	
	public var endDate: Date {
		return guarantee (self.calendar.date (byAdding: Self.representedUnit, value: 1, to: self.startDate));
	}
	
	public init (containing date: Date, calendar: Calendar) {
		let startDate = guarantee (calendar.dateInterval (of: Self.representedUnit, for: date)).start;
		let backingValue = UnitBackingType (date: startDate, calendar: calendar, components: Self.requiredComponents);
		self.init (backedBy: backingValue, calendar: calendar);
	}

	public init (containing date: Date, timeZone: TimeZone, calendar: Calendar) {
		var calendar = calendar;
		calendar.timeZone = timeZone;
		self.init (containing: date, calendar: calendar);
	}
	
	public init (containing date: Date, timeZone: TimeZone = .current) {
		var calendar = Calendar.current;
		calendar.timeZone = timeZone;
		self.init (containing: date, calendar: calendar);
	}
	
	public init (containing date: Date, timeZone: TimeZone = .current, calendarIdentifier: Calendar.Identifier) {
		var calendar = Calendar (identifier: calendarIdentifier);
		calendar.timeZone = timeZone;
		self.init (containing: date, calendar: calendar);
	}
}

extension CPCCalendarUnit {
	private static func resultingCalendarForOperation (on firstValue: Self, _ otherValues: Self...) -> Calendar {
		let calendar = firstValue.calendar;
		guard !otherValues.contains (where: { $0.calendar != calendar }) else {
			let calendars = Set (([firstValue] + otherValues).map { $0.calendar }).sorted { "\($0.identifier)" < "\($1.identifier)"};
			fatalError ("Cannot decide on resulting calendar for operation on \(Self.self) values: incompatible calendars \(calendars)");
		}
		return calendar;
	}
	
	public func distance (to other: Self) -> Int {
		let calendar = Self.resultingCalendarForOperation (on: self, other);
		return UnitBackingType.getDistanceAs (Self.representedUnit, from: self.backingValue, to: other.backingValue, using: calendar);
	}
	
	public func advanced (by n: Int) -> Self {
		return Self (backedBy: UnitBackingType.advance (self.backingValue, byAdding: Self.representedUnit, value: n, using: self.calendar), calendar: self.calendar);
	}
}
