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

internal extension CPCCalendarView.Layout {
	internal typealias Storage = CPCCalendarViewLayoutStorage;
	private typealias Column = (x: CGFloat, width: CGFloat);
	
	internal static func makeEmptyStorage () -> Storage {
		return EmptyStorage ();
	}
	
	internal func allowedDatesRangeDidChange () {
		
	}
	
	internal func prepareUpdatedLayout (current storage: Storage, invalidationContext: InvalidationContext?) -> Storage {
		guard let verticalOffset = invalidationContext?.verticalOffset, let storage = storage as? DefaultStorage else {
			return self.performInitialLayoutCalculations ();
		}
		return self.performScrollLayoutCalculations (verticalOffset: verticalOffset, withCurrent: storage);
	}
	
	internal func performPostUpdateActions (for layoutStorage: Storage) {
		if let storage = layoutStorage as? DefaultStorage, !storage.isInitial {
			self.collectionView?.reloadData ();
		} else {
			DispatchQueue.main.async {
				self.collectionView?.scrollToItem (at: IndexPath (item: 0, section: (layoutStorage.sectionCount + 1) / 2), at: .centeredVertically, animated: false);
			};
		}
	}
	
	private func performInitialLayoutCalculations () -> Storage {
		let collectionView = guarantee (self.collectionView), layoutSize = CGSize (width: collectionView.bounds.width, height: collectionView.bounds.height * 5.0);
		let columns = self.makeColumns (self.columnCount);
		let middleRowInfo = self.makeMiddleRow (columns: columns, midY: layoutSize.height / 2);
		let topRows = self.makeRows (before: middleRowInfo, columns: columns) { rowFrame, months in rowFrame.minY < 0.0 };
		let bottomRows = self.makeRows (after: middleRowInfo, columns: columns) { rowFrame, months in rowFrame.maxY > layoutSize.height };
		return DefaultStorage (topRows + middleRowInfo + bottomRows, contentSize: layoutSize);
	}
	
	private func performScrollLayoutCalculations (verticalOffset: CGFloat, withCurrent storage: Storage) -> Storage {
		guard let storage = storage as? DefaultStorage else {
			fatalError ("[CPCalendar] Internal error: cannot update empty storage");
		}
		
		let columns = self.makeColumns (self.columnCount);
		if (verticalOffset > 0.0) {
			let insertedRows = self.makeRows (before: storage.firstRowInfo, columns: columns) { rowFrame, months in rowFrame.minY < -verticalOffset };
			return storage.prepending (insertedRows, verticalOffset: verticalOffset);
		} else {
			let layoutSize = storage.contentSize;
			let insertedRows = self.makeRows (after: storage.lastRowInfo, columns: columns) { rowFrame, months in rowFrame.maxY > layoutSize.height - verticalOffset };
			return storage.appending (insertedRows, verticalOffset: verticalOffset);
		}
	}

	private func makeColumns (_ columnCount: Int) -> [Column] {
		let insets = self.columnContentInsets, collectionView = guarantee (self.collectionView), width = collectionView.bounds.width, scale = collectionView.separatorWidth;
		let columnsX = (0 ... columnCount).map { (CGFloat ($0) * width / CGFloat (columnCount)).rounded (scale: scale) };
		return (0 ..< columnCount).map { (col: Int) in (x: columnsX [col] + insets.left, width: columnsX [col + 1] - columnsX [col] - insets.left - insets.right) };
	}
	
	private func makeRows (before rowInfo: RowInfo, columns: [Column], stop predicate: @escaping (CGRect, Range <CPCMonth>) -> Bool) -> [RowInfo] {
		return sequence (first: rowInfo) {
			let rowFrame = $0.frame, months = $0.months;
			return predicate (rowFrame, months) ? nil : self.makeRow (before: months.lowerBound, columns: columns, maxY: rowFrame.minY);
		}.dropFirst ().reversed ();
	}
	
	private func makeRows (after rowInfo: RowInfo, columns: [Column], stop predicate: @escaping (CGRect, Range <CPCMonth>) -> Bool) -> [RowInfo] {
		return Array (sequence (first: rowInfo) {
			let rowFrame = $0.frame, months = $0.months;
			return predicate (rowFrame, months) ? nil : self.makeRow (after: months.upperBound, columns: columns, minY: rowFrame.maxY);
		}.dropFirst ());
	}
	
