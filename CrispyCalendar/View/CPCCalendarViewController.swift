//
//  CPCCalendarViewController.swift
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

/// Use a selection delegate (a custom object that implements this protocol) to modify behavior
/// of a calendar view controller when user interacts with it.
public protocol CPCCalendarViewControllerSelectionDelegate: AnyObject {
	/// Selected days associated with this view controller.
	var selection: CPCViewSelection { get set };
	
	/// Tells the delegate that a specific cell is about to be selected by user.
	///
	/// The delegate must updated stored `selection` value according to the desired selection scheme
	/// and return whether the resulting selection was somehow changed.
	///
	/// - Parameters:
	///   - calendarViewController: View controller to handle user interaction for.
	///   - day: Day value rendered by the interacted cell.
	/// - Returns: `true` if user actions have lead to an updated selection value; otherwise, `false`.
	func calendarViewController (_ calendarViewController: CPCCalendarViewController, shouldSelect day: CPCDay) -> Bool;
	
	/// Tells the delegate that a specific cell is about to be deselected by user.
	///
	/// The delegate must updated stored `selection` value according to the desired selection scheme
	/// and return whether the resulting selection was somehow changed.
	///
	/// - Parameters:
	///   - calendarView: View controller to handle user interaction for.
	///   - day: Day value rendered by the interacted cell.
	/// - Returns: `true` if user actions have lead to an updated selection value; otherwise, `false`.
	func calendarViewController (_ calendarViewController: CPCCalendarViewController, shouldDeselect day: CPCDay) -> Bool;
}

private protocol SelectionStorageProtocol {
	var selection: CPCViewSelection { get set };
}

private enum SelectionStorage {
	private struct ProxyingStorage: SelectionStorageProtocol {
		private unowned let viewController: CPCCalendarViewController;
		
		fileprivate var selection: CPCViewSelection {
			get { return self.viewController.calendarView.selection }
			set { self.viewController.calendarView.selection = newValue }
		}
		
		fileprivate init (for viewController: CPCCalendarViewController) {
			self.viewController = viewController;
		}
	}
	
	private struct RegularStorage: SelectionStorageProtocol {
		fileprivate var selection: CPCViewSelection;
	}

	fileprivate static func make <T> (for viewController: T) -> SelectionStorageProtocol where T: CPCCalendarViewController {
		if viewController is CPCCalendarViewSelectionDelegate {
			return RegularStorage (selection: .none);
		} else {
			return ProxyingStorage (for: viewController);
		}
	}
}

/// A view controller that manages a `CPCCalendarView` instance as its root view and optionally displays
/// a supplementary view providing weekdays for the calendar view.
open class CPCCalendarViewController: UIViewController {
	
	// MARK: - Private types
	
	private final class ViewDelegate: CPCCalendarViewSelectionDelegate {
		fileprivate weak var viewControllerDelegate: CPCCalendarViewControllerSelectionDelegate?;

		private unowned let viewController: CPCCalendarViewController;
		
		fileprivate init (_ viewControllerDelegate: CPCCalendarViewControllerSelectionDelegate, for viewController: CPCCalendarViewController) {
			self.viewController = viewController;
			self.viewControllerDelegate = viewControllerDelegate;
		}
		
		fileprivate var selection: CPCViewSelection {
			get {
				return self.viewControllerDelegate?.selection ?? .none;
			}
			set {
				self.viewControllerDelegate?.selection = newValue;
			}
		}
		
		fileprivate func calendarView (_ calendarView: CPCCalendarView, shouldSelect day: CPCDay) -> Bool {
			return self.viewControllerDelegate?.calendarViewController (self.viewController, shouldSelect: day) ?? false;
		}
		
		fileprivate func calendarView (_ calendarView: CPCCalendarView, shouldDeselect day: CPCDay) -> Bool {
			return self.viewControllerDelegate?.calendarViewController (self.viewController, shouldDeselect: day) ?? false;
		}
	}
	
	// MARK: - Public properties
	
	/// The object that acts as the selection delegate of this view controller.
	open weak var selectionDelegate: CPCCalendarViewControllerSelectionDelegate? {
		get {
			return self.viewDelegate?.viewControllerDelegate;
		}
		set {
			self.viewDelegate = newValue.map { ViewDelegate ($0, for: self) };
			self.calendarView.selectionDelegate = self.viewDelegate;
		}
	}
	
	open override var view: UIView! {
		get { return super.view }
		set {
			switch (newValue) {
			case let newValue as CPCCalendarView:
				newValue.calendarViewController = self;
				fallthrough;
			case nil:
				super.view = newValue;
			case .some (let newView):
				fatalError ("[CrispyCalendar] Sanity check failure: \(CPCCalendarViewController.self) is designed to manage \(CPCCalendarView.self) instances; \(newView) is given");
			}
		}
	}
	
	/// The view that the controller manages.
	open var calendarView: CPCCalendarView! {
		return self.view as? CPCCalendarView
	}
	
	/// Week view that is rendered as part of calendar view.
	open var weekView: CPCWeekView! {
		willSet { self.weekView?.removeFromSuperview () }
		didSet { self.calendarView.addSubview (weekView) }
	}
	
	/// See `selection`.
	@objc (selection)
	open var _objcBridgedSelection: __CPCViewSelection {
		get { return self.selection as __CPCViewSelection }
		set { self.selection = newValue as CPCViewSelection }
	}

	/// Selected days associated with this view controller.
	open var selection: CPCViewSelection {
		get { return self.selectionStorage.selection }
		set { self.selectionStorage.selection = newValue }
	}
	
	/// The minimum date that a calendar view controller should present to user. Defaults to `nil` meaning no lower limit.
	open var minimumDate: Date? {
		get {
			return self.calendarView.minimumDate;
		}
		set {
			self.calendarView.minimumDate = newValue;
		}
	}
	
