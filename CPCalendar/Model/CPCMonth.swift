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

fileprivate extension Int {
	fileprivate static let minSignedThreeQuarters = Int.min >> (Int.bitWidth / 4);
	fileprivate static let maxSignedThreeQuarters = Int (bitPattern: UInt.max >> (UInt.bitWidth / 4 + 1));
	fileprivate static let maxUnsignedQuarter = Int (bitPattern: UInt.max >> (UInt.bitWidth * 3 / 4));
}

private protocol CPCMonthBackingStorageProtocol: CustomStringConvertible {
	var year: Int { get }
	var month: Int { get }
	
	init (year: Int, month: Int)
	
#if swift(>=4.2)
	func hash (into hasher: inout Hasher);
#else
	var hashValue: Int { get }
#endif
}

extension CPCMonthBackingStorageProtocol {
	fileprivate var description: String {
		return "\(self.year)-\(self.month)";
	}
}

/// Calendar unit that repsesents a month.
public struct CPCMonth: CPCCompoundCalendarUnit {
	public typealias Element = CPCWeek;
	internal typealias UnitBackingType = BackingStorage;
	
	internal struct BackingStorage: Hashable, CustomStringConvertible, CPCMonthBackingStorageProtocol {
		fileprivate struct Packed: Hashable, CustomStringConvertible, CPCMonthBackingStorageProtocol {
			fileprivate static let acceptableYears = Int.minSignedThreeQuarters ... .maxSignedThreeQuarters;
			fileprivate static let acceptableMonths = 0 ... .maxUnsignedQuarter;

			private let value: Int;
			
			fileprivate var year: Int {
				return self.value >> (Int.bitWidth / 4);
			}
			fileprivate var month: Int {
				return self.value & .maxUnsignedQuarter;
			}
			
			fileprivate init (year: Int, month: Int) {
				self.value = (year << (Int.bitWidth / 4)) | month;
			}
		}
		
		fileprivate struct Default: Hashable, CustomStringConvertible, CPCMonthBackingStorageProtocol {
			fileprivate let year: Int;
			fileprivate let month: Int;
		}
		
		internal static func == (lhs: BackingStorage, rhs: BackingStorage) -> Bool {
			return (lhs.month == rhs.month) && (lhs.year == rhs.year);
		}
		
		private let storage: CustomStringConvertible & CPCMonthBackingStorageProtocol;
		
		internal var year: Int {
			return self.storage.year;
		}
		internal var month: Int {
			return self.storage.month;
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
		
		internal init (year: Int, month: Int) {
			guard Packed.acceptableYears ~= year, Packed.acceptableMonths ~= month else {
				self.storage = Default (year: year, month: month);
				return;
			}
			self.storage = Packed (year: year, month: month);
		}
		
		internal func containingYear (_ calendar: CalendarWrapper) -> CPCYear {
			return CPCYear (backedBy: CPCYear.BackingStorage (year: self.year), calendar: calendar);
		}
	}

	internal static let representedUnit = Calendar.Component.month;
	internal static let descriptionDateFormatTemplate = "LLyyyy";
	
	public let indices: CountableRange <Int>;

	/// Year of represented month.
	public var year: Int {
		return self.backingValue.year;
	}
	/// Month number of represented month.
	public var month: Int {
		return self.backingValue.month;
	}
	/// Year that contains represented month.
	public var containingYear: CPCYear {
		return self.backingValue.containingYear (self.calendarWrapper);
	}
	
	internal let calendarWrapper: CalendarWrapper;
	internal let backingValue: BackingStorage;
	
	internal init (backedBy value: BackingStorage, calendar: CalendarWrapper) {
		self.calendarWrapper = calendar;
		self.backingValue = value;
		self.indices = CPCMonth.indices (for: value, using: calendar.calendar);
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

extension CPCMonth.BackingStorage: ExpressibleByDateComponents {
	internal static let requiredComponents: Set <Calendar.Component> = CPCYear.BackingStorage.requiredComponents.union (.month);

	internal init (_ dateComponents: DateComponents) {
		self.init (
			year: guarantee (dateComponents.year),
			month: guarantee (dateComponents.month)
		);
	}
}

extension CPCMonth.BackingStorage: DateComponentsConvertible {
	internal func dateComponents (_ calendar: Calendar) -> DateComponents {
		return DateComponents (calendar: calendar, year: self.year, month: self.month);
	}
}

extension CPCMonth.BackingStorage: CPCCalendarUnitBackingType {
	internal typealias BackedType = CPCMonth;
	
	internal var description: String {
		return self.storage.description;
	}
}

public extension CPCMonth {
	/// Value that represents a current month.
	public static var current: CPCMonth {
		return self.init (containing: Date (), calendar: .current);
	}
	
	/// Value that represents a next month.
	public static var next: CPCMonth {
		return self.current.next;
	}
	
	/// Value that represents a previous month.
	public static var prev: CPCMonth {
		return self.current.prev;
	}
	
	/// Create a new value, corresponding to a month in the future or past.
	///
	/// - Parameter monthsSinceNow: Distance from current month in months.
	public init (monthsSinceNow: Int) {
		self = CPCMonth.current.advanced (by: monthsSinceNow);
	}
}
