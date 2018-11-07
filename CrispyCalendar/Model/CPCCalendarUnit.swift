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

/// Protocol containing common interface for CPCDay, CPCWeek, CPCMonth and CPCYear.
public protocol CPCCalendarUnitBase: CustomStringConvertible, CustomDebugStringConvertible, Strideable, Hashable, CPCDateInterval where Stride == Int {
	/// Calendar of the calenar unit.
	var calendar: Calendar { get }
	
	/// Creates a new calendar unit that contains a given date in current time zone according to system calendar.
	///
	/// - Parameters:
	///   - date: Date to perform calculations for.
	init (containing date: Date);
	
	/// Creates a new calendar unit that contains a given date according to system calendar.
	///
	/// - Parameters:
	///   - date: Date to perform calculations for.
	///   - timeZone: Time zone to perform calculations in.
	init (containing date: Date, timeZone: TimeZone);
	
	/// Creates a new calendar unit that contains a given date in current time zone according to calendar with supplied identifier.
	///
	/// - Parameters:
	///   - date: Date to perform calculations for.
	///   - calendarIdentifier: Identifier of calendar to perform calculations with.
	init (containing date: Date, calendarIdentifier: Calendar.Identifier);

	/// Creates a new calendar unit that contains a given date according to supplied calendar.
	///
	/// - Parameters:
	///   - date: Date to perform calculations for.
	///   - calendar: Calendar to perform calculations with.
	init (containing date: Date, calendar: Calendar);

	/// Creates a new calendar unit that contains a given date according to calendar with supplied identifier.
	///
	/// - Parameters:
	///   - date: Date to perform calculations for.
	///   - timeZone: Time zone to perform calculations in.
	///   - calendarIdentifier: Identifier of calendar to perform calculations with.
	init (containing date: Date, timeZone: TimeZone, calendarIdentifier: Calendar.Identifier);

	/// Creates a new calendar unit that contains a given date according to supplied calendar and time zone.
	///
	/// - Parameters:
	///   - date: Date to perform calculations for.
	///   - timeZone: Time zone to perform calculations in.
	///   - calendar: Calendar to perform calculations with.
	init (containing date: Date, timeZone: TimeZone, calendar: Calendar);
	
	/// Creates a new calendar unit that contains a given date according to the calendar of another calendar unit.
	///
	/// - Parameters:
	///   - date: Date to perform calculations for.
	///   - otherUnit: Calendar source.
	init (containing date: Date, calendarOf otherUnit: CPCDay);
	
	/// Creates a new calendar unit that contains a given date according to the calendar of another calendar unit.
	///
	/// - Parameters:
	///   - date: Date to perform calculations for.
	///   - otherUnit: Calendar source.
	init (containing date: Date, calendarOf otherUnit: CPCWeek);
	
	/// Creates a new calendar unit that contains a given date according to the calendar of another calendar unit.
	///
	/// - Parameters:
	///   - date: Date to perform calculations for.
	///   - otherUnit: Calendar source.
	init (containing date: Date, calendarOf otherUnit: CPCMonth);

	/// Creates a new calendar unit that contains a given date according to the calendar of another calendar unit.
	///
	/// - Parameters:
	///   - date: Date to perform calculations for.
	///   - otherUnit: Calendar source.
	init (containing date: Date, calendarOf otherUnit: CPCYear);
}

/// Common protocol implementing most of CPCDay, CPCWeek, CPCMonth and CPCYear functionality.
internal protocol CPCCalendarUnit: CPCCalendarUnitBase {
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

extension CPCCalendarUnitBase {
	public init (containing date: Date, timeZone: TimeZone, calendar: Calendar) {
		var calendar = calendar;
		calendar.timeZone = timeZone;
		self.init (containing: date, calendar: calendar);
	}
	
	public init (containing date: Date, timeZone: TimeZone) {
		self.init (containing: date, timeZone: timeZone, calendar: .currentUsed);
	}
	
	public init (containing date: Date) {
		self.init (containing: date, timeZone: .current);
	}
	
	public init (containing date: Date, timeZone: TimeZone, calendarIdentifier: Calendar.Identifier) {
		var calendar = Calendar (identifier: calendarIdentifier);
		calendar.locale = .currentUsed;
		self.init (containing: date, timeZone: timeZone, calendar: calendar);
	}
	
	public init (containing date: Date, calendarIdentifier: Calendar.Identifier) {
		self.init (containing: date, timeZone: .current, calendarIdentifier: calendarIdentifier);
	}
}

extension CPCCalendarUnit {
	internal typealias CalendarWrapper = CPCCalendarWrapper;
	
