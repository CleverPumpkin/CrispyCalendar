//
//  CPCCalendarView_ProtocolConformances.swift
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

	open func selectionDidChange () {}
	
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

extension CPCCalendarView: UIContentSizeCategoryAdjusting {}
