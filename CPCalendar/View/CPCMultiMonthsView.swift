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

fileprivate extension RangeReplaceableCollection {
	fileprivate mutating func remove (where predicate: (Element) throws -> Bool) rethrows -> Element? {
		return try self.index (where: predicate).map { self.remove (at: $0) };
	}
}

public protocol CPCMultiMonthsViewSelectionDelegate: AnyObject {
	var selection: CPCViewSelection { get set };
	
	func multiMonthView (_ multiMonthView: CPCMultiMonthsView, shouldSelect day: CPCDay) -> Bool;
	func multiMonthView (_ multiMonthView: CPCMultiMonthsView, shouldDeselect day: CPCDay) -> Bool;
}

open class CPCMultiMonthsView: UIView, CPCViewProtocol, CPCViewBackedByAppearanceStorage {
	open override var backgroundColor: UIColor? {
		didSet {
			self.updateManagedMonthViews { $0.backgroundColor = self.backgroundColor };
		}
	}
	
	@IBInspectable open dynamic var titleFont: UIFont {
		get {
			return self.appearanceStorage.titleFont;
		}
		set {
			self.appearanceStorage.titleFont = newValue;
			self.updateManagedMonthViews { $0.titleFont = newValue };
		}
	}
	@IBInspectable open dynamic var titleColor: UIColor {
		get {
			return self.appearanceStorage.titleColor;
		}
		set {
			self.appearanceStorage.titleColor = newValue;
			self.updateManagedMonthViews { $0.titleColor = newValue };
		}
	}
	@IBInspectable open dynamic var titleAlignment: NSTextAlignment {
		get {
			return self.appearanceStorage.titleAlignment;
		}
		set {
			guard (self.titleAlignment != newValue) else {
				return;
			}
			self.appearanceStorage.titleAlignment = newValue;
			self.updateManagedMonthViews { $0.titleAlignment = newValue };
		}
	}
	open var titleStyle: TitleStyle {
		get {
			return self.appearanceStorage.titleStyle;
		}
		set {
			guard !self.isAppearanceProxy else {
				return self.titleFormat = newValue.rawValue;
			}
			self.appearanceStorage.titleStyle = newValue;
			self.updateManagedMonthViews { $0.titleStyle = newValue };
		}
	}
	@IBInspectable open dynamic var titleMargins: UIEdgeInsets {
		get {
			return self.appearanceStorage.titleMargins;
		}
		set {
			self.appearanceStorage.titleMargins = newValue;
			self.updateManagedMonthViews { $0.titleMargins = newValue };
		}
	}
	
	@IBInspectable open dynamic var dayCellFont: UIFont {
		get {
			return self.appearanceStorage.dayCellFont;
		}
		set {
			self.appearanceStorage.dayCellFont = newValue;
			self.updateManagedMonthViews { $0.dayCellFont = newValue };
		}
	}
	@IBInspectable open dynamic var dayCellTextColor: UIColor {
		get {
			return self.appearanceStorage.dayCellTextColor;
		}
		set {
			self.appearanceStorage.dayCellTextColor = newValue;
			self.updateManagedMonthViews { $0.dayCellTextColor = newValue };
		}
	}
	@IBInspectable open dynamic var separatorColor: UIColor {
		get {
			return self.appearanceStorage.separatorColor;
		}
		set {
			self.appearanceStorage.separatorColor = newValue;
			self.updateManagedMonthViews { $0.separatorColor = newValue };
		}
	}
	
