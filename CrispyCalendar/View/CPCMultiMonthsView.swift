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

public protocol CPCMultiMonthsViewSelectionDelegate: AnyObject {
	var selection: CPCViewSelection { get set };
	
	func multiMonthView (_ multiMonthView: CPCMultiMonthsView, shouldSelect day: CPCDay) -> Bool;
	func multiMonthView (_ multiMonthView: CPCMultiMonthsView, shouldDeselect day: CPCDay) -> Bool;
}

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
	@objc open var monthViews: [CPCMonthView] {
		return self.monthViewsManager.monthViews;
	}
	
	@objc open func addMonthView (_ monthView: CPCMonthView) {
		self.addSubview (monthView);
		self.startManagingMonthView (monthView);
	}
	
	@objc open func insertMonthView (_ monthView: CPCMonthView, at index: Int) {
		self.insertSubview (monthView, belowSubview: self.unownedMonthViews [index]);
		self.startManagingMonthView (monthView);
	}
	
	private func startManagingMonthView (_ monthView: CPCMonthView) {
		monthView.adjustsFontForContentSizeCategory = self.adjustsFontForContentSizeCategory;
		self.monthViewsManager.addMonthView (monthView);
	}
	
	@objc open func removeMonthView (_ monthView: CPCMonthView) {
		self.monthViewsManager.removeMonthView (monthView);
	}
}

extension CPCMultiMonthsView: CPCViewDelegatingSelectionHandling {
	public typealias SelectionDelegateType = CPCMultiMonthsViewSelectionDelegate;

	internal func selectionValue (of delegate: SelectionDelegateType) -> Selection {
		return delegate.selection;
	}
	
	internal func setSelectionValue (_ selection: Selection, in delegate: SelectionDelegateType) {
		delegate.selection = selection;
	}
	
	internal func resetSelection (in delegate: SelectionDelegateType) {}
	
	internal func handlerShouldSelectDayCell (_ day: CPCDay, delegate: SelectionDelegateType) -> Bool {
		return delegate.multiMonthView (self, shouldSelect: day);
	}
	
	internal func handlerShouldDeselectDayCell (_ day: CPCDay, delegate: SelectionDelegateType) -> Bool {
		return delegate.multiMonthView (self, shouldDeselect: day);
	}
}

extension CPCMultiMonthsView: CPCViewBackedByAppearanceStorage {}
extension CPCMultiMonthsView: UIContentSizeCategoryAdjusting {}
