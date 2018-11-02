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

internal protocol CPCCalendarViewLayoutDelegate: UICollectionViewDelegate {
	func referenceIndexPathForCollectionView (_ collectionView: UICollectionView) -> IndexPath;
	func collectionView (_ collectionView: UICollectionView, startOfSectionFor indexPath: IndexPath) -> IndexPath;
	func collectionView (_ collectionView: UICollectionView, endOfSectionFor indexPath: IndexPath) -> IndexPath;
	func collectionView (_ collectionView: UICollectionView, estimatedAspectRatioComponentsForItemAt indexPath: IndexPath) -> CPCMonthView.AspectRatio;
}

internal extension CPCCalendarView {
	internal final class Layout: UICollectionViewLayout {
		internal typealias ColumnContentInsetReference = CPCCalendarView.ColumnContentInsetReference;
		
		private static var defaultColumnContentInsetReference: ColumnContentInsetReference {
			if #available (iOS 11.0, *) {
				return .fromSafeAreaInsets;
			} else {
				return .fromContentInset;
			}
		}
		
		internal var columnCount = 1 {
			didSet {
				guard self.columnCount > 0 else {
					return self.columnCount = 1;
				}
				self.invalidateLayout ();
				self.collectionView?.reloadData ();
			}
		}
		
		internal var columnContentInset = UIEdgeInsets.zero {
			didSet {
				self.invalidateLayout ();
				self.collectionView?.reloadData ();
			}
		}
		
		internal var columnContentInsetReference: ColumnContentInsetReference = Layout.defaultColumnContentInsetReference {
			didSet {
				self.invalidateLayout ();
				self.collectionView?.reloadData ();
			}
		}
		
		internal override var collectionViewContentSize: CGSize {
			return CGSize (width: guarantee (self.collectionView).bounds.width, height: .virtualContentHeight);
		}
		
		internal override func invalidateLayout (with context: UICollectionViewLayoutInvalidationContext) {
			let collectionView = guarantee (self.collectionView);
			if (context.invalidateDataSourceCounts) {
				self.referenceIndexPath = self.delegate?.referenceIndexPathForCollectionView (collectionView) ?? IndexPath ();
			}
			if (context.invalidateEverything) {
				self.storage = nil;
				collectionView.contentOffset = CGPoint (x: 0.0, y: .virtualOriginHeight - collectionView.bounds.height / 2.0);
			}
			super.invalidateLayout (with: context);
		}
		
		internal override func prepare () {
			super.prepare ();
		}
		
		private var delegate: CPCCalendarViewLayoutDelegate? {
			guard let delegate = self.collectionView?.delegate else {
				return nil;
			}
			guard let layoutDelegate = delegate as? CPCCalendarViewLayoutDelegate else {
				fatalError ("[CrispyCalendar]: invalid delegate type (\(delegate), \(CPCCalendarViewLayoutDelegate.self) is expected)");
			}
			return layoutDelegate;
		}
		
		internal var storage: Storage?;
		internal var referenceIndexPath = IndexPath ();
		
		private weak var invalidationContext: InvalidationContext?;
		
		internal override func layoutAttributesForItem (at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
			guard let storage = self.storage ?? self.makeInitialStorage () else {
				return nil;
			}
			let requestedRow = (indexPath.item - self.referenceIndexPath.item) / self.columnCount;
			if (storage.lastRowIndex <= requestedRow) {
				storage.appendRows ((storage.lastRowIndex ... requestedRow).map { self.estimateAspectRatios (forRowAt: $0) });
			}
			if (storage.firstRowIndex > requestedRow) {
				storage.prependRows (stride (from: storage.firstRowIndex - 1, through: requestedRow, by: -1).map { self.estimateAspectRatios (forRowAt: $0) });
			}
			return storage [indexPath];
		}
		
		internal override func layoutAttributesForElements (in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
			guard let storage = self.storage ?? self.makeInitialStorage () else {
				return nil;
			}
			while rect.minY < storage.minY {
				storage.prependRow (self.estimateAspectRatios (forRowAt: storage.firstRowIndex - 1));
			}
			while rect.maxY > storage.maxY {
				storage.appendRow (self.estimateAspectRatios (forRowAt: storage.lastRowIndex));
			}
			return storage [rect];
		}
	}
}

