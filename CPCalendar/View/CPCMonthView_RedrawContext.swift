//
//  CPCMonthView_RedrawContext.swift
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

fileprivate extension DateFormatter {
	private struct CacheKey: Hashable {
		private let calendarWrapper: CalendarWrapper;
		private let dateFormat: String;
		
		fileprivate init (_ calendarWrapper: CalendarWrapper, _ dateFormat: String) {
			self.calendarWrapper = calendarWrapper;
			self.dateFormat = dateFormat;
		}
		
		fileprivate var hashValue: Int {
			return hashIntegers (self.dateFormat.hashValue, self.calendarWrapper.hashValue);
		}
	}
	
	private static var availableFormatters = UnfairThreadsafeStorage ([CacheKey: [DateFormatter]] ());
	
	private static func availableFormatter (for month: CPCMonth, format: String) -> DateFormatter? {
		return self.availableFormatters.withMutableStoredValue {
			let cacheKey = CacheKey (month.calendarWrapper, format);
			guard var available = $0 [cacheKey], !available.isEmpty else {
				return nil;
			}
			let result = available.removeLast ();
			$0 [cacheKey] = available;
			return result;
		};
	}
	
	fileprivate static func dequeueFormatter (for month: CPCMonth, format: String) -> DateFormatter {
		if let reusedFormatter = self.availableFormatter (for: month, format: format) {
			return reusedFormatter;
		}
		
		let dateFormatter = DateFormatter ();
		dateFormatter.calendar = month.calendar;
		dateFormatter.dateFormat = format;
		dateFormatter.formattingContext = .standalone;
		return dateFormatter;
	}

	fileprivate static func dequeueFormatter (for month: CPCMonth, dateFormatTemplate template: String) -> DateFormatter {
		return self.dequeueFormatter (for: month, format: DateFormatter.dateFormat (fromTemplate: template, options: 0, locale: month.calendar.locale) ?? template);
	}
	
	fileprivate static func makeReusable (_ formatters: [DateFormatter], wrapper: CalendarWrapper) {
		DateFormatter.availableFormatters.withMutableStoredValue {
			for formatter in formatters {
				formatter.makeReusableUnlocked (&$0, wrapper: wrapper);
			}
		};
	}

	fileprivate func makeReusable (wrapper: CalendarWrapper) {
		DateFormatter.availableFormatters.withMutableStoredValue {
			self.makeReusableUnlocked (&$0, wrapper: wrapper);
		};
	}
	
	private func makeReusableUnlocked (_ cache: inout [CacheKey: [DateFormatter]], wrapper: CalendarWrapper) {
		let cacheKey = CacheKey (wrapper, self.dateFormat), value = [self];
		if let formatters = cache [cacheKey] {
			cache [cacheKey] = formatters + value;
		} else {
			cache [cacheKey] = value;
		}
	}
}

internal protocol CPCMonthViewRedrawContext {
	/// Runs a redraw context
	/// Note: Redraw contexts are designed to be one-shot (e. g. DateFormatters are internally reused), so calling run () twice may lead to unexpected behaviour.
	func run ();
}

internal extension CPCMonthView {
	internal typealias RedrawContext = CPCMonthViewRedrawContext;
	
	fileprivate struct TitleRedrawContext {
		fileprivate let month: CPCMonth;
		private let formatter: DateFormatter;
		private let titleFrame: CGRect;
		private let titleContentFrame: CGRect;
		private let titleAttributes: [NSAttributedStringKey: Any];
	}
	
	fileprivate struct GridRedrawContext {
		private typealias AffectedIndices = (affected: CellIndices, highlighted: CellIndex?, selected: CellIndices?);
		
		fileprivate let month: CPCMonth;
		private let layout: Layout;
		private let cellIndices: AffectedIndices;
		private let dayFormatter: DateFormatter;
		private let separatorColor: UIColor;
		private let cellTitleHeight: CGFloat;
		private let cellTitleAttributes: [NSAttributedStringKey: Any];
		private let cellBackgroundColors: DayCellStateBackgroundColors;
	}

	internal func titleRedrawContext (_ rect: CGRect) -> RedrawContext? {
		return TitleRedrawContext (redrawing: rect, in: self);
	}
	
	internal func gridRedrawContext (_ rect: CGRect) -> RedrawContext? {
		return GridRedrawContext (redrawing: rect, in: self);
	}
}

