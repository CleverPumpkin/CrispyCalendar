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

/* internal */ extension CPCCalendarView {
	internal final class Layout: UICollectionViewLayout {
		
		// MARK: - Internal types
		
		internal typealias ColumnContentInsetReference = CPCCalendarView.ColumnContentInsetReference;
		
		// MARK: - Internal static properties
		
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
		
		// MARK: - Internal properties
		
		internal var columnCount = UIDevice.current.userInterfaceIdiom.defaultLayoutColumnsCount {
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
			
			let contentHeight: CGFloat
			
			switch storage?.height {
			case .unspecified:
				contentHeight = .virtualContentHeight
			case let .absolute(height):
				contentHeight = height
			case .none:
				contentHeight = 0
			}
			
			return CGSize(width: collectionView?.visibleContentBounds.width ?? 0.0, height: contentHeight)
		}
		
		internal let invalidLayoutAttributes = Attributes (forCellWith: IndexPath ());
		
		// MARK: - Private properties
		
		private var delegate: CPCCalendarViewLayoutDelegate? {
			guard let delegate = self.collectionView?.delegate else {
				return nil;
			}
			guard let layoutDelegate = delegate as? CPCCalendarViewLayoutDelegate else {
				fatalError ("[CrispyCalendar]: invalid delegate type (\(delegate), \(CPCCalendarViewLayoutDelegate.self) is expected)");
			}
			return layoutDelegate;
		}
		
		private var shouldCenterMiddleRow: Bool {
			numberOfMonthsToDisplay == nil
		}
		
		private var storage: Storage?;
		private var prevStorage: Storage?;
		private var referenceIndexPath: IndexPath = [];
		private var invalidationContext: InvalidationContext?;
		private let numberOfMonthsToDisplay: Int?
		
		// MARK: - Initialization
		
		init(numberOfMonthsToDisplay: Int? = nil) {
			self.numberOfMonthsToDisplay = numberOfMonthsToDisplay
			
			super.init()
		}
		
		required init?(coder: NSCoder) {
			self.numberOfMonthsToDisplay = nil
			
			super.init(coder: coder)
		}
		
		// MARK: - Internal methods
		
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
			let context = self.makeInvalidationContext (with: context);
			let collectionView = guarantee (self.collectionView);
			if (context.invalidateDataSourceCounts) {
				self.referenceIndexPath = self.delegate?.referenceIndexPathForCollectionView (collectionView) ?? [];
			}
			if (context.invalidateEverything) {
				self.storage = nil;
				collectionView.contentCenterOffset.y = numberOfMonthsToDisplay == nil ? .virtualOriginHeight : 0
			}
			
			if let storage = self.storage {
				if (context.invalidateAllRows) {
					storage.invalidate ();
				} else if let invalidatedRows = context.invalidatedRows {
					storage.invalidate (rowsIn: invalidatedRows);
				}
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
			var updatedAspectRatios = context.updatedAspectRatios ?? [:];
			updatedAspectRatios [original.position] = preferred.aspectRatio;
			context.updatedAspectRatios = updatedAspectRatios;
			if (indexPath.item < self.referenceIndexPath.item) {
				context.invalidateItems (at: stride (from: indexPath.item, through: storage.firstIndexPath.item, by: -1).map { IndexPath (item: $0, section: 0) });
			} else {
				context.invalidateItems (at: stride (from: indexPath.item, to: storage.lastIndexPath.item, by: 1).map { IndexPath (item: $0, section: 0) });
			}
			return context;
		}

		internal override func shouldInvalidateLayout (forBoundsChange newBounds: CGRect) -> Bool {
			guard let storage = self.storage, !storage.isStorageValid (forContentGuide: self.contentGuide (for: newBounds), columnSpacing: self.columnSpacing) else {
				return self.storage == nil;
			}
			return true;
		}
		
		internal override func invalidationContext (forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
			let context = self.makeInvalidationContext ();
			context.updatedContentGuide = true;
			self.storage?.invalidate ();
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
			
			if let context = self.invalidationContext, let storage = self.storage, let prevBounds = context.prevBounds {
				if let updatedAspectRatios = context.updatedAspectRatios {
					storage.updateStoredAttributes (using: updatedAspectRatios);
					storage.layoutElements (in: collectionView.visibleContentBounds);
				}
				
				let prevStorage = storage.copy ();
				self.prevStorage = prevStorage;
				
				let centerRectHeight = max (self.columnContentInset.height, 1.0);
				let centerRect = CGRect (x: prevStorage.contentGuideLeading, y: prevBounds.midY - centerRectHeight, width: prevStorage.contentGuideWidth, height: 2.0 * centerRectHeight);
				let visibleIndexPaths = prevStorage [centerRect];
				let middleIndexPath	= visibleIndexPaths.min { ($0.frame.midX - centerRect.midX).magnitude < ($1.frame.midX - centerRect.midX).magnitude }?.indexPath ?? self.referenceIndexPath;
				let additionalOffset = ((prevStorage [middleIndexPath]?.frame.midY).map { $0 - prevBounds.midY } ?? 0.0) / prevBounds.height * bounds.height;

				if context.updatedColumnCount {
					self.makeStorage (middleIndexPath: middleIndexPath, layoutInfo: Storage.LayoutInfo (
						columnCount: self.columnCount,
						contentGuide: self.contentGuide,
						columnSpacing: self.columnSpacing,
						contentScale: collectionView.separatorWidth,
						middleRowOrigin: bounds.midY + additionalOffset,
						invalidAttributes: self.invalidLayoutAttributes,
						numberOfMonthsToDisplay: self.numberOfMonthsToDisplay
					));
				} else if context.updatedContentGuide {
					storage.updateContentGuide (self.contentGuide);
					if numberOfMonthsToDisplay == nil, let middleCellFrame = self.layoutAttributesForItem (at: middleIndexPath)?.frame {
						collectionView.contentCenterOffset.y = middleCellFrame.midY + additionalOffset;
					} else {
						collectionView.contentCenterOffset.y = additionalOffset;
					}
				}
			}
		}
		
		internal override func initialLayoutAttributesForAppearingItem (at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
			return self.prevStorage? [itemIndexPath];
		}
		
		override func finalLayoutAttributesForDisappearingItem (at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
			return self.storage? [itemIndexPath];
		}
		
		internal override func finalizeAnimatedBoundsChange () {
			self.prevStorage = nil;
			super.finalizeAnimatedBoundsChange ();
		}
	}
}

