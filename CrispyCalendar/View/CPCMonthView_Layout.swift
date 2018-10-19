//
//  CPCMonthView_Layout.swift
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

internal extension UIView {
	internal var separatorWidth: CGFloat {
		return 1.0 / (self.window?.screen ?? .main).nativeScale;
	}
}

internal extension CPCMonthView {
	internal typealias CellIndices = GridIndices <Int>;
	internal typealias CellIndex = CellIndices.Element;

	internal struct Layout {
		internal typealias SeparatorOrigins = (horizontal: ComputedArray <Int, CGFloat>, vertical: ComputedArray <Int, CGFloat>);
		
		internal let separatorWidth: CGFloat;
		internal let titleFrame: CGRect?;
		internal let gridFrame: CGRect;
		internal let cellFrames: ComputedCollection <CellIndex, CGRect, CellIndices>;
		internal let separatorOrigins: SeparatorOrigins;
		
		internal var titleContentFrame: CGRect {
			guard let titleFrame = self.titleFrame else {
				return .null;
			}
			
			let result = titleFrame.inset (by: self.titleMargins), scale = self.separatorWidth;
			return CGRect (
				origin: CGPoint (x: result.minX.rounded (.up, scale: scale), y: result.minY.rounded (.up, scale: scale)),
				size: CGSize (width: result.width.rounded (.down, scale: scale), height: result.height.rounded (.down, scale: scale))
			);
		}
		
		private let month: CPCMonth;
		private let cellsOrigin: CGPoint;
		private let cellSize: CGSize;
		private let titleMargins: UIEdgeInsets;

		internal init? (view: CPCMonthView) {
			guard let month = view.month, !month.isEmpty else {
				return nil;
			}
			
			let monthValue = month.month, width = month [ordinal: 0].count, height = month.count;
			guard let cellIndices = CellIndices (rowCount: height, columnCount: width)?.indices (filteredUsing: { month [ordinal: $0.row] [ordinal: $0.column].month == monthValue }), !cellIndices.isEmpty else {
				return nil;
			}
			guard !month.contains (where: { $0.count != width }) else {
				fatalError ("[CrispyCalendar] Sanity check failure: \(month) is not representable as a rectangular grid");
			}
			
			let separatorWidth = view.separatorWidth;
			let titleMargins = view.effectiveTitleMargins;
			let titleFrame: CGRect, gridFrame: CGRect;
			if (view.titleStyle == .none) {
				titleFrame = .null;
				gridFrame = view.bounds;
			} else {
				let titleHeight = (titleMargins.top + view.effectiveTitleFont.lineHeight.rounded (.up, scale: separatorWidth) + titleMargins.bottom).rounded (.up, scale: separatorWidth);
				(titleFrame, gridFrame) = view.bounds.divided (atDistance: titleHeight, from: .minYEdge);
			}
			let cellsOrigin = CGPoint (x: gridFrame.minX - separatorWidth / 2.0, y: gridFrame.minY + separatorWidth / 2.0);
			let cellSize = CGSize (
				width: (gridFrame.width + separatorWidth) / CGFloat (width),
				height: (gridFrame.height - separatorWidth) / CGFloat (height)
			);
			
			let separatorIndices = (horizontal: 0 ... height + 1, vertical: 0 ... width + 1);
			let separatorLocations = (
				horizontal: separatorIndices.horizontal.map { fma (cellSize.height, CGFloat ($0), cellsOrigin.y - separatorWidth / 2.0).rounded (scale: separatorWidth) + separatorWidth / 2.0 },
				vertical: separatorIndices.vertical.map { fma (cellSize.width, CGFloat ($0), cellsOrigin.x - separatorWidth / 2.0).rounded (scale: separatorWidth) + separatorWidth / 2.0 }
			);
			
			self.month = month;
			self.separatorWidth = separatorWidth;

			self.titleFrame = (titleFrame.isNull ? nil : titleFrame);
			self.titleMargins = titleMargins;
			
			self.gridFrame = gridFrame;
			self.cellSize = cellSize;
			self.cellsOrigin = cellsOrigin;
			self.separatorOrigins = (
				horizontal: ComputedArray (separatorIndices.horizontal) { separatorLocations.horizontal [$0] },
				vertical: ComputedArray (separatorIndices.vertical) { separatorLocations.vertical [$0] }
			);
			self.cellFrames = ComputedCollection (indices: cellIndices) { index in
				let column = index.column, columnMinX = separatorLocations.vertical [column], columnMaxX = separatorLocations.vertical [column + 1];
				let row = index.row, rowMinY = separatorLocations.horizontal [row], rowMaxY = separatorLocations.horizontal [row + 1];
				return CGRect (x: columnMinX, y: rowMinY, width: columnMaxX - columnMinX, height: rowMaxY - rowMinY);
			};
		}
		
		internal func isValid (for view: CPCMonthView) -> Bool {
			guard self.month == view.month else {
				return false;
			}
			
			let separatorWidth = self.separatorWidth, viewBounds = view.bounds, viewSeparatorWidth = view.separatorWidth;
			guard (separatorWidth - viewSeparatorWidth).magnitude < 1e-3 else {
				return false;
			}
			
			let titleMargins = self.titleMargins, titleHeight = self.titleFrame.map { ($0.height - titleMargins.top - titleMargins.bottom).rounded (.down, scale: separatorWidth) };
			let viewTitleMargins = view.effectiveTitleMargins, viewTitleHeight = ((view.titleStyle == .none) ? nil : view.effectiveTitleFont.lineHeight.rounded (.up, scale: viewSeparatorWidth));
			switch (titleHeight, viewTitleHeight) {
			case (nil, nil):
				break;
			case (.some (let height1), .some (let height2)) where (height1 - height2).magnitude < 1e-3:
				break;
			default:
				return false;
			}
			guard
				(titleMargins.top - viewTitleMargins.top).magnitude < 1e-3,
				(titleMargins.left - viewTitleMargins.left).magnitude < 1e-3,
				(titleMargins.bottom - viewTitleMargins.bottom).magnitude < 1e-3,
				(titleMargins.right - viewTitleMargins.right).magnitude < 1e-3,
				titleFrame.map ({ ($0.width - viewBounds.width).magnitude < 1e-3 }) ?? true else {
				return false;
			}
			
			let gridFrame = self.gridFrame;
			guard
				(gridFrame.width - viewBounds.width).magnitude < 1e-3,
				(gridFrame.maxY - viewBounds.height).magnitude < 1e-3 else {
				return false;
			}
			
			return true;
		}
		
		internal func cellIndex (at point: CGPoint, treatingSeparatorPointsAsEarlierIndexes flag: Bool = false) -> CellIndex? {
			guard self.isPointInsideGrid (point) else {
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

		private func isPointInsideGrid (_ point: CGPoint) -> Bool {
			let gridFrame = self.gridFrame;
			return (gridFrame.minX ... gridFrame.maxX).contains (point.x) && (gridFrame.minY ... gridFrame.maxY).contains (point.y);
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

#if !swift(>=4.2)
fileprivate extension CGRect {
	fileprivate func inset (by insets: UIEdgeInsets) -> CGRect {
		return UIEdgeInsetsInsetRect (self, insets);
	}
}
#endif
