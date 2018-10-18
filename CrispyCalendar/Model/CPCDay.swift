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

fileprivate extension Int {
	fileprivate static let minSignedHalf = Int.min >> (Int.bitWidth / 2);
	fileprivate static let maxSignedHalf = Int (bitPattern: UInt.max >> (UInt.bitWidth / 2 + 1));
	fileprivate static let maxUnsignedQuarter = Int (bitPattern: UInt.max >> (UInt.bitWidth * 3 / 4));
}

private protocol CPCDayBackingStorageProtocol: CustomStringConvertible {
	var year: Int { get }
	var month: Int { get }
	var day: Int { get }
	
	init (year: Int, month: Int, day: Int)
	
#if swift(>=4.2)
	func hash (into hasher: inout Hasher);
#else
	var hashValue: Int { get }
#endif
}

extension CPCDayBackingStorageProtocol {
	fileprivate var description: String {
		return "\(self.year)-\(self.month)-\(self.day)";
	}
}

/// Calendar unit that repsesents a single day.
public struct CPCDay {
		internal struct BackingStorage: Hashable, CPCDayBackingStorageProtocol {
		fileprivate struct Packed: Hashable, CPCDayBackingStorageProtocol {
			fileprivate static let acceptableYears = Int.minSignedHalf ... .maxSignedHalf;
			fileprivate static let acceptableMonths = 0 ... .maxUnsignedQuarter;
			fileprivate static let acceptableDays = 0 ... .maxUnsignedQuarter;

			private let value: Int;
			
			fileprivate var year: Int {
				return self.value >> (Int.bitWidth / 2);
			}
			
			fileprivate var month: Int {
				return (self.value >> (Int.bitWidth / 4)) & .maxUnsignedQuarter;
			}
			
			fileprivate var day: Int {
				return self.value & .maxUnsignedQuarter;
			}
			
			fileprivate init (year: Int, month: Int, day: Int) {
				self.value = (year << (Int.bitWidth / 2)) | (month << (Int.bitWidth / 4)) | day;
			}
		}
		
		fileprivate struct Default: Hashable, CPCDayBackingStorageProtocol {
			fileprivate let year: Int;
			fileprivate let month: Int;
			fileprivate let day: Int;
		}
		
		internal static func == (lhs: BackingStorage, rhs: BackingStorage) -> Bool {
			return (lhs.day == rhs.day) && (lhs.month == rhs.month) && (lhs.year == rhs.year);
		}
		
		private let storage: CPCDayBackingStorageProtocol;
		
		internal init (year: Int, month: Int, day: Int) {
			guard Packed.acceptableYears ~= year, Packed.acceptableMonths ~= month, Packed.acceptableDays ~= day else {
				self.storage = Default (year: year, month: month, day: day);
				return;
			}
			self.storage = Packed (year: year, month: month, day: day);
		}
		
		fileprivate var year: Int {
			return self.storage.year;
		}
		fileprivate var month: Int {
			return self.storage.month;
		}
		fileprivate var day: Int {
			return self.storage.day;
		}
		
#if swift(>=4.2)
		internal func hash (into hasher: inout Hasher) {
			self.storage.hash (into: &hasher);
		}
#else
		internal var hashValue: Int {
			return self.storage.hashValue;
		}
#endif

		fileprivate init (_ storage: CPCDayBackingStorageProtocol) {
			self.storage = storage;
		}
		
		fileprivate func containingYear (_ calendar: CalendarWrapper) -> CPCYear {
			return CPCYear (backedBy: CPCYear.BackingStorage (year: self.year), calendar: calendar);
		}
		
		fileprivate func containingMonth (_ calendar: CalendarWrapper) -> CPCMonth {
			return CPCMonth (backedBy: CPCMonth.BackingStorage (year: self.year, month: self.month), calendar: calendar);
		}
	}

	internal let calendarWrapper: CalendarWrapper;
	internal let backingValue: BackingStorage;

	internal init (backedBy value: BackingStorage, calendar: CalendarWrapper) {
		self.calendarWrapper = calendar;
		self.backingValue = value;
	}
}

