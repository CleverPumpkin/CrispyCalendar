//
//  CPCCalendarView.swift
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

public protocol CPCCalendarViewSelectionDelegate: AnyObject {
	var selection: CPCViewSelection { get set };
	
	func calendarView (_ calendarView: CPCCalendarView, shouldSelect day: CPCDay) -> Bool;
	func calendarView (_ calendarView: CPCCalendarView, shouldDeselect day: CPCDay) -> Bool;
}

open class CPCCalendarView: UIView {
	internal unowned let contentView: CPCMultiMonthsView;
	
	private var scrollViewController: ScrollViewController!;
	
	private unowned let scrollView: UIScrollView;
	
	public override init (frame: CGRect) {
		let (scrollView, contentView) = CPCCalendarView.makeSubviews (frame);
		self.scrollView = scrollView;
		self.contentView = contentView;
		
		super.init (frame: frame);
		self.commonInit (scrollView);
	}
	
	public required init? (coder aDecoder: NSCoder) {
		let (scrollView, contentView) = CPCCalendarView.makeSubviews (.zero);
		self.scrollView = scrollView;
		self.contentView = contentView;
		
		super.init (coder: aDecoder);
		self.commonInit (scrollView);
	}
	
	private func commonInit (_ scrollView: UIScrollView) {
		self.addSubview (scrollView);
		
		NSLayoutConstraint.activate ([
			scrollView.leadingAnchor.constraint (equalTo: self.leadingAnchor),
			self.trailingAnchor.constraint (equalTo: scrollView.trailingAnchor),
			scrollView.topAnchor.constraint (equalTo: self.topAnchor),
			self.bottomAnchor.constraint (equalTo: scrollView.bottomAnchor),
		]);
		
		self.scrollViewController = ScrollViewController (self);
	}
	
	open override func layoutSubviews () {
		super.layoutSubviews ();
		self.scrollViewController.reloadMonthViewsIfNeeded ();
	}
}

extension CPCCalendarView {
	fileprivate final class ScrollViewController: NSObject, UIScrollViewDelegate {
		fileprivate var columnCount = 1 {
			didSet {
				self.calendarView.setNeedsLayout ();
			}
		}
		
		fileprivate var columnContentInsets = UIEdgeInsets.zero {
			didSet {
				self.calendarView.setNeedsLayout ();
			}
		}
		
		private unowned let calendarView: CPCCalendarView;
		
		private var reusableMonthViews = [CPCMonthView] ();
		private var prevOffset: CGFloat;
		private var layoutStorage: Layout?;
		private var presentedPageIndex = 0 {
			didSet {
				self.precalculateNextPageIfNeeed ();
			}
		}
		private var pendingPageCalculations = UnfairThreadsafeStorage ([Int: DispatchWorkItem] ());
		
		fileprivate init (_ calendarView: CPCCalendarView) {
			self.calendarView = calendarView;
			self.prevOffset = calendarView.scrollView.contentOffset.y;
			super.init ();
			
			calendarView.scrollView.delegate = self;
		}
	}
	
	private static let columnHeightMultiplier = CGFloat (5.0);

	open var columnCount: Int {
		get {
			return self.scrollViewController.columnCount;
		}
		set {
			self.scrollViewController.columnCount = max (1, newValue);
		}
	}
	
	open var columnContentInsets: UIEdgeInsets {
		get {
			return self.scrollViewController.columnContentInsets;
		}
		set {
			self.scrollViewController.columnContentInsets = newValue;
		}
	}

