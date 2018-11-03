//
//  CPCCalendarView_Layout_Storage.swift
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

internal extension CPCCalendarView.Layout {
	internal typealias AspectRatio = CPCMonthView.AspectRatio;
	
	internal final class Storage {
		internal struct LayoutInfo {
			internal var columnCount = 1;
			internal var contentGuide: Range <CGFloat>;
			internal var columnSpacing = 0.0 as CGFloat;
			internal var contentScale = 1.0 / UIScreen.main.nativeScale;
			internal var middleRowOrigin: CGFloat;
		}
		
		internal struct AttributesPosition: Hashable {
			internal let row: Int;
			internal let item: Int;
		}
		
		internal var contentGuideLeading: CGFloat {
			return self.contentGuide.lowerBound;
		}
		
		internal var contentGuideWidth: CGFloat {
			return self.contentGuide.upperBound - self.contentGuide.lowerBound;
		}

		internal private (set) var columnSpacing: CGFloat;

		fileprivate let columnCount: Int;
		
		fileprivate var columnWidth: CGFloat {
			return self.contentGuideWidth / CGFloat (self.columnCount) - self.columnSpacing / 2;
		}
		
		fileprivate var columnStride: CGFloat {
			return self.columnWidth + self.columnSpacing;
		}
		
		fileprivate private (set) var contentScale: CGFloat;
		
		private var contentGuide: Range <CGFloat>;
		private var rawAttributes: FloatingBaseArray <Attributes>;
		private var incompleteRowLengths = [Int: Int] ();
		private var middleRowOrigin: CGFloat;
		
		internal init <C> (middleRowData: C, layoutInfo: LayoutInfo) where C: Collection, C.Element == (indexPath: IndexPath, aspectRatio: AspectRatio) {
			self.columnCount = layoutInfo.columnCount;
			self.contentGuide = layoutInfo.contentGuide;
			self.columnSpacing = layoutInfo.columnSpacing;
			self.contentScale = layoutInfo.contentScale;
			self.middleRowOrigin = layoutInfo.middleRowOrigin;
			
			self.rawAttributes = FloatingBaseArray ();
			self.rawAttributes.reserveCapacity (self.columnCount);
			let drawCellSeparators = (self.columnCount > 1), firstItem = middleRowData [middleRowData.startIndex].indexPath.item;
			for (indexPath, aspectRatio) in middleRowData {
				let attributes = Attributes (forCellWith: indexPath);
				attributes.aspectRatio = aspectRatio;
				attributes.position = AttributesPosition (row: 0, item: indexPath.item - firstItem);
				(attributes.drawsLeadingSeparator, attributes.drawsTrailingSeparator) = (drawCellSeparators, drawCellSeparators);
				self.rawAttributes.append (attributes);
			}
			if (middleRowData.count < self.columnCount) {
				self.incompleteRowLengths [0] = middleRowData.count;
				self.rawAttributes.append (contentsOf: (middleRowData.count ..< self.columnCount).map { _ in .invalid });
			}
			
			self.layoutRow (at: 0);
		}
		
		private init (copying storage: Storage) {
			self.columnCount = storage.columnCount;
			self.contentGuide = storage.contentGuide;
			self.columnSpacing = storage.columnSpacing;
			self.contentScale = storage.contentScale;
			self.middleRowOrigin = storage.middleRowOrigin;
			self.rawAttributes = FloatingBaseArray (storage.rawAttributes, copyItems: true);
			self.incompleteRowLengths = storage.incompleteRowLengths;
		}
		
		internal func prependRow <C> (_ rowData: C) where C: Collection, C.Element == AspectRatio {
			self.rawAttributes.reserveAdditionalCapacity (rowData.count.nextDividable (by: self.columnCount));
			let newRowIndex = self.firstRowIndex - 1;
			if (rowData.count < self.columnCount) {
				self.rawAttributes.prepend (contentsOf: (rowData.count ..< self.columnCount).map { _ in .invalid });
				self.incompleteRowLengths [newRowIndex] = rowData.count;
			}
			self.rawAttributes.prepend (contentsOf: rowData.makeAttributes (startingAt: self.firstIndexPath.offset (by: -rowData.count), row: newRowIndex, drawCellSeparators: self.columnCount > 1));
			self.layoutRow (at: newRowIndex);
		}

