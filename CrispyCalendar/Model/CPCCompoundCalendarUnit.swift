//
//  CPCCompoundCalendarUnit.swift
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

/// Protocol, implementing a collection of smaller units that are contained in this calendar unit.
internal protocol CPCCompoundCalendarUnit: CPCCalendarUnit, RandomAccessCollection where Element: CPCCalendarUnit, Indices == CountableRange <Int> {
	/// Calculate all possible indices for a given compound unit.
	///
	/// - Parameters:
	///   - value: Backing value of a compound unit to perform calculations for.
	///   - calendar: Calendar to perform calculations with.
	/// - Returns: All indices that are valid for compound unit that contains a date represented by given `value`.
	static func indices (for value: BackingType, using calendar: Calendar) -> CountableRange <Int>;
}

extension CPCCompoundCalendarUnit {
	public var startIndex: Int {
		return self.indices.lowerBound;
	}
	
	public var endIndex: Int {
		return self.indices.upperBound;
	}
	
	public func index (of element: Element) -> Index? {
		if let cachedResult = self.cachedIndex (of: element) {
			return cachedResult;
		}

		let calendarWrapper = resultingCalendarForOperation (for: self, element), calendar = calendarWrapper.calendar;
		let startDate = self.start, elementStartDate = element.start;
		guard calendar.isDate (startDate, equalTo: elementStartDate, toGranularity: Self.representedUnit) else {
			return nil;
		}

		let distanceFromStart = guarantee (calendar.dateComponents ([Element.representedUnit], from: startDate, to: elementStartDate).value (for: Element.representedUnit));
		let result = self.startIndex + distanceFromStart;
		self.cacheIndex (result, for: element);
		return result;
	}

	public subscript (position: Int) -> Element {
		if let cachedResult = self.cachedElement (at: position) {
			return cachedResult;
		}
		
		let calendar = self.calendar, firstElementBacking = Element.BackingType (containing: self.start, calendar: calendar);
		let result = Element (backedBy: firstElementBacking.advanced (by: position - self.indices.lowerBound, using: calendar), calendar: self.calendarWrapper);
		self.cacheElement (result, for: position)
		return result;
	}
	
	/// Returns a subunit at nth place using zero-based indexes.
	///
	/// - Parameter position: Zero-based index of subunit.
	public subscript (ordinal position: Int) -> Element {
		return self [position + self.indices.lowerBound];
	}
}
