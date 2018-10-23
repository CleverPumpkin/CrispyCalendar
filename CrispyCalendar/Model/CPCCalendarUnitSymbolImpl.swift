//
//  CPCCalendarUnitSymbolImpl.swift
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

/// Common implementation of `CPCCalendarUnitSymbol` requirements.
internal protocol CPCCalendarUnitSymbolImpl: CPCCalendarUnit, CPCCalendarUnitSymbol {
	/// KeyPaths of a `Calendar` instance that should be used to retrieve non-standalone symbols.
	static var symbolKeyPaths: [Style: KeyPath <Calendar, [String]>] { get };
	/// KeyPaths of a `Calendar` instance that should be used to retrieve standalone symbols.
	static var standaloneSymbolKeyPaths: [Style: KeyPath <Calendar, [String]>] { get };
	
	/// Index that should be used to fetch a localized symbol.
	var unitOrdinalValue: Int { get };
}

extension CPCCalendarUnitSymbolImpl {	
	public func symbol (style: Style, standalone: Bool) -> String {
		return self.calendar [keyPath: guarantee ((standalone ? Self.standaloneSymbolKeyPaths : Self.symbolKeyPaths) [style])] [self.unitOrdinalValue];
	}
}

extension CPCDay {
	public struct Weekday {
		private let day: CPCDay;
		
		fileprivate init (_ day: CPCDay) {
			self.day = day;
		}
	}
	
	public var weekday: Weekday {
		return Weekday (self);
	}
}

extension CPCDay.Weekday: CPCCalendarUnitSymbol {
	private typealias Weekday = CPCDay.Weekday;
	
	private static let symbolKeyPaths: [Style: KeyPath <Calendar, [String]>] = [
		.normal: \.weekdaySymbols,
		.short: \.shortWeekdaySymbols,
		.veryShort: \.veryShortWeekdaySymbols,
	];
	
	private static let standaloneSymbolKeyPaths: [Style: KeyPath <Calendar, [String]>] = [
		.normal: \.standaloneWeekdaySymbols,
		.short: \.shortStandaloneWeekdaySymbols,
		.veryShort: \.veryShortStandaloneWeekdaySymbols,
	];
	
	/// Day of week for represented day.
	public var weekday: Int {
		let week = self.day.containingWeek;
		return (guarantee (week.first).distance (to: self.day) + self.day.calendar.firstWeekday - 1) % week.count + 1;
	}
	
	/// Indicates whether represented day belongs to weekend.
	public var isWeekend: Bool {
		return self.day.calendar.isDateInWeekend (self.day.start);
	}

	public func symbol (style: Style, standalone: Bool) -> String {
		let weekdaySymbols = self.day.calendar [keyPath: guarantee ((standalone ? Weekday.standaloneSymbolKeyPaths : Weekday.symbolKeyPaths) [style])];
		return weekdaySymbols [(self.weekday - 1) % weekdaySymbols.count];
	}
}

extension CPCMonth: CPCCalendarUnitSymbolImpl {
	static let symbolKeyPaths: [Style: KeyPath <Calendar, [String]>] = [
		.normal: \.monthSymbols,
		.short: \.shortMonthSymbols,
		.veryShort: \.veryShortMonthSymbols,
	];
	
	static let standaloneSymbolKeyPaths: [Style: KeyPath <Calendar, [String]>] = [
		.normal: \.standaloneMonthSymbols,
		.short: \.shortStandaloneMonthSymbols,
		.veryShort: \.veryShortStandaloneMonthSymbols,
	];
	
	internal var unitOrdinalValue: Int {
		return self.month - 1;
	}
}
