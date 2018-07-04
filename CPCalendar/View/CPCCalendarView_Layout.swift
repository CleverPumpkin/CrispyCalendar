//
//  CPCCalendarView_Layout.swift
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

extension CPCCalendarView {
	internal class Layout: UICollectionViewLayout {
		internal var columnCount = 1 {
			didSet {
				self.invalidateLayout (); // TODO
			}
		}
		
		internal var columnContentInsets = UIEdgeInsets.zero {
			didSet {
				self.invalidateLayout (); // TODO
			}
		}
		
		internal let calendar: CPCCalendarWrapper;
		internal let monthViewsManager = CPCMonthViewsManager ();
		
		private var storage: Storage = EmptyStorage ();
		private var currentInvalidationContext: InvalidationContext?;
		private var isReloadingDataAfterInsertingAdditionalRows = false;
		
		internal init (calendar: CPCCalendarWrapper) {
			self.calendar = calendar;
			super.init ();
		}
		
		internal required init? (coder aDecoder: NSCoder) {
			self.calendar = Calendar.current.wrapped ();
			super.init (coder: aDecoder);
		}
	}
}

extension CPCCalendarView.Layout: UICollectionViewDataSource {
	internal func prepare (collectionView: UICollectionView) {
		collectionView.register (CPCCalendarView.Cell.self, forCellWithReuseIdentifier: .cellIdentifier);
		collectionView.dataSource = self;
	}
	
	internal func numberOfSections (in collectionView: UICollectionView) -> Int {
		return self.storage.sectionCount;
	}
	
	internal func collectionView (_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return self.storage.numberOfItems (in: section);
	}
	
	internal func collectionView (_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell (withReuseIdentifier: .cellIdentifier, for: indexPath) as! CPCCalendarView.Cell;
		cell.monthViewsManager = self.monthViewsManager;
		return cell;
	}
}

extension CPCCalendarView.Layout: UICollectionViewDelegate {
	
}

extension CPCCalendarView.Layout {
	fileprivate typealias RowInfo = ([CGRect], months: Range <CPCMonth>);
	private typealias Column = (x: CGFloat, width: CGFloat);
	
	internal override class var layoutAttributesClass: AnyClass {
		return Attributes.self;
	}
	
	internal override class var invalidationContextClass: AnyClass {
		return InvalidationContext.self;
	}
	
	internal override var collectionViewContentSize: CGSize {
		return self.storage.contentSize;
	}
	
	internal override func layoutAttributesForElements (in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
		return self.storage [rect];
	}
	
	internal override func layoutAttributesForItem (at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
		return self.storage [indexPath];
	}
	
	internal override func shouldInvalidateLayout (forBoundsChange newBounds: CGRect) -> Bool {
		if
			let invalidationContext = self.currentInvalidationContext,
			let collectionView = self.collectionView,
			let verticalOffset = invalidationContext.verticalOffset,
			((newBounds.minY - collectionView.bounds.minY).magnitude - verticalOffset.magnitude).magnitude < 1e-3 {
			return false;
		}
		
		guard let invalidationContext = InvalidationContext.forBoundsChange (newBounds, currentStorage: self.storage) else {
			return false;
		}
		self.currentInvalidationContext = invalidationContext;
		return true;
	}
	
	internal override func invalidationContext (forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
		return self.currentInvalidationContext ?? super.invalidationContext (forBoundsChange: newBounds);
	}
	
	internal override func prepare () {
		if let verticalOffset = self.currentInvalidationContext?.verticalOffset, let storage = self.storage as? DefaultStorage {
			self.performScrollLayoutCalculations (verticalOffset: verticalOffset, storage: storage);
		} else if self.isReloadingDataAfterInsertingAdditionalRows {
			return self.isReloadingDataAfterInsertingAdditionalRows = false;
		} else {
			self.performInitialLayoutCalculations ();
		}
	}
	
	private func performInitialLayoutCalculations () {
		let collectionView = guarantee (self.collectionView), layoutSize = CGSize (width: collectionView.bounds.width, height: collectionView.bounds.height * 5.0);
		let columns = self.makeColumns (self.columnCount);
		let middleRowInfo = self.makeMiddleRow (columns: columns, midY: layoutSize.height / 2);
		let topRows = self.makeRows (before: middleRowInfo, columns: columns) { rowFrame, months in rowFrame.minY < 0.0 };
		let bottomRows = self.makeRows (after: middleRowInfo, columns: columns) { rowFrame, months in rowFrame.maxY > layoutSize.height };
		self.storage = DefaultStorage (topRows + middleRowInfo + bottomRows, contentSize: layoutSize);
		DispatchQueue.main.async {
			collectionView.scrollToItem (at: IndexPath (item: 0, section: (self.storage.sectionCount + 1) / 2), at: .centeredVertically, animated: false);
		};
	}
	