	private static func makeSubviews (_ frame: CGRect) -> (scrollView: UIScrollView, contentView: CPCMultiMonthsView) {
		let bounds = CGRect (origin: .zero, size: frame.standardized.size);
		let scrollView = UIScrollView (frame: bounds);
		scrollView.translatesAutoresizingMaskIntoConstraints = false;
		scrollView.showsVerticalScrollIndicator = false;
		scrollView.showsHorizontalScrollIndicator = false;
		
		let contentView = CPCMultiMonthsView (frame: CGRect (x: 0.0, y: 0.0, width: bounds.width, height: bounds.height * CPCCalendarView.columnHeightMultiplier));
		contentView.translatesAutoresizingMaskIntoConstraints = false;
		scrollView.addSubview (contentView);
		
		NSLayoutConstraint.activate ([
			contentView.leadingAnchor.constraint (equalTo: scrollView.leadingAnchor),
			scrollView.trailingAnchor.constraint (equalTo: contentView.trailingAnchor),
			contentView.topAnchor.constraint (equalTo: scrollView.topAnchor),
			scrollView.bottomAnchor.constraint (equalTo: contentView.bottomAnchor),
			contentView.widthAnchor.constraint (equalTo: scrollView.widthAnchor),
			contentView.heightAnchor.constraint (equalTo: scrollView.heightAnchor, multiplier: CPCCalendarView.columnHeightMultiplier),
		]);
		
		scrollView.contentOffset = CGPoint (x: 0.0, y: bounds.height * (CPCCalendarView.columnHeightMultiplier - 1.0) / 2);
		
		return (scrollView: scrollView, contentView: contentView);
	}
}

extension CPCCalendarView.ScrollViewController {
	fileprivate typealias ScrollViewController = CPCCalendarView.ScrollViewController;

	fileprivate struct Layout {
		fileprivate let columnSize: CGSize;
		
		private let columnCount: Int;
		private let firstInset: CGFloat, otherInsets: CGFloat;
		private let separatorWidth: CGFloat;
		private unowned let contentView: UIView & CPCViewProtocol;

		private var calculatedPages = [Page] ();
		private var firstPageIndex = 0;
		
		fileprivate func isValid (for controller: ScrollViewController) -> Bool {
			if (!Thread.isMainThread) {
				var result: Bool!;
				DispatchQueue.main.sync {
					result = self.isValid (for: controller);
				}
				return result;
			}
			
			guard
				(self.columnSize.width - controller.columnSize.width).magnitude < 1e-3,
				(self.columnSize.height - controller.columnSize.height).magnitude < 1e-3,
				(self.firstInset - controller.columnContentInsets.left).magnitude < 1e-3,
				(self.otherInsets * 2 - controller.columnContentInsets.left - controller.columnContentInsets.right).magnitude < 1e-3,
				(self.separatorWidth - controller.calendarView.separatorWidth).magnitude < 1e-3 else {
					return false;
			}
			
			return true;
		}
	}
	
	private static let sharedQueue = DispatchQueue (label: "CPCCalendarView.ScrollViewController.sharedQueue", qos: .userInitiated, attributes: .concurrent);
	private static let maxPrecalculatedPages = 5;

	private var columnSize: CGSize {
		let insets = self.columnContentInsets, columnCount = CGFloat (self.columnCount), bounds = self.calendarView.bounds;
		return CGSize (
			width: (bounds.width - (insets.left + insets.right) / 2 * (columnCount + 1)) / columnCount,
			height: bounds.height * CPCCalendarView.columnHeightMultiplier
		);
	}
	
	private var layout: Layout {
		get {
			let scrollView = self.calendarView.scrollView, targetContentOffset: CGFloat;
			if let storedValue = self.layoutStorage, storedValue.columnSize.height > 0.0 {
				if storedValue.isValid (for: self) {
					return storedValue;
				}
				targetContentOffset = CGFloat (self.presentedPageIndex) * (CPCCalendarView.columnHeightMultiplier - 2.0) * storedValue.columnSize.height + scrollView.contentOffset.y;
			} else {
				targetContentOffset = self.calendarView.bounds.height * (CPCCalendarView.columnHeightMultiplier - 1.0) / 2.0;
			}
			
			let updatedLayout = Layout (controller: self);
			self.layoutStorage = updatedLayout;
			let columnHeight = updatedLayout.columnSize.height;
			scrollView.contentOffset.y = targetContentOffset.remainder (dividingBy: columnHeight);
			self.presentedPageIndex = (targetContentOffset / columnHeight).integerRounded (.down);
			return updatedLayout;
		}
		set {
			self.layoutStorage = newValue;
		}
	}
	
