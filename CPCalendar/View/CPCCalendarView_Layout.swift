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
		
		private var storage = makeEmptyStorage ();
		private var currentInvalidationContext: InvalidationContext?;
		
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
		let enabledRegionStart = CPCDay (containing: (self.minimumDate ?? .distantPast), calendar: self.calendar);
		let enabledRegionEnd = CPCDay (containing: (self.maximumDate ?? .distantFuture), calendar: self.calendar);
		cell.enabledRegion = enabledRegionStart ..< enabledRegionEnd;
		return cell;
	}
}

extension CPCCalendarView.Layout: UICollectionViewDelegate {
	
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
		
		internal override var invalidateEverything: Bool {
			return self.verticalOffset == nil;
		}
		
		internal override var invalidateDataSourceCounts: Bool {
			return true;
		}
		
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
