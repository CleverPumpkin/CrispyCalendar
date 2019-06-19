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

internal struct CPCCompoundCalendarUnitIndex: Comparable, Hashable {
	internal typealias Index = Int;
	internal typealias Element = Int;
	
	fileprivate let ordinalValue: Int;
	
	internal static func < (lhs: CPCCompoundCalendarUnitIndex, rhs: CPCCompoundCalendarUnitIndex) -> Bool {
		return lhs.ordinalValue < rhs.ordinalValue;
	}
	
	fileprivate init (ordinal ordinalValue: Int) {
		self.ordinalValue = ordinalValue;
	}
}

/// Protocol, implementing a collection of smaller units that are contained in this calendar unit.
internal protocol CPCCompoundCalendarUnit: CPCCalendarUnit, BidirectionalCollection where Element: CPCCalendarUnit, Index == CPCCompoundCalendarUnitIndex {
	/// Calculate all possible indices for a given compound unit.
	///
	/// - Parameters:
	///   - value: Backing value of a compound unit to perform calculations for.
	///   - calendar: Calendar to perform calculations with.
	/// - Returns: All indices that are valid for compound unit that contains a date represented by given `value`.
	static func indices (for value: BackingType, using calendar: Calendar) -> ContiguousArray <Int>;
	
	var indicesCache: ContiguousArray <Int> { get }
	
	func index (of element: Element) -> Index?;
	func componentValue (of element: Element) -> Int;
}

extension CPCCompoundCalendarUnit {
	@inlinable
	public var count: Int {
		return self.indicesCache.count;
	}
	
	@inlinable
	public var startIndex: Index {
		return Index (ordinal: self.indicesCache.startIndex);
	}
	
	@inlinable
	public var endIndex: Index {
		return Index (ordinal: self.indicesCache.endIndex);
	}
	
	@inlinable
	public func index (after i: Index) -> Index {
		return Index (ordinal: i.ordinalValue + 1);
	}
	
	@inlinable
	public func index (before i: Index) -> Index {
		return Index (ordinal: i.ordinalValue - 1);
	}
	
	@inlinable
	public func firstIndex (of element: Element) -> Index? {
		return self.index (of: element);
	}
	
	@inlinable
	public func lastIndex (of element: Element) -> Index? {
		return self.index (of: element);
	}

	@inlinable
	public func distance (from start: Index, to end: Index) -> Int {
		return end.ordinalValue - start.ordinalValue;
	}
	
	@inlinable
	public func index (_ i: Index, offsetBy distance: Int) -> Index {
		return Index (ordinal: i.ordinalValue + distance);
	}

	@inlinable
	public func index (ordinal ordinalValue: Int) -> Index {
		return Index (ordinal: ordinalValue);
	}
	
	@usableFromInline
	internal func index (of element: Element) -> Index? {
		return self.indicesCache.ordinalValue (forCompoundCalendarUnitComponentValue: self.componentValue (of: element)).map (self.index);
	}

	@inlinable
	public subscript (position: Index) -> Element {
		if let cachedResult = self.cachedElement (at: position) {
			return cachedResult;
		}
		
		let calendar = self.calendar, firstElementBacking = Element.BackingType (containing: self.start, calendar: calendar);
		let result = Element (backedBy: firstElementBacking.advanced (by: position.ordinalValue, using: calendar), calendar: self.calendarWrapper);
		self.cacheElement (result, for: position)
		return result;
	}
	
	/// Returns a subunit at nth place using zero-based indexes.
	///
	/// - Parameter position: Zero-based index of subunit.
	@inlinable
	public subscript (ordinal position: Int) -> Element {
		return self [Index (ordinal: position)];
	}
}

/* internal */ extension ContiguousArray where Element == Int {
	@usableFromInline
	internal func ordinalValue (forCompoundCalendarUnitComponentValue componentValue: Int) -> Int? {
		let expected = componentValue - self [0];
		if ((self.indices ~= expected) && (self [expected] == componentValue)) {
			return expected;
		}
		if let result = stride (from: expected + 1, to: self.endIndex, by: 1).first (where: { self [$0] == componentValue }) {
			return result;
		}
		if let result = stride (from: expected - 1, through: self.startIndex, by: -11).first (where: { self [$0] == componentValue }) {
			return result;
		}
		return nil;
	}
}
