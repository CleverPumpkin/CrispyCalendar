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

// MARK: - Protocol declaration

/// Common protocol implementing most of CPCDay, CPCWeek, CPCMonth and CPCYear functionality.
internal protocol CPCCalendarUnit: CustomStringConvertible, CustomDebugStringConvertible, Strideable, Hashable, CPCDateInterval where Stride == Int {
	/// Type serving as a storage for calendar unit info.
	associatedtype BackingType where BackingType: CPCCalendarUnitBackingType;
	
	/// Calendar unit that is represented by this model type.
	static var representedUnit: Calendar.Component { get };
	/// DateFormatter-compatible string to generate `description`s and `debugDescription`s.
	static var descriptionDateFormatTemplate: String { get };
	
	/// Calendar that is used to calculate unit's `start` an `end` dates and related units.
	var calendar: Calendar { get };
	/// Unit's calendar that is wrapped in `CalendarWrapper` object for performance reasons.
	var calendarWrapper: CalendarWrapper { get };
	/// "Raw" value of calendar unit, e.g. month and year values for `CPCMonth`.
	var backingValue: BackingType { get };
	
	/// Creates a new calendar unit.
	///
	/// - Parameters:
	///   - value: Backing value representing calendar unit.
	///   - calendar: Calendar to perform various calculations with.
	init (backedBy value: BackingType, calendar: CalendarWrapper);
}

// MARK: - Default implementations

extension CPCCalendarUnit {
	public var calendar: Calendar {
		return self.calendarWrapper.calendar;
	}
	
	public var start: Date {
		return self.backingValue.startDate (using: self.calendar);
	}
	
	public var end: Date {
		return guarantee (self.calendar.date (byAdding: Self.representedUnit, value: 1, to: self.start));
	}
	
#if swift(>=4.2)
	public func hash (into hasher: inout Hasher) {
		self.backingValue.hash (into: &hasher);
	}
#else
	public var hashValue: Int {
		return self.backingValue.hashValue;
	}
#endif
	
	/// Creates a new calendar unit that contains a given date according to supplied wrapped calendar.
	///
	/// - Parameters:
	///   - date: Date to perform calculations for.
	///   - calendar: Calendar to perform calculations with.
	internal init (containing date: Date, calendar: CalendarWrapper) {
		self.init (backedBy: BackingType (containing: date, calendar: calendar.calendar), calendar: calendar);
	}

	/// Creates a new calendar unit that contains a given date according to supplied calendar and time zone.
	///
	/// - Parameters:
	///   - date: Date to perform calculations for.
	///   - timeZone: Time zone to perform calculations in.
	///   - calendar: Calendar to perform calculations with.
	public init (containing date: Date, timeZone: TimeZone, calendar: Calendar) {
		var calendar = calendar;
		calendar.timeZone = timeZone;
		self.init (containing: date, calendar: calendar);
	}
	
	/// Creates a new calendar unit that contains a given date according to system calendar.
	///
	/// - Parameters:
	///   - date: Date to perform calculations for.
	///   - timeZone: Time zone to perform calculations in.
	public init (containing date: Date, timeZone: TimeZone = .current) {
		self.init (containing: date, timeZone: timeZone, calendar: .current);
	}
	
	/// Creates a new calendar unit that contains a given date according to calendar with supplied identifier.
	///
	/// - Parameters:
	///   - date: Date to perform calculations for.
	///   - timeZone: Time zone to perform calculations in.
	///   - calendarIdentifier: Identifier of calendar to perform calculations with.
	public init (containing date: Date, timeZone: TimeZone = .current, calendarIdentifier: Calendar.Identifier) {
		var calendar = Calendar (identifier: calendarIdentifier);
		calendar.locale = .current;
		self.init (containing: date, timeZone: timeZone, calendar: calendar);
	}

	/// Creates a new calendar unit that contains a given date according to the calendar of another calendar unit.
	///
	/// - Parameters:
	///   - date: Date to perform calculations for.
	///   - calendar: Calendar to perform calculations with.
	public init <Unit> (containing date: Date, calendarOf otherUnit: Unit) where Unit: CPCCalendarUnit {
		self.init (containing: date, calendar: otherUnit.calendarWrapper);
	}
}

/// Test equivalence of units' calendars and abort if they differ.
///
/// - Parameters:
///   - first: First calendar unit.
///   - second: Second calendar unit.
/// - Returns: Calendar of both of supplied units.
internal func resultingCalendarForOperation <T, U> (for first: T, _ second: U) -> CPCCalendarWrapper where T: CPCCalendarUnit, U: CPCCalendarUnit {
	let calendar = first.calendarWrapper;
	guard second.calendarWrapper == calendar else {
		fatalError ("Cannot decide on resulting calendar for operation on \(T.self) and \(U.self) values: incompatible calendars \(calendar.calendar, second.calendar)");
	}
	return calendar;
}

// MARK: - Parent protocol conformances.

extension CPCCalendarUnit {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		return lhs.backingValue == rhs.backingValue;
	}
	
	public func distance (to other: Self) -> Int {
		if let cachedResult = self.cachedDistance (to: other) {
			return cachedResult;
		}
		
		let calendar = resultingCalendarForOperation (for: self, other);
		let result = self.backingValue.distance (to: other.backingValue, using: calendar.calendar);
		self.cacheDistance (result, to: other);
		return result;
	}
	
	public func advanced (by n: Int) -> Self {
		if let cachedResult = self.cachedAdvancedUnit (by: n) {
			return cachedResult;
		}
		
		let result = Self (backedBy: self.backingValue.advanced (by: n, using: self.calendar), calendar: self.calendarWrapper);
		self.cacheUnitValue (result, advancedBy: n);
		return result;
	}
}

extension CPCCalendarUnit {
	private var dateIntervalFormatter: DateIntervalFormatter {
		let result = DateIntervalFormatter.calendarUnitIntervalFormatter (for: Self.self).copy () as! DateIntervalFormatter;
		result.calendar = self.calendar;
		return result;
	}
	
	public var description: String {
		let intervalFormatter = self.dateIntervalFormatter;
		return "<\(Self.self): \(intervalFormatter.string (from: self.start, to: self.end))>";
	}
	
	public var debugDescription: String {
		let intervalFormatter = self.dateIntervalFormatter, calendar = self.calendar, calendarID = calendar.identifier, locale = calendar.locale ?? .current;
		return "<\(Self.self): \(intervalFormatter.string (from: self.start, to: self.end)); backing: \(self.backingValue); calendar: \(locale.localizedString (for: calendarID) ?? "\(calendarID)"); locale: \(locale.identifier)>";
	}
}

fileprivate extension DateIntervalFormatter {
	private static var calendarUnitIntervalFormatters = UnfairThreadsafeStorage ([ObjectIdentifier: DateIntervalFormatter] ());
	
	fileprivate static func calendarUnitIntervalFormatter <Unit> (for unitType: Unit.Type = Unit.self) -> DateIntervalFormatter where Unit: CPCCalendarUnit {
		let key = ObjectIdentifier (unitType);
		return self.calendarUnitIntervalFormatters.withMutableStoredValue {
			if let storedValue = $0 [key] {
				return storedValue;
			}
			
			let formatter = DateIntervalFormatter ();
			formatter.dateTemplate = Unit.descriptionDateFormatTemplate;
			$0 [key] = formatter;
			return formatter;
		};
	}
}
