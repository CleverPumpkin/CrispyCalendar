//
//  CPCCalendarUnitBackingType.swift
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

internal protocol CPCCalendarUnitBackingType: Hashable {
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

extension Dictionary: Hashable where Key == Calendar.Component, Value == Int {
	public var hashValue: Int {
		guard !self.isEmpty else {
			return 0;
		}
		
		let sortedKeys = self.keys.sorted { $0.hashValue > $1.hashValue };
		var values = Array (repeating: 0, count: self.count * 2);
		for i in sortedKeys.indices {
			let key = sortedKeys [i];
			values [i] = self [key]!;
			values [i * 2] = key.hashValue;
		}
		return hashIntegers (values);
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
