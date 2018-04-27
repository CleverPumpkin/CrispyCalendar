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
		calendar.locale = .current;
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