		internal func appendRow <C> (_ rowData: C) where C: Collection, C.Element == AspectRatio {
			self.rawAttributes.reserveAdditionalCapacity (rowData.count.nextDividable (by: self.columnCount));
			let newRowIndex = self.lastRowIndex;
			self.rawAttributes.append (contentsOf: rowData.makeAttributes (startingAt: self.lastIndexPath, row: newRowIndex, drawCellSeparators: self.columnCount > 1));
			if (rowData.count < self.columnCount) {
				self.rawAttributes.append (contentsOf: (rowData.count ..< self.columnCount).map { _ in .invalid });
				self.incompleteRowLengths [newRowIndex] = rowData.count;
			}
			self.layoutRow (at: newRowIndex);
		}
		
		internal func copy () -> Storage {
			return Storage (copying: self);
		}
	}
	
	fileprivate struct Row {
		fileprivate var index: Int {
			return self.rawAttributes.startIndex / self.columnCount;
		}
		
		fileprivate var columnCount: Int {
			return self.storage.columnCount;
		}
		
		fileprivate var frame: CGRect {
			let baseAttrs = self.rawAttributes [self.rawAttributes.startIndex];
			return CGRect (origin: baseAttrs.frame.origin, size: CGSize (width:self.storage.contentGuideWidth, height: baseAttrs.rowHeight));
		}
		
		private var contentScale: CGFloat {
			return self.storage.contentScale;
		}
		
		private let storage: Storage;
		private let rawAttributes: FloatingBaseArraySlice <Attributes>;
		
		fileprivate init (_ storage: Storage, rawAttributes: FloatingBaseArraySlice <Attributes>) {
			self.storage = storage;
			self.rawAttributes = rawAttributes;
		}
		
		fileprivate func recalculateFrames (layoutBlock: (CGFloat) -> CGFloat) {
			let columnsStart = self.storage.contentGuideLeading, columnWidth = self.storage.columnWidth, scale = self.storage.contentScale;
			var rowHeight = 0.0 as CGFloat;
			let itemHeights = self.rawAttributes.map { attrs -> CGFloat in
				let height = fma (attrs.aspectRatio.multiplier, columnWidth, attrs.aspectRatio.constant);
				rowHeight = max (rowHeight, height);
				return height;
			};
			
			rowHeight = rowHeight.rounded (.up, scale: scale);
			let rowOrigin = layoutBlock (rowHeight), columnStride = self.storage.columnStride;
			for (height, attrs) in zip (itemHeights, self.rawAttributes) {
				let columnStart = fma (CGFloat (attrs.position.item), columnStride, columnsStart).rounded (scale: self.contentScale);
				attrs.frame = CGRect (
					x: columnStart,
					y: rowOrigin,
					width: columnWidth.rounded (scale: scale),
					height: height.rounded (.up, scale: scale)
				);
				attrs.rowHeight = rowHeight;
			}
		}
	}
}

internal extension CPCCalendarView.Layout.Storage {
	internal var minY: CGFloat {
		return self.firstAttributes.frame.minY;
	}
	
	internal var maxY: CGFloat {
		return self.lastAttributes.frame.maxY;
	}
	
	internal var firstRowIndex: Int {
		return self.rawAttributes.startIndex / self.columnCount;
	}
	
	internal var lastRowIndex: Int {
		return self.rawAttributes.endIndex / self.columnCount;
	}
	
	internal var firstIndexPath: IndexPath {
		return self.firstAttributes.indexPath;
	}
	
	internal var lastIndexPath: IndexPath {
		return self.lastAttributes.indexPath.next;
	}
	
	internal subscript (indexPath: IndexPath) -> CPCCalendarView.Layout.Attributes? {
		guard let rowStartIndex = self.rawAttributes.binarySearch (withGranularity: self.columnCount, using: {
			if ($0.indexPath.item > indexPath.item) {
				return .orderedAscending;
			} else if ($0.indexPath.item + self.rowLength (at: $0.position.row) <= indexPath.item) {
				return .orderedDescending;
			} else {
				return .orderedSame;
			}
		}) else {
			return nil;
		}
		let rowStartIndexPath = self.rawAttributes [rowStartIndex].indexPath;
		return self.rawAttributes [rowStartIndex + indexPath.item - rowStartIndexPath.item];
	}

