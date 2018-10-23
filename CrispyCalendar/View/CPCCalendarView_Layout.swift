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
		internal typealias ColumnContentInsetsReference = CPCCalendarView.ColumnContentInsetsReference;
		
		internal var columnCount = 1 {
			didSet {
				self.invalidateLayout ();
				self.collectionView?.reloadData ();
			}
		}
		
		internal var columnContentInsets = UIEdgeInsets.zero {
			didSet {
				self.invalidateLayout ();
				self.collectionView?.reloadData ();
			}
		}
		
		internal var columnContentInsetsReference: ColumnContentInsetsReference = .default {
			didSet {
				self.invalidateLayout ();
				self.collectionView?.reloadData ();
			}
		}
		
		internal let calendar: CPCCalendarWrapper;
		internal let monthViewsManager = CPCMonthViewsManager ();
		
		internal var minimumDate: Date? {
			didSet {
				guard self.minimumDate != oldValue else {
					return;
				}
				self.allowedDatesRangeDidChange ();
			}
		}
		
		internal var maximumDate: Date? {
			didSet {
				guard self.maximumDate != oldValue else {
					return;
				}
				self.allowedDatesRangeDidChange ();
			}
		}
		
		internal var ignoreFirstBoundsChange = false;
		internal var layoutInitialDate = Date () {
			didSet {
				self.invalidateLayout ();
			}
		}
		
		private var storage = makeEmptyStorage ();
		private var currentInvalidationContext: InvalidationContext?;
		
		internal init (calendar: CPCCalendarWrapper) {
			self.calendar = calendar;
			super.init ();
		}
		
		internal required init? (coder aDecoder: NSCoder) {
			self.calendar = Calendar.currentUsed.wrapped ();
			super.init (coder: aDecoder);
		}
	}
}

extension CPCCalendarView.Layout: UICollectionViewDataSource {
	internal func prepare (collectionView: UICollectionView) {
		collectionView.register (CPCCalendarView.Cell.self, forCellWithReuseIdentifier: .cellIdentifier);
		collectionView.dataSource = self;
		collectionView.delegate = self;
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
		
		let minimumDay: CPCDay?, maximumDay: CPCDay?;
		if let month = self.storage [indexPath]?.month {
			if let minimumDate = self.minimumDate, month.start < minimumDate {
				minimumDay = CPCDay (containing: minimumDate, calendar: self.calendar);
			} else {
				minimumDay = nil;
			}
			if let maximumDate = self.maximumDate, month.end > maximumDate {
				maximumDay = CPCDay (containing: maximumDate, calendar: self.calendar);
			} else {
				maximumDay = nil;
			}
		} else {
			(minimumDay, maximumDay) = (nil, nil);
		}
		switch (minimumDay, maximumDay) {
		case (nil, nil):
			cell.enabledRegion = nil;
		case (.some (let minimumDay), nil):
			cell.enabledRegion = minimumDay ..< CPCDay (containing: .distantFuture, calendar: self.calendar);
		case (nil, .some (let maximumDay)):
			cell.enabledRegion = CPCDay (containing: .distantPast, calendar: self.calendar) ..< maximumDay;
		case (.some (let minimumDay), .some (let maximumDay)):
			cell.enabledRegion = minimumDay ..< maximumDay;
		}
		return cell;
	}
}

extension CPCCalendarView.Layout: UICollectionViewDelegate {
	private var scrollToTodayDate: Date {
		if let minimumDate = self.minimumDate, minimumDate.timeIntervalSinceNow > 0.0 {
			return minimumDate;
		} else if let maximumDate = self.maximumDate, maximumDate.timeIntervalSinceNow < 0.0 {
			return maximumDate;
		} else {
			return Date ();
		}
	}
	
	internal func layoutMarginsDidChange () {
		if (self.columnContentInsetsReference == .fromLayoutMargins) {
			self.invalidateLayout ();
		}
	}
	
	internal func safeAreaInsetsDidChange () {
		if (self.columnContentInsetsReference == .fromSafeAreaInsets) {
			self.invalidateLayout ();
		}
	}

	internal func scrollViewShouldScrollToTop (_ scrollView: UIScrollView) -> Bool {
		return (scrollView !== self.collectionView) || !self.scrollToToday ();
	}
	