extension CPCDay: CPCDateInterval {
	public var start: Date { return self.startValue }
	public var end: Date { return self.endValue };
}

extension CPCDay: CPCCalendarUnitBase {
	public init (containing date: Date, calendar: Calendar) {
		self.init (containing: date, calendar: calendar.wrapped ());
	}

	/// Creates a new calendar unit that contains a given date according to the calendar of another calendar unit.
	///
	/// - Parameters:
	///   - date: Date to perform calculations for.
	///   - otherUnit: Calendar source.
	public init (containing date: Date, calendarOf otherUnit: CPCDay) {
		self.init (containing: date, calendar: otherUnit.calendarWrapper);
	}
	
	/// Creates a new calendar unit that contains a given date according to the calendar of another calendar unit.
	///
	/// - Parameters:
	///   - date: Date to perform calculations for.
	///   - otherUnit: Calendar source.
	public init (containing date: Date, calendarOf otherUnit: CPCWeek) {
		self.init (containing: date, calendar: otherUnit.calendarWrapper);
	}
	
	/// Creates a new calendar unit that contains a given date according to the calendar of another calendar unit.
	///
	/// - Parameters:
	///   - date: Date to perform calculations for.
	///   - otherUnit: Calendar source.
	public init (containing date: Date, calendarOf otherUnit: CPCMonth) {
		self.init (containing: date, calendar: otherUnit.calendarWrapper);
	}
	
	/// Creates a new calendar unit that contains a given date according to the calendar of another calendar unit.
	///
	/// - Parameters:
	///   - date: Date to perform calculations for.
	///   - otherUnit: Calendar source.
	public init (containing date: Date, calendarOf otherUnit: CPCYear) {
		self.init (containing: date, calendar: otherUnit.calendarWrapper);
	}
}

extension CPCDay: CPCCalendarUnit {
	internal typealias BackingType = BackingStorage;
	
	internal static let representedUnit = Calendar.Component.day;
	internal static let requiredComponents: Set <Calendar.Component> = [.day, .month, .year];
	internal static let descriptionDateFormatTemplate = "ddMMyyyy";
}

extension CPCDay.BackingStorage: ExpressibleByDateComponents {
	internal static let requiredComponents: Set <Calendar.Component> = CPCMonth.BackingStorage.requiredComponents.union (.day);

	internal init (_ dateComponents: DateComponents) {
		self.init (
			year: guarantee (dateComponents.year),
			month: guarantee (dateComponents.month),
			day: guarantee (dateComponents.day)
		);
	}
}

extension CPCDay.BackingStorage: DateComponentsConvertible {
	internal func dateComponents (_ calendar: Calendar) -> DateComponents {
		return DateComponents (calendar: calendar, year: self.year, month: self.month, day: self.day);
	}
}

extension CPCDay.BackingStorage: CPCCalendarUnitBackingType {
	internal typealias BackedType = CPCDay;

	internal var description: String {
		return self.storage.description;
	}
}

public extension CPCDay {
	/// Value that represents a current day.
	public static var today: CPCDay {
		if let cachedToday = self.cachedToday {
			return cachedToday;
		}
		let today = CPCDay (containing: Date (), calendar: .current);
		self.cachedToday = today;
		return today;
	}
	
	private static var cachedToday: CPCDay? {
		didSet {
			_ = self.dateChangeObserver;
		}
	}
	private static let dateChangeObserver = NotificationCenter.default.addObserver (forName: .NSCalendarDayChanged, object: nil, queue: nil) { _ in
		CPCDay.cachedToday = nil;
	};
	
	/// Value that represents yesterday.
	public static var yesterday: CPCDay {
		return self.today.next;
	}
	
	/// Value that represents tomorrow.
	public static var tommorow: CPCDay {
		return self.today.prev;
	}
	
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
		return CPCWeek (containing: self.start, calendarOf: self);
	}
	
	/// Create a new value, corresponding to a day in the future or past.
	///
	/// - Parameter daysSinceNow: Distance from today in days.
	public init (daysSinceNow: Int) {
		self = CPCDay.today.advanced (by: daysSinceNow);
	}
}
