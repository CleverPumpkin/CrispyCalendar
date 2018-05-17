//
//  CPCMonthView.RedrawContext.swift
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

fileprivate extension UIRectCorner {
	fileprivate static let anyLeft: UIRectCorner = [.topLeft, .bottomLeft];
	fileprivate static let anyTop: UIRectCorner = [.topLeft, .topRight];
}

fileprivate extension CGRect {
	fileprivate func slice (atDistance distance: CGSize, from corner: UIRectCorner) -> CGRect {
		precondition ([.topLeft, .topRight, .bottomLeft, .bottomRight].contains (corner), "Cannot slice rectangle from multiple corners");
		
		let x: CGFloat;
		if ([.topLeft, .bottomLeft].contains (corner)) {
			x = self.minX;
		} else {
			x = self.maxX - distance.width;
		}
		let y: CGFloat;
		if ([.topLeft, .topRight].contains (corner)) {
			y = self.minY;
		} else {
			y = self.maxY - distance.height;
		}
		return CGRect (origin: CGPoint (x: x, y: y), size: distance);
	}
}

extension CPCMonthView {
	internal struct RedrawContext {
		private typealias AffectedIndices = (affected: CellIndices, highlighted: CellIndex?, selected: CellIndices?);
		
		private unowned let view: CPCMonthView;
		private let month: CPCMonth;
		private let layoutInfo: GridLayoutInfo;
		private let cellIndices: AffectedIndices;
		private let dayFormatter: DateFormatter;
		private let dayCellTitleHeight: CGFloat;
		private let dayCellTitleAttributes: [NSAttributedStringKey: Any];
		
		private static func calculateAffectedIndices (of view: CPCMonthView, in rect: CGRect, for month: CPCMonth, using layoutInfo: GridLayoutInfo) -> AffectedIndices? {
			let rect = rect.intersection (view.bounds);
			guard
				!rect.isNull,
				let topLeftIdx = layoutInfo.cellIndex (at: rect.origin, treatingSeparatorPointsAsEarlierIndexes: false),
				let bottomRightIdx = layoutInfo.cellIndex (at: CGPoint (x: rect.maxX, y: rect.maxY), treatingSeparatorPointsAsEarlierIndexes: true),
				let affected = layoutInfo.cellFrames.indices.subindices (forRows: topLeftIdx.row ... bottomRightIdx.row, columns: topLeftIdx.column ... bottomRightIdx.column),
				!affected.isEmpty else {
				return nil;
			}
			
			let highlighted: CellIndex?;
			if let viewHighlightedIdx = view.highlightedDayIndex, affected.rows ~= viewHighlightedIdx.row, affected.columns ~= viewHighlightedIdx.column {
				highlighted = affected.convert (index: viewHighlightedIdx, from: layoutInfo.cellFrames.indices);
			} else {
				highlighted = nil;
			}
			
			let selection = view.selection;
			let selected = affected.indices { selection.isDaySelected (month [ordinal: $0.row] [ordinal: $0.column]) };
	
			return (affected: affected, highlighted: highlighted, selected: selected);
		}
		
		internal init? (redrawing rect: CGRect, in view: CPCMonthView) {
			guard
				let month = view.month,
				let layoutInfo = view.gridLayoutInfo,
				let indices = RedrawContext.calculateAffectedIndices (of: view, in: rect, for: month, using: layoutInfo) else {
				return nil;
			}
			
			self.view = view;
			self.month = month;
			self.layoutInfo = layoutInfo;
			self.cellIndices = indices;

			self.dayFormatter = DateFormatter ();
			self.dayFormatter.setLocalizedDateFormatFromTemplate ("d");
			
			self.dayCellTitleHeight = view.font.lineHeight.rounded (.up, scale: layoutInfo.separatorWidth);
			self.dayCellTitleAttributes = [
				.font: view.font,
				.foregroundColor: view.titleColor,
				.paragraphStyle: { () -> Any in
					let result = NSMutableParagraphStyle ();
					result.alignment = .center;
					result.lineBreakMode = .byTruncatingTail;
					return result.copy ();
				} (),
			];
		}
		