	private func makeMiddleRow (columns: [Column], midY: CGFloat) -> RowInfo {
		let currentMonth = CPCMonth (containing: Date (), calendar: self.calendar), currentMonthIndex = currentMonth.unitOrdinalValue;
		let firstMonthOfMiddleRow = currentMonth.advanced (by: -(currentMonthIndex % columnCount)), scale = guarantee (self.collectionView).separatorWidth;
		return self.makeRow (startingWith: firstMonthOfMiddleRow, columns: columns) { (midY - $0 / 2).rounded (scale: scale) };
	}

	private func makeRow (before month: CPCMonth, columns: [Column], maxY: CGFloat) -> RowInfo {
		let columnCount = self.columnCount, prevRowFirstMonth: CPCMonth;
		if (month.unitOrdinalValue < columnCount) {
			let prevYear = month.containingYear.prev, numberOfMonthsInIncompleteRow = prevYear.count % columnCount;
			prevRowFirstMonth = month.advanced (by: (numberOfMonthsInIncompleteRow == 0) ? -columnCount : -numberOfMonthsInIncompleteRow);
		} else {
			prevRowFirstMonth = month.advanced (by: -columnCount);
		}
		return self.makeRow (startingWith: prevRowFirstMonth, columns: columns) { maxY - $0 };
	}
	
	private func makeRow (after month: CPCMonth, columns: [Column], minY: CGFloat) -> RowInfo {
		return self.makeRow (startingWith: month, columns: columns) { _ in minY };
	}

	private func makeRow (startingWith firstMonth: CPCMonth, columns: [Column], positioningRowUsing block: (_ rowHeight: CGFloat) -> CGFloat) -> RowInfo {
		let scale = guarantee (self.collectionView).separatorWidth, monthsCount = min (columns.count, firstMonth.distance (to: firstMonth.containingYear.last!) + 1);
		var maxRowHeight = 0.0 as CGFloat, rowHeights = [CGFloat] ();
		rowHeights.reserveCapacity (columns.count);
		for column in columns.indices {
			guard column < monthsCount else {
				rowHeights.append (0.0);
				continue;
			}
			
			let month = firstMonth.advanced (by: column), viewsMgr = self.monthViewsManager, titleFont = viewsMgr.titleFont, titleMargins = viewsMgr.titleMargins;
			let viewAttributes = CPCMonthView.LayoutAttributes (month: month, separatorWidth: scale, titleFont: titleFont, titleMargins: titleMargins);
			let viewHeight = CPCMonthView.heightThatFits (width: columns [column].width, with: viewAttributes);
			rowHeights.append (viewHeight);
			maxRowHeight = max (maxRowHeight, viewHeight);
		};
		
		let rowY = block (maxRowHeight);
		let frames = columns.indices.map { CGRect (x: columns [$0].x, y: rowY, width: columns [$0].width, height: rowHeights [$0]) };
		return RowInfo (frames: frames, height: maxRowHeight, months: firstMonth ..< firstMonth.advanced (by: monthsCount));
	}
}

internal protocol CPCCalendarViewLayoutStorage {
	typealias Attributes = CPCCalendarView.Layout.Attributes;
	
	var contentSize: CGSize { get };
	var sectionCount: Int { get };
	
	subscript (rect: CGRect) -> [Attributes]? { get };
	subscript (indexPath: IndexPath) -> Attributes? { get };
	
	func numberOfItems (in section: Int) -> Int;
}

extension CPCCalendarView.Layout {
	fileprivate struct RowInfo {
		fileprivate let frames: [CGRect];
		fileprivate let height: CGFloat;
		fileprivate let months: Range <CPCMonth>;
		
		fileprivate var frame: CGRect {
			guard let first = self.frames.first, let last = self.frames.last else {
				return .null;
			}
			return CGRect (x: first.minX, y: first.minY, width: last.maxX - first.minX, height: self.height);
		}
		
		fileprivate func offsetBy (verticalOffset: CGFloat) -> RowInfo {
			return RowInfo (frames: self.frames.map { $0.offsetBy (dx: 0.0, dy: verticalOffset) }, height: self.height, months: self.months);
		}
	}

	fileprivate struct EmptyStorage {}

