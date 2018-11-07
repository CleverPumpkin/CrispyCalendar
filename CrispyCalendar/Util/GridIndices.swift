//
//  GridIndices.swift
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

internal struct GridIndices <Idx> where Idx: FixedWidthInteger {
	internal struct Element: CustomStringConvertible, CustomDebugStringConvertible, Hashable, Strideable, ExpressibleByNilLiteral {
		internal typealias Stride = Idx.Stride;
		
		internal var description: String {
			return "(\(self.row), \(self.column))";
		}
		
		internal var debugDescription: String {
			return "[Idx: \(self.index), rows: \(self.info.rows), columns: \(self.info.columns), value: \(self.description)]";
		}
		
		internal var row: Idx {
			return self.info.rows.lowerBound + self.index / numericCast (self.info.columns.count);
		}
		
		internal var column: Idx {
			return self.info.columns.lowerBound + self.index % numericCast (self.info.columns.count);
		}
		
		fileprivate let info: Info;
		private let index: Idx;
		
		internal static func < (lhs: Element, rhs: Element) -> Bool {
			return lhs.index < rhs.index;
		}
		
		fileprivate static func min (_ info: Info) -> Element {
			return Element (index: 0, info: info);
		}

		fileprivate static func max (_ info: Info) -> Element {
			return Element (index: info.indices.upperBound, info: info);
		}
		
		private static func indexValue (info: Info, row: Idx, column: Idx) -> Idx {
			return (row - info.rows.lowerBound) * (info.columns.upperBound - info.columns.lowerBound) + (column - info.columns.lowerBound);
		}
		
		internal init (nilLiteral: ()) {
			self.init (index: 0, info: .invalid);
		}
		
		fileprivate init (row: Idx, column: Idx, info: Info) {
			precondition (info.rows ~= row, "Invalid row \(row) for \(info)");
			precondition (info.columns ~= column, "Invalid column \(column) for \(info)");
			let indexValue = Element.indexValue (info: info, row: row, column: column);
			self.init (index: indexValue, info: info);
		}
		
		private init (index: Idx, info: Info) {
			self.info = info;
			self.index = index;
		}
		
		internal func distance (to other: Element) -> Stride {
			guard self.info == other.info else {
				fatalError ("[CrispyCalendar] Sanity check failure: incompatible indexes \(self) and \(other): \(self.info) != \(other.info)");
			}
			return self.index.distance (to: other.index);
		}
		
		internal func advanced (by n: Idx.Stride) -> Element {
			let info = self.info, maxIndexValue = info.indices.upperBound;
			let newIndexValue = self.index.advanced (by: n);
			precondition (newIndexValue <= maxIndexValue, "Cannot advance index \(self) by \(n): valid index range is \(info.rows) X \(info.columns)");
			guard newIndexValue != info.indices.upperBound else {
				return Element.max (info);
			}
			
			return Element (index: newIndexValue, info: info);
		}
	}
	
	fileprivate final class Info: Hashable, CustomStringConvertible, CustomDebugStringConvertible {
		fileprivate static var invalid: Info {
			let zeroRange = Idx (0) ..< Idx (0);
			return Info (rows: zeroRange, columns: zeroRange);
		}
		
		internal var description: String {
			return "(Grid \(self.rows) x \(self.columns), \(self.indices.count) indices)";
		}
		
		internal var debugDescription: String {
			return "(Grid \(self.rows) x \(self.columns), indices: \(self.indices), indexValues: \(self.indices), indexes: \(self.min) ..< \(self.max))";
		}
		
#if swift(>=4.2)
		
		fileprivate let rows: Range <Idx>;
		fileprivate let columns: Range <Idx>;
		
#else
		
		private struct HashableValues: Hashable {
			private let minRow: Idx;
			private let maxRow: Idx;
			private let minCol: Idx;
			private let maxCol: Idx;
			
			fileprivate var rows: Range <Idx> {
				return self.minRow ..< self.maxRow;
			}
			
			fileprivate var columns: Range <Idx> {
				return self.minCol ..< self.maxCol;
			}
			
			fileprivate init (rows: Range <Idx>, columns: Range <Idx>) {
				self.minRow = rows.lowerBound;
				self.maxRow = rows.upperBound;
				self.minCol = columns.lowerBound;
				self.maxCol = columns.upperBound;
			}
		}
		
		fileprivate var rows: Range <Idx> {
			return self.hashableValues.rows;
		}
		
		fileprivate var columns: Range <Idx> {
			return self.hashableValues.columns;
		}
		private let hashableValues: HashableValues;

#endif

		fileprivate var indices: Range <Idx> {
			return 0 ..< numericCast (self.rows.count * self.columns.count);
		}
		
		fileprivate var min: Element {
			return Element.min (self);
		}
		
		fileprivate var max: Element {
			return Element.max (self);
		}
		
#if swift(>=4.2)
		fileprivate func hash (into hasher: inout Hasher) {
			hasher.combine (self.rows);
			hasher.combine (self.columns);
		}
#else
		fileprivate var hashValue: Int {
			return self.hashableValues.hashValue;
		}
#endif
		
		fileprivate static func == (lhs: Info, rhs: Info) -> Bool {
			return (lhs === rhs) || ((lhs.rows == rhs.rows) && (lhs.columns == rhs.columns));
		}
	
		private init (rows: Range <Idx>, columns: Range <Idx>) {
#if swift(>=4.2)
			self.rows = rows;
			self.columns = columns;
#else
			self.hashableValues = HashableValues (rows: rows, columns: columns);
#endif
		}
		
		fileprivate convenience init <R1, R2> (rows: R1, columns: R2) where R1: RangeExpression, R1.Bound == Idx, R2: RangeExpression, R2.Bound == Idx {
#if swift(>=4.2)
			self.init (rows: rows.unwrapped, columns: columns.unwrapped);
#else
			self.init (rows: Range (rows), columns: Range (columns));
#endif
		}
		
		fileprivate func index (forRow row: Idx, column: Idx) -> Element {
			return Element (row: row, column: column, info: self);
		}
		
		fileprivate func convert (index: Element) -> Element {
			return Element (row: index.row, column: index.column, info: self);
		}
	}
	
