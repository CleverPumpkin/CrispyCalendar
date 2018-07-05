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
	
	deinit {
		self.monthViewsManager.prepareForContainerDeallocation ();
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
		collectionView.isDirectionalLockEnabled = true;
		collectionView.alwaysBounceVertical = true;
		return collectionView;
	}
	
	internal func invalidateLayout () {
		self.layout.invalidateLayout ();
	}
}

extension CPCCalendarView: CPCViewProtocol {
	@IBInspectable open dynamic var titleFont: UIFont {
		get { return self.monthViewsManager.titleFont }
		set {
			self.monthViewsManager.titleFont = newValue;
			self.invalidateLayout ();
		}
	}
	
	@IBInspectable open dynamic var titleColor: UIColor {
		get { return self.monthViewsManager.titleColor }
		set { self.monthViewsManager.titleColor = newValue }
	}
	
	@IBInspectable open dynamic var titleAlignment: NSTextAlignment {
		get { return self.monthViewsManager.titleAlignment }
		set { self.monthViewsManager.titleAlignment = newValue }
	}
	
	open var titleStyle: TitleStyle {
		get { return self.monthViewsManager.titleStyle }
		set {
			guard !self.isAppearanceProxy else {
				return self.titleFormat = newValue.rawValue;
			}
			guard newValue != self.titleStyle else {
				return;
			}
			self.monthViewsManager.titleStyle = newValue;
			self.invalidateLayout ();
		}
	}
	
	@IBInspectable open dynamic var titleMargins: UIEdgeInsets {
		get { return self.monthViewsManager.titleMargins }
		set {
			guard newValue != self.titleMargins else {
				return;
			}
			self.monthViewsManager.titleMargins = newValue;
			self.invalidateLayout ();
		}
	}
	
	@IBInspectable open dynamic var dayCellFont: UIFont {
		get { return self.monthViewsManager.dayCellFont }
		set {
			self.monthViewsManager.dayCellFont = newValue;
			self.invalidateLayout ();
		}
	}
	
	@IBInspectable open dynamic var dayCellTextColor: UIColor {
		get { return self.monthViewsManager.dayCellTextColor }
		set { self.monthViewsManager.dayCellTextColor = newValue }
	}
	
	@IBInspectable open dynamic var separatorColor: UIColor {
		get { return self.monthViewsManager.separatorColor }
		set { self.monthViewsManager.separatorColor = newValue }
	}
	
	open var cellRenderer: CellRenderer {
		get { return self.monthViewsManager.cellRenderer }
		set { self.monthViewsManager.cellRenderer = newValue }
	}
	
	@objc dynamic internal func dayCellBackgroundColor (for backgroundStateValue: Int, isTodayValue: Int) -> UIColor? {
		return self.dayCellBackgroundColorImpl (backgroundStateValue, isTodayValue);
	}
	
	open func dayCellBackgroundColor (for state: DayCellState) -> UIColor? {
		guard !self.isAppearanceProxy else {
			let (backgroundStateValue, isTodayValue) = state.appearanceValues;
			return self.dayCellBackgroundColor (for: backgroundStateValue, isTodayValue: isTodayValue);
		}
		return self.monthViewsManager.dayCellBackgroundColor (for: state);
	}
	
	@objc dynamic internal func setDayCellBackgroundColor (_ backgroundColor: UIColor?, for backgroundStateValue: Int, isTodayValue: Int) {
		return self.setDayCellBackgroundColorImpl (backgroundColor, backgroundStateValue, isTodayValue);
	}
	
	open func setDayCellBackgroundColor (_ backgroundColor: UIColor?, for state: DayCellState) {
		guard !self.isAppearanceProxy else {
			let (backgroundStateValue, isTodayValue) = state.appearanceValues;
			return self.setDayCellBackgroundColor (backgroundColor, for: backgroundStateValue, isTodayValue: isTodayValue);
		}
		self.monthViewsManager.setDayCellBackgroundColor (backgroundColor, for: state);
	}
}

extension CPCCalendarView: CPCViewDelegatingSelectionHandling {
	public typealias SelectionDelegateType = CPCCalendarViewSelectionDelegate;
	
	open var selectionDelegate: SelectionDelegateType? {
		get {
			return (self.selectionHandler as? CPCViewDelegatingSelectionHandler)?.delegate as? SelectionDelegateType;
		}
		set {
			if let newValue = newValue {
				let selectionHandler = CPCViewDelegatingSelectionHandler (self);
				selectionHandler.delegate = newValue as AnyObject;
				self.selectionHandler = selectionHandler;
			} else {
				self.selectionHandler = CPCViewSelectionHandler.primitive (for: self.selection);
			}
		}
	}
	
	@objc open func selectionDidChange () {}
	
	internal func selectionValue (of delegate: SelectionDelegateType) -> Selection {
		return delegate.selection;
	}
	
	internal func setSelectionValue (_ selection: Selection, in delegate: SelectionDelegateType) {
		delegate.selection = selection;
	}
	
	internal func resetSelection (in delegate: SelectionDelegateType) {}
	
	internal func handlerShouldSelectDayCell (_ day: CPCDay, delegate: SelectionDelegateType) -> Bool {
		return delegate.calendarView (self, shouldSelect: day);
	}
	
	internal func handlerShouldDeselectDayCell (_ day: CPCDay, delegate: SelectionDelegateType) -> Bool {
		return delegate.calendarView (self, shouldDeselect: day);
	}
}

extension CPCCalendarView: CPCMultiMonthsViewProtocol {
	internal func updateManagedMonthViews (using block: (CPCMonthView) -> ()) {
		self.monthViewsManager.updateManagedMonthViews (using: block);
		self.layout.invalidateLayout ();
	}
}

extension CPCCalendarView: UIContentSizeCategoryAdjusting {}
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
	
	open func scrollTo (date: Date, animated: Bool) {
		return self.scrollTo (month: CPCMonth (containing: date, calendar: self.calendarWrapper), animated: animated);
	}
	
	open func scrollTo (day: CPCDay, animated: Bool) {
		return self.scrollTo (month: CPCMonth (containing: day.start, calendar: self.calendarWrapper), animated: animated);
	}
	
	open func scrollTo (month: CPCMonth, animated: Bool) {
		let scrollDestination: CPCMonth;
		if let minimumDate = self.minimumDate, month.end <= minimumDate {
			scrollDestination = CPCMonth (containing: minimumDate, calendarOf: month);
		} else if let maximumDate = self.maximumDate, month.start >= maximumDate {
			scrollDestination = CPCMonth (containing: maximumDate, calendarOf: month);
		} else {
			scrollDestination = month;
		}
		self.layout.scrollToMonth (month: scrollDestination);
	}
}