		internal func run () {
			let allIndices = self.cellIndices.affected;
			guard let firstIndex = allIndices.first, let lastIndex = allIndices.last, let ctx = UIGraphicsGetCurrentContext () else {
				return;
			}
			
			let layoutInfo = self.layoutInfo, halfSepW = layoutInfo.separatorWidth / 2.0;
			let minIndex = allIndices.minElement, minFrame = layoutInfo.cellFrames [minIndex];
			let maxIndex = allIndices.maxElement.advanced (by: -1), maxFrame = layoutInfo.cellFrames [maxIndex];
			let frame = minFrame.union (maxFrame).insetBy (dx: -halfSepW, dy: -halfSepW);
			ctx.clear (frame);
			ctx.addRect (frame);
			
			if (firstIndex != minIndex) {
				let firstCellFrame = layoutInfo.cellFrames [firstIndex];
				ctx.addRect (frame.slice (atDistance: CGSize (width: firstCellFrame.minX - minFrame.minX, height: firstCellFrame.height), from: .topLeft));
			}
			if (lastIndex != maxIndex) {
				let lastCellFrame = layoutInfo.cellFrames [lastIndex];
				ctx.addRect (frame.slice (atDistance: CGSize (width: maxFrame.maxX - lastCellFrame.maxX, height: lastCellFrame.height), from: .bottomRight));
			}
			ctx.clip (using: .evenOdd);
			
			if let normalBackgroundColor = self.view.cellBackgroundColors.effectiveColor (for: .normal) {
				ctx.setFillColor (normalBackgroundColor.cgColor);
				ctx.fill (frame);
			}
			for index in self.cellIndices.affected {
				self.drawDayCellContent (at: index, in: ctx);
			}
			
			let verticalSeparatorIndexes = layoutInfo.verticalSeparatorIndexes (for: allIndices.columns), horizontalSeparatorIndexes = layoutInfo.horizontalSeparatorIndexes (for: allIndices.rows);
			var separatorPoints = [CGPoint] ();
			separatorPoints.reserveCapacity (2 * (verticalSeparatorIndexes.count + horizontalSeparatorIndexes.count));
			for verticalSepX in layoutInfo.separatorOrigins.vertical [verticalSeparatorIndexes] {
				separatorPoints.append (CGPoint (x: verticalSepX, y: frame.minY));
				separatorPoints.append (CGPoint (x: verticalSepX, y: frame.maxY));
			}
			for horizontalSepY in layoutInfo.separatorOrigins.horizontal [horizontalSeparatorIndexes] {
				separatorPoints.append (CGPoint (x: frame.minX, y: horizontalSepY));
				separatorPoints.append (CGPoint (x: frame.maxX, y: horizontalSepY));
			}
			ctx.setStrokeColor (self.view.separatorColor.cgColor);
			ctx.setLineWidth (layoutInfo.separatorWidth);
			ctx.strokeLineSegments (between: separatorPoints);
		}
		
		private func drawDayCellContent (at index: CellIndex, in context: CGContext) {
			let day = self.month [ordinal: index.row] [ordinal: index.column];
			let state = self.dayCellState (for: day, at: index), frame = self.layoutInfo.cellFrames [index];

			if state != .normal, let backgroundColor = self.view.cellBackgroundColors.effectiveColor (for: state) {
				context.setFillColor (backgroundColor.cgColor);
				context.fill (frame);
			}
			
			let dayString = NSAttributedString (string: self.dayFormatter.string (from: day.start), attributes: self.dayCellTitleAttributes);
			let separatorWidth = self.layoutInfo.separatorWidth;
			dayString.draw (in: CGRect (
				x: frame.minX + separatorWidth / 2.0,
				y: frame.midY - self.dayCellTitleHeight / 2.0,
				width: frame.width - separatorWidth,
				height: self.dayCellTitleHeight
			));
		}
		
		private func dayCellState (for day: CPCDay, at index: CellIndex) -> CPCDayCellState {
			if let selectedIndices = self.cellIndices.selected, selectedIndices.contains (index) {
				return .selected;
			}
			return CPCDayCellState (backgroundState: (self.cellIndices.highlighted == index) ? .highlighted : .normal, isToday: day == .today);
		}
	}
}