	internal subscript (rect: CGRect) -> [CPCCalendarView.Layout.Attributes] {
		guard let topRow = self.row (containing: rect.minY, allowBeforeFirst: true), let bottomRow = self.row (containing: rect.maxY, allowAfterLast: true) else {
			return [];
		}
	
		let leadingColumn = max (((rect.minX - self.contentGuideLeading) / self.contentGuideWidth).integerRounded (.down), 0);
		let trailingColumn = min (((rect.maxX - self.contentGuideLeading) / self.contentGuideWidth).integerRounded (.up), self.columnCount - 1);
		if ((leadingColumn == 0) && (trailingColumn == (self.columnCount - 1))) {
			return self.rawAttributes [topRow.index * self.columnCount ..< (bottomRow.index + 1) * self.columnCount].filter { $0 !== Attributes.invalid };
		} else {
			var result = [Attributes] ();
			result.reserveCapacity ((bottomRow.index - topRow.index + 1) * (trailingColumn - leadingColumn + 1));
			for row in topRow.index ... bottomRow.index {
				let rowLength = self.incompleteRowLengths [row] ?? self.columnCount;
				if (leadingColumn >= rowLength) {
					continue;
				}
				let startIndex = row * self.columnCount + leadingColumn, endIndex = row * self.columnCount + min (trailingColumn, rowLength - 1);
				result.append (contentsOf: self.rawAttributes [startIndex ... endIndex]);
			}
			return result;
		}
	}
	
	internal func updateStoredAttributes (using newAspectRatios: [AttributesPosition: CPCMonthView.AspectRatio]) {
		var firstTopRowToUpdate = self.firstRowIndex, firstBottomRowToUpdate = self.lastRowIndex;
		for (position, aspectRatio) in newAspectRatios {
			self.rawAttributes [position.row * self.columnCount + position.item].aspectRatio = aspectRatio;
			firstBottomRowToUpdate = max (position.row, firstBottomRowToUpdate);
			firstTopRowToUpdate = min (position.row, firstTopRowToUpdate);
		}
		
		for row in stride (from: firstTopRowToUpdate, through: self.firstRowIndex, by: -1) {
			self.layoutRow (at: row);
		}
		for row in stride (from: firstBottomRowToUpdate, to: self.lastRowIndex, by: 1) {
			self.layoutRow (at: row);
		}
	}
	
	internal func isStorageValid (forContentGuide contentGuide: Range <CGFloat>, columnSpacing: CGFloat) -> Bool {
		return (
			((self.contentGuide.lowerBound - contentGuide.lowerBound).magnitude < 1e-3) &&
			((self.contentGuide.upperBound - contentGuide.upperBound).magnitude < 1e-3) &&
			((self.columnSpacing - columnSpacing).magnitude < 1e-3)
		);
	}

	internal func isStorageValid (forColumnCount columnCount: Int) -> Bool {
		return self.columnCount == columnCount;
	}
	
	internal func updateContentGuide (_ newContentGuide: Range <CGFloat>) {
		let oldWidth = self.contentGuideWidth, oldLeading = self.contentGuideLeading;
		self.contentGuide = newContentGuide;
		
		if ((self.contentGuideWidth - oldWidth).magnitude > 1e-3) {
			self.layoutRow (at: 0);
			for row in stride (from: -1, through: self.firstRowIndex, by: -1) {
				self.layoutRow (at: row);
			}
			for row in stride (from: 1, to: self.lastRowIndex, by: 1) {
				self.layoutRow (at: row);
			}
		} else if ((self.contentGuideLeading - oldLeading).magnitude > 1e-3) {
			let offset = self.contentGuideLeading - oldLeading;
			for attrs in self.rawAttributes {
				attrs.frame = attrs.frame.offsetBy (dx: offset, dy: 0.0);
			}
		}
	}
}

fileprivate extension CPCCalendarView.Layout.Storage {
	fileprivate typealias Attributes = CPCCalendarView.Layout.Attributes;
	private typealias Row = CPCCalendarView.Layout.Row;
	
	private var firstAttributes: Attributes {
		return self.rawAttributes [self.rawAttributes.startIndex];
	}
	
	private var lastAttributes: Attributes {
		return self.rawAttributes [(self.lastRowIndex - 1) * self.columnCount + self.rowLength (at: self.lastRowIndex - 1) - 1];
	}
	
	private var firstRow: Row {
		return self.row (at: self.firstRowIndex);
	}
	
	private var lastRow: Row {
		return self.row (at: self.lastRowIndex - 1);
	}
	
	private func row (at index: Int) -> Row {
		return Row (self, rawAttributes: self.rawAttributes [(index * self.columnCount) ..< (index * self.columnCount + self.rowLength (at: index))]);
	}
	
	private func rowLength (at index: Int) -> Int {
		return self.incompleteRowLengths [index] ?? self.columnCount;
	}

	private func row (containing verticalOffset: CGFloat, allowBeforeFirst: Bool = false, allowAfterLast: Bool = false) -> Row? {
		if (allowBeforeFirst && (verticalOffset < self.firstAttributes.frame.minY)) {
			return self.firstRow;
		}
		if (allowAfterLast && (verticalOffset >= self.lastAttributes.frame.maxY)) {
			return self.row (at: self.lastRowIndex - 1);
		}

		return self.rawAttributes.binarySearch (withGranularity: self.columnCount) {
			if ($0.frame.minY > verticalOffset) {
				return .orderedAscending;
			} else if ($0.frame.maxY < verticalOffset) {
				return .orderedDescending;
			} else {
				return .orderedSame;
			}
		}.map { self.row (at: $0 / self.columnCount) };
	}
	
	private func layoutRow (at index: Int) {
		let row = self.row (at: index);
		if (index > 0) {
			row.recalculateFrames { _ in self.row (at: index - 1).frame.maxY };
		} else if (index < 0) {
			row.recalculateFrames { self.row (at: index + 1).frame.minY - $0 };
		} else {
			row.recalculateFrames { (self.middleRowOrigin - $0 / 2).rounded (scale: self.contentScale) };
		}
	}
}