internal extension CPCCalendarView.Layout {
	internal final class Attributes: UICollectionViewLayoutAttributes {
		internal var drawsLeadingSeparator = false;
		internal var drawsTrailingSeparator = false;
		internal var rowHeight = 0.0 as CGFloat;
		internal var aspectRatio: CPCMonthView.AspectRatio = (0.0, 0.0);
		
		internal override func copy (with zone: NSZone? = nil) -> Any {
			let copiedValue = super.copy (with: zone);
			if let copiedAttributes = copiedValue as? Attributes {
				copiedAttributes.drawsLeadingSeparator = self.drawsLeadingSeparator;
				copiedAttributes.drawsTrailingSeparator = self.drawsTrailingSeparator;
				copiedAttributes.rowHeight = self.rowHeight;
				copiedAttributes.aspectRatio = self.aspectRatio;
			}
			return copiedValue;
		}
		
		internal override var description: String {
			return "<Attributes \(UnsafePointer (to: self)); frame: \(self.frame.offsetBy (dx: 0.0, dy: -.virtualOriginHeight)); height = \(self.aspectRatio.multiplier) x width + \(self.aspectRatio.constant); indexPath = \(self.indexPath))>"
		}
	}
	
	private final class InvalidationContext: UICollectionViewLayoutInvalidationContext {
		
	}
	
	internal func layoutMarginsDidChange () {
		if (self.columnContentInsetReference == .fromLayoutMargins) {
			self.invalidateLayout ();
		}
	}
	
	internal func safeAreaInsetsDidChange () {
		if (self.columnContentInsetReference == .fromSafeAreaInsets) {
			self.invalidateLayout ();
		}
	}
}

private extension CPCCalendarView.Layout {
	private var layoutInfo: Storage.LayoutInfo? {
		guard let collectionView = self.collectionView else {
			return nil;
		}
		return Storage.LayoutInfo (
			columnCount: self.columnCount,
			contentGuide: 0.0 ..< collectionView.bounds.width,
			contentScale: collectionView.separatorWidth,
			middleRowOrigin: .virtualOriginHeight
		);
	}
	
	private func makeInitialStorage () -> Storage? {
		guard let collectionView = self.collectionView, let delegate = self.delegate, let layoutInfo = self.layoutInfo else {
			return nil;
		}
		let sectionStart = delegate.collectionView (collectionView, startOfSectionFor: self.referenceIndexPath);
		let sectionEnd = delegate.collectionView (collectionView, endOfSectionFor: self.referenceIndexPath);
		let middleRowStartItem = self.referenceIndexPath.item - (self.referenceIndexPath.item - sectionStart.item) % self.columnCount;
		let middleRowEndItem = min (sectionEnd.item, middleRowStartItem + self.columnCount);
		
		let middleRowData: [(IndexPath, AspectRatio)] = (middleRowStartItem ..< middleRowEndItem).map {
			let indexPath = IndexPath (item: $0, section: 0);
			return (indexPath, delegate.collectionView (collectionView, estimatedAspectRatioComponentsForItemAt: indexPath));
		};
		self.storage = Storage (middleRowData: middleRowData, layoutInfo: layoutInfo);
		return self.storage;
	}
	
	private func estimateAspectRatios (forRowAt index: Int) -> [AspectRatio] {
		guard let collectionView = self.collectionView, let delegate = self.delegate else {
			return [];
		}
		return (index * self.columnCount ..< (index + 1) * self.columnCount).offset (by: self.referenceIndexPath.item).map {
			delegate.collectionView (collectionView, estimatedAspectRatioComponentsForItemAt: IndexPath (item: $0, section: 0))
		};
	}
}

internal extension UIEdgeInsets {
	internal var width: CGFloat {
		return self.left + self.right;
	}
}

fileprivate extension CGFloat {
	fileprivate static let virtualOriginHeight = CGFloat.virtualContentHeight / 2.0;
	fileprivate static let virtualContentHeight = CGFloat (1 << 38);
}