	private var isMonthViewsReloadNeeded: Bool {
		return !(self.layoutStorage?.isValid (for: self) ?? false);
	}
	
	fileprivate func reloadMonthViewsIfNeeded () {
		guard self.isMonthViewsReloadNeeded else {
			return;
		}
		self.reloadMonthViews ();
	}
	
	fileprivate func scrollViewDidScroll (_ scrollView: UIScrollView) {
		let currentOffset = scrollView.contentOffset.y, offsetDiff = currentOffset - self.prevOffset;
		self.prevOffset = currentOffset;
		self.updatePresentedPageIndexIfNeeded (offset: currentOffset, offsetDiff: offsetDiff);
	}
	
	private func updatePresentedPageIndexIfNeeded (offset: CGFloat, offsetDiff: CGFloat) {
		let scrollView = self.calendarView.scrollView, boundsHeight = scrollView.bounds.height, columnHeight = self.columnSize.height;
		if ((offset < 0.0) && (offsetDiff < -1e-3)) {
			self.presentedPageIndex -= 1;
			self.prevOffset = offset + columnHeight - boundsHeight;
		} else if ((offset > columnHeight - boundsHeight) && (offsetDiff > 1e-3)) {
			self.presentedPageIndex += 1;
			self.prevOffset = offset - columnHeight + boundsHeight;
		} else {
			return self.startMonthViewUpdatesWhereNeeded ();
		}
		
		scrollView.contentOffset.y = self.prevOffset;
		self.reloadMonthViews ();
	}
	
	private func dequeueOrMakeMonthView (month: CPCMonth) -> CPCMonthView {
		if self.reusableMonthViews.isEmpty {
			return CPCMonthView (frame: .zero, month: month);
		} else {
			let result = self.reusableMonthViews.removeLast ();
			result.month = month;
			return result;
		}
	}

	private func reloadMonthViews () {
		let contentView = self.calendarView.contentView, monthViews = contentView.monthViews;
		for monthView in monthViews {
			monthView.contentsUpdatesPaused = true;
			contentView.removeMonthView (monthView);
		}
		self.reusableMonthViews.append (contentsOf: monthViews);
		
		let page = self.layout [self.presentedPageIndex];
		for row in page {
			for month in row.months {
				let monthView = self.dequeueOrMakeMonthView (month: month);
				monthView.frame = row.viewFrame (for: month);
				contentView.addMonthView (monthView);
			}
		}
		self.startMonthViewUpdatesWhereNeeded ();
	}
	
	private func startMonthViewUpdatesWhereNeeded () {
		let calendarView = self.calendarView, monthViews = calendarView.contentView.monthViews;
		for monthView in monthViews {
			if (calendarView.convert (monthView.bounds, from: monthView).intersects (calendarView.bounds)) {
				monthView.contentsUpdatesPaused = false;
			}
		}
	}
	