private protocol CPCMonthViewRedrawContextImpl: CPCMonthViewRedrawContext {
	var reusableFormatters: [DateFormatter] { get };
	var month: CPCMonth { get };
	
	init? (redrawing rect: CGRect, in view: CPCMonthView);
	func run (context: CGContext);
}

extension CPCMonthViewRedrawContextImpl {
	internal func run () {
		guard let context = UIGraphicsGetCurrentContext () else {
			return;
		}
		self.run (context: context);
		DateFormatter.makeReusable (self.reusableFormatters, wrapper: self.month.calendarWrapper);
	}
}

extension CPCMonthView.TitleRedrawContext: CPCMonthViewRedrawContextImpl {
	fileprivate var reusableFormatters: [DateFormatter] {
		return [self.formatter];
	}
	
	fileprivate init? (redrawing rect: CGRect, in view: CPCMonthView) {
		guard
			let month = view.month,
			let layout = view.layout,
			let titleFrame = layout.titleFrame,
			rect.intersects (titleFrame) else {
			return nil;
		}
		
		self.month = month;
		self.titleFrame = titleFrame;
		self.titleContentFrame = layout.titleContentFrame;
		self.formatter = DateFormatter.dequeueFormatter (for: month, format: view.titleStyle.rawValue);
		self.titleAttributes = [
			.font: view.effectiveTitleFont,
			.foregroundColor: view.titleColor,
			.paragraphStyle: NSParagraphStyle.centeredWithMiddleTruncation,
		];
	}
	
	fileprivate func run (context ctx: CGContext) {
		let titleString = NSAttributedString (string: self.formatter.string (from: self.month.start), attributes: self.titleAttributes);
		
		ctx.clear (self.titleFrame);
		titleString.draw (in: self.titleContentFrame);
	}
}

extension CPCMonthView.GridRedrawContext: CPCMonthViewRedrawContextImpl {
	private typealias Layout = CPCMonthView.Layout;
	private typealias CellIndex = CPCMonthView.CellIndex;
	private typealias DayCellState = CPCMonthView.DayCellState;
	private typealias GridRedrawContext = CPCMonthView.GridRedrawContext;
	
	private static func calculateAffectedIndices (of view: CPCMonthView, in rect: CGRect, for month: CPCMonth, using layout: Layout) -> AffectedIndices? {
		let rect = rect.intersection (layout.gridFrame);
		guard
			!rect.isNull,
			let topLeftIdx = layout.cellIndex (at: rect.origin, treatingSeparatorPointsAsEarlierIndexes: false),
			let bottomRightIdx = layout.cellIndex (at: CGPoint (x: rect.maxX, y: rect.maxY), treatingSeparatorPointsAsEarlierIndexes: true),
			let affected = layout.cellFrames.indices.subindices (forRows: topLeftIdx.row ... bottomRightIdx.row, columns: topLeftIdx.column ... bottomRightIdx.column),
			!affected.isEmpty else {
			return nil;
		}
		
		let highlighted: CellIndex?;
		if let viewHighlightedIdx = view.highlightedDayIndex, affected.rows ~= viewHighlightedIdx.row, affected.columns ~= viewHighlightedIdx.column {
			highlighted = affected.convert (index: viewHighlightedIdx, from: layout.cellFrames.indices);
		} else {
			highlighted = nil;
		}
		
		let selection = view.selection;
		let selected = affected.indices { selection.isDaySelected (month [ordinal: $0.row] [ordinal: $0.column]) };

		return (affected: affected, highlighted: highlighted, selected: selected);
	}
	
	fileprivate var reusableFormatters: [DateFormatter] {
		return [self.dayFormatter];
	}

	fileprivate init? (redrawing rect: CGRect, in view: CPCMonthView) {
		guard
			let month = view.month,
			let layout = view.layout,
			let indices = GridRedrawContext.calculateAffectedIndices (of: view, in: rect, for: month, using: layout) else {
			return nil;
		}
		let dayCellFont = view.effectiveDayCellFont;
		
		self.month = month;
		self.layout = layout;
		self.cellIndices = indices;
		self.separatorColor = view.separatorColor;
		self.cellBackgroundColors = view.cellBackgroundColors;

		self.dayFormatter = DateFormatter.dequeueFormatter (for: month, dateFormatTemplate: "d");
		self.cellTitleHeight = dayCellFont.lineHeight.rounded (.up, scale: layout.separatorWidth);
		self.cellTitleAttributes = [
			.font: dayCellFont,
			.foregroundColor: view.dayCellTextColor,
			.paragraphStyle: NSParagraphStyle.centeredWithTailTruncation,
		];
	}
		