	fileprivate struct DefaultStorage {
		fileprivate let contentSize: CGSize;
		fileprivate let isInitial: Bool;

		fileprivate var firstRowInfo: RowInfo {
			return self.edgeRows.first;
		}
		fileprivate var lastRowInfo: RowInfo {
			return self.edgeRows.last;
		}

		private let attributes: [Attributes];
		private let edgeRows: (first: RowInfo, last: RowInfo);
		
		private var columnCount: Int {
			return self.edgeRows.first.frames.count;
		}
		
		private static func attributes (for calculatedRows: [RowInfo], columnCount: Int, sectionForFirstRow: Int) -> [Attributes] {
			var attributes = [Attributes] ();
			attributes.reserveCapacity (calculatedRows.count * columnCount);
			for section in calculatedRows.indices {
				let row = calculatedRows [section], months = row.months, frames = row.frames, height = row.height, firstMonth = months.lowerBound, monthsCount = months.count;
				attributes.append (contentsOf: frames.indices.map {
					let attrs = Attributes (forCellWith: IndexPath (item: $0, section: sectionForFirstRow + section));
					if ($0 < monthsCount) {
						attrs.frame = frames [$0];
						attrs.month = firstMonth.advanced (by: $0);
						attrs.rowHeight = height;
					}
					return attrs;
				});
			}
			return attributes;
		}
		
		private static func attributes (_ attributes: [Attributes], offsetBy verticalOffset: CGFloat) -> [Attributes] {
			return attributes.map {
				let result = $0.copy () as! Attributes;
				result.frame = result.frame.offsetBy (dx: 0.0, dy: verticalOffset);
				return result;
			};
		}
		
		private static func attributes (_ attributes: [Attributes], offsetBy rowCount: Int) -> [Attributes] {
			return attributes.map {
				let indexPath = $0.indexPath;
				let result = Attributes (forCellWith: IndexPath (item: indexPath.item, section: indexPath.section + rowCount));
				result.frame = $0.frame;
				result.rowHeight = $0.rowHeight;
				result.month = $0.month;
				return result;
			};
		}
		
		fileprivate init (_ rows: [RowInfo], contentSize: CGSize) {
			guard let firstRowInfo = rows.first, let lastRowInfo = rows.last else {
				preconditionFailure ("\(DefaultStorage.self) can not be initialized with empty attributes array, use \(EmptyStorage.self) instead");
			}
			
			let attributes = DefaultStorage.attributes (for: rows, columnCount: firstRowInfo.frames.count, sectionForFirstRow: 0);
			self.init (for: attributes, edgeRows: (firstRowInfo, lastRowInfo), contentSize: contentSize, isInitial: true);
		}
		
		private init (for attributes: [Attributes], edgeRows: (first: RowInfo, last: RowInfo), contentSize: CGSize, isInitial: Bool = false) {
			self.contentSize = contentSize;
			self.isInitial = isInitial;
			self.attributes = attributes;
			self.edgeRows = edgeRows;
		}
		
		fileprivate func prepending (_ rows: [RowInfo], verticalOffset: CGFloat) -> DefaultStorage {
			guard let firstRowInfo = rows.first else {
				return self;
			}
			
			let prependedAttributes = DefaultStorage.attributes (for: rows, columnCount: self.columnCount, sectionForFirstRow: 0);
			let offsetExistingAttributes = prependedAttributes + DefaultStorage.attributes (self.attributes, offsetBy: rows.count / self.columnCount);
			
			return DefaultStorage (
				for: DefaultStorage.attributes (prependedAttributes + offsetExistingAttributes, offsetBy: verticalOffset),
				edgeRows: (firstRowInfo.offsetBy (verticalOffset: verticalOffset), self.lastRowInfo.offsetBy (verticalOffset: verticalOffset)),
				contentSize: self.contentSize.adding (height: verticalOffset.magnitude)
			);
		}
		
		fileprivate func appending (_ rows: [RowInfo], verticalOffset: CGFloat) -> DefaultStorage {
			guard let lastRowInfo = rows.last else {
				return self;
			}
			let appendedAttributes = DefaultStorage.attributes (for: rows, columnCount: self.columnCount, sectionForFirstRow: self.sectionCount);
			let contentSize = self.contentSize.adding (height: verticalOffset.magnitude);
			return DefaultStorage (for: self.attributes + appendedAttributes, edgeRows: (self.firstRowInfo, lastRowInfo), contentSize: contentSize);
		}
	}
}

extension CPCCalendarView.Layout.EmptyStorage: CPCCalendarViewLayoutStorage {
	fileprivate var sectionCount: Int {
		return 0;
	}
	