	private func precalculateNextPageIfNeeed () {
		if !Thread.isMainThread {
			return DispatchQueue.main.async { self.precalculateNextPageIfNeeed () };
		}
		
		let currentPage = self.presentedPageIndex, maxPages = ScrollViewController.maxPrecalculatedPages, currentOffset = self.calendarView.scrollView.contentOffset.y;
		let alreadyCalculated = self.layout.calculatedPageIndexes, desiredPages: [[Int]];
		if (currentOffset > self.prevOffset) {
			desiredPages = [
				(currentPage + maxPages >= alreadyCalculated.upperBound) ? Array (alreadyCalculated.upperBound ... currentPage + maxPages) : [],
				(currentPage - maxPages < alreadyCalculated.lowerBound - 1) ? Array (stride (from: alreadyCalculated.lowerBound - 1, to: currentPage - maxPages, by: -1)) : [],
			];
		} else if (currentOffset < self.prevOffset) {
			desiredPages = [
				(currentPage - maxPages < alreadyCalculated.lowerBound) ? Array (stride (from: alreadyCalculated.lowerBound - 1, through: currentPage - maxPages, by: -1)) : [],
				(currentPage + maxPages >= alreadyCalculated.upperBound) ? Array (alreadyCalculated.upperBound ..< currentPage + maxPages) : [],
			];
		} else {
			desiredPages = [
				(currentPage + maxPages >= alreadyCalculated.upperBound) ? Array (alreadyCalculated.upperBound ..< currentPage + maxPages) : [],
				(currentPage - maxPages < alreadyCalculated.lowerBound) ? Array (stride (from: alreadyCalculated.lowerBound - 1, to: currentPage - maxPages, by: -1)) : [],
			];
		}
		
		let queue = ScrollViewController.sharedQueue;
		self.pendingPageCalculations.withMutableStoredValue {
			for pagesSubsequence in desiredPages where !pagesSubsequence.isEmpty {
				var prevItem: DispatchWorkItem?;
				for pageIdx in 0 ..< pagesSubsequence.count {
					let page = pagesSubsequence [pageIdx];
					guard !$0.keys.contains (page) else {
						continue;
					}
					
					let workItem = DispatchWorkItem { [weak self] in
						self?.layout.ensurePageCalculated (page);
						self?.completePageCalculation (page);
					};
					$0 [page] = workItem;
					
					if let prevItem = prevItem {
						prevItem.notify (queue: queue, execute: workItem);
					} else if let executingItem = $0 [page - 1] {
						executingItem.notify (queue: queue, execute: workItem);
					} else {
						queue.async (execute: workItem);
					}
					prevItem = workItem;
				}
			}
		};
	}
	
	private func completePageCalculation (_ index: Int) {
		self.pendingPageCalculations.withMutableStoredValue {
			$0 [index] = nil;
		};
		self.precalculateNextPageIfNeeed ();
	}
}

extension CPCCalendarView.ScrollViewController.Layout {
	fileprivate typealias ScrollViewController = CPCCalendarView.ScrollViewController;
	fileprivate typealias Layout = ScrollViewController.Layout;
	
	fileprivate struct Page {
		private let rows: [Row];
	}
			
	fileprivate var calculatedPageIndexes: CountableRange <Int> {
		return self.firstPageIndex ..< (self.firstPageIndex + self.calculatedPages.count);
	}
	
	fileprivate init (controller: CPCCalendarView.ScrollViewController) {
		self.columnCount = controller.columnCount;
		self.columnSize = controller.columnSize;
		self.firstInset = controller.columnContentInsets.left;
		self.otherInsets = (controller.columnContentInsets.left + controller.columnContentInsets.right) / 2.0;
		self.separatorWidth = controller.calendarView.separatorWidth;
		self.contentView = controller.calendarView.contentView;
	}
	
	fileprivate mutating func ensurePageCalculated (_ index: Int) {
		if self.calculatedPages.isEmpty {
			self.calculatedPages.append (Page (startPageFor: self));
		}
		
		let startIndex = self.firstPageIndex, endIndex = startIndex + self.calculatedPages.count;
		switch (index) {
		case let lowerBound where lowerBound < startIndex:
			var currentPage = self.calculatedPages.first!;
			let newPages = (lowerBound ..< startIndex).map { _ -> Page in
				let result = Page (previousFor: currentPage, of: self);
				currentPage = result;
				return result;
			};
			self.firstPageIndex = lowerBound;
			self.calculatedPages.insert (contentsOf: newPages.reversed (), at: 0);

		case let upperBound where upperBound >= endIndex:
			self.calculatedPages.reserveCapacity (upperBound - startIndex);
			var currentPage = self.calculatedPages.last!;
			for _ in endIndex ... upperBound {
				let page = Page (nextFor: currentPage, of: self);
				self.calculatedPages.append (page);
				currentPage = page;
			}
			
		default:
			return;
		}
	}
	