	open var cellRenderer: CPCDayCellRenderer {
		get {
			return self.appearanceStorage.cellRenderer;
		}
		set {
			self.appearanceStorage.cellRenderer = newValue;
			self.updateManagedMonthViews { $0.cellRenderer = newValue };
		}
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

	internal private (set) var monthViews = UnownedArray <CPCMonthView> ();
	internal var appearanceStorage = CPCViewAppearanceStorage ();
	
	private var multiSelectionHandler = CPCViewDefaultSelectionHandler;
	
	@objc dynamic internal func dayCellBackgroundColor (for backgroundStateValue: Int, isTodayValue: Int) -> UIColor? {
		return self.dayCellBackgroundColorImpl (backgroundStateValue, isTodayValue);
	}
	
	open func dayCellBackgroundColor (for state: DayCellState) -> UIColor? {
		guard !self.isAppearanceProxy else {
			let (backgroundStateValue, isTodayValue) = state.appearanceValues;
			return self.dayCellBackgroundColor (for: backgroundStateValue, isTodayValue: isTodayValue);
		}
		return self.appearanceStorage.cellBackgroundColors [state];
	}
	
	@objc dynamic internal func setDayCellBackgroundColor (_ backgroundColor: UIColor?, for backgroundStateValue: Int, isTodayValue: Int) {
		return self.setDayCellBackgroundColorImpl (backgroundColor, backgroundStateValue, isTodayValue);
	}
	
	open func setDayCellBackgroundColor (_ backgroundColor: UIColor?, for state: DayCellState) {
		guard !self.isAppearanceProxy else {
			let (backgroundStateValue, isTodayValue) = state.appearanceValues;
			return self.setDayCellBackgroundColor (backgroundColor, for: backgroundStateValue, isTodayValue: isTodayValue);
		}
		self.appearanceStorage.cellBackgroundColors [state] = backgroundColor;
		self.updateManagedMonthViews { $0.setDayCellBackgroundColor (backgroundColor, for: state) };
	}

	private func updateManagedMonthViews (using block: (CPCMonthView) -> ()) {
		self.monthViews.forEach (block);
	}
}

extension CPCMultiMonthsView: UIContentSizeCategoryAdjusting {}

extension CPCMultiMonthsView {
	open func addMonthView (_ monthView: CPCMonthView) {
		self.insertMonthView (monthView, at: self.monthViews.count);
	}
	
	open func insertMonthView (_ monthView: CPCMonthView, at index: Int) {
		if (index == self.monthViews.count) {
			self.addSubview (monthView);
			self.monthViews.append (monthView);
		} else {
			self.insertSubview (monthView, belowSubview: self.monthViews [index]);
			self.monthViews.insert (monthView, at: index);
		}
		monthView.copyStyle (from: self);
		monthView.cellRenderer = self.cellRenderer;
		monthView.backgroundColor = self.backgroundColor;
		monthView.selectionHandler = self.selectionHandler (for: monthView);
		monthView.adjustsFontForContentSizeCategory = self.adjustsFontForContentSizeCategory;
		monthView.setNeedsDisplay ();
	}
	
	open func removeMonthView (_ monthView: CPCMonthView) {
		guard let removedView = self.monthViews.remove (where: { $0 === monthView }) else {
			return;
		}
		removedView.selectionHandler = CPCViewDefaultSelectionHandler;
	}
	
	open override func willRemoveSubview (_ subview: UIView) {
		super.willRemoveSubview (subview);
		
		guard let monthView = subview as? CPCMonthView else {
			return;
		}
		self.removeMonthView (monthView);
	}
}

extension CPCMultiMonthsView: CPCViewDelegatingSelectionHandling {
	public typealias SelectionDelegateType = CPCMultiMonthsViewSelectionDelegate;
	
	private struct MonthViewHandler: CPCViewSelectionHandlerProtocol {
		fileprivate let selection: Selection;
		fileprivate unowned let monthView: CPCMonthView;

		private unowned let parent: CPCMultiMonthsView;

		fileprivate init (_ parent: CPCMultiMonthsView, for monthView: CPCMonthView) {
			self.parent = parent;
			self.monthView = monthView;
			self.selection = monthView.month.map { parent.selection.clamped (to: $0) } ?? .none;
		}
		
		fileprivate func clearingSelection () -> CPCMultiMonthsView.MonthViewHandler {
			return self;
		}
		
		fileprivate func handleTap (day: CPCDay) -> CPCViewSelectionHandlerProtocol? {
			return self.parent.selectionHandler (self, handleTapOn: day);
		}
	}
	
	internal var selectionHandler: SelectionHandler {
		get {
			return self.multiSelectionHandler;
		}
		set {
			self.setMultiSelectionHandler (newValue);
		}
	}
	
	fileprivate func selectionHandler (for monthView: CPCMonthView) -> SelectionHandler {
		return MonthViewHandler (self, for: monthView);
	}
	
	private func setMultiSelectionHandler (_ multiSelectionHandler: SelectionHandler, sender: CPCMonthView? = nil) {
		self.multiSelectionHandler = multiSelectionHandler;
		for monthView in self.monthViews where monthView !== sender {
			monthView.selectionHandler = self.selectionHandler (for: monthView);
		}
	}

	private func selectionHandler (_ handler: MonthViewHandler, handleTapOn day: CPCDay) -> SelectionHandler? {
		guard let newHandler = self.selectionHandler.handleTap (day: day) else {
			return nil;
		}
		let monthView = handler.monthView;
		self.setMultiSelectionHandler (newHandler, sender: monthView);
		return self.selectionHandler (for: monthView);
	}

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
