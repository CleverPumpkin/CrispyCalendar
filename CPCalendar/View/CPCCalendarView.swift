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

internal extension CGRect {
	internal var bounds: CGRect {
		return CGRect (origin: .zero, size: CGSize (width: self.size.width.magnitude, height: self.size.height.magnitude));
	}
}

public protocol CPCCalendarViewSelectionDelegate: AnyObject {
	var selection: CPCViewSelection { get set };
	
	func calendarView (_ calendarView: CPCCalendarView, shouldSelect day: CPCDay) -> Bool;
	func calendarView (_ calendarView: CPCCalendarView, shouldDeselect day: CPCDay) -> Bool;
}

open class CPCCalendarView: UIView {
	open var calendar: Calendar {
		get { return self.calendarWrapper.calendar }
		set {
			guard self.calendarWrapper.calendar != newValue else {
				return;
			}
			self.calendarWrapper = newValue.wrapped ();
		}
	}
	
	open override var backgroundColor: UIColor? {
		didSet {
			self.collectionView.backgroundColor = self.backgroundColor;
		}
	}

	open var adjustsFontForContentSizeCategory = false {
		didSet {
			self.updateManagedMonthViews (using: { $0.adjustsFontForContentSizeCategory = self.adjustsFontForContentSizeCategory });
		}
	}
	
	open var minimumDate: Date? {
		get { return self.layout.minimumDate }
		set { self.layout.minimumDate = newValue }
	}
	
	open var maximumDate: Date? {
		get { return self.layout.maximumDate }
		set { self.layout.maximumDate = newValue }
	}

	internal unowned let collectionView: UICollectionView;

	internal var calendarViewController: CPCCalendarViewController?;
	internal var monthViewsManager: CPCMonthViewsManager {
		return self.layout.monthViewsManager;
	}
	
	public override init (frame: CGRect) {
		let collectionView = CPCCalendarView.makeCollectionView (frame);
		self.collectionView = collectionView;
		super.init (frame: frame);
		self.commonInit (collectionView);
	}
	
	public required init? (coder aDecoder: NSCoder) {
		let collectionView = CPCCalendarView.makeCollectionView (.zero);
		self.collectionView = collectionView;
		super.init (coder: aDecoder);
		self.commonInit (collectionView);
	}
	
	private func commonInit (_ collectionView: UICollectionView) {
		self.monthViewsManager.selectionDidChangeBlock = { [unowned self] in
			self.selectionDidChange ();
			self.calendarViewController?.selectionDidChange ();
		};
		self.layout.prepare (collectionView: collectionView);
		self.addSubview (collectionView);
	}

	open override func layoutSubviews () {
		super.layoutSubviews ();
		self.collectionView.frame = self.bounds;
	}
}

extension CPCCalendarView {
	internal var layout: Layout {
		return unsafeDowncast (self.collectionView.collectionViewLayout);
	}
	
	private var calendarWrapper: CPCCalendarWrapper {
		get { return self.layout.calendar }
		set {
			let layout = Layout (calendar: newValue);
			layout.prepare (collectionView: self.collectionView);
			self.collectionView.collectionViewLayout = layout;
		}
	}
	
	private static func makeCollectionView (_ frame: CGRect, calendar: Calendar = .current) -> UICollectionView {
		let collectionView = UICollectionView (frame: frame.bounds, collectionViewLayout: Layout (calendar: calendar.wrapped ()));
		collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight];
		collectionView.allowsSelection = false;
		return collectionView;
	}
	
	internal func invalidateLayout () {
		self.layout.invalidateLayout ();
	}
}

extension CPCCalendarView: CPCMultiMonthsViewProtocol {
	internal func updateManagedMonthViews (using block: (CPCMonthView) -> ()) {
		self.monthViewsManager.updateManagedMonthViews (using: block);
		self.layout.invalidateLayout ();
	}
}

extension CPCCalendarView: CPCViewBackedByAppearanceStorage {}

extension CPCCalendarView /* UIScrollViewProtocol */ {
	open var bounces: Bool {
		get { return self.collectionView.bounces }
		set { self.collectionView.bounces = newValue }
	}
	open var alwaysBounceVertical: Bool {
		get { return self.collectionView.alwaysBounceVertical }
		set { self.collectionView.alwaysBounceVertical = newValue }
	}
	open var alwaysBounceHorizontal: Bool {
		get { return self.collectionView.alwaysBounceHorizontal }
		set { self.collectionView.alwaysBounceHorizontal = newValue }
	}

	open var scrollsToToday: Bool {
		get { return self.collectionView.scrollsToTop }
		set { self.collectionView.scrollsToTop = newValue }
	}
	
	open var contentInset: UIEdgeInsets {
		get { return self.collectionView.contentInset }
		set { self.collectionView.contentInset = newValue }
	}
	open var scrollIndicatorInsets: UIEdgeInsets {
		get { return self.collectionView.scrollIndicatorInsets }
		set { self.collectionView.scrollIndicatorInsets = newValue }
	}
	@available (iOS 11.0, *)
	open var adjustedContentInset: UIEdgeInsets {
		return self.collectionView.adjustedContentInset;
	}
	@available (iOS 11.0, *)
	open var contentInsetAdjustmentBehavior: UIScrollViewContentInsetAdjustmentBehavior {
		get { return self.collectionView.contentInsetAdjustmentBehavior }
		set { self.collectionView.contentInsetAdjustmentBehavior = newValue }
	}

	open var showsHorizontalScrollIndicator: Bool {
		get { return self.collectionView.showsHorizontalScrollIndicator }
		set { self.collectionView.showsHorizontalScrollIndicator = newValue }
	}
	open var showsVerticalScrollIndicator: Bool {
		get { return self.collectionView.showsVerticalScrollIndicator }
		set { self.collectionView.showsVerticalScrollIndicator = newValue }
	}

}
