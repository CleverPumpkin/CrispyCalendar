//
//  CPCMultiMonthsView.swift
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
/// of a multi-months view when user interacts with it.
public protocol CPCMultiMonthsViewSelectionDelegate: AnyObject {
	/// Selected days associated with this view.
	var selection: CPCViewSelection { get set };
	
	/// Tells the delegate that a specific cell is about to be selected by user.
	///
	/// The delegate must updated stored `selection` value according to the desired selection scheme
	/// and return whether the resulting selection was somehow changed.
	///
	/// - Parameters:
	///   - multiMonthView: View to handle user interaction for.
	///   - day: Day value rendered by the interacted cell.
	/// - Returns: `true` if user actions have lead to an updated selection value; otherwise, `false`.
	func multiMonthView (_ multiMonthView: CPCMultiMonthsView, shouldSelect day: CPCDay) -> Bool;

	/// Tells the delegate that a specific cell is about to be deselected by user.
	///
	/// The delegate must updated stored `selection` value according to the desired selection scheme
	/// and return whether the resulting selection was somehow changed.
	///
	/// - Parameters:
	///   - multiMonthView: View to handle user interaction for.
	///   - day: Day value rendered by the interacted cell.
	/// - Returns: `true` if user actions have lead to an updated selection value; otherwise, `false`.
	func multiMonthView (_ multiMonthView: CPCMultiMonthsView, shouldDeselect day: CPCDay) -> Bool;
}

/// A container view that provides an aggregate interface for managed month views.
///
/// After a month view has been added to the container, its appearance properties
/// must no longer can be individually; their values are managed by the container
/// view and are exactly same for all children. Selection and user interaction is
/// also managed by the container, which provides aggregate selection value, enabled
/// region and supports selection that spans across multiple views. On the other hand,
/// layout of the managed subviews is not performed and remains user responsibility.
open class CPCMultiMonthsView: UIView, CPCViewProtocol {
	open override var backgroundColor: UIColor? {
		didSet {
			self.updateManagedMonthViews { $0.backgroundColor = self.backgroundColor };
		}
	}
	
	@IBInspectable open dynamic var titleFont: UIFont {
		get { return self.monthViewsManager.titleFont }
		set { self.monthViewsManager.titleFont = newValue }
	}
	@IBInspectable open dynamic var titleColor: UIColor {
		get { return self.monthViewsManager.titleColor }
		set { self.monthViewsManager.titleColor = newValue }
	}
	@IBInspectable open dynamic var titleAlignment: NSTextAlignment {
		get { return self.monthViewsManager.titleAlignment }
		set {
			guard (self.titleAlignment != newValue) else {
				return;
			}
			self.monthViewsManager.titleAlignment = newValue;
		}
	}
	open var titleStyle: TitleStyle {
		get { return self.monthViewsManager.titleStyle }
		set {
			guard !self.isAppearanceProxy else {
				return self.titleFormat = newValue.rawValue;
			}
			self.monthViewsManager.titleStyle = newValue;
		}
	}
	@IBInspectable open dynamic var titleMargins: UIEdgeInsets {
		get { return self.monthViewsManager.titleMargins }
		set { self.monthViewsManager.titleMargins = newValue }
	}
	
	@IBInspectable open dynamic var dayCellFont: UIFont {
		get { return self.monthViewsManager.dayCellFont }
		set { self.monthViewsManager.dayCellFont = newValue }
	}
	@IBInspectable open dynamic var dayCellTextColor: UIColor {
		get { return self.monthViewsManager.dayCellTextColor }
		set { self.monthViewsManager.dayCellTextColor = newValue }
	}
	@IBInspectable open dynamic var separatorColor: UIColor {
		get { return self.monthViewsManager.separatorColor }
		set { self.monthViewsManager.separatorColor = newValue }
	}
	
	open var cellRenderer: CPCDayCellRenderer {
		get { return self.monthViewsManager.cellRenderer }
		set { self.monthViewsManager.cellRenderer = newValue }
	}

	open var adjustsFontForContentSizeCategory = false {
		didSet {
			self.updateManagedMonthViews { $0.adjustsFontForContentSizeCategory = self.adjustsFontForContentSizeCategory };
		}
	}
	
	/// The object that acts as the selection delegate of this view.
	open var selectionDelegate: CPCMultiMonthsViewSelectionDelegate? {
		get {
			return (self.selectionHandler as? CPCViewDelegatingSelectionHandler)?.delegate as? CPCMultiMonthsViewSelectionDelegate;
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
	
	deinit {
		self.monthViewsManager.prepareForContainerDeallocation ();
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
	
	internal let monthViewsManager = CPCMonthViewsManager ();
}

extension CPCMultiMonthsView: CPCMultiMonthsViewProtocol {
	/// The list of views arranged by the container view.
	@objc open var monthViews: [CPCMonthView] {
		return self.monthViewsManager.monthViews;
	}
	
	/// Adds a managed month view to the end of `monthViews` array.
	///
	/// - Note: This method also adds the given view as subview to the container.
	/// - Parameter monthView: The month view to be added.
	@objc open func addMonthView (_ monthView: CPCMonthView) {
		self.addSubview (monthView);
		self.startManagingMonthView (monthView);
	}
	
	/// Adds the provided view to the `monthViews` array at the specified index.
	///
	/// - Note: This method also adds the given view as subview to the container.
	/// - Parameters:
	///   - monthView: The month view to be added.
	///   - index: Index for the aded view.
	@objc open func insertMonthView (_ monthView: CPCMonthView, at index: Int) {
		self.insertSubview (monthView, belowSubview: self.unownedMonthViews [index]);
		self.startManagingMonthView (monthView);
	}
	
	private func startManagingMonthView (_ monthView: CPCMonthView) {
		monthView.adjustsFontForContentSizeCategory = self.adjustsFontForContentSizeCategory;
		self.monthViewsManager.addMonthView (monthView);
	}
	
	/// Removes the provided view from `monthViews` and stops it properties management.
	///
	/// - Note: This method does not remove month view from the container's `subviews`.
	/// - Parameter monthView: Month view to remove.
	@objc open func removeMonthView (_ monthView: CPCMonthView) {
		self.monthViewsManager.removeMonthView (monthView);
	}
}

extension CPCMultiMonthsView: CPCViewDelegatingSelectionHandling {
	open var selection: CPCViewSelection {
		get { return self.selectionHandler.selection }
		set { self.setSelection (newValue) }
	}

	internal func selectionValue (of delegate: CPCMultiMonthsViewSelectionDelegate) -> Selection {
		return delegate.selection;
	}
	
	internal func setSelectionValue (_ selection: Selection, in delegate: CPCMultiMonthsViewSelectionDelegate) {
		delegate.selection = selection;
	}
	
	internal func resetSelection (in delegate: CPCMultiMonthsViewSelectionDelegate) {}
	
	internal func handlerShouldSelectDayCell (_ day: CPCDay, delegate: CPCMultiMonthsViewSelectionDelegate) -> Bool {
		return delegate.multiMonthView (self, shouldSelect: day);
	}
	
	internal func handlerShouldDeselectDayCell (_ day: CPCDay, delegate: CPCMultiMonthsViewSelectionDelegate) -> Bool {
		return delegate.multiMonthView (self, shouldDeselect: day);
	}
}

extension CPCMultiMonthsView: CPCViewBackedByAppearanceStorage {}
extension CPCMultiMonthsView: UIContentSizeCategoryAdjusting {}