	@inlinable
	public var calendar: Calendar {
		return self.calendarWrapper.calendar;
	}
	
	@inlinable
	public var start: Date {
		return self.backingValue.startDate (using: self.calendar);
	}
	
	@inlinable
	public var end: Date {
		return guarantee (self.calendar.date (byAdding: Self.representedUnit, value: 1, to: self.start));
	}
	
	public static func == (lhs: Self, rhs: Self) -> Bool {
		return (lhs.calendarWrapper === rhs.calendarWrapper) && (lhs.backingValue == rhs.backingValue);
	}
	
#if swift(>=4.2)
	public func hash (into hasher: inout Hasher) {
		hasher.combine (self.calendarWrapper);
		hasher.combine (self.backingValue);
	}
#else
	public var hashValue: Int {
		return self.backingValue.hashValue * 7 &+ self.calendarWrapper.hashValue * 11;
	}
#endif
	
	@usableFromInline
	internal init (containing date: Date, calendar: CalendarWrapper) {
		self.init (backedBy: BackingType (containing: date, calendar: calendar.calendar), calendar: calendar);
	}

	public init (containing date: Date, calendarOf otherUnit: CPCDay) {
		self.init (containing: date, calendar: otherUnit.calendarWrapper);
	}
	
	public init (containing date: Date, calendarOf otherUnit: CPCWeek) {
		self.init (containing: date, calendar: otherUnit.calendarWrapper);
	}
	
	public init (containing date: Date, calendarOf otherUnit: CPCMonth) {
		self.init (containing: date, calendar: otherUnit.calendarWrapper);
	}
	
	public init (containing date: Date, calendarOf otherUnit: CPCYear) {
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
		fatalError ("[CrispyCalendar] Sanity check failure: cannot decide on resulting calendar for operation on \(T.self) and \(U.self) values: incompatible calendars \(calendar.calendar, second.calendar)");
	}
	return calendar;
}

// MARK: - Parent protocol conformances.

extension CPCCalendarUnit {
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
		return DateIntervalFormatter.calendarUnitIntervalFormatter (for: Self.self, calendar: self.calendarWrapper);
	}
	
	public var description: String {
		return self.dateIntervalFormatter.string (from: self.start, to: self.start);
	}
	
	public var debugDescription: String {
		let intervalFormatter = self.dateIntervalFormatter, calendar = self.calendar, calendarID = calendar.identifier, locale = calendar.locale ?? .currentUsed;
		return "<\(Self.self): \(intervalFormatter.string (from: self.start, to: self.end)); backing: \(self.backingValue); calendar: \(locale.localizedString (for: calendarID) ?? "\(calendarID)"); locale: \(locale.identifier)>";
	}
}

fileprivate extension DateIntervalFormatter {
	private struct CacheKey: Hashable {
		private let unitType: ObjectIdentifier;
		private unowned let calendar: CPCCalendarWrapper;
		
#if swift(>=4.2)
		public func hash (into hasher: inout Hasher) {
			hasher.combine (self.unitType);
			hasher.combine (self.calendar);
		}
#else
		public var hashValue: Int {
			return self.unitType.hashValue ^ self.calendar.hashValue;
		}
#endif
		
		fileprivate static func == (lhs: CacheKey, rhs: CacheKey) -> Bool {
			return (lhs.unitType == rhs.unitType) && (lhs.calendar === rhs.calendar);
		}
		
		fileprivate init <Unit> (for unitType: Unit.Type, calendar: CPCCalendarWrapper) where Unit: CPCCalendarUnit {
			self.unitType = ObjectIdentifier (unitType);
			self.calendar = calendar;
		}
	}
	
	private static var calendarUnitIntervalFormatters = UnfairThreadsafeStorage ([CacheKey: DateIntervalFormatter] ());
	
	fileprivate static func calendarUnitIntervalFormatter <Unit> (for unitType: Unit.Type, calendar: CPCCalendarWrapper) -> DateIntervalFormatter where Unit: CPCCalendarUnit {
		let key = CacheKey (for: unitType, calendar: calendar);
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

internal extension Locale {
	internal static var currentUsed: Locale {
		return Bundle.main.preferredLocalizations.first.map (Locale.init) ?? .current;
	}
}

internal extension Calendar {
	internal static var currentUsed: Calendar {
		var result = Calendar.current;
		result.locale = .currentUsed;
		return result;
	}
}