/* internal */ extension CPCCalendarView.Layout {
	internal final class Attributes: UICollectionViewLayoutAttributes {
		internal var drawsLeadingSeparator = false;
		internal var drawsTrailingSeparator = false;
		internal var position = Storage.AttributesPosition (row: 0, item: 0);
		internal var rowHeight = 0.0 as CGFloat;
		internal var aspectRatio: CPCMonthView.AspectRatio = (0.0, 0.0);
		
		internal override func isEqual (_ object: Any?) -> Bool {
			guard super.isEqual (object), let object = object as? Attributes else {
				return false;
			}
			guard self !== object else {
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
			return """
				<Attributes \(UnsafePointer (to: self));
				frame: \(self.frame);
				indexPath: \(self.indexPath));
				position: [\(self.position.row), \(self.position.item)];
				height = \(self.aspectRatio.multiplier) x width + \(self.aspectRatio.constant)>
			""".replacingOccurrences (of: "\n\t", with: " ");
		}
	}
	
	internal func contentGuideDidChange () {
		guard let storage = self.storage, !storage.isStorageValid (forContentGuide: self.contentGuide, columnSpacing: self.columnSpacing) else {
			return;
		}
		
		let context = self.makeInvalidationContext ();
		context.updatedContentGuide = true;
		self.invalidateLayout (with: context);
	}
}

private extension CPCCalendarView.Layout {
	private final class InvalidationContext: UICollectionViewLayoutInvalidationContext {
		fileprivate var prevBounds: CGRect?;

		fileprivate var updatedAspectRatios: [Storage.AttributesPosition: AspectRatio]?;
		fileprivate var invalidatedRows: IndexSet?;
		fileprivate var updatedContentGuide = false;
		fileprivate var updatedColumnCount = false;
		fileprivate var invalidateAllRows: Bool {
			return self.updatedContentGuide || self.updatedColumnCount;
		}

		fileprivate func invalidateRows <S> (_ rows: S) where S: Sequence, S.Element == Int {
			let invalidatedRows = IndexSet (rows);
			self.invalidatedRows = self.invalidatedRows.map { invalidatedRows.union ($0) } ?? invalidatedRows;
		}
		
		internal override var description: String {
			return """
				<InvalidationContext \(UnsafePointer (to: self));
				invalidatedItemIndexPaths: \(self.invalidatedItemIndexPaths?.description ?? "nil");
				invalidatedSupplementaryIndexPaths: \(self.invalidatedSupplementaryIndexPaths?.description ?? "nil");
				invalidatedDecorationIndexPaths: \(self.invalidatedDecorationIndexPaths?.description ?? "nil");
				invalidatedRows: \(self.invalidateAllRows ? "all" : self.invalidatedRows?.description ?? "nil");
				updatedAspectRatios: \(self.updatedAspectRatios?.map { "\($0.key) -> \($0.value)" }.joined (separator: ", ") ?? "nil");
				updatedContentGuide: \(self.updatedContentGuide);
				updatedColumnCount: \(self.updatedColumnCount))>
			""".replacingOccurrences (of: "\n\t", with: " ");
		}
	}
	
	private var visibleContentBounds: CGRect {
		return (self.collectionView?.bounds).map { self.contentBounds (for: $0) } ?? .null;
	}
	
	private var contentGuide: Range <CGFloat> {
		return (self.collectionView?.bounds).map { self.contentGuide (for: $0) } ?? (.nan ..< .nan);
	}
	
	private var columnSpacing: CGFloat {
		return (self.columnContentInset.left + self.columnContentInset.right) / 2.0;
	}
	
	private func contentGuide (for bounds: CGRect) -> Range <CGFloat> {
		let contentBounds = self.contentBounds (for: bounds);
		guard !contentBounds.isInfinite else {
			return .nan ..< .nan;
		}
		return (contentBounds.minX + self.columnContentInset.left) ..< contentBounds.maxX - self.columnContentInset.right;
	}
	
	private func contentBounds (for bounds: CGRect) -> CGRect {
		guard let collectionView = self.collectionView else {
			return .null;
		}

		let contentBounds = collectionView.contentBounds (for: bounds);
		let insetBounds: CGRect;
		switch (self.columnContentInsetReference) {
		case .fromContentInset:
			insetBounds = contentBounds;
			break;
		case .fromLayoutMargins:
			insetBounds = bounds.inset (by: collectionView.layoutMargins).intersection (contentBounds);
		case .fromSafeAreaInsets:
			if #available (iOS 11.0, *) {
				insetBounds = bounds.inset (by: collectionView.safeAreaInsets).intersection (contentBounds);
			} else {
				insetBounds = contentBounds;
			}
		}
		return insetBounds.offsetBy (dx: bounds.minX - contentBounds.minX, dy: bounds.minY - contentBounds.minY);
	}
	
	private func makeInitialStorage () -> Storage? {
		guard let collectionView = self.collectionView else {
			return nil;
		}
		return self.makeStorage (middleIndexPath: self.referenceIndexPath, layoutInfo: Storage.LayoutInfo (
			columnCount: self.columnCount,
			contentGuide: self.contentGuide,
			columnSpacing: self.columnSpacing,
			contentScale: collectionView.separatorWidth,
			middleRowOrigin: .virtualOriginHeight,
			invalidAttributes: self.invalidLayoutAttributes,
			numberOfMonthsToDisplay: self.numberOfMonthsToDisplay
		));
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
		let sectionStart = delegate.collectionView (collectionView, startOfSectionFor: indexPath.offset (by: -1));
		return (sectionStart.item + (indexPath.item - sectionStart.item - self.columnCount).nextDividable (by: self.columnCount)) ..< indexPath.item;
	}
	
	private func rowItemIndices (forRowAfter indexPath: IndexPath, in collectionView: UICollectionView, delegate: CPCCalendarViewLayoutDelegate) -> Range <Int> {
		let sectionEnd = delegate.collectionView (collectionView, endOfSectionFor: indexPath);
		return indexPath.item ..< min (sectionEnd.item, indexPath.item + self.columnCount);
	}
	
	private func makeInvalidationContext (with otherContext: UICollectionViewLayoutInvalidationContext? = nil) -> InvalidationContext {
		let context: InvalidationContext;
		if let currentContext = self.invalidationContext {
			context = currentContext;
		} else {
			switch (otherContext) {
			case nil:
				context = InvalidationContext ();
			case let otherContext as InvalidationContext:
				context = otherContext;
			case .some (let otherContext):
				fatalError ("Cannot use invalidation context \(otherContext), \(InvalidationContext.self) expected");
			}
			self.invalidationContext = context;
		}
		if (context.prevBounds == nil) {
			context.prevBounds = self.visibleContentBounds;
		}
		return context;
	}

	private func columnCountDidChange () {
		guard let storage = self.storage, !storage.isStorageValid (forColumnCount: self.columnCount) else {
			return;
		}
		let context = self.makeInvalidationContext ();
		context.updatedColumnCount = true;
		self.invalidateLayout (with: context);
	}
}

