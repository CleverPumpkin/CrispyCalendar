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

internal protocol CPCCompoundCalendarUnit: CPCCalendarUnit, RandomAccessCollection where Element: CPCCalendarUnit, Index == Int {
	var smallerUnitRange: Range <Int> { get };
}

extension CPCCompoundCalendarUnit {
	internal static func smallerUnitRange (for value: UnitBackingType, using calendar: Calendar) -> Range <Int> {
		return guarantee (calendar.range (of: Element.representedUnit, in: self.representedUnit, for: value.date (using: calendar)));
	}
	
	public var startIndex: Int {
		return self.smallerUnitRange.lowerBound;
	}
	
	public var endIndex: Int {
		return self.smallerUnitRange.upperBound;
	}
	
	public func index (of element: Element) -> Index? {
		if let cachedResult = self.cachedIndex (of: element) {
			return cachedResult;
		}
		
		let calendar = resultingCalendarForOperation (for: self, element);
		let startDate = self.startDate, elementStartDate = element.startDate;
		guard calendar.isDate (startDate, equalTo: elementStartDate, toGranularity: Self.representedUnit) else {
			return nil;
		}

		let result = guarantee (calendar.dateComponents ([Element.representedUnit], from: startDate, to: elementStartDate).value (for: Element.representedUnit));
		self.cacheIndex (result, for: element);
		return result;
	}

	public subscript (position: Int) -> Element {
		if let cachedResult = self.cachedElement (at: position) {
			return cachedResult;
		}
		
		let result = Element (containing: self.startDate, calendar: self.calendar).advanced (by: position - self.smallerUnitRange.lowerBound);
		self.cacheElement (result, for: position)
		return result;
	}
	
	public subscript (ordinal position: Int) -> Element {
		return self [position + self.smallerUnitRange.lowerBound];
	}
}
