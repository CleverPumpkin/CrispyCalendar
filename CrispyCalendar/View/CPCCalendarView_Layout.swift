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
		
		internal override class var invalidationContextClass: AnyClass {
			return InvalidationContext.self;
		}
		
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
				self.columnCountDidChange ();
			}
		}
		
		internal var columnContentInset = UIEdgeInsets.zero {
			didSet {
				self.contentGuideDidChange ();
			}
		}
		
		internal var columnContentInsetReference: ColumnContentInsetReference = Layout.defaultColumnContentInsetReference {
			didSet {
				self.contentGuideDidChange ();
			}
		}
		
		internal override var collectionViewContentSize: CGSize {
			return CGSize (width: self.collectionView?.visibleContentBounds.width ?? 0.0, height: .virtualContentHeight);
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
		
		private var storage: Storage?;
		private var referenceIndexPath: IndexPath = [];
		
		private var prevStorage: Storage?;
		private var invalidationContext: InvalidationContext?;
		
		internal override func layoutAttributesForItem (at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
			guard let storage = self.storage ?? self.makeInitialStorage () else {
				return nil;
			}
			while storage.lastIndexPath <= indexPath {
				storage.appendRow (self.estimateAspectRatios (forRowAfter: storage.lastIndexPath));
			}
			while storage.firstIndexPath > indexPath {
				storage.prependRow (self.estimateAspectRatios (forRowBefore: storage.firstIndexPath));
			}
			return storage [indexPath];
		}
		
		internal override func layoutAttributesForElements (in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
			guard let storage = self.storage ?? self.makeInitialStorage () else {
				return nil;
			}
			
			storage.layoutElements (in: rect);
			
			while rect.minY < storage.minY {
				storage.prependRow (self.estimateAspectRatios (forRowBefore: storage.firstIndexPath), layoutImmediately: true);
			}
			while rect.maxY > storage.maxY {
				storage.appendRow (self.estimateAspectRatios (forRowAfter: storage.lastIndexPath), layoutImmediately: true);
			}
			return storage [rect];
		}
		
		internal override func invalidateLayout (with context: UICollectionViewLayoutInvalidationContext) {
			let collectionView = guarantee (self.collectionView);
			if (context.invalidateDataSourceCounts) {
				self.referenceIndexPath = self.delegate?.referenceIndexPathForCollectionView (collectionView) ?? [];
			}
			if (context.invalidateEverything) {
				self.storage = nil;
				collectionView.contentOffset = CGPoint (x: 0.0, y: .virtualOriginHeight - collectionView.visibleContentBounds.height / 2.0);
			}
			super.invalidateLayout (with: context);
		}
		
		internal override func shouldInvalidateLayout (forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Bool {
			guard let originalAttributes = originalAttributes as? Attributes, let preferredAttributes = preferredAttributes as? Attributes else {
				return false;
			}
			return (
				((originalAttributes.aspectRatio.multiplier - preferredAttributes.aspectRatio.multiplier).magnitude > 1e-3) ||
				((originalAttributes.aspectRatio.constant - preferredAttributes.aspectRatio.constant).magnitude > 1e-3)
			);
		}
		
		internal override func invalidationContext (forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutInvalidationContext {
			guard let original = originalAttributes as? Attributes, let preferred = preferredAttributes as? Attributes, let storage = self.storage else {
				return super.invalidationContext (forPreferredLayoutAttributes: preferredAttributes, withOriginalAttributes: originalAttributes);
			}
			
			let indexPath = original.indexPath;
			let context = self.makeInvalidationContext ();
			context.updatedAspectRatios [original.position] = preferred.aspectRatio;
			if (indexPath.item < self.referenceIndexPath.item) {
				context.invalidateItems (at: stride (from: indexPath.item, through: storage.firstIndexPath.item, by: -1).map { IndexPath (item: $0, section: 0) });
			} else {
				context.invalidateItems (at: stride (from: indexPath.item, to: storage.lastIndexPath.item, by: 1).map { IndexPath (item: $0, section: 0) });
			}
			return context;
		}

		internal override func shouldInvalidateLayout (forBoundsChange newBounds: CGRect) -> Bool {
			guard let storage = self.storage, !storage.isStorageValid (forContentGuide: self.contentGuide, columnSpacing: self.columnSpacing) else {
				return self.storage == nil;
			}
			return true;
		}
		
		internal override func invalidationContext (forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
			let context = self.makeInvalidationContext ();
			context.updatedContentGuide = true;
			return context;
		}
		
		internal override func prepare () {
			super.prepare ();
			
			defer {
				self.invalidationContext = nil;
			}
			guard let collectionView = self.collectionView else {
				return;
			}
			let bounds = collectionView.visibleContentBounds;
			
			if let context = self.invalidationContext, let storage = self.storage {
				storage.updateStoredAttributes (using: context.updatedAspectRatios);
				if context.updatedColumnCount {
					let prevBounds = context.prevBounds;
					let visibleIndexPaths = storage [CGRect (x: prevBounds.midX - 1.0, y: prevBounds.midY - 1.0, width: 2.0, height: 2.0)];
					let middleIndexPath	= (visibleIndexPaths.isEmpty ? self.referenceIndexPath : visibleIndexPaths [visibleIndexPaths.count / 2].indexPath);
					let additionalOffset = ((storage [middleIndexPath]?.frame.midY).map { $0 - prevBounds.midY } ?? 0.0) / prevBounds.height * bounds.height;
					
					let layoutInfo = Storage.LayoutInfo (
						columnCount: self.columnCount,
						contentGuide: self.contentGuide,
						columnSpacing: self.columnSpacing,
						contentScale: collectionView.separatorWidth,
						middleRowOrigin: bounds.midY + additionalOffset
					);
					
					self.prevStorage = self.storage;
					self.makeStorage (middleIndexPath: middleIndexPath, layoutInfo: layoutInfo);
				} else if context.updatedContentGuide {
					storage.updateContentGuide (self.contentGuide);
				}
			}
		}
		
		internal override func prepare (forAnimatedBoundsChange oldBounds: CGRect) {
			super.prepare (forAnimatedBoundsChange: oldBounds);
			self.prevStorage = self.storage?.copy ();
		}
		
		internal override func finalizeAnimatedBoundsChange () {
			self.prevStorage = nil;
			super.finalizeAnimatedBoundsChange ();
		}
	}
}

internal extension CPCCalendarView.Layout {
	internal final class Attributes: UICollectionViewLayoutAttributes {
		internal override var frame: CGRect {
			didSet { self.isFrameValid = true }
		}
		internal var drawsLeadingSeparator = false;
		internal var drawsTrailingSeparator = false;
		internal var position = Storage.AttributesPosition (row: 0, item: 0);
		internal var rowHeight = 0.0 as CGFloat;
		internal var aspectRatio: CPCMonthView.AspectRatio = (0.0, 0.0) {
			didSet {
				if (((self.aspectRatio.constant - oldValue.constant).magnitude > 1e-3) || ((self.aspectRatio.multiplier - oldValue.multiplier).magnitude > 1e-3)) {
					self.isFrameValid = false;
				}
			}
		}
		internal private (set) var isFrameValid = false;
		
		internal func invalidateFrame () {
			self.isFrameValid = false;
		}

		internal override func isEqual (_ object: Any?) -> Bool {
			guard super.isEqual (object), let object = object as? Attributes else {
				return false;
			}
			if self === object {
				return true;
			}
			return (
				(self.drawsLeadingSeparator == object.drawsLeadingSeparator) &&
				(self.drawsTrailingSeparator == object.drawsTrailingSeparator) &&
				(self.position == object.position) &&
				((self.rowHeight - object.rowHeight).magnitude < 1e-3) &&
				((self.aspectRatio.constant - object.aspectRatio.constant).magnitude < 1e-3) &&
				((self.aspectRatio.multiplier - object.aspectRatio.multiplier).magnitude < 1e-3)
			);
		}

		internal override func copy (with zone: NSZone? = nil) -> Any {
			let copiedValue = super.copy (with: zone);
			if let copiedAttributes = copiedValue as? Attributes {
				copiedAttributes.drawsLeadingSeparator = self.drawsLeadingSeparator;
				copiedAttributes.drawsTrailingSeparator = self.drawsTrailingSeparator;
				copiedAttributes.position = self.position;
				copiedAttributes.rowHeight = self.rowHeight;
				copiedAttributes.aspectRatio = self.aspectRatio;
			}
			return copiedValue;
		}
		
		internal override var description: String {
			return "<Attributes \(UnsafePointer (to: self)); frame: \(self.frame); height = \(self.aspectRatio.multiplier) x width + \(self.aspectRatio.constant); indexPath = \(self.indexPath)); position = [\(self.position.row, self.position.item)]>"
		}
	}
	
	internal func layoutMarginsDidChange () {
		self.contentGuideDidChange ();
	}
	
	internal func safeAreaInsetsDidChange () {
		self.contentGuideDidChange ();
	}
}

private extension CPCCalendarView.Layout {
	private final class InvalidationContext: UICollectionViewLayoutInvalidationContext {
		fileprivate let prevBounds: CGRect;

		fileprivate var updatedAspectRatios = [Storage.AttributesPosition: AspectRatio] ();
		fileprivate var updatedContentGuide = false;
		fileprivate var updatedColumnCount = false;
		
		fileprivate convenience override init () {
			self.init (bounds: .null);
		}
		
		fileprivate init (bounds: CGRect) {
			self.prevBounds = bounds;
			super.init ();
		}
	}
	
	private var visibleContentBounds: CGRect {
		guard let collectionView = self.collectionView else {
			return .null;
		}
		
		let bounds = collectionView.bounds, visibleBounds = collectionView.visibleContentBounds;
		let insetBounds: CGRect;
		switch (self.columnContentInsetReference) {
		case .fromContentInset:
			insetBounds = visibleBounds;
			break;
		case .fromLayoutMargins:
			insetBounds = collectionView.bounds.inset (by: collectionView.layoutMargins).intersection (visibleBounds);
		case .fromSafeAreaInsets:
			if #available (iOS 11.0, *) {
				insetBounds = collectionView.bounds.inset (by: collectionView.safeAreaInsets).intersection (visibleBounds);
			} else {
				insetBounds = visibleBounds;
			}
		}
		return insetBounds.offsetBy (dx: bounds.minX - visibleBounds.minX, dy: bounds.minY - visibleBounds.minY);
	}
	
	private var contentGuide: Range <CGFloat> {
		let contentBounds = self.visibleContentBounds;
		guard !contentBounds.isInfinite else {
			return .nan ..< .nan;
		}
		return (contentBounds.minX + self.columnContentInset.left) ..< contentBounds.maxX - self.columnContentInset.right;
	}
	
	private var columnSpacing: CGFloat {
		return (self.columnContentInset.left + self.columnContentInset.right) / 2.0;
	}
	
	private func makeInitialStorage () -> Storage? {
		guard let collectionView = self.collectionView else {
			return nil;
		}
		let layoutInfo = Storage.LayoutInfo (
			columnCount: self.columnCount,
			contentGuide: self.contentGuide,
			columnSpacing: self.columnSpacing,
			contentScale: collectionView.separatorWidth,
			middleRowOrigin: .virtualOriginHeight
		);
		return self.makeStorage (middleIndexPath: self.referenceIndexPath, layoutInfo: layoutInfo);
	}
	
	@discardableResult
	private func makeStorage (middleIndexPath: IndexPath, layoutInfo: Storage.LayoutInfo) -> Storage? {
		guard let collectionView = self.collectionView, let delegate = self.delegate else {
			return nil;
		}
		let sectionStart = delegate.collectionView (collectionView, startOfSectionFor: middleIndexPath);
		let sectionEnd = delegate.collectionView (collectionView, endOfSectionFor: middleIndexPath);
		let middleRowStartItem = sectionStart.item + (middleIndexPath.item - sectionStart.item) / self.columnCount * self.columnCount;
		let middleRowEndItem = min (sectionEnd.item, middleRowStartItem + self.columnCount);
		
		let middleRowData: [(IndexPath, AspectRatio)] = (middleRowStartItem ..< middleRowEndItem).map {
			let indexPath = IndexPath (item: $0, section: 0);
			return (indexPath, delegate.collectionView (collectionView, estimatedAspectRatioComponentsForItemAt: indexPath));
		};
		self.storage = Storage (middleRowData: middleRowData, layoutInfo: layoutInfo);
		return self.storage;
	}
	
	private func estimateAspectRatios (forRowBefore indexPath: IndexPath) -> [AspectRatio] {
		return self.estimateAspectRatios (startingAt: indexPath, using: self.rowItemIndices (forRowBefore:in:delegate:));
	}

	private func estimateAspectRatios (forRowAfter indexPath: IndexPath) -> [AspectRatio] {
		return self.estimateAspectRatios (startingAt: indexPath, using: self.rowItemIndices (forRowAfter:in:delegate:));
	}
	
	private func estimateAspectRatios (startingAt startIndexPath: IndexPath, using rowIndicesGetter: (IndexPath, UICollectionView, CPCCalendarViewLayoutDelegate) -> Range <Int>) -> [AspectRatio] {
		guard let collectionView = self.collectionView, let delegate = self.delegate else {
			return [];
		}
		return rowIndicesGetter (startIndexPath, collectionView, delegate).map {
			delegate.collectionView (collectionView, estimatedAspectRatioComponentsForItemAt: IndexPath (item: $0, section: 0));
		};
	}
	
	private func rowItemIndices (forRowBefore indexPath: IndexPath, in collectionView: UICollectionView, delegate: CPCCalendarViewLayoutDelegate) -> Range <Int> {
		let indexPath =  indexPath.offset (by: -1);
		let sectionStart = delegate.collectionView (collectionView, startOfSectionFor: indexPath);
		return sectionStart.item + (indexPath.item - sectionStart.item) / self.columnCount * self.columnCount ..< indexPath.item + 1;
	}
	
	private func rowItemIndices (forRowAfter indexPath: IndexPath, in collectionView: UICollectionView, delegate: CPCCalendarViewLayoutDelegate) -> Range <Int> {
		let sectionEnd = delegate.collectionView (collectionView, endOfSectionFor: indexPath);
		return indexPath.item ..< min (sectionEnd.item, indexPath.item + self.columnCount);
	}
	
	private func makeInvalidationContext () -> InvalidationContext {
		if let context = self.invalidationContext {
			return context;
		}
		let context = InvalidationContext (bounds: self.visibleContentBounds);
		self.invalidationContext = context;
		return context;
	}
	
	private func contentGuideDidChange () {
		guard let collectionView = self.collectionView else {
			return;
		}
		if (self.shouldInvalidateLayout (forBoundsChange: collectionView.bounds)) {
			self.invalidateLayout (with: self.invalidationContext (forBoundsChange: collectionView.bounds));
		}
	}

	private func columnCountDidChange () {
		if !(self.storage?.isStorageValid (forColumnCount: self.columnCount) ?? true) {
			let context = self.makeInvalidationContext ();
			context.updatedColumnCount = true;
			self.invalidateLayout (with: context);
		}
	}
}

fileprivate extension UICollectionView {
	fileprivate var visibleContentBounds: CGRect {
		return self.bounds.inset (by: self.effectiveContentInset);
	}
	
	fileprivate var effectiveContentInset: UIEdgeInsets {
		if #available (iOS 11.0, *) {
			return self.adjustedContentInset;
		} else {
			return self.contentInset;
		}
	}
}

internal extension UIEdgeInsets {
	internal var width: CGFloat {
		return self.left + self.right;
	}

	internal var height: CGFloat {
		return self.top + self.bottom;
	}
}

fileprivate extension CGFloat {
	fileprivate static let virtualOriginHeight = CGFloat.virtualContentHeight / 2.0;
#if arch(x86_64) || arch(arm64)
	fileprivate static let virtualContentHeight = CGFloat (1 << 38);
#else
	fileprivate static let virtualContentHeight = CGFloat (1 << 19);
#endif
}