/* fileprivate */ extension UICollectionView {
	fileprivate var visibleContentBounds: CGRect {
		return self.contentBounds (for: self.bounds);
	}
	
	fileprivate var contentCenterOffset: CGPoint {
		get {
			let value = self.contentOffset, bounds = self.visibleContentBounds, insets = self.effectiveContentInset;
			return CGPoint (
				x: value.x + insets.left + bounds.width / 2,
				y: value.y + insets.top + bounds.height / 2
			);
		}
		set {
			let bounds = self.visibleContentBounds, insets = self.effectiveContentInset;
			self.contentOffset = CGPoint (
				x: newValue.x - bounds.width / 2 - insets.left,
				y: newValue.y - bounds.height / 2 - insets.top
			);
		}
	}
	
	fileprivate var effectiveContentInset: UIEdgeInsets {
		if #available (iOS 11.0, *) {
			return self.adjustedContentInset;
		} else {
			return self.contentInset;
		}
	}
	
	fileprivate func contentBounds (for bounds: CGRect) -> CGRect {
		return bounds.inset (by: self.effectiveContentInset);
	}
}

/* internal */ extension UIEdgeInsets {
	internal var width: CGFloat {
		return self.left + self.right;
	}

	internal var height: CGFloat {
		return self.top + self.bottom;
	}
}

/* fileprivate */ extension CGFloat {
	fileprivate static let virtualOriginHeight = CGFloat.virtualContentHeight / 2.0;
#if arch(x86_64) || arch(arm64)
	fileprivate static let virtualContentHeight = CGFloat (1 << 38);
#else
	fileprivate static let virtualContentHeight = CGFloat (1 << 19);
#endif
}

/* fileprivate */ extension UIUserInterfaceIdiom {
	fileprivate var defaultLayoutColumnsCount: Int {
		switch (self) {
		case .unspecified, .phone, .carPlay:
			return 1;
		case .pad, .tv:
			return 3;
		@unknown default:
			return 1;
		}
	}
}

/* fileprivate */ extension BinaryInteger {
	fileprivate func nextDividable (by divisor: Self) -> Self {
		let remainder = self % divisor;
		return ((remainder > 0) ? self + divisor - remainder : self);
	}
}