internal extension IndexPath {
	internal var next: IndexPath {
		return self.offset (by: 1);
	}
	
	internal var prev: IndexPath {
		return self.offset (by: -1);
	}
	
	internal func offset (by amount: Int) -> IndexPath {
		return IndexPath (item: self.item + amount, section: self.section);
	}
}

fileprivate extension CPCCalendarView.Layout.Attributes {
	fileprivate static let invalid = CPCCalendarView.Layout.Attributes ();
}

private protocol UnsafeBufferRepresentable: RandomAccessCollection {
	func withUnsafeBufferPointer <R> (_ body: (UnsafeBufferPointer <Element>) throws -> R) rethrows -> R;
}
extension Array: UnsafeBufferRepresentable {}
extension ContiguousArray: UnsafeBufferRepresentable {}
extension ArraySlice: UnsafeBufferRepresentable {}
extension FloatingBaseArray: UnsafeBufferRepresentable {}

extension UnsafeBufferRepresentable where Index: BinaryInteger {
	fileprivate func binarySearch (withGranularity granularity: Index = 1, using comparator: (Element) -> ComparisonResult) -> Index? {
		return self.withUnsafeBufferPointer { buffer in
			let base = buffer.baseAddress!;
			return withoutActuallyEscaping (comparator) { comparator in
				guard let found = bsearch_b (nil, UnsafeRawPointer (base), self.count / Int (granularity), MemoryLayout <Element>.stride * Int (granularity), { _, element in
					return Int32 (comparator (element!.assumingMemoryBound (to: Element.self).pointee).rawValue);
				}) else {
					return nil;
				};
				return self.startIndex.advanced (by: base.distance (to: found.assumingMemoryBound (to: Element.self)));
			}
		};
	}
}

extension UnsafeBufferRepresentable where Index: BinaryInteger, Element: Comparable {
	fileprivate func binarySearch (of element: Element) -> Index? {
		return self.binarySearch (using: element.comparator);
	}
}

fileprivate extension FloatingBaseArray {
	fileprivate mutating func reserveAdditionalCapacity (_ k: Int) {
		self.reserveCapacity (self.count + k);
	}
}

fileprivate extension Comparable {
	fileprivate static func comparator (lhs: Self, rhs: Self) -> ComparisonResult {
		if (lhs < rhs) {
			return .orderedAscending;
		} else if (lhs > rhs) {
			return .orderedDescending;
		} else {
			return .orderedSame;
		}
	}
	
	fileprivate func comparator (other: Self) -> ComparisonResult {
		return Self.comparator (lhs: self, rhs: other);
	}
}

fileprivate extension Collection where Element == CPCMonthView.AspectRatio {
	fileprivate typealias Attributes = CPCCalendarView.Layout.Attributes;
	private typealias AttributesPosition = CPCCalendarView.Layout.Storage.AttributesPosition;
	
	fileprivate func makeAttributes (startingAt indexPath: IndexPath, row: Int, drawCellSeparators: Bool) -> [Attributes] {
		return self.enumerated ().map {
			let result = Attributes (forCellWith: indexPath.offset (by: $0.offset));
			result.position = AttributesPosition (row: row, item: $0.offset);
			result.aspectRatio = $0.element;
			(result.drawsLeadingSeparator, result.drawsTrailingSeparator) = (drawCellSeparators, drawCellSeparators);
			return result;
		};
	}
}

fileprivate extension BinaryInteger {
	fileprivate func nextDividable (by divisor: Self) -> Self {
		return self + divisor - self % divisor - 1;
	}
}