	fileprivate var contentSize: CGSize {
		return .zero;
	}
	
	fileprivate var months: Range <CPCMonth> {
		return .current ..< .current;
	}
	
	fileprivate subscript (rect: CGRect) -> [Attributes]? {
		return nil;
	}
	
	fileprivate subscript (indexPath: IndexPath) -> Attributes? {
		return nil;
	}

	fileprivate func numberOfItems (in section: Int) -> Int {
		fatalError ("Not implemented");
	}
}

extension CPCCalendarView.Layout.DefaultStorage: CPCCalendarViewLayoutStorage {
	fileprivate var sectionCount: Int {
		return self.attributes.count / self.columnCount;
	}
	
	fileprivate subscript (rect: CGRect) -> [Attributes]? {
		let columnCount = self.columnCount;
		let columns = self.column (for: rect.minX) ... self.column (for: rect.maxX);
		let rows = self.row (for: rect.minY) ... self.row (for: rect.maxY);
		
		guard (columns.count != columnCount) else {
			return Array (self.attributes [rows.lowerBound * columnCount ..< (rows.upperBound + 1) * columnCount]);
		}
		
		var result = [Attributes] ();
		result.reserveCapacity (columns.count * rows.count);
		for row in rows {
			let rowFirstIndex = row * columnCount;
			result.append (contentsOf: self.attributes [rowFirstIndex ..< rowFirstIndex + columnCount].filter { $0.month != nil });
		}
		return result;
	}
	
	fileprivate subscript (indexPath: IndexPath) -> Attributes? {
		let attributes = self.attributes [indexPath.section * self.columnCount + indexPath.item];
		return ((attributes.month != nil) ? attributes : nil);
	}
	
	fileprivate func numberOfItems (in section: Int) -> Int {
		let sectionAttributes = self.attributes [self.columnCount * section ..< self.columnCount * (section + 1)];
		return sectionAttributes.reduce (into: 0) {
			if ($1.month != nil) {
				$0 += 1;
			};
		};
	}
	
	private func column (for x: CGFloat) -> Int {
		guard x > 0.0 else {
			return 0;
		}
		
		let width = self.contentSize.width, count = self.columnCount;
		guard x < width else {
			return count - 1;
		}
		
		return (x / width * CGFloat (count)).integerRounded (.down);
	}
	
	private func row (for y: CGFloat) -> Int {
		guard y > 0.0 else {
			return 0;
		}
		
		let attributes = self.attributes, rowCount = attributes.count / self.columnCount;
		guard y < self.contentSize.height else {
			return rowCount - 1;
		}
		
		return self.attributes.binarySearch (withGranularity: self.columnCount) {
			let rowMinY = $0.frame.minY;
			if (y < rowMinY) {
				return .orderedAscending;
			}
			
			let rowMaxY = rowMinY + $0.rowHeight;
			if (y > rowMaxY) {
				return .orderedDescending;
			} else {
				return .orderedSame;
			}
		}!;
	}
}

fileprivate extension Array {
	fileprivate func binarySearch (withGranularity granularity: Index = 1, using comparator: (Element) -> ComparisonResult) -> Index? {
		return self.withUnsafeBufferPointer {
			let base = $0.baseAddress!;
			return withoutActuallyEscaping (comparator) { comparator in
				guard let found = bsearch_b (nil, UnsafeRawPointer (base), self.count, MemoryLayout <Element>.stride * granularity, { _, element in
					return Int32 (comparator (element!.assumingMemoryBound (to: Element.self).pointee).rawValue);
				}) else {
					return nil;
				};
				return base.distance (to: found.assumingMemoryBound (to: Element.self));
			}
		};
	}
}

fileprivate extension Array where Element: Comparable {
	fileprivate func binarySearch (of element: Element) -> Index? {
		return self.binarySearch {
			if ($0 < element) {
				return .orderedAscending;
			} else if ($0 > element) {
				return .orderedDescending;
			} else {
				return .orderedSame;
			}
		};
	}
}

fileprivate extension CGSize {
	fileprivate func adding (height: CGFloat) -> CGSize {
		return CGSize (width: self.width, height: self.height + height);
	}
}

fileprivate extension CGRect {
	fileprivate static func union (lhs: CGRect, rhs: CGRect) -> CGRect {
		return lhs.union (rhs);
	}
}