	fileprivate subscript (page: Int) -> Page {
		mutating get {
			self.ensurePageCalculated (page);
			return self.calculatedPages [page - self.firstPageIndex];
		}
	}
}

private protocol LayoutPageRow {
	var months: CountableClosedRange <CPCMonth> { get }
	var frame: CGRect { get }
	
	func viewFrame (for month: CPCMonth) -> CGRect;
}

private enum LayoutPageRowConstraint {
	case minY (CGFloat);
	case midY (CGFloat);
	case maxY (CGFloat);
}

extension CPCCalendarView.ScrollViewController.Layout.Page {
	fileprivate typealias ScrollViewController = CPCCalendarView.ScrollViewController;
	fileprivate typealias Layout = ScrollViewController.Layout;
	fileprivate typealias Page = Layout.Page;
	fileprivate typealias Row = LayoutPageRow;
	
	fileprivate var monthsRange: CountableClosedRange <CPCMonth>? {
		guard let first = self.rows.first, let last = self.rows.last else {
			return nil;
		}
		return first.months.lowerBound ... last.months.upperBound;
	}
	
	fileprivate init (startPageFor layout: Layout) {
		let currentYear = CPCYear.current, currentMonth = CPCMonth.current, currentMonthIndex = currentMonth.month - currentYear [ordinal: 0].month;
		let firstMonthOfMiddleRow = currentYear [ordinal: (currentMonthIndex / layout.columnCount) * layout.columnCount];
		let lastMonthOfMiddleRow = currentYear [Swift.min (currentYear.endIndex, firstMonthOfMiddleRow.month + layout.columnCount) - 1];
		
		let columnHeight = layout.columnSize.height;
		let middleRow = Page.makeRow (months: firstMonthOfMiddleRow ... lastMonthOfMiddleRow, layout: layout, constraint: .midY (columnHeight / 2.0));
		let bottomRows = Page.makeRows (for: layout, after: middleRow, startingAt: middleRow.frame.maxY);
		let topRows = Page.makeRows (for: layout, before: middleRow, startingAt: middleRow.frame.minY);
		
		self.rows = topRows + CollectionOfOne (middleRow) + bottomRows;
	}

	fileprivate init (previousFor page: Page, of layout: Layout) {
		let multiplier = CPCCalendarView.columnHeightMultiplier;
		let firstRow = guarantee (page.rows.first { $0.frame.minY > layout.columnSize.height / multiplier });
		self.rows = Page.makeRows (for: layout, before: firstRow, startingAt: layout.columnSize.height * (1.0 - 1.0 / multiplier) + firstRow.frame.minY);
	}

	fileprivate init (nextFor page: Page, of layout: Layout) {
		let multiplier = CPCCalendarView.columnHeightMultiplier;
		let lastRow = guarantee (page.rows.reversed ().first { layout.columnSize.height - $0.frame.maxY > layout.columnSize.height / multiplier });
		self.rows = Page.makeRows (for: layout, after: lastRow, startingAt: lastRow.frame.maxY + layout.columnSize.height / multiplier - layout.columnSize.height);
	}
	
	fileprivate subscript (row: Int) -> Row {
		return self.rows [row];
	}
}

extension CPCCalendarView.ScrollViewController.Layout.Page: RandomAccessCollection {
	fileprivate typealias Element = Row;

	fileprivate var startIndex: Int {
		return self.rows.startIndex;
	}
	
	fileprivate var endIndex: Int {
		return self.rows.endIndex;
	}
	
	fileprivate func index (after i: Int) -> Int {
		return self.rows.index (after: i);
	}
	
	fileprivate func index (before i: Int) -> Int {
		return self.rows.index (before: i);
	}
	
}

