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
		
		private var storage: Storage = EmptyStorage ();
		
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
		return collectionView.dequeueReusableCell (withReuseIdentifier: .cellIdentifier, for: indexPath);
	}
}

extension CPCCalendarView.Layout {
	private typealias Column = (x: CGFloat, width: CGFloat);
	
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
		return (newBounds.width - self.collectionViewContentSize.width).magnitude > 1e-3;
	}
	
	internal override func prepare () {
		let collectionView = guarantee (self.collectionView), layoutSize = CGSize (width: collectionView.bounds.width, height: collectionView.bounds.height * 5);
		let columns = self.makeColumns (self.columnCount);
		let middleRowInfo = self.makeMiddleRow (columns: columns, midY: layoutSize.height / 2);
		
		let topRows = sequence (first: middleRowInfo) { (row, months) in
			let maxY = row.map { $0.minY }.min ()!;
			guard maxY > 0.0 else {
				return nil;
			}
			return self.makeRow (before: months.lowerBound, columns: columns, maxY: maxY);
		};
		
		let bottomRows = sequence (first: middleRowInfo) { (row, months) in
			let minY = row.map { $0.maxY }.max ()!;
			guard minY < layoutSize.height else {
				return nil;
			}
			return self.makeRow (after: months.upperBound, columns: columns, minY: minY);
		};
		
		self.storage = DefaultStorage (topRows.dropFirst ().reversed () + bottomRows, contentSize: layoutSize, columnCount: columns.count);
	}
	
	private func makeColumns (_ columnCount: Int) -> [Column] {
		let insets = self.columnContentInsets, collectionView = guarantee (self.collectionView), width = collectionView.bounds.width, scale = collectionView.separatorWidth;
		let columnsX = (0 ... columnCount).map { (CGFloat ($0) * width / CGFloat (columnCount)).rounded (scale: scale) };
		return (0 ..< columnCount).map { (col: Int) in (x: columnsX [col] + insets.left, width: columnsX [col + 1] - columnsX [col] - insets.left - insets.right) };
	}
	
	private func makeMiddleRow (columns: [Column], midY: CGFloat) -> ([CGRect], months: Range <CPCMonth>) {
		let currentMonth = CPCMonth (containing: Date (), calendar: self.calendar), currentMonthIndex = currentMonth.unitOrdinalValue;
		let firstMonthOfMiddleRow = currentMonth.advanced (by: -(currentMonthIndex % columnCount)), scale = guarantee (self.collectionView).separatorWidth;
		return self.makeRow (startingWith: firstMonthOfMiddleRow, columns: columns) { (midY - $0 / 2).rounded (scale: scale) };
	}

	private func makeRow (before month: CPCMonth, columns: [Column], maxY: CGFloat) -> ([CGRect], months: Range <CPCMonth>) {
		let columnCount = self.columnCount, prevRowFirstMonth: CPCMonth;
		if (month.unitOrdinalValue < columnCount) {
			let prevYear = month.containingYear.prev, numberOfMonthsInIncompleteRow = prevYear.count % columnCount;
			prevRowFirstMonth = month.advanced (by: (numberOfMonthsInIncompleteRow == 0) ? -columnCount : -numberOfMonthsInIncompleteRow);
		} else {
			prevRowFirstMonth = month.advanced (by: -columnCount);
		}
		return self.makeRow (startingWith: prevRowFirstMonth, columns: columns) { maxY - $0 };
	}
	
	private func makeRow (after month: CPCMonth, columns: [Column], minY: CGFloat) -> ([CGRect], months: Range <CPCMonth>) {
		return self.makeRow (startingWith: month, columns: columns) { _ in minY };
	}

	private func makeRow (startingWith firstMonth: CPCMonth, columns: [Column], positioningRowUsing block: (_ rowHeight: CGFloat) -> CGFloat)
		-> ([CGRect], months: Range <CPCMonth>) {
		let scale = guarantee (self.collectionView).separatorWidth, monthsCount = min (columns.count, firstMonth.distance (to: firstMonth.containingYear.last!) + 1);
		var maxRowHeight = 0.0 as CGFloat, rowHeights = [CGFloat] ();
		rowHeights.reserveCapacity (columns.count);
		for column in columns.indices {
			guard column < monthsCount else {
				rowHeights.append (0.0);
				continue;
			}
			
			let month = firstMonth.advanced (by: column);
			let viewAttributes = CPCMonthView.LayoutAttributes (month: month, separatorWidth: scale, titleFont: .systemFont (ofSize: 15), titleMargins: .zero); // TODO
			let viewHeight = CPCMonthView.heightThatFits (width: columns [column].width, with: viewAttributes);
			rowHeights.append (viewHeight);
			maxRowHeight = max (maxRowHeight, viewHeight);
		};
		
		let rowY = block (maxRowHeight);
		let frames = columns.indices.map { CGRect (x: columns [$0].x, y: rowY, width: columns [$0].width, height: rowHeights [$0]) };
		return (frames, months: firstMonth ..< firstMonth.advanced (by: monthsCount));
	}
}

private protocol Storage {
	typealias Attributes = CPCCalendarView.Layout.Attributes;
	
	var contentSize: CGSize { get }
	var sectionCount: Int { get }
	
	subscript (rect: CGRect) -> [Attributes]? { get };
	subscript (indexPath: IndexPath) -> Attributes? { get };
	
	func numberOfItems (in section: Int) -> Int;
}

extension CPCCalendarView.Layout {
	fileprivate struct EmptyStorage {}

	fileprivate struct DefaultStorage {
		fileprivate let contentSize: CGSize;
		
		private let attributes: [Attributes];
		private let firstMonth: CPCMonth;
		private let columnCount: Int;
		
		fileprivate init (_ rows: [([CGRect], months: Range <CPCMonth>)], contentSize: CGSize, columnCount: Int) {
			guard let firstMonth = rows.first?.months.lowerBound else {
				preconditionFailure ("\(DefaultStorage.self) can not be initialized with empty attributes array, use \(EmptyStorage.self) instead");
			}
			
			var attributes = [Attributes] ();
			attributes.reserveCapacity (rows.count * columnCount);
			for section in rows.indices {
				let (frames, months) = rows [section], firstMonth = months.lowerBound, monthsCount = months.count;
				attributes.append (contentsOf: frames.indices.map {
					let attrs = Attributes (forCellWith: IndexPath (item: $0, section: section));
					if ($0 < monthsCount) {
						attrs.month = firstMonth.advanced (by: $0);
						attrs.frame = frames [$0];
					}
					return attrs;
				});
			}
			
			self.contentSize = contentSize;
			self.firstMonth = firstMonth;
			self.columnCount = columnCount;
			self.attributes = attributes;
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
			return Array (self.attributes [rows.lowerBound * columnCount ..< rows.upperBound * columnCount]);
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