	@discardableResult
	internal func scrollToToday (animated: Bool = true) -> Bool {
		return self.scrollToDay (CPCDay (containing: self.scrollToTodayDate, calendar: self.calendar), animated: animated);
	}

	@discardableResult
	internal func scrollToDay (_ day: CPCDay, animated: Bool = true) -> Bool {
		guard !self.storage.isEmpty else {
			if let minimumDate = self.minimumDate, minimumDate > day.end {
				self.layoutInitialDate = minimumDate;
				return false;
			} else if let maximumDate = self.maximumDate, maximumDate < day.start {
				self.layoutInitialDate = maximumDate;
				return false;
			} else {
				self.layoutInitialDate = day.start;
				return true;
			}
		}
		
		let targetMonth = day.containingMonth;
		guard let indexPath = self.storage.indexPath (for: targetMonth) else {
			self.storage = self.tryCalculatingLayoutUntil (month: targetMonth, for: self.storage);
			guard self.storage.indexPath (for: targetMonth) != nil else {
				return false;
			}
			self.layoutInitialDate = day.start;
			self.collectionView?.reloadData ();
			return true;
		}
		
		guard let cellFrame = self.layoutAttributesForItem (at: indexPath)?.frame else {
			return false;
		}
		let viewsMgr = self.monthViewsManager;
		let titleHeight = viewsMgr.titleFont.lineHeight.rounded (.up) + viewsMgr.titleMargins.top + viewsMgr.titleMargins.bottom;
		let containingWeek = day.containingWeek;
		let dayCellHeight = (cellFrame.height - titleHeight) / CGFloat (targetMonth.count);
		let dayCellY = cellFrame.minY + titleHeight + CGFloat (targetMonth [ordinal: 0].distance (to: containingWeek)) * dayCellHeight;
		guard let collectionView = self.collectionView else {
			return false;
		}
		let effectiveContentInset: UIEdgeInsets;
		if #available (iOS 11.0, *) {
			effectiveContentInset = collectionView.adjustedContentInset
		} else {
			effectiveContentInset = collectionView.contentInset;
		};
		let bounds = collectionView.bounds.inset (by: effectiveContentInset), targetRect = bounds.offsetBy (dx: 0.0, dy: dayCellY + dayCellHeight / 2 - bounds.midY);
		collectionView.scrollRectToVisible (targetRect, animated: animated);
		return true;
	}
}

extension CPCCalendarView.Layout {
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
		if (self.ignoreFirstBoundsChange) {
			self.ignoreFirstBoundsChange = false;
			return false;
		}
		
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
		super.prepare ();
		self.storage = self.prepareUpdatedLayout (current: self.storage, invalidationContext: self.currentInvalidationContext);
		self.currentInvalidationContext = nil;
		self.performPostUpdateActions (for: self.storage);
	}
	
	private func allowedDatesRangeDidChange () {
		// TODO: constrain already calculated month views instead of performing full relayout
		self.invalidateLayout ();
		self.collectionView?.reloadData ();
	}
}

extension CPCCalendarView.Layout {
	internal final class Attributes: UICollectionViewLayoutAttributes {
		internal var month: CPCMonth?;
		internal var rowHeight = 0 as CGFloat;
		internal var drawLeadingSeparator = true;
		internal var drawTrailingSeparator = true;

		internal override func copy (with zone: NSZone? = nil) -> Any {
			let attributes = super.copy (with: zone);
			guard let result = attributes as? Attributes else {
				return attributes;
			}
			result.month = self.month;
			result.rowHeight = self.rowHeight;
			return result;
		}
	}
	
	internal class InvalidationContext: UICollectionViewLayoutInvalidationContext {
		internal let verticalOffset: CGFloat?;
		
		fileprivate static func forBoundsChange (_ newBounds: CGRect, currentStorage: Storage) -> InvalidationContext? {
			let contentSize = currentStorage.contentSize;
			guard currentStorage.sectionCount > 0, (newBounds.width - currentStorage.contentSize.width).magnitude < 1e-3 else {
				return InvalidationContext ();
			}
			
			guard (newBounds.minY > newBounds.height) || currentStorage.isTopBoundReached else {
				return InvalidationContext (verticalOffset: 5.0 * newBounds.height);
			}
			guard (newBounds.maxY < contentSize.height - newBounds.height) || currentStorage.isBottomBoundReached else {
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

fileprivate extension String {
	fileprivate static let cellIdentifier = "cellID";
}
