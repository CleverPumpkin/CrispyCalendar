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

/* internal */ extension CGRect {
	internal var bounds: CGRect {
		return CGRect (origin: .zero, size: CGSize (width: self.size.width.magnitude, height: self.size.height.magnitude));
	}
}

/// Use a selection delegate (a custom object that implements this protocol) to modify behavior
/// of a calendar view when user interacts with it.
public protocol CPCCalendarViewSelectionDelegate: AnyObject {
	/// Selected days associated with this view.
	var selection: CPCViewSelection { get set };
	
	/// Tells the delegate that a specific cell is about to be selected by user.
	///
	/// The delegate must updated stored `selection` value according to the desired selection scheme
	/// and return whether the resulting selection was somehow changed.
	///
	/// - Parameters:
	///   - calendarView: View to handle user interaction for.
	///   - day: Day value rendered by the interacted cell.
	/// - Returns: `true` if user actions have lead to an updated selection value; otherwise, `false`.
	func calendarView (_ calendarView: CPCCalendarView, shouldSelect day: CPCDay) -> Bool;

	/// Tells the delegate that a specific cell is about to be deselected by user.
	///
	/// The delegate must updated stored `selection` value according to the desired selection scheme
	/// and return whether the resulting selection was somehow changed.
	///
	/// - Parameters:
	///   - calendarView: View to handle user interaction for.
	///   - day: Day value rendered by the interacted cell.
	/// - Returns: `true` if user actions have lead to an updated selection value; otherwise, `false`.
	func calendarView (_ calendarView: CPCCalendarView, shouldDeselect day: CPCDay) -> Bool;
}

/// A container view that internally manages and reuses `CPCMonthView` instances to provide
/// an illusion of infinitely scrollable calendar interface.
///
/// Implementation details are  private and you are strongly discouraged from relying on
/// any internal hierarchy of the container. Instead, use `CPCMultiMonthView` that provides
/// the same unified selection handling and appearance attributes management, but assigning
/// month values to specific views or arranging them visually remains under user control.
open class CPCCalendarView: UIView {
	
	// MARK: - Public types
	
	/// Defines the boundary for ccalendar view content.
	@objc (CPCCalendarViewColumnContentInsetReference)
	public enum ColumnContentInsetReference: Int {
		/// Uses `contentInset` as zero boundary.
		case fromContentInset;
		/// Uses `layoutMargin` as zero boundary.
		case fromLayoutMargins;
		/// Uses `safeAreaInsets` as zero boundary.
		case fromSafeAreaInsets;
	};
	
	// MARK: - Public properties
	
