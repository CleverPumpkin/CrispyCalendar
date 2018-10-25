//
//  CPCCalendarUnitBacking.swift
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

internal extension CPCDay {
	internal typealias BackingStorage = __CPCDayBackingStorage;
}

internal extension CPCMonth {
	internal typealias BackingStorage = __CPCMonthBackingStorage;
}

internal extension CPCYear {
	internal typealias BackingStorage = __CPCYearBackingStorage;
}

extension CPCDay.BackingStorage: RawValueConvertible, ExpressibleByDateComponents, DateComponentsConvertible, CPCCalendarUnitBackingType {
	internal typealias BackedType = CPCDay;
	
	internal static let requiredComponents: Set<Calendar.Component> = [.calendar, .era, .year, .month, .day];
	
	internal init (_ dateComponents: DateComponents) {
		self.init (
			era: guarantee (dateComponents.era),
			year: guarantee (dateComponents.year),
			month: guarantee (dateComponents.encodedMonth),
			day: guarantee (dateComponents.day)
		);
	}
	
	internal func dateComponents (_ calendar: Calendar) -> DateComponents {
		var result = DateComponents (calendar: calendar, era: self.era, year: self.year, month: self.month, day: self.day);
		if (self.month < 0) {
			result.month = abs (self.month);
			result.isLeapMonth = true;
		}
		return result;
	}
	
	internal func containingYear (_ calendar: CPCCalendarWrapper) -> CPCYear.BackingStorage {
#if !arch(x86_64) && !arch(arm64)
		return CPCYear.BackingStorage (containing: self, layout: CPCYear.BackingStorage.Layout (for: calendar));
#else
		return CPCYear.BackingStorage (containing: self);
#endif
	}
	
	internal func containingMonth (_ calendar: CPCCalendarWrapper) -> CPCMonth.BackingStorage {
#if !arch(x86_64) && !arch(arm64)
		return CPCMonth.BackingStorage (containing: self, layout: CPCMonth.BackingStorage.Layout (for: calendar));
#else
		return CPCMonth.BackingStorage (containing: self);
#endif
	}
}

extension CPCDay.BackingStorage: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
	public var description: String {
		return "Era \(self.era) \(self.year)-\(self.month)-\(self.day)";
	}

	public var debugDescription: String {
		return "\(self.description) (raw: \(self.rawValue))";
	}

	public var customMirror: Mirror {
		return Mirror (CPCDay.self, children: [
			"era": self.era,
			"year": self.year,
			"month": self.month,
			"day": self.day,
			"rawValue": self.rawValue,
		], displayStyle: .struct);
	}
}

extension CPCMonth.BackingStorage: RawValueConvertible, ExpressibleByDateComponents, DateComponentsConvertible, CPCCalendarUnitBackingType {
	internal typealias BackedType = CPCMonth;
	
#if !arch(x86_64) && !arch(arm64)
	fileprivate typealias Layout = __CPCYearMonthStorageLayout;
#endif
	
	internal static let requiredComponents: Set<Calendar.Component> = [.calendar, .era, .year, .month];

	internal init (_ dateComponents: DateComponents) {
#if !arch(x86_64) && !arch(arm64)
		self.init (
			era: guarantee (dateComponents.era),
			year: guarantee (dateComponents.year),
			month: guarantee (dateComponents.encodedMonth),
			layout: Layout (for: guarantee (dateComponents.calendar))
		);
#else
		self.init (
			era: guarantee (dateComponents.era),
			year: guarantee (dateComponents.year),
			month: guarantee (dateComponents.encodedMonth)
		);
#endif
	}
	
	internal func dateComponents (_ calendar: Calendar) -> DateComponents {
		var result = DateComponents (calendar: calendar, era: self.era, year: self.year, month: self.month);
		if (self.month < 0) {
			result.month = abs (self.month);
			result.isLeapMonth = true;
		}
		return result;
	}
	
	internal func containingYear (_ calendar: CPCCalendarWrapper) -> CPCYear.BackingStorage {
		return CPCYear.BackingStorage (containing: self);
	}
}

extension CPCMonth.BackingStorage: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
	public var description: String {
		return "Era \(self.era), year \(self.year), month \(self.month)";
	}

	public var debugDescription: String {
		return "\(self.description) (raw: \(self.rawValue))";
	}

	public var customMirror: Mirror {
		return Mirror (CPCDay.self, children: [
			"era": self.era,
			"year": self.year,
			"month": self.month,
			"layout": self.layout,
			"rawValue": self.rawValue,
		], displayStyle: .struct);
	}

