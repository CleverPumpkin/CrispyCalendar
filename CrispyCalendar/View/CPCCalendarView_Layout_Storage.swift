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

import UIKit

/* internal */ extension CPCCalendarView.Layout {
	
	// MARK: - Internal types
	
	internal enum HeightType {
		case unspecified
		case absolute(CGFloat)
	}
	
	internal typealias AspectRatio = CPCMonthView.AspectRatio;
	
	internal final class Storage {
		
		// MARK: - Internal types
		
		internal struct LayoutInfo {
			var columnCount = 1
			var contentGuide: Range <CGFloat>
			var columnSpacing = 0.0 as CGFloat
			var contentScale = 1.0 / UIScreen.main.nativeScale
			var middleRowOrigin: CGFloat
			var invalidAttributes: CPCCalendarView.Layout.Attributes
			var numberOfMonthsToDisplay: Int? = nil
		}
		
		internal struct AttributesPosition: Hashable {
			internal let row: Int;
			internal let item: Int;
		}
		
		// MARK: - Internal properties
		
		internal var contentGuideLeading: CGFloat {
			return self.contentGuide.lowerBound;
		}
		
		internal var contentGuideWidth: CGFloat {
			return self.contentGuide.upperBound - self.contentGuide.lowerBound;
		}

		internal private (set) var columnSpacing: CGFloat;
		
		internal var height: HeightType {

			guard let visibleRowsRange else {
				return .unspecified
			}
			
			let targetIndex = visibleRowsRange.upperBound
				
			guard targetIndex < lastRowIndex else {
				return .unspecified
			}
				
			let start = row(at: visibleRowsRange.lowerBound)
			let end = row(at: targetIndex)
				
			return .absolute(end.frame.maxY - start.frame.minY)
		}

		// MARK: - Private properties
		
		fileprivate let columnCount: Int;
		
		fileprivate var columnWidth: CGFloat {
			return (self.contentGuideWidth - CGFloat (self.columnCount - 1) * self.columnSpacing) / CGFloat (self.columnCount);
		}
		
		fileprivate var columnStride: CGFloat {
			return self.columnWidth + self.columnSpacing;
		}
		
		fileprivate private (set) var contentScale: CGFloat;
		
		private var contentGuide: Range <CGFloat>;
		private var rawAttributes: FloatingBaseArray <Attributes>;
		private var incompleteRowLengths = [Int: Int] ();
		private var middleRowOrigin: CGFloat;
		private var validatedRows: ClosedRange <Int>?;
		private let visibleRowsRange: ClosedRange<Int>?
		
		private unowned let invalidAttributes: Attributes;

		// MARK: - Initialization
		
		internal init <C> (middleRowData: C, layoutInfo: LayoutInfo) where C: Collection, C.Element == (indexPath: IndexPath, aspectRatio: AspectRatio) {
			self.columnCount = layoutInfo.columnCount;
			self.contentGuide = layoutInfo.contentGuide;
			self.columnSpacing = layoutInfo.columnSpacing;
			self.contentScale = layoutInfo.contentScale;
			self.middleRowOrigin = layoutInfo.middleRowOrigin;
			self.invalidAttributes = layoutInfo.invalidAttributes;
			
			if let numberOfMonthsToDisplay = layoutInfo.numberOfMonthsToDisplay {
				self.visibleRowsRange = 0...(numberOfMonthsToDisplay / columnCount)
			} else {
				self.visibleRowsRange = nil
			}
			
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
				self.rawAttributes.append (contentsOf: repeatElement (self.invalidAttributes, count: self.columnCount - middleRowData.count));
			}
		}
		
		private init (copying storage: Storage) {
			self.columnCount = storage.columnCount;
			self.contentGuide = storage.contentGuide;
			self.columnSpacing = storage.columnSpacing;
			self.contentScale = storage.contentScale;
			self.middleRowOrigin = storage.middleRowOrigin;
			self.rawAttributes = FloatingBaseArray (storage.rawAttributes, copyItems: true);
			self.incompleteRowLengths = storage.incompleteRowLengths;
			self.invalidAttributes = storage.invalidAttributes;
			self.visibleRowsRange = storage.visibleRowsRange
		}
		
		// MARK: - Internal methods
		
		internal func prependRow <C> (_ rowData: C, layoutImmediately: Bool = false) where C: Collection, C.Element == AspectRatio {
			rawAttributes.reserveAdditionalCapacity(columnCount)
			
			let firstRowIndexPath = firstIndexPath.offset(
				by: -rowData.count
			)
			
			let newRowIndex = self.firstRowIndex - 1
			
			if (rowData.count < columnCount) {
				rawAttributes.prepend(
					contentsOf: repeatElement(
						invalidAttributes,
						count: columnCount - rowData.count
					)
				)
				
				incompleteRowLengths[newRowIndex] = rowData.count
			}
			
			rawAttributes.prepend(
				contentsOf: rowData.makeAttributes(
					startingAt: firstRowIndexPath,
					row: newRowIndex,
					drawCellSeparators: columnCount > 1
				)
			)
			
			if (layoutImmediately) {
				layoutRow(firstRow);
			}
		}

		internal func appendRow <C> (_ rowData: C, layoutImmediately: Bool = false) where C: Collection, C.Element == AspectRatio {
			
			rawAttributes.reserveAdditionalCapacity(self.columnCount)
			
			let newRowIndex = lastRowIndex
			
			rawAttributes.append(
				contentsOf: rowData.makeAttributes(
					startingAt: lastIndexPath,
					row: newRowIndex,
					drawCellSeparators: columnCount > 1
				)
			)
			
			if (rowData.count < columnCount) {
				rawAttributes.append(
					contentsOf: repeatElement(
						invalidAttributes,
						count: columnCount - rowData.count
					)
				)
				
				incompleteRowLengths[newRowIndex] = rowData.count
			}
			
			if (layoutImmediately) {
				layoutRow(at: lastRowIndex - 1);
			}
		}
		
		internal func copy () -> Storage {
			return Storage (copying: self);
		}
	}
	
	// MARK: - Private types
	
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
		
		fileprivate var prev: Row? {
			guard self.index > self.storage.firstRowIndex else {
				return nil;
			}
			return self.storage.row (at: self.index - 1);
		}
		
		fileprivate var next: Row? {
			guard self.index < self.storage.lastRowIndex - 1 else {
				return nil;
			}
			return self.storage.row (at: self.index + 1);
		}
		
		fileprivate var reference: Row? {
			switch (self.index) {
			case ..<0:
				return self.next;
			case 1...:
				return self.prev;
			default:
				return nil;
			}
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

/* internal */ extension CPCCalendarView.Layout.Storage {
	internal var minY: CGFloat {
		return self.firstAttributes.frame.minY;
	}
	
	internal var maxY: CGFloat {
		return self.lastAttributes.frame.maxY;
	}
	
	internal var isUpperRowsLayoutCompleted: Bool {
		guard let visibleRowsRange else {
			return false
		}
		
		return firstRow.index <= visibleRowsRange.lowerBound
	}
	
	internal var isLowerRowsLayoutCompleted: Bool {
		guard let visibleRowsRange else {
			return false
		}
		
		return lastRow.index >= visibleRowsRange.upperBound
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
		let result = self.rawAttributes [rowStartIndex + indexPath.item - rowStartIndexPath.item];
		self.layoutRow (at: result.position.row);
		return result;
	}
	
	internal func layoutElements (in rect: CGRect) {
		repeat {
			let invalidRow: Row;
			if let validatedRows = self.validatedRows {
				let firstValidRow = self.row (at: validatedRows.lowerBound), lastValidRow = self.row (at: validatedRows.upperBound);
				if firstValidRow.frame.minY > rect.minY, let row = firstValidRow.prev {
					invalidRow = row;
				} else if lastValidRow.frame.maxY < rect.maxY, let row = lastValidRow.next {
					invalidRow = row;
				} else {
					return;
				}
			} else {
				invalidRow = self.middleRow;
			}
			self.layoutRow (invalidRow);
		} while (true);
	}

	internal subscript (rect: CGRect) -> [CPCCalendarView.Layout.Attributes] {
		guard let topRow = self.row (containing: rect.minY, allowBeforeFirst: true), let bottomRow = self.row (containing: rect.maxY, allowAfterLast: true) else {
			return [];
		}
		
		let leadingColumn: Int, trailingColumn: Int;
		if (self.contentGuideWidth > 0.0) {
			leadingColumn = max (((rect.minX - self.contentGuideLeading) / self.columnWidth).integerRounded (.down), 0);
			trailingColumn = min (((rect.maxX - self.contentGuideLeading) / self.columnWidth).integerRounded (.up), self.columnCount - 1);
		} else {
			(leadingColumn, trailingColumn) = (0, self.columnCount - 1);
		}
		if ((leadingColumn == 0) && (trailingColumn == (self.columnCount - 1))) {
			return self.rawAttributes [topRow.index * self.columnCount ..< (bottomRow.index + 1) * self.columnCount].filter { $0 !== self.invalidAttributes };
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
		for (position, aspectRatio) in newAspectRatios {
			self.rawAttributes [position.row * self.columnCount + position.item].aspectRatio = aspectRatio;
		}
	}
	
	internal func invalidate () {
		self.validatedRows = nil;
	}
	
	internal func invalidate <S> (rowsIn invalidatedRows: S) where S: Sequence, S.Element == Int {
		guard let validatedRows = self.validatedRows else {
			return;
		}
		
		var lowerBound = validatedRows.lowerBound, upperBound = validatedRows.upperBound;
		for row in invalidatedRows {
			switch (row) {
			case 0:
				return self.validatedRows = nil;
			case lowerBound ... -1:
				lowerBound = row + 1;
			case 1 ... upperBound:
				upperBound = row - 1;
			default:
				break;
			}
		}
		self.validatedRows = lowerBound ... upperBound;
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
		if ((self.contentGuideWidth - oldWidth).magnitude > 1e-3) || ((self.contentGuideLeading - oldLeading).magnitude > 1e-3) {
			self.validatedRows = nil;
		}
	}
}

/* fileprivate */ extension CPCCalendarView.Layout.Storage {
	fileprivate typealias Attributes = CPCCalendarView.Layout.Attributes;
	fileprivate typealias Row = CPCCalendarView.Layout.Row;
	
	private var firstAttributes: Attributes {
		return self.rawAttributes [self.rawAttributes.startIndex];
	}
	
	private var lastAttributes: Attributes {
		return self.rawAttributes [(self.lastRowIndex - 1) * self.columnCount + self.rowLength (at: self.lastRowIndex - 1) - 1];
	}
	
	private var firstRow: Row {
		return self.row (at: self.firstRowIndex);
	}
	
	private var middleRow: Row {
		return self.row (at: 0);
	}
	
	private var lastRow: Row {
		return self.row (at: self.lastRowIndex - 1);
	}
	
	fileprivate func row (at index: Int) -> Row {
		return Row (self, rawAttributes: self.rawAttributes [(index * self.columnCount) ..< (index * self.columnCount + self.rowLength (at: index))]);
	}
	
	private func rowLength (at index: Int) -> Int {
		return self.incompleteRowLengths [index] ?? self.columnCount;
	}

	private func row (containing verticalOffset: CGFloat, allowBeforeFirst: Bool = false, allowAfterLast: Bool = false) -> Row? {
		guard let validatedRows = self.validatedRows else {
			return nil;
		}

		if (allowBeforeFirst && (verticalOffset < self.row (at: validatedRows.lowerBound).frame.minY)) {
			return self.firstRow;
		}
		if (allowAfterLast && (verticalOffset >= self.row (at: validatedRows.upperBound).frame.maxY)) {
			return self.row (at: self.lastRowIndex - 1);
		}
		return self.rawAttributes.binarySearch (withGranularity: self.columnCount) {
			let row = $0.position.row;
			guard validatedRows ~= row else {
				return (row > 0) ? .orderedAscending : .orderedDescending;
			}
			
			let relativeOffset = verticalOffset - $0.frame.minY;
			if (relativeOffset < 0.0) {
				return .orderedAscending;
			} else if (relativeOffset > $0.rowHeight) {
				return .orderedDescending;
			} else {
				return .orderedSame;
			}
		}.map { self.row (at: $0 / self.columnCount) };
	}
	
	@discardableResult
	private func layoutRow (at index: Int) -> Row {
		return self.layoutRow (self.row (at: index), at: index);
	}
	
	@discardableResult
	private func layoutRow (_ row: Row) -> Row {
		return self.layoutRow (row, at: row.index);
	}
	
	private func layoutRow (_ row: Row, at index: Int) -> Row {
		if let reference = row.reference {
			let referenceFrame: CGRect;
			if let validatedRows = self.validatedRows, validatedRows ~= reference.index {
				referenceFrame = reference.frame;
			} else {
				referenceFrame = self.layoutRow (reference).frame;
			}
			if (index > 0) {
				row.recalculateFrames { _ in referenceFrame.maxY };
				self.validatedRows = (self.validatedRows?.lowerBound ?? 0) ... index;
			} else {
				row.recalculateFrames { referenceFrame.minY - $0 };
				self.validatedRows = index ... (self.validatedRows?.upperBound ?? 0);
			}
			return row;
		} else {
			let middleRow = self.middleRow
			
			if (validatedRows == nil) {
				
				middleRow.recalculateFrames { height -> CGFloat in
					
					guard visibleRowsRange == nil else {
						return 0
					}
					
					return (middleRowOrigin - height / 2).rounded (scale: self.contentScale)
				}
				
				validatedRows = 0 ... 0;
			}
			
			return middleRow
		}
	}
	
	private func makeIterator (enumeratingRowsFrom startRow: Int, to endRow: Int) -> AnyIterator <Row> {
		return self.makeIterator (enumeratingRowsFrom: startRow, through: endRow + ((endRow > startRow) ? -1 : 1));
	}
	
	private func makeIterator (enumeratingRowsFrom startRow: Int, through endRow: Int) -> AnyIterator <Row> {
		precondition (((startRow > 0) == (endRow > 0)) || (startRow == 0) || (endRow == 0), "Cannot step over middle row while enumerate rows from \(startRow) to \(endRow)");
		let advance = (startRow < endRow) ? 1 : -1;
		var rowIndex = startRow;
		return AnyIterator {
			guard rowIndex != endRow + advance else {
				return nil;
			}
			let row = self.row (at: rowIndex);
			rowIndex += advance;
			return row;
		};
	}

	private func makeIterator (enumeratingRowsFrom startRow: Row, to endRow: Row) -> AnyIterator <Row> {
		return self.makeIterator (enumeratingRowsFrom: startRow.index, to: endRow.index);
	}
	
	private func makeIterator (enumeratingRowsFrom startRow: Row, through endRow: Row) -> AnyIterator <Row> {
		return self.makeIterator (enumeratingRowsFrom: startRow.index, through: endRow.index);
	}
}

/* internal */ extension IndexPath {
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

/* fileprivate */ extension FloatingBaseArray {
	fileprivate mutating func reserveAdditionalCapacity (_ k: Int) {
		self.reserveCapacity (self.count + k);
	}
}

/* fileprivate */ extension Comparable {
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

/* fileprivate */ extension Collection where Element == CPCMonthView.AspectRatio {
	fileprivate typealias Attributes = CPCCalendarView.Layout.Attributes;
	private typealias AttributesPosition = CPCCalendarView.Layout.Storage.AttributesPosition;
	
	fileprivate func makeAttributes (
		startingAt indexPath: IndexPath,
		row: Int,
		drawCellSeparators: Bool
	) -> [Attributes] {
		return self.enumerated ().map {
			
			let result = Attributes(
				forCellWith: indexPath.offset(
					by: $0.offset
				)
			)
			
			result.position = AttributesPosition(
				row: row,
				item: $0.offset
			)
			
			result.aspectRatio = $0.element;
			
			(result.drawsLeadingSeparator, result.drawsTrailingSeparator) = (drawCellSeparators, drawCellSeparators)
			
			return result;
		};
	}
}
