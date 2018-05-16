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

internal protocol CPCCalendarUnit: Strideable, Hashable, CPCDateInterval where Stride == Int {
	associatedtype UnitBackingType where UnitBackingType: CPCCalendarUnitBackingType;
	
	static var representedUnit: Calendar.Component { get };
	static var requiredComponents: Set <Calendar.Component> { get };
	
	var calendar: Calendar { get };
	var backingValue: UnitBackingType { get };
	
	init (backedBy value: UnitBackingType, calendar: Calendar);
}

extension CPCCalendarUnit {
	public var start: Date {
		return self.backingValue.date (using: self.calendar);
	}
	
	public var end: Date {
		return guarantee (self.calendar.date (byAdding: Self.representedUnit, value: 1, to: self.start));
	}
	
	public var hashValue: Int {
		return self.backingValue.hashValue;
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

internal func resultingCalendarForOperation <T, U> (for first: T, _ second: U) -> Calendar where T: CPCCalendarUnit, U: CPCCalendarUnit {
	let calendar = first.calendar;
	guard second.calendar == calendar else {
		fatalError ("Cannot decide on resulting calendar for operation on \(T.self) and \(U.self) values: incompatible calendars \(calendar, second.calendar)");
	}
	return calendar;
}

extension CPCCalendarUnit {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		return lhs.backingValue == rhs.backingValue;
	}
	
	public func distance (to other: Self) -> Int {
		if let cachedResult = self.cachedDistance (to: other) {
			return cachedResult;
		}
		
		let calendar = resultingCalendarForOperation (for: self, other);
		let result = UnitBackingType.getDistanceAs (Self.representedUnit, from: self.backingValue, to: other.backingValue, using: calendar);
		self.cacheDistance (result, to: other);
		return result;
	}
	
	public func advanced (by n: Int) -> Self {
		if let cachedResult = self.cachedAdvancedUnit (by: n) {
			return cachedResult;
		}
		
		let result = Self (backedBy: UnitBackingType.advance (self.backingValue, byAdding: Self.representedUnit, value: n, using: self.calendar), calendar: self.calendar);
		self.cacheUnitValue (result, advancedBy: n);
		return result;
	}
}