#if arch(x86_64) || arch(arm64)
	private var layout: String {
		return "x64";
	}
#endif
}

extension CPCYear.BackingStorage: RawValueConvertible, ExpressibleByDateComponents, DateComponentsConvertible, CPCCalendarUnitBackingType {
	internal typealias BackedType = CPCYear;
	
#if !arch(x86_64) && !arch(arm64)
	fileprivate typealias Layout = __CPCYearMonthStorageLayout;
#endif

	internal static let requiredComponents: Set<Calendar.Component> = [.calendar, .era, .year];

	internal init (_ dateComponents: DateComponents) {
#if !arch(x86_64) && !arch(arm64)
		self.init (
			era: guarantee (dateComponents.era),
			year: guarantee (dateComponents.year),
			layout: Layout (for: guarantee (dateComponents.calendar))
		);
#else
		self.init (
			era: guarantee (dateComponents.era),
			year: guarantee (dateComponents.year)
		);
#endif
	}
	
	internal func dateComponents (_ calendar: Calendar) -> DateComponents {
		return DateComponents (calendar: calendar, era: self.era, year: self.year);
	}
}

extension CPCYear.BackingStorage: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
	public var description: String {
		return "Era \(self.era), year \(self.year)";
	}

	public var debugDescription: String {
		return "\(self.description) (raw: \(self.rawValue))";
	}

	public var customMirror: Mirror {
		return Mirror (CPCDay.self, children: [
			"era": self.era,
			"year": self.year,
			"layout": self.layout,
			"rawValue": self.rawValue,
		], displayStyle: .struct);
	}

#if arch(x86_64) || arch(arm64)
	private var layout: String {
		return "x64";
	}
#endif
}

#if !arch(x86_64) && !arch(arm64)
fileprivate extension __CPCYearMonthStorageLayout {
	private typealias Layout = __CPCYearMonthStorageLayout;
	
	private static var layoutsCache = UnfairThreadsafeStorage ([Calendar.Identifier: Layout] ());
	
	fileprivate init (for calendar: CPCCalendarWrapper) {
		self.init (for: calendar.calendar);
	}
	
	fileprivate init (for calendar: Calendar) {
		self = Layout.layoutsCache.withMutableStoredValue {
			if let cachedLayout = $0 [calendar.identifier] {
				return cachedLayout;
			}
			
			let result = Layout (erasRange: calendar.maximumRange (of: .era));
			$0 [calendar.identifier] = result;
			return result;
		};
	}
	
	private init (erasRange: Range <Int>?) {
		switch (erasRange?.usedBitCount) {
		case nil, 0, 1:
			self = .default;
		case .some (let count) where 2 ... 8 ~= count:
			self = .japanese;
		case .some (let count) where 9 ... 19 ~= count:
			self = .chinese;
		case let requiredEraBits:
			fatalError ("[CrispyCalendar] Cannot handle eras: \(requiredEraBits!) required");
		}
	}
}

extension __CPCYearMonthStorageLayout: CustomStringConvertible, CustomDebugStringConvertible {
	public var description: String {
		switch (self) {
		case .default:
			return "default";
		case .japanese:
			return "japanese";
		case .chinese:
			return "chinese";
		}
	}
	
	public var debugDescription: String {
		let rawBits = String (self.rawValue, radix: 2);
		let padding = String (repeating: "0", count: 2 - rawBits.count);
		return "\(self.description) (bits: \(padding)\(rawBits))";
	}
}

#endif

fileprivate extension DateComponents {
	fileprivate var encodedMonth: Int? {
		get {
			return self.month.map {
				if let isLeapMonth = self.isLeapMonth, isLeapMonth {
					return -$0;
				} else {
					return $0;
				}
			}
		}
		set {
			guard let newValue = newValue else {
				return (self.isLeapMonth, self.month) = (nil, nil);
			}
			self.month = abs (newValue);
			self.isLeapMonth = (newValue < 0);
		}
	}
}

private protocol RawValueConvertible: Hashable {
	associatedtype RawValue where RawValue: Hashable;
	
	var rawValue: RawValue { get }
}

extension RawValueConvertible {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		return lhs.rawValue == rhs.rawValue;
	}
	
	public func hash (into hasher: inout Hasher) {
		hasher.combine (self.rawValue);
	}
}

fileprivate extension FixedWidthInteger {
	fileprivate var usedBitCount: Int {
		return Self.bitWidth - self.leadingZeroBitCount;
	}
}

fileprivate extension Range where Bound: FixedWidthInteger {
	fileprivate var usedBitCount: Int {
		return (self.upperBound - self.lowerBound - 1).usedBitCount;
	}
}