	/// Calendar to be used for various locale-dependent info.
	open var calendar: Calendar {
		get { return self.calendarWrapper.calendar }
		set {
			guard self.calendarWrapper.calendar != newValue else {
				return;
			}
			if weekView?.calendar != newValue {
				weekView?.calendar = newValue
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
	
	/// The minimum date that a calendar view should present to user. Defaults to `nil` meaning no lower limit.
	open var minimumDate: Date? {
		get { return self.dataSource.minimumDate }
		set { self.dataSource.minimumDate = newValue }
	}
	
	/// The maximum date that a calendar view should present to user. Defaults to `nil` meaning no upper limit.
	open var maximumDate: Date? {
		get { return self.dataSource.maximumDate }
		set { self.dataSource.maximumDate = newValue }
	}

	/// The number of columns to display in a calendar view.
	@IBInspectable open dynamic var columnCount: Int {
		get { return self.layout.columnCount }
		set { self.layout.columnCount = newValue }
	}
	
	/// Insets or outsets that are applied to each calendar column.
	@IBInspectable open dynamic var columnContentInset: UIEdgeInsets {
		get { return self.layout.columnContentInset }
		set { self.layout.columnContentInset = newValue }
	}
	
	/// Defines the boundary used for layout calculations.
	///
	/// - Note: calendar view's behaviour when using this value is analagous to that exhibited by
	/// `UICollectionViewFlowLayout.sectionInsetReference`, meaning contentInset are always respected.
	@IBInspectable open dynamic var columnContentInsetReference: ColumnContentInsetReference {
		get { return self.layout.columnContentInsetReference }
		set { self.layout.columnContentInsetReference = newValue }
	}
	
	// MARK: - Internal properties
	
	internal unowned let collectionView: UICollectionView;

	internal var calendarViewController: CPCCalendarViewController? {
		get { return self.calendarViewControllerPtr?.pointee }
		set { self.calendarViewControllerPtr = UnsafePointer (to: newValue) }
	}
	internal var monthViewsManager: CPCMonthViewsManager {
		return self.dataSource.monthViewsManager;
	}
	
	// MARK: - Private properties
	
	private var dataSource: DataSource
	private var calendarViewControllerPtr: UnsafePointer <CPCCalendarViewController>?;
	private var weekView: CPCWeekView?
	
	// MARK: - Initializaiton
	
	public init (frame: CGRect, startingDay: CPCDay?, numberOfMonthsToDisplay: Int?) {
		let collectionView = CPCCalendarView.makeCollectionView(frame, numberOfMonthsToDisplay: numberOfMonthsToDisplay)
		
		self.collectionView = collectionView
		self.dataSource = DataSource(statingAt: startingDay ?? .today)
		
		super.init (frame: frame)
		
		self.commonInit (collectionView)
	}
	
	public override init (frame: CGRect) {
		let collectionView = CPCCalendarView.makeCollectionView(frame)
		
		self.collectionView = collectionView;
		self.dataSource = DataSource()
		
		super.init (frame: frame);
		
		self.commonInit (collectionView);
	}
	
	public required init? (coder aDecoder: NSCoder) {
		let collectionView = CPCCalendarView.makeCollectionView(.zero)
		
		self.collectionView = collectionView
		self.dataSource = DataSource()
		
		super.init (coder: aDecoder)
		
		self.commonInit (collectionView)
	}
	
	// MARK: - Deinitialization
	
	deinit {
		monthViewsManager.prepareForContainerDeallocation()
	}
	
	// MARK: - Public methods

	open override func layoutSubviews () {
		super.layoutSubviews ();
		self.collectionView.frame = self.bounds;
	}
	
	open override func layoutMarginsDidChange () {
		super.layoutMarginsDidChange ();
		self.layout.contentGuideDidChange ();
	}
	
	@available (iOS 11.0, *)
	open override func safeAreaInsetsDidChange () {
		super.safeAreaInsetsDidChange ();
		self.layout.contentGuideDidChange ();
	}
	
	open override func willMove (toWindow newWindow: UIWindow?) {
		super.willMove (toWindow: newWindow);
		if (newWindow != nil) {
			self.calendarWrapper.retainGarbageCollector ();
		}
	}
	
	open override func didMoveToWindow () {
		super.didMoveToWindow ();
		if (self.window == nil) {
			self.calendarWrapper.releaseGarbageCollector ();
		}
	}
	
	open override func didAddSubview (_ subview: UIView) {
		super.didAddSubview (subview);
		if let weekView = subview as? CPCWeekView {
			weekView.calendarView = self;
			self.weekView = weekView;
		}
	}
	
	open override func willRemoveSubview (_ subview: UIView) {
		if let weekView = subview as? CPCWeekView {
			weekView.calendarView = nil;
			self.weekView = weekView;
		}
		super.willRemoveSubview (subview);
	}
	
	// MARK: - Private methods
	
	private func commonInit (_ collectionView: UICollectionView) {
		self.monthViewsManager.selectionDidChangeBlock = { [unowned self] in
			self.selectionDidChange ();
			self.calendarViewController?.selectionDidChange ();
		};
		collectionView.register (Cell.self, forCellWithReuseIdentifier: DataSource.cellReuseIdentifier);
		self.prepareCollectionView (collectionView, using: self.dataSource);
		self.addSubview (collectionView);
	}
	
	private func prepareCollectionView (_ collectionView: UICollectionView, using dataSource: DataSource) {
		collectionView.prefetchDataSource = dataSource;
		collectionView.dataSource = dataSource;
		collectionView.delegate = dataSource;
	}
}

extension CPCCalendarView {
	internal var layout: Layout {
		return unsafeDowncast (self.collectionView.collectionViewLayout);
	}
	
	private var calendarWrapper: CPCCalendarWrapper {
		get { return self.dataSource.calendar }
		set {
			self.calendarWrapper.releaseGarbageCollector ();
			
			newValue.retainGarbageCollector ();
			let dataSource = DataSource (replacing: self.dataSource, calendar: newValue);
			self.prepareCollectionView (self.collectionView, using: dataSource);
			self.dataSource = dataSource;
		}
	}
	
	private static func makeCollectionView (
		_ frame: CGRect,
		calendar: Calendar = .currentUsed,
		numberOfMonthsToDisplay: Int? = nil
	) -> UICollectionView {
		let layout = Layout(numberOfMonthsToDisplay: numberOfMonthsToDisplay)
		let collectionView = CPCCollectionView(frame: frame.bounds, collectionViewLayout: layout)
		
		collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		collectionView.allowsSelection = false
		collectionView.isDirectionalLockEnabled = true
		collectionView.alwaysBounceVertical = true
		
		return collectionView
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
	
	@IBInspectable open dynamic var separatorColor: UIColor {
		get { return self.monthViewsManager.separatorColor }
		set { self.monthViewsManager.separatorColor = newValue }
	}
	
	open var cellRenderer: CellRenderer {
		get { return self.monthViewsManager.cellRenderer }
		set { self.monthViewsManager.cellRenderer = newValue }
	}
	
	@objc (dayCellTextColorForState:)
	open dynamic func dayCellTextColor (for state: DayCellState) -> UIColor? {
		return self.monthViewsManager.dayCellTextColor (for: state);
	}
	
	@objc (setDayCellTextColor:forState:)
	open dynamic func setDayCellTextColor (_ textColor: UIColor?, for state: DayCellState) {
		self.monthViewsManager.setDayCellTextColor (textColor, for: state);
	}

	@objc (dayCellBackgroundColorForState:)
	open dynamic func dayCellBackgroundColor (for state: DayCellState) -> UIColor? {
		return self.monthViewsManager.dayCellBackgroundColor (for: state);
	}
	
	@objc (setDayCellBackgroundColor:forState:)
	open dynamic func setDayCellBackgroundColor (_ backgroundColor: UIColor?, for state: DayCellState) {
		self.monthViewsManager.setDayCellBackgroundColor (backgroundColor, for: state);
	}
}

extension CPCCalendarView: CPCViewDelegatingSelectionHandling {
	/// See `selection`.
	@objc (selection)
	open var _objcBridgedSelection: __CPCViewSelection {
		get { return self.selection as __CPCViewSelection }
		set { self.selection = newValue as CPCViewSelection }
	}
	
	open var selection: CPCViewSelection {
		get { return self.selectionHandler.selection }
		set { self.setSelection (newValue) }
	}

	/// The object that acts as the selection delegate of this view.
	open var selectionDelegate: CPCCalendarViewSelectionDelegate? {
		get {
			return (self.selectionHandler as? CPCViewDelegatingSelectionHandler)?.delegate as? CPCCalendarViewSelectionDelegate;
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
	
	/// Tells the view that selected days were changed in response to user actions.
	///
	/// Default implementation does nothing. Subclasses can override it to perform additional actions whenever selection changes.
	@objc open func selectionDidChange () {}
	
	internal func selectionValue (of delegate: CPCCalendarViewSelectionDelegate) -> Selection {
		return delegate.selection;
	}
	
	internal func setSelectionValue (_ selection: Selection, in delegate: CPCCalendarViewSelectionDelegate) {
		delegate.selection = selection;
	}
	
	internal func resetSelection (in delegate: CPCCalendarViewSelectionDelegate) {}
	
	internal func handlerShouldSelectDayCell (_ day: CPCDay, delegate: CPCCalendarViewSelectionDelegate) -> Bool {
		return delegate.calendarView (self, shouldSelect: day);
	}
	
	internal func handlerShouldDeselectDayCell (_ day: CPCDay, delegate: CPCCalendarViewSelectionDelegate) -> Bool {
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

extension CPCCalendarView /* UIScrollViewProtocol */ {
	/// A Boolean value that controls whether the scroll view bounces past the edge of content and back again.
	open var bounces: Bool {
		get { return self.collectionView.bounces }
		set { self.collectionView.bounces = newValue }
	}
	/// A Boolean value that determines whether bouncing always occurs when vertical scrolling reaches the end of the content.
	open var alwaysBounceVertical: Bool {
		get { return self.collectionView.alwaysBounceVertical }
		set { self.collectionView.alwaysBounceVertical = newValue }
	}
	/// A Boolean value that determines whether bouncing always occurs when horizontal scrolling reaches the end of the content view.
	open var alwaysBounceHorizontal: Bool {
		get { return self.collectionView.alwaysBounceHorizontal }
		set { self.collectionView.alwaysBounceHorizontal = newValue }
	}

	/// A Boolean value that controls whether the scroll-to-today gesture is enabled.
	open var scrollsToToday: Bool {
		get { return self.collectionView.scrollsToTop }
		set { self.collectionView.scrollsToTop = newValue }
	}
	
	/// The custom distance that the content view is inset from the safe area or scroll view edges.
	open var contentInset: UIEdgeInsets {
		get { return self.collectionView.contentInset }
		set { self.collectionView.contentInset = newValue }
	}
	/// The distance the scroll indicators are inset from the edge of the scroll view.
	open var scrollIndicatorInsets: UIEdgeInsets {
		get { return self.collectionView.scrollIndicatorInsets }
		set { self.collectionView.scrollIndicatorInsets = newValue }
	}

	/// The insets derived from the content insets and the safe area of the scroll view.
	@available (iOS 11.0, *)
	open var adjustedContentInset: UIEdgeInsets {
		return self.collectionView.adjustedContentInset;
	}
	/// The behavior for determining the adjusted content offsets.
	@available (iOS 11.0, *)
	open var contentInsetAdjustmentBehavior: UIScrollView.ContentInsetAdjustmentBehavior {
		get { return self.collectionView.contentInsetAdjustmentBehavior }
		set { self.collectionView.contentInsetAdjustmentBehavior = newValue }
	}

	/// A Boolean value that controls whether the horizontal scroll indicator is visible.
	open var showsHorizontalScrollIndicator: Bool {
		get { return self.collectionView.showsHorizontalScrollIndicator }
		set { self.collectionView.showsHorizontalScrollIndicator = newValue }
	}
	/// A Boolean value that controls whether the vertical scroll indicator is visible.
	open var showsVerticalScrollIndicator: Bool {
		get { return self.collectionView.showsVerticalScrollIndicator }
		set { self.collectionView.showsVerticalScrollIndicator = newValue }
	}
	
	/// Scrolls a specific area of the content so that it is visible in the receiver.
	///
	/// - Parameters:
	///   - date: A date that must be visible after scroll animation finishes.
	///   - animated: `true` if the scrolling should be animated, `false` if it should be immediate.
	open func scrollTo (date: Date, animated: Bool) {
		return self.scrollTo (month: CPCMonth (containing: date, calendar: self.calendarWrapper), animated: animated);
	}
	
	/// Scrolls a specific area of the content so that it is visible in the receiver.
	///
	/// - Parameters:
	///   - day: A specific day that must be visible after scroll animation finishes.
	///   - animated: `true` if the scrolling should be animated, `false` if it should be immediate.
	open func scrollTo (day: CPCDay, animated: Bool) {
		let scrollDestination: CPCDay;
		if let minimumDate = self.minimumDate, day.end <= minimumDate {
			scrollDestination = CPCDay (containing: minimumDate, calendarOf: day);
		} else if let maximumDate = self.maximumDate, day.start >= maximumDate {
			scrollDestination = CPCDay (containing: maximumDate, calendarOf: day);
		} else {
			scrollDestination = day;
		}
		self.dataSource.scroll (collectionView: self.collectionView, to: scrollDestination, animated: animated);
	}
	
	/// Scrolls a specific area of the content so that it is visible in the receiver.
	///
	/// - Parameters:
	///   - month: A specific month that must be visible after scroll animation finishes.
	///   - animated: `true` if the scrolling should be animated, `false` if it should be immediate.
	open func scrollTo (month: CPCMonth, animated: Bool) {
		self.scrollTo (day: CPCDay (containing: month.start + month.duration / 2, calendarOf: month), animated: animated);
	}
}