	fileprivate func run (context ctx: CGContext) {
		let allIndices = self.cellIndices.affected;
		guard let firstIndex = allIndices.first, let lastIndex = allIndices.last else {
			return;
		}
		
		let layout = self.layout, halfSepW = layout.separatorWidth / 2.0;
		let minIndex = allIndices.minElement, minFrame = layout.cellFrames [minIndex];
		let maxIndex = allIndices.maxElement.advanced (by: -1), maxFrame = layout.cellFrames [maxIndex];
		let frame = minFrame.union (maxFrame).insetBy (dx: -halfSepW, dy: -halfSepW);
		ctx.clear (frame);
		ctx.addRect (frame);
		
		if (firstIndex != minIndex) {
			let firstCellFrame = layout.cellFrames [firstIndex];
			ctx.addRect (frame.slice (atDistance: CGSize (width: firstCellFrame.minX - minFrame.minX, height: firstCellFrame.height), from: .topLeft));
		}
		if (lastIndex != maxIndex) {
			let lastCellFrame = layout.cellFrames [lastIndex];
			ctx.addRect (frame.slice (atDistance: CGSize (width: maxFrame.maxX - lastCellFrame.maxX, height: lastCellFrame.height), from: .bottomRight));
		}
		ctx.clip (using: .evenOdd);
		
		if let normalBackgroundColor = self.cellBackgroundColors [effective: .normal] {
			ctx.setFillColor (normalBackgroundColor.cgColor);
			ctx.fill (frame);
		}
		for index in self.cellIndices.affected {
			self.drawDayCellContent (at: index, in: ctx);
		}
		
		let verticalSeparatorIndexes = layout.verticalSeparatorIndexes (for: allIndices.columns), horizontalSeparatorIndexes = layout.horizontalSeparatorIndexes (for: allIndices.rows);
		var separatorPoints = [CGPoint] ();
		separatorPoints.reserveCapacity (2 * (verticalSeparatorIndexes.count + horizontalSeparatorIndexes.count));
		for verticalSepX in layout.separatorOrigins.vertical [verticalSeparatorIndexes] {
			separatorPoints.append (CGPoint (x: verticalSepX, y: frame.minY));
			separatorPoints.append (CGPoint (x: verticalSepX, y: frame.maxY));
		}
		for horizontalSepY in layout.separatorOrigins.horizontal [horizontalSeparatorIndexes] {
			separatorPoints.append (CGPoint (x: frame.minX, y: horizontalSepY));
			separatorPoints.append (CGPoint (x: frame.maxX, y: horizontalSepY));
		}
		ctx.setStrokeColor (self.separatorColor.cgColor);
		ctx.setLineWidth (layout.separatorWidth);
		ctx.strokeLineSegments (between: separatorPoints);
	}
	
	private func drawDayCellContent (at index: CellIndex, in context: CGContext) {
		let day = self.month [ordinal: index.row] [ordinal: index.column];
		let state = self.dayCellState (for: day, at: index), frame = self.layout.cellFrames [index];

		if state != .normal, let backgroundColor = self.cellBackgroundColors [effective: state] {
			context.setFillColor (backgroundColor.cgColor);
			context.fill (frame);
		}
		
		let dayString = NSAttributedString (string: self.dayFormatter.string (from: day.start), attributes: self.cellTitleAttributes);
		let separatorWidth = self.layout.separatorWidth;
		dayString.draw (in: CGRect (
			x: frame.minX + separatorWidth / 2.0,
			y: frame.midY - self.cellTitleHeight / 2.0,
			width: frame.width - separatorWidth,
			height: self.cellTitleHeight
		));
	}
	
	private func dayCellState (for day: CPCDay, at index: CellIndex) -> DayCellState {
		if let selectedIndices = self.cellIndices.selected, selectedIndices.contains (index) {
			return .selected;
		}
		return CPCDayCellState (backgroundState: (self.cellIndices.highlighted == index) ? .highlighted : .normal, isToday: day == .today);
	}
}
