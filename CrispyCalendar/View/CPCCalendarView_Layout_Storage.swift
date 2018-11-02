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
			internal var contentScale = 1.0 / UIScreen.main.nativeScale;
			internal var middleRowOrigin: CGFloat;
		}
		
		internal let columnCount: Int;
		
		fileprivate var contentGuideLeading: CGFloat {
			return self.contentGuide.lowerBound;
		}
		
		fileprivate var contentGuideWidth: CGFloat {
			return self.contentGuide.upperBound - self.contentGuide.lowerBound;
		}
		
		fileprivate var columnWidth: CGFloat {
			return self.contentGuideWidth / CGFloat (self.columnCount);
		}
		
		fileprivate var contentScale: CGFloat;
		
		private var contentGuide: Range <CGFloat>;
		private var rawAttributes: FloatingBaseArray <Attributes>;
		private var incompleteRowLengths = [Int: Int] ();
		
		internal init <C> (middleRowData: C, layoutInfo: LayoutInfo) where C: Collection, C.Element == (IndexPath, AspectRatio) {
			self.columnCount = layoutInfo.columnCount;
			self.contentGuide = layoutInfo.contentGuide;
			self.contentScale = layoutInfo.contentScale;
			
			self.rawAttributes = FloatingBaseArray ();
			self.rawAttributes.reserveCapacity (self.columnCount);
			for (indexPath, aspectRatio) in middleRowData {
				let attributes = Attributes (forCellWith: indexPath);
				attributes.aspectRatio = aspectRatio;
				self.rawAttributes.append (attributes);
			}
			if (middleRowData.count < self.columnCount) {
				self.incompleteRowLengths [0] = middleRowData.count;
				self.rawAttributes.append (contentsOf: ((middleRowData.count % self.columnCount) ..< self.columnCount).map { _ in .invalid });
			}
			
			let row = Row (self, rawAttributes: self.rawAttributes [...]);
			row.recalculateFrames { (layoutInfo.middleRowOrigin - $0 / 2).rounded (scale: layoutInfo.contentScale) };
		}
		
		internal func prependRow <C> (_ aspectRatioData: C) where C: Collection, C.Element == AspectRatio {
			self.prependRows (CollectionOfOne (aspectRatioData));
		}

		internal func appendRow <C> (_ aspectRatioData: C) where C: Collection, C.Element == AspectRatio {
			self.appendRows (CollectionOfOne (aspectRatioData));
		}
		
		internal func prependRows <C> (_ rowsData: C) where C: Collection, C.Element: Collection, C.Element.Element == AspectRatio {
			self.reserveStorageCapacity (for: rowsData);
			var indexPath: IndexPath = [0, self.firstIndexPath.item - 1];
			for rowData in rowsData {
				if (rowData.count < self.columnCount) {
					self.rawAttributes.prepend (contentsOf: (rowData.count ..< self.columnCount).map { _ in .invalid });
					self.incompleteRowLengths [indexPath.item] = rowData.count;
				}
				self.rawAttributes.prepend (contentsOf: rowData.map {
					let result = Attributes (forCellWith: indexPath);
					indexPath.item -= 1;
					result.aspectRatio = $0;
					return result;
				});
				self.firstRow.recalculateFrames { self.rowAt (index: self.firstRowIndex + 1).frame.minY - $0 };
			}
		}
		
		internal func appendRows <C> (_ rowsData: C) where C: Collection, C.Element: Collection, C.Element.Element == AspectRatio {
			self.reserveStorageCapacity (for: rowsData);
			var indexPath: IndexPath = [0, self.lastIndexPath.item + 1];
			for rowData in rowsData {
				self.rawAttributes.append (contentsOf: rowData.map {
					let result = Attributes (forCellWith: indexPath);
					indexPath.item += 1;
					result.aspectRatio = $0;
					return result;
				});
				if (rowData.count < self.columnCount) {
					self.rawAttributes.append (contentsOf: (rowData.count ..< self.columnCount).map { _ in .invalid });
					self.incompleteRowLengths [indexPath.item] = rowData.count;
				}
				self.rowAt (index: self.lastRowIndex - 1).recalculateFrames { _ in self.rowAt (index: self.lastRowIndex - 2).frame.maxY };
			}
		}
		
		private func reserveStorageCapacity <C> (for rowsData: C) where C: Collection, C.Element: Collection, C.Element.Element == AspectRatio {
			self.rawAttributes.reserveAdditionalCapacity (rowsData.reduce (into: 0) { $0 += $1.count.nextDividable (by: self.columnCount) });
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
			let rowOrigin = layoutBlock (rowHeight);
			for (height, attrs) in zip (itemHeights, self.rawAttributes) {
				attrs.frame = CGRect (x: columnsStart, y: rowOrigin, width: columnWidth.rounded (scale: scale), height: height.rounded (.up, scale: scale))
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
	
	internal subscript (indexPath: IndexPath) -> CPCCalendarView.Layout.Attributes? {
		guard (self.firstIndexPath ... self.lastIndexPath) ~= indexPath else {
			return nil;
		}
		return self.rawAttributes [indexPath.item - self.rawAttributes [0].indexPath.item];
	}

	internal subscript (rect: CGRect) -> [CPCCalendarView.Layout.Attributes] {
		guard let topRow = self.row (containing: rect.minY, allowBeforeFirst: true), let bottomRow = self.row (containing: rect.maxY, allowAfterLast: true) else {
			return [];
		}
		return Array (self.rawAttributes [topRow.index * self.columnCount ..< (bottomRow.index + 1) * self.columnCount]);
	}	
}

fileprivate extension CPCCalendarView.Layout.Storage {
	fileprivate typealias Attributes = CPCCalendarView.Layout.Attributes;
	private typealias Row = CPCCalendarView.Layout.Row;
	
	private var firstIndexPath: IndexPath {
		return self.firstAttributes.indexPath;
	}

	private var lastIndexPath: IndexPath {
		return self.lastAttributes.indexPath;
	}
	
	private var firstAttributes: Attributes {
		return self.rawAttributes [self.rawAttributes.startIndex];
	}
	
	private var lastAttributes: Attributes {
		let lastIndex = self.rawAttributes.endIndex - 1;
		if let lastRowLength = self.incompleteRowLengths [lastIndex] {
			return self.rawAttributes [lastIndex - (self.columnCount - lastRowLength)];
		} else {
			return self.rawAttributes [lastIndex];
		}
	}
	
	private var firstRow: Row {
		return self.rowAt (index: self.firstRowIndex);
	}
	
	private var lastRow: Row {
		return self.rowAt (index: self.lastRowIndex);
	}
	
	private func rowAt (index: Int) -> Row {
		let rowLength = self.incompleteRowLengths [index] ?? self.columnCount;
		return Row (self, rawAttributes: self.rawAttributes [(index * self.columnCount) ..< (index * self.columnCount + rowLength)]);
	}

	private func row (containing verticalOffset: CGFloat, allowBeforeFirst: Bool = false, allowAfterLast: Bool = false) -> Row? {
		if (allowBeforeFirst && (verticalOffset < self.firstAttributes.frame.minY)) {
			return self.firstRow;
		}
		if (allowAfterLast && (verticalOffset >= self.lastAttributes.frame.maxY)) {
			return self.rowAt (index: self.lastRowIndex - 1);
		}

		return self.rawAttributes.binarySearch (withGranularity: self.columnCount) {
			if ($0.frame.minY > verticalOffset) {
				return .orderedAscending;
			} else if ($0.frame.maxY < verticalOffset) {
				return .orderedDescending;
			} else {
				return .orderedSame;
			}
		}.map (self.rowAt);
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

fileprivate extension BinaryInteger {
	fileprivate func nextDividable (by divisor: Self) -> Self {
		return self + divisor - self % divisor - 1;
	}
}