	private func performScrollLayoutCalculations (verticalOffset: CGFloat, storage: DefaultStorage) {
		let collectionView = guarantee (self.collectionView), columns = self.makeColumns (self.columnCount), updatedStorage: Storage;
		if (verticalOffset > 0.0) {
			let insertedRows = self.makeRows (before: storage.firstRowInfo, columns: columns) { rowFrame, months in rowFrame.minY < -verticalOffset };
			updatedStorage = storage.prepending (insertedRows, verticalOffset: verticalOffset);
		} else {
			let layoutSize = storage.contentSize;
			let insertedRows = self.makeRows (after: storage.lastRowInfo, columns: columns) { rowFrame, months in rowFrame.maxY > layoutSize.height - verticalOffset };
			updatedStorage = storage.appending (insertedRows, verticalOffset: verticalOffset);
		}
		
		self.currentInvalidationContext = nil;
		self.storage = updatedStorage;
		collectionView.reloadData ();
	}
	
	private func makeColumns (_ columnCount: Int) -> [Column] {
		let insets = self.columnContentInsets, collectionView = guarantee (self.collectionView), width = collectionView.bounds.width, scale = collectionView.separatorWidth;
		let columnsX = (0 ... columnCount).map { (CGFloat ($0) * width / CGFloat (columnCount)).rounded (scale: scale) };
		return (0 ..< columnCount).map { (col: Int) in (x: columnsX [col] + insets.left, width: columnsX [col + 1] - columnsX [col] - insets.left - insets.right) };
	}
	
	private func makeRows (before rowInfo: RowInfo, columns: [Column], stop predicate: @escaping (CGRect, Range <CPCMonth>) -> Bool) -> [RowInfo] {
		return sequence (first: rowInfo) { (row, months) in
			let rowFrame = row.reduce (.null, CGRect.union);
			guard !predicate (rowFrame, months) else {
				return nil;
			}
			return self.makeRow (before: months.lowerBound, columns: columns, maxY: rowFrame.minY);
		}.dropFirst ().reversed ();
	}
	