	/// The maximum date that a calendar view controller should present to user. Defaults to `nil` meaning no upper limit.
	open var maximumDate: Date? {
		get {
			return self.calendarView.maximumDate;
		}
		set {
			self.calendarView.maximumDate = newValue;
		}
	}
	
	/// The number of columns to display in a calendar view.
	@IBInspectable open dynamic var columnCount: Int {
		get { return self.calendarView.columnCount }
		set { self.calendarView.columnCount = newValue }
	}
	
	/// Insets or outsets that are applied to each calendar column.
	@IBInspectable open dynamic var columnContentInset: UIEdgeInsets {
		get { return self.calendarView.columnContentInset }
		set { self.calendarView.columnContentInset = newValue }
	}
	
	// MARK: - Private properties

	private var selectionStorage: SelectionStorageProtocol!;
	private var viewDelegate: ViewDelegate?;
	private let numberOfMonthsToDisplay: Int?
	private let startingDay: CPCDay?
	
	// MARK: - Initialization
	
	public init(
		dateRange: ClosedRange<Date>,
		calendar: Calendar = .current,
		startingDay: Date = Date()
	) {
		
		let maximumDay = CPCDay(containing: dateRange.upperBound, calendar: calendar)
		let minimumDay = CPCDay(containing: dateRange.lowerBound, calendar: calendar)
		let maximumMonth = maximumDay.containingMonth
		let minimumMonth = minimumDay.containingMonth
		let fistWeekOfMaximumMonth = maximumMonth.first
		let fistDayOfMaximumMonth = fistWeekOfMaximumMonth?.first { day -> Bool in
			day.containingMonth == maximumMonth
		}
		
		var numberOfMonthsToDisplay = minimumMonth.distance(to: maximumMonth)
		
		if maximumDay == fistDayOfMaximumMonth {
			numberOfMonthsToDisplay -= 1
		}
		
		self.numberOfMonthsToDisplay = numberOfMonthsToDisplay
		self.startingDay = CPCDay(containing: startingDay, calendar: .current)
		
		super.init(nibName: nil, bundle: nil)
		
		commonInit()
		
		self.minimumDate = dateRange.lowerBound
		self.maximumDate = dateRange.upperBound
	}
	
	public override init (nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		self.startingDay = nil
		self.numberOfMonthsToDisplay = nil
		
		super.init(nibName: nil, bundle: nil)
		
		commonInit()
	}
	
	public required init? (coder aDecoder: NSCoder) {
		self.startingDay = nil
		self.numberOfMonthsToDisplay = nil
		
		super.init(coder: aDecoder)
		
		commonInit()
	}
	
	// MARK: - Deinitialization
	
	deinit {
		self.calendarView?.calendarViewController = nil;
	}
	
	// MARK: - Public methods
	
	open override func loadView () {
		let view = CPCCalendarView (
			frame: UIScreen.main.bounds,
			startingDay: startingDay,
			numberOfMonthsToDisplay: numberOfMonthsToDisplay
		)
		
		view.backgroundColor = .white
		
		let weekView = CPCWeekView(
			frame: CGRect(
				origin: .zero,
				size: CGSize(
					width: view.bounds.width,
					height: 0.0
				)
			)
		)
		
		weekView.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
		weekView.backgroundColor = .gray
		view.addSubview (weekView)
		
		let weekViewLayer = weekView.layer
		weekViewLayer.shadowColor = UIColor (white: 0.0, alpha: 1.0).cgColor
		weekViewLayer.shadowOpacity = 0.1
		weekViewLayer.shadowRadius = 8.0
		weekViewLayer.shadowOffset = .zero

		self.view = view
		self.weekView = weekView
	}
	
	open override func viewWillLayoutSubviews () {
		super.viewWillLayoutSubviews ();
		self.layoutWeekView ();
	}
	
#if swift(>=4.2)
	open override func didMove (toParent parent: UIViewController?) {
		super.didMove (toParent: parent);
		self.layoutWeekView ();
	}
#else
	open override func didMove (toParentViewController parent: UIViewController?) {
		super.didMove (toParentViewController: parent);
		self.layoutWeekView ();
	}
#endif
	
	@available (iOS 11.0, *)
	open override func viewSafeAreaInsetsDidChange () {
		super.viewSafeAreaInsetsDidChange ();
		self.layoutWeekView ();
	}
	
	/// Tells the view controller that selected days were changed in response to user actions.
	///
	/// Default implementation does nothing. Subclasses can override it to perform additional actions whenever selection changes.
	@objc open func selectionDidChange () {}
	
	// MARK: - Private methods
	
	private func commonInit() {
		
		selectionStorage = SelectionStorage.make(for: self)
	}
	
	private func layoutWeekView () {
		guard let weekView = self.weekView else { return }
		let oldWeekViewHeight = weekView.bounds.height, weekViewTop: CGFloat;
		if #available (iOS 11.0, *) {
			weekViewTop = self.view.safeAreaInsets.top - self.additionalSafeAreaInsets.top;
		} else {
			weekViewTop = self.topLayoutGuide.length;
		}
		
		let fittingSize = self.view.bounds.size, weekViewHeight = weekView.sizeThatFits (fittingSize).height + 15.0;
		weekView.frame = CGRect (x: 0.0, y: weekViewTop, width: fittingSize.width, height: weekViewHeight);
		if #available (iOS 11.0, *) {
			self.additionalSafeAreaInsets.top += weekViewHeight - oldWeekViewHeight;
		} else {
			self.calendarView.contentInset.top += weekViewHeight - oldWeekViewHeight;
			self.calendarView.scrollIndicatorInsets.top += weekViewHeight - oldWeekViewHeight;
		};
	}
}