extension CPCCalendarView.ScrollViewController.Layout.Page {
	private static func makeRows (for layout: Layout, after row: Row, startingAt yPosition: CGFloat) -> [Row] {
		let columnHeight = layout.columnSize.height;
		return Array (sequence (state: (yPosition, row.months.upperBound)) { state -> Row? in
			let (minY, lastBottomMonth) = state;
			
			guard minY < columnHeight else {
				return nil;
			}
			
			let firstRowMonth = lastBottomMonth.next, lastMonthForFullRow = lastBottomMonth.advanced (by: layout.columnCount), lastRowMonth: CPCMonth;
			if (lastMonthForFullRow.year == firstRowMonth.year) {
				lastRowMonth = lastMonthForFullRow;
			} else {
				lastRowMonth = CPCYear (backedBy: firstRowMonth.year, calendar: firstRowMonth.calendarWrapper).last!;
			}
			
			let row = Page.makeRow (months: firstRowMonth ... lastRowMonth, layout: layout, constraint: .minY (minY));
			state = (row.frame.maxY, lastRowMonth);
			return row;
		});
	}
	
	fileprivate static func makeRows (for layout: Layout, before row: Row, startingAt yPosition: CGFloat) -> [Row] {
		return sequence (state: (yPosition, row.months.lowerBound)) { state -> Row? in
			let (maxY, lastTopMonth) = state;
			guard maxY > 0.0 else {
				return nil;
			}
			
			let lastRowMonth = lastTopMonth.prev, rowSize: Int;
			if (lastRowMonth.year == lastTopMonth.year) {
				rowSize = layout.columnCount;
			} else {
				let yearSize = CPCYear (backedBy: lastRowMonth.year, calendar: lastRowMonth.calendarWrapper).count;
				rowSize = (yearSize - 1) % layout.columnCount + 1;
			}
			let firstRowMonth = lastTopMonth.advanced (by: -rowSize);
			
			let row = Page.makeRow (months: firstRowMonth ... lastRowMonth, layout: layout, constraint: .maxY (maxY));
			state = (row.frame.minY, firstRowMonth)
			return row;
		}.reversed ();
	}
	
	private static func layoutAttributes (for month: CPCMonth, layout: Layout) -> CPCMonthView.LayoutAttributes {
		let contentView = layout.contentView;
		return CPCMonthView.LayoutAttributes (month: month, separatorWidth: layout.separatorWidth, titleFont: contentView.titleFont, titleMargins: contentView.titleMargins);
	}

	private static func makeRowFrame (x: CGFloat, width: CGFloat, height: CGFloat, scale: CGFloat, constraint: LayoutPageRowConstraint) -> CGRect {
		let y: CGFloat;
		switch (constraint) {
		case .minY (let minY):
			y = minY;
		case .midY (let midY):
			y = midY - height / 2;
		case .maxY (let maxY):
			y = maxY - height;
		}
		return CGRect (x: x.rounded (scale: scale), y: y.rounded (scale: scale), width: width.rounded (scale: scale), height: height.rounded (scale: scale));
	}