	internal var minElement: Element {
		return self.info.min;
	}
	
	internal var maxElement: Element {
		return self.info.max;
	}
	
	internal var rows: Range <Idx> {
		return self.info.rows;
	}
	
	internal var columns: Range <Idx> {
		return self.info.columns;
	}
	
	private let info: Info;
	private let values: [Element];
	
	private init? (info: Info, values: [Element]) {
		guard !values.isEmpty else {
			return nil;
		}
		self.info = info;
		self.values = values;
	}
	
	internal init? (rowCount: Idx, columnCount: Idx) {
		let info = Info (rows: 0 ..< rowCount, columns: 0 ..< columnCount);
		self.init (info: info, values: Array (info.min ..< info.max));
	}
	
	internal func indices (filteredUsing predicate: (Element) -> Bool) -> GridIndices? {
		return GridIndices (info: self.info, values: self.values.filter (predicate));
	}
	
	internal func subindices <R1, R2> (forRows rows: R1, columns: R2) -> GridIndices? where R1: RangeExpression, R1.Bound == Idx, R2: RangeExpression, R2.Bound == Idx {
		let info = Info (rows: rows, columns: columns);
		precondition (info.rows.clamped (to: self.info.rows) == info.rows, "Cannot instantiate subindices for rows \(rows) because only \(self.info.rows) are available");
		precondition (info.columns.clamped (to: self.info.columns) == info.columns, "Cannot instantiate subindices for columns \(rows) because only \(self.info.columns) are available");
		
		return GridIndices (info: info, values: self.values.compactMap { index in
			guard info.rows ~= index.row, info.columns ~= index.column else {
				return nil;
			}
			return info.convert (index: index);
		});
	}
	
	internal func index (forRow row: Idx, column: Idx) -> Element {
		return self.info.index (forRow: row, column: column);
	}

	internal func convert (index i: Element, from indices: GridIndices) -> Element {
		return self.info.convert (index: i);
	}
	
	internal func convert (index i: Element, to indices: GridIndices) -> Element {
		return indices.info.convert (index: i);
	}
}

extension GridIndices: CustomStringConvertible, CustomDebugStringConvertible {
	internal var description: String {
		var descriptionElements = [CustomStringConvertible] ();
		var rangeStart: Element?, prevIndex: Element?;
		
		func handleIndex (_ index: Element) {
			guard let possibleStart = rangeStart else {
				return rangeStart = index;
			}
			
			guard let prevIndex = prevIndex, prevIndex.distance (to: index) != 1 else {
				return;
			}
			
			if possibleStart.distance (to: prevIndex) == 1 {
				descriptionElements.append (possibleStart);
			} else {
				descriptionElements.append (possibleStart ... prevIndex);
			}
			rangeStart = nil;
		}
		
		for idx in self.values {
			handleIndex (idx);
			prevIndex = idx;
		}
		handleIndex (self.maxElement);
		
		if let lastIndex = prevIndex?.advanced (by: 1) {
			handleIndex (lastIndex);
		}
		
		return descriptionElements.description;
	}

	internal var debugDescription: String {
		return "(Indices: \(self.values) \(self.info.debugDescription))";
	}
}

extension GridIndices: RandomAccessCollection {
	internal typealias Index = Element;
	internal typealias Indices = GridIndices;
	internal typealias SubSequence = GridIndices <Idx>;

	internal var startIndex: Element {
		return guarantee (self.values.first);
	}
	
	internal var endIndex: Element {
		return guarantee (self.values.last).advanced (by: 1);
	}
	
	internal var indices: GridIndices {
		return self;
	}
	
	internal subscript (position: Element) -> Element {
		return position;
	}
	
	internal func index (after i: Element) -> Element {
		guard let indexIndex = self.values.index (of: i) else {
			fatalError ("[CrispyCalendar] Internal error: invalid index \(i) for grid indices \(self)");
		}
		let nextIndexIndex = indexIndex + 1;
		return ((nextIndexIndex == self.values.count) ? self.endIndex : self.values [nextIndexIndex]);
	}
	
	internal func index (before i: Element) -> Element {
		if i == self.endIndex {
			return guarantee (self.values.last);
		}
		guard let indexIndex = self.values.index (of: i) else {
			fatalError ("[CrispyCalendar] Internal error: invalid index \(i) for grid indices \(self)");
		}
		return self.values [indexIndex - 1];
	}
}