	private func makeRows (after rowInfo: RowInfo, columns: [Column], stop predicate: @escaping (CGRect, Range <CPCMonth>) -> Bool) -> [RowInfo] {
		return Array (sequence (first: rowInfo) { (row, months) in
			let rowFrame = row.reduce (.null, CGRect.union);
			guard !predicate (rowFrame, months) else {
				return nil;
			}
			return self.makeRow (after: months.upperBound, columns: columns, minY: rowFrame.maxY);
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
		return (frames, months: firstMonth ..< firstMonth.advanced (by: monthsCount));
	}
}

extension CPCCalendarView.Layout {
	internal final class Attributes: UICollectionViewLayoutAttributes {
		internal var month: CPCMonth?;
		
		internal override func copy (with zone: NSZone? = nil) -> Any {
			let attributes = super.copy (with: zone);
			guard let result = attributes as? Attributes else {
				return attributes;
			}
			result.month = self.month;
			return result;
		}
	}
	
	fileprivate class InvalidationContext: UICollectionViewLayoutInvalidationContext {
		fileprivate let verticalOffset: CGFloat?;
		
		fileprivate override var invalidateEverything: Bool {
			return self.verticalOffset == nil;
		}
		
		fileprivate override var invalidateDataSourceCounts: Bool {
			return true;
		}
		
		fileprivate static func forBoundsChange (_ newBounds: CGRect, currentStorage: Storage) -> InvalidationContext? {
			let contentSize = currentStorage.contentSize;
			guard currentStorage.sectionCount > 0, (newBounds.width - currentStorage.contentSize.width).magnitude < 1e-3 else {
				return InvalidationContext ();
			}
			
			guard (newBounds.minY > newBounds.height) else {
				return InvalidationContext (verticalOffset: 5.0 * newBounds.height);
			}
			guard (newBounds.maxY < contentSize.height - newBounds.height) else {
				return InvalidationContext (verticalOffset: -5.0 * newBounds.height);
			}
			
			return nil;
		}
		
		fileprivate override init () {
			self.verticalOffset = nil;
			super.init ();
		}
		
		private init (verticalOffset: CGFloat) {
			self.verticalOffset = verticalOffset;
			super.init ();
			self.contentSizeAdjustment = CGSize (width: 0.0, height: verticalOffset.magnitude);
			self.contentOffsetAdjustment = CGPoint (x: 0.0, y: max (verticalOffset, 0.0));
		}
	}
}

private protocol Storage {
	typealias Attributes = CPCCalendarView.Layout.Attributes;
	
	var contentSize: CGSize { get };
	var sectionCount: Int { get };
	
	subscript (rect: CGRect) -> [Attributes]? { get };
	subscript (indexPath: IndexPath) -> Attributes? { get };
	
	func numberOfItems (in section: Int) -> Int;
}

extension CPCCalendarView.Layout {
	fileprivate struct EmptyStorage {}

	fileprivate struct DefaultStorage {
		fileprivate let contentSize: CGSize;
		fileprivate let firstRowInfo: RowInfo;
		fileprivate let lastRowInfo: RowInfo;
		
		private let attributes: [Attributes];
		
		private var columnCount: Int {
			return self.firstRowInfo.0.count;
		}
		
		private static func attributes (for calculatedRows: [RowInfo], columnCount: Int, sectionForFirstRow: Int) -> [Attributes] {
			var attributes = [Attributes] ();
			attributes.reserveCapacity (calculatedRows.count * columnCount);
			for section in calculatedRows.indices {
				let (frames, months) = calculatedRows [section], firstMonth = months.lowerBound, monthsCount = months.count;
				attributes.append (contentsOf: frames.indices.map {
					let attrs = Attributes (forCellWith: IndexPath (item: $0, section: sectionForFirstRow + section));
					if ($0 < monthsCount) {
						attrs.month = firstMonth.advanced (by: $0);
						attrs.frame = frames [$0];
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
				result.month = $0.month;
				return result;
			};
		}
		
		private static func rowInfo (_ rowInfo: RowInfo, offsetBy verticalOffset: CGFloat) -> RowInfo {
			return (rowInfo.0.map { $0.offsetBy (dx: 0.0, dy: verticalOffset) }, months: rowInfo.months);
		}

		fileprivate init (_ rows: [RowInfo], contentSize: CGSize) {
			guard let firstRowInfo = rows.first, let lastRowInfo = rows.last else {
				preconditionFailure ("\(DefaultStorage.self) can not be initialized with empty attributes array, use \(EmptyStorage.self) instead");
			}
			
			self.init (
				for: DefaultStorage.attributes (for: rows, columnCount: firstRowInfo.0.count, sectionForFirstRow: 0),
				edgeRows: (first: firstRowInfo, last: lastRowInfo),
				contentSize: contentSize
			);
		}
		
		private init (for attributes: [Attributes], edgeRows: (first: RowInfo, last: RowInfo), contentSize: CGSize) {
			self.contentSize = contentSize;
			self.firstRowInfo = edgeRows.first;
			self.lastRowInfo = edgeRows.last;
			self.attributes = attributes;
		}
		
		fileprivate func prepending (_ rows: [RowInfo], verticalOffset: CGFloat) -> DefaultStorage {
			guard let firstRowInfo = rows.first else {
				return self;
			}
			
			let prependedAttributes = DefaultStorage.attributes (for: rows, columnCount: self.columnCount, sectionForFirstRow: 0);
			let offsetExistingAttributes = prependedAttributes + DefaultStorage.attributes (self.attributes, offsetBy: rows.count / self.columnCount);
			
			return DefaultStorage (
				for: DefaultStorage.attributes (prependedAttributes + offsetExistingAttributes, offsetBy: verticalOffset),
				edgeRows: (first: DefaultStorage.rowInfo (firstRowInfo, offsetBy: verticalOffset), last:  DefaultStorage.rowInfo (self.lastRowInfo, offsetBy: verticalOffset)),
				contentSize: self.contentSize.adding (height: verticalOffset.magnitude)
			);
		}
		
		fileprivate func appending (_ rows: [RowInfo], verticalOffset: CGFloat) -> DefaultStorage {
			guard let lastRowInfo = rows.last else {
				return self;
			}
			let appendedAttributes = DefaultStorage.attributes (for: rows, columnCount: self.columnCount, sectionForFirstRow: self.sectionCount);
			return DefaultStorage (
				for: self.attributes + appendedAttributes,
				edgeRows: (first: self.firstRowInfo, last: lastRowInfo),
				contentSize: self.contentSize.adding (height: verticalOffset.magnitude)
			);
		}
	}
}

extension CPCCalendarView.Layout.EmptyStorage: Storage {
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

extension CPCCalendarView.Layout.DefaultStorage: Storage {
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
		
		return self.attributes.withUnsafeBufferPointer {
			let base = $0.baseAddress!;
			return base.distance (to: bsearch_b (nil, UnsafeRawPointer (base), rowCount, MemoryLayout <Attributes>.stride * self.columnCount) { _, attributes in
				let frame = attributes!.assumingMemoryBound (to: Attributes.self).pointee.frame;
				if (y < frame.minY) {
					return -1;
				} else if (y > frame.maxY) {
					return 1;
				} else {
					return 0;
				}
			}.assumingMemoryBound (to: Attributes.self));
		};
	}
}

fileprivate extension String {
	fileprivate static let cellIdentifier = "cellID";
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