	private static func makeRow (months: CountableClosedRange <CPCMonth>, layout: Layout, constraint: LayoutPageRowConstraint) -> Row {
		struct SingleMonthRow: Row {
			fileprivate let frame: CGRect;

			fileprivate var months: CountableClosedRange <CPCMonth> {
				return self.month ... self.month;
			}

			private let month: CPCMonth;
			
			fileprivate init (month: CPCMonth, layout: Layout, constraint: LayoutPageRowConstraint) {
				let columnWidth = layout.columnSize.width, scale = layout.separatorWidth;
				let monthViewHeight = CPCMonthView.heightThatFits (width: columnWidth, with: Page.layoutAttributes (for: month, layout: layout));
				self.frame = Page.makeRowFrame (x: layout.firstInset, width: columnWidth, height: monthViewHeight, scale: scale, constraint: constraint);
				self.month = month;
			}
			
			fileprivate func viewFrame (for month: CPCMonth) -> CGRect {
				return self.frame;
			}
		}
		
		struct DoubleMonthsRow: Row {
			fileprivate var months: CountableClosedRange <CPCMonth> {
				return self.leftMonth ... self.rightMonth;
			}
			
			fileprivate var frame: CGRect {
				return self.leftFrame.union (self.rightFrame);
			}

			private let leftMonth: CPCMonth, rightMonth: CPCMonth;
			private let leftFrame: CGRect, rightFrame: CGRect;
			
			fileprivate init (months: (CPCMonth, CPCMonth), layout: Layout, constraint: LayoutPageRowConstraint) {
				let columnWidth = layout.columnSize.width, scale = layout.separatorWidth, leftMonth = months.0, rightMonth = months.1;
				let leftViewHeight = CPCMonthView.heightThatFits (width: columnWidth, with: Page.layoutAttributes (for: leftMonth, layout: layout));
				let rightViewHeight = CPCMonthView.heightThatFits (width: columnWidth, with: Page.layoutAttributes (for: rightMonth, layout: layout));

				self.leftMonth = leftMonth;
				self.rightMonth = rightMonth;
				self.leftFrame = Page.makeRowFrame (x: layout.firstInset, width: columnWidth, height: leftViewHeight, scale: scale, constraint: constraint);
				self.rightFrame = Page.makeRowFrame (x: layout.firstInset + columnWidth + layout.otherInsets, width: columnWidth, height: rightViewHeight, scale: scale, constraint: constraint);
			}
			
			fileprivate func viewFrame (for month: CPCMonth) -> CGRect {
				return (month == self.leftMonth) ? self.leftFrame : self.rightFrame;
			}
		}
		
		struct DefaultRow: Row {
			fileprivate let months: CountableClosedRange <CPCMonth>;
			fileprivate let frame: CGRect;
			
			private let viewsStrideX: CGFloat;
			private let viewHeights: [CGFloat];
			private let scale: CGFloat;
			
			fileprivate init (months: CountableClosedRange <CPCMonth>, layout: Layout, constraint: LayoutPageRowConstraint) {
				let viewsWidth = layout.columnSize.width, viewsStrideX = viewsWidth + layout.otherInsets, scale = layout.separatorWidth;
				let frameWidth = fma (viewsStrideX, CGFloat (layout.columnCount), -layout.otherInsets);

				var maxHeight = CGFloat (0.0);
				let viewHeights = months.map { month -> CGFloat in
					let height = CPCMonthView.heightThatFits (width: viewsWidth, with: Page.layoutAttributes (for: month, layout: layout));
					maxHeight = Swift.max (maxHeight, height);
					return height;
				};
				
				self.months = months;
				self.frame = Page.makeRowFrame (x: layout.firstInset, width: frameWidth, height: maxHeight, scale: scale, constraint: constraint);
				self.viewsStrideX = viewsStrideX;
				self.viewHeights = viewHeights;
				self.scale = scale;
			}
			
			fileprivate func viewFrame (for month: CPCMonth) -> CGRect {
				let index = month.month - self.months.lowerBound.month, frame = self.frame, strideX = self.viewsStrideX;
				let viewMinX = fma (strideX, CGFloat (index), frame.minX).rounded (scale: self.scale);
				let viewMaxX = fma (strideX, CGFloat (index + 1 - self.viewHeights.count), frame.maxX).rounded (scale: self.scale);
				return CGRect (x: viewMinX, y: frame.minY, width: viewMaxX - viewMinX, height: self.viewHeights [index]);
			}
		}
		
		switch (months.count) {
		case 1:
			return SingleMonthRow (month: months.lowerBound, layout: layout, constraint: constraint);
		case 2:
			return DoubleMonthsRow (months: (months.lowerBound, months.upperBound), layout: layout, constraint: constraint);
		default:
			return DefaultRow (months: months, layout: layout, constraint: constraint);
		}
	}
}
