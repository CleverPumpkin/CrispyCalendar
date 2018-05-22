//
//  CPCDay.swift
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

/// Calendar unit that repsesents a single day.
public struct CPCDay: CPCCalendarUnit {
	internal typealias UnitBackingType = BackingStorage;
	
	internal struct BackingStorage: Hashable {
		internal let day: Int;
		
		internal var month: Int {
			return self.monthValues.month;
		}
		internal var year: Int {
			return self.monthValues.year;
		}
		
		internal func containingYear (_ calendar: CalendarWrapper) -> CPCYear {
			return self.monthValues.containingYear (calendar);
		}

		internal func containingMonth (_ calendar: CalendarWrapper) -> CPCMonth {
			return CPCMonth (backedBy: self.monthValues, calendar: calendar);
		}

		fileprivate let monthValues: CPCMonth.BackingStorage;
	}
	
	internal static let representedUnit = Calendar.Component.day;
	internal static let requiredComponents: Set <Calendar.Component> = [.day, .month, .year];
	internal static let descriptionDateFormatTemplate = "ddMMyyyy";
	
	/// Year of represented day.
	public var year: Int {
		return self.backingValue.year;
	}
	/// Month of represented day.
	public var month: Int {
		return self.backingValue.month;
	}
	/// Week number of represented day.
	public var week: Int {
		return self.calendar.component (.weekOfYear, from: self.start);
	}
	/// This day's number.
	public var day: Int {
		return self.backingValue.day;
	}
	/// Year that contains represented day.
	public var containingYear: CPCYear {
		return self.backingValue.containingYear (self.calendarWrapper);
	}
	/// Month that contains represented day.
	public var containingMonth: CPCMonth {
		return self.backingValue.containingMonth (self.calendarWrapper);
	}
	/// Week that contains represented day.
	public var containingWeek: CPCWeek {
		return CPCWeek (containing: self.start, calendar: self.calendarWrapper);
	}

	internal let calendarWrapper: CalendarWrapper;
	internal let backingValue: BackingStorage;

	internal init (backedBy value: BackingStorage, calendar: CalendarWrapper) {
		self.calendarWrapper = calendar;
		self.backingValue = value;
	}
}

extension CPCDay.BackingStorage: ExpressibleByDateComponents {
	internal static let requiredComponents: Set <Calendar.Component> = CPCMonth.BackingStorage.requiredComponents.union (.day);

	internal init (_ dateComponents: DateComponents) {
		self.monthValues = CPCMonth.BackingStorage (dateComponents);
		self.day = guarantee (dateComponents.day);
	}
}

extension CPCDay.BackingStorage: DateComponentsConvertible {
	internal func dateComponents (_ calendar: Calendar) -> DateComponents {
		var components = self.monthValues.dateComponents (calendar);
		components.day = self.day;
		return components;
	}
}

extension CPCDay.BackingStorage: CPCCalendarUnitBackingType {
	internal typealias BackedType = CPCDay;
}

public extension CPCDay {
	/// Value that represents a current day.
	public static var today: CPCDay {
		return CPCDay (containing: Date (), calendar: .current);
	}
	
	/// Value that represents yesterday.
	public static var yesterday: CPCDay {
		return self.today.next;
	}
	
	/// Value that represents tomorrow.
	public static var tommorow: CPCDay {
		return self.today.prev;
	}
	
	/// Day of week for represented day.
	public var weekday: Int {
		return guarantee (self.containingWeek.index (of: self));
	}
	
	/// Indicates whether represented day belongs to weekend.
	public var isWeekend: Bool {
		return self.calendar.isDateInWeekend (self.start);
	}

	/// Create a new value, corresponding to a day in the future or past.
	///
	/// - Parameter daysSinceNow: Distance from today in days.
	public init (daysSinceNow: Int) {
		self = CPCDay.today.advanced (by: daysSinceNow);
	}
}

public extension CPCDay {
	private static let dateFormatter: DateFormatter = {
		let result = DateFormatter ();
		result.setLocalizedDateFormatFromTemplate (CPCDay.descriptionDateFormatTemplate);
		return result;
	} ();
	
	private var dateFormatter: DateFormatter {
		let result = CPCDay.dateFormatter.copy () as! DateFormatter;
		result.calendar = self.calendar;
		return result;
	}
	
	public var description: String {
		return "<\(CPCDay.self): \(self.dateFormatter.string (from: self.start))>";
	}
}
