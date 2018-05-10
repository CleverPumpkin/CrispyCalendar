//
//  CPCMonthView.GridLayoutInfo.swift
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

fileprivate extension UIView {
	fileprivate var separatorWidth: CGFloat {
		guard let window = self.window else {
			return 1.0;
		}
		return 1.0 / window.screen.nativeScale;
	}
}

internal extension CPCMonthView {
	internal typealias CellIndices = GridIndices <Int>;
	internal typealias CellIndex = CellIndices.Element;

	internal struct GridLayoutInfo {
		internal let separatorWidth: CGFloat;
		internal let cellFrames: ComputedCollection <CellIndex, CGRect, CellIndices>;
		internal let separatorOrigins: (horizontal: ComputedArray <Int, CGFloat>, vertical: ComputedArray <Int, CGFloat>);
		
		private let month: CPCMonth;
		private let boundsSize: CGSize;
		private let cellsOrigin: CGPoint;
		private let cellSize: CGSize;
		
		internal init? (view: CPCMonthView) {
			guard let month = view.month, !month.isEmpty else {
				return nil;
			}
			
			let monthValue = month.month, width = month [ordinal: 0].count, height = month.count;
			guard let cellIndices = CellIndices (rowCount: height, columnCount: width)?.indices (filteredUsing: { month [ordinal: $0.row] [ordinal: $0.column].month == monthValue }), !cellIndices.isEmpty else {
				return nil;
			}
			guard !month.contains (where: { $0.count != width }) else {
				fatalError ("\(month) is not representable as a rectangular grid");
			}

			let boundsSize = view.bounds.standardized.size;
			let separatorWidth = view.separatorWidth;
			let cellsOrigin = CGPoint (x: -separatorWidth / 2.0, y: separatorWidth / 2.0);
			let cellSize = CGSize (
				width: (boundsSize.width + separatorWidth) / CGFloat (width),
				height: (boundsSize.height - separatorWidth) / CGFloat (height)
			);
			
			let separatorIndices = (horizontal: 0 ... height + 1, vertical: 0 ... width + 1);
			let separatorLocations = (
				horizontal: separatorIndices.horizontal.map { fma (cellSize.height, CGFloat ($0), cellsOrigin.y - separatorWidth / 2.0).rounded (scale: separatorWidth) + separatorWidth / 2.0 },
				vertical: separatorIndices.vertical.map { fma (cellSize.width, CGFloat ($0), cellsOrigin.x - separatorWidth / 2.0).rounded (scale: separatorWidth) + separatorWidth / 2.0 }
			);
			
			self.month = month;
			self.cellSize = cellSize;
			self.boundsSize = boundsSize;
			self.cellsOrigin = cellsOrigin;
			self.separatorWidth = separatorWidth;
			self.separatorOrigins = (
				horizontal: ComputedArray (separatorIndices.horizontal) { separatorLocations.horizontal [$0] },
				vertical: ComputedArray (separatorIndices.vertical) { separatorLocations.vertical [$0] }
			);
			self.cellFrames = ComputedCollection (indices: cellIndices, subscript: { index in
				let column = index.column, columnMinX = separatorLocations.vertical [column], columnMaxX = separatorLocations.vertical [column + 1];
				let row = index.row, rowMinY = separatorLocations.horizontal [row], rowMaxY = separatorLocations.horizontal [row + 1];
				return CGRect (x: columnMinX, y: rowMinY, width: columnMaxX - columnMinX, height: rowMaxY - rowMinY);
			});
		}
		
		internal func isValid (for view: CPCMonthView) -> Bool {
			let viewSize = view.bounds.standardized.size;
			guard
				(self.boundsSize.width - viewSize.width).magnitude < 1e-3,
				(self.boundsSize.height - viewSize.height).magnitude < 1e-3,
				self.month == view.month,
				self.separatorWidth == view.separatorWidth else {
				return false;
			}
			
			return true;
		}
		
		internal func cellIndex (at point: CGPoint, treatingSeparatorPointsAsEarlierIndexes flag: Bool = false) -> CellIndex? {
			guard self.isPointInsideBounds (point) else {
				return nil;
			}
			let indices = self.cellFrames.indices;
			return indices.index (
				forRow: indices.rows.clamp (self.cellCoordinate (at: point.y, gridOrigin: self.cellsOrigin.y, cellSize: self.cellSize.height, separatorOrigins: self.separatorOrigins.horizontal, treatSeparatorAsEarlierIndex: flag)),
				column: indices.columns.clamp (self.cellCoordinate (at: point.x, gridOrigin: self.cellsOrigin.x, cellSize: self.cellSize.width, separatorOrigins: self.separatorOrigins.vertical, treatSeparatorAsEarlierIndex: flag))
			);
		}
		
		private func cellCoordinate (at viewCoordinate: CGFloat, gridOrigin: CGFloat, cellSize: CGFloat, separatorOrigins: ComputedArray <Int, CGFloat>, treatSeparatorAsEarlierIndex: Bool) -> Int {
			let result = ((viewCoordinate - gridOrigin) / cellSize).integerRounded (.down);
			return (treatSeparatorAsEarlierIndex && ((separatorOrigins [result] - viewCoordinate).magnitude < self.separatorWidth)) ? result - 1 : result;
		}

		private func isPointInsideBounds (_ point: CGPoint) -> Bool {
			return (0.0 ... self.boundsSize.width).contains (point.x) && (0.0 ... self.boundsSize.height).contains (point.y);
		}
		
		internal func cellIndex (forRow row: Int, column: Int) -> CellIndex {
			return self.cellFrames.indices.index (forRow: row, column: column);
		}
		
		internal func horizontalSeparatorIndexes (for rows: CountableRange <Int>) -> CountableClosedRange <Int> {
			return (rows.lowerBound ... rows.upperBound).clamped (to: 0 ... self.cellFrames.indices.rows.upperBound);
		}

		internal func verticalSeparatorIndexes (for columns: CountableRange <Int>) -> CountableClosedRange <Int> {
			return (columns.lowerBound ... columns.upperBound).clamped (to: 1 ... self.cellFrames.indices.columns.upperBound - 1);
		}
	}
}
