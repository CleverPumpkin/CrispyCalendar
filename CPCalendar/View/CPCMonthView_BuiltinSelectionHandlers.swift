//
//  CPCMonthView+BuiltinSelectionHandlers.swift
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

internal protocol CPCMonthViewSelectionHandler {
	var selection: CPCMonthView.Selection { get };
	
	mutating func clearSelection ();
	mutating func dayCellTapped (_ day: CPCDay) -> Bool;
}

fileprivate extension CPCMonthView.Selection {
	fileprivate var builtinHandler: CPCMonthView.SelectionHandler {
		switch (self) {
		case .none:
			return CPCMonthView.DisabledSelectionHandler ();
		case .single (let day):
			return CPCMonthView.SingleDaySelectionHandler (day);
		case .range (let range):
			return CPCMonthView.DaysRangeSelectionHandler (range);
		case .unordered (let days):
			return CPCMonthView.UnorderedDaysSelectionHandler (days);
		case .ordered (let days):
			return CPCMonthView.OrderedDaysSelectionHandler (days);
		}
	}
}

extension CPCMonthView {
	open var selection: Selection {
		get {
			return self.selectionHandler.selection;
		}
		set {
			if var delegatingHandler = self.selectionHandler as? DelegatingSelectionHandler {
				delegatingHandler.selection = newValue;
			} else {
				self.selectionHandler = newValue.builtinHandler;
			}
		}
	}
	
	open weak var selectionDelegate: SelectionDelegate? {
		get {
			return (self.selectionHandler as? DelegatingSelectionHandler)?.delegate;
		}
		set {
			switch (self.selectionDelegate, newValue) {
			case (nil, .some (let delegate)):
				self.selectionHandler = DelegatingSelectionHandler (monthView: self, delegate: delegate);
			case (.some (let delegate), nil):
				self.selectionHandler = delegate.selection.builtinHandler;
			default:
				break;
			}
		}
	}
}

internal extension CPCMonthView {
	internal static let defaultSelectionHandler: SelectionHandler = DisabledSelectionHandler ();
	
	fileprivate struct DisabledSelectionHandler {
		fileprivate init () {}
	}
	
	fileprivate struct SingleDaySelectionHandler {
		private var selectedDay: CPCDay?;

		fileprivate init (_ selectedDay: CPCDay?) {
			self.selectedDay = selectedDay;
		}
	}
	
	fileprivate struct DaysRangeSelectionHandler {
		private var selectedDays: CountableRange <CPCDay>;
		
		fileprivate init (_ selectedDays: CountableRange <CPCDay> = .today ..< .today) {
			self.selectedDays = selectedDays;
		}
	}
	
	fileprivate struct UnorderedDaysSelectionHandler {
		private var selectedDays: Set <CPCDay>;
		
		fileprivate init (_ selectedDays: Set <CPCDay> = Set ()) {
			self.selectedDays = selectedDays;
		}
	}
	
	fileprivate struct OrderedDaysSelectionHandler {
		private var selectedDays: [CPCDay];
		
		fileprivate init (_ selectedDays: [CPCDay] = []) {
			self.selectedDays = selectedDays;
		}
	}
	
	fileprivate struct DelegatingSelectionHandler {
		fileprivate unowned let monthView: CPCMonthView;
		
		fileprivate weak var delegate: SelectionDelegate?;
	}
}

extension CPCMonthView.DisabledSelectionHandler: CPCMonthViewSelectionHandler {
	internal var selection: CPCMonthView.Selection {
		return .none;
	}
	
	internal mutating func dayCellTapped (_ day: CPCDay) -> Bool {
		return false;
	}
	
	internal mutating func clearSelection () {}
}

extension CPCMonthView.SingleDaySelectionHandler: CPCMonthViewSelectionHandler {
	internal var selection: CPCMonthView.Selection {
		return .single (self.selectedDay);
	}
	
	internal mutating func dayCellTapped (_ day: CPCDay) -> Bool {
		if (day == self.selectedDay) {
			self.selectedDay = nil;
		} else {
			self.selectedDay = day;
		}
		return true;
	}

	internal mutating func clearSelection () {
		self.selectedDay = nil;
	}
}

extension CPCMonthView.DaysRangeSelectionHandler: CPCMonthViewSelectionHandler {
	internal var selection: CPCMonthView.Selection {
		return .range (self.selectedDays);
	}
	
	internal mutating func dayCellTapped (_ day: CPCDay) -> Bool {
		if (self.selectedDays.count == 1) {
			let selectedDay = self.selectedDays.lowerBound;
			if (day < selectedDay) {
				self.selectedDays = day ..< selectedDay.next;
			} else {
				self.selectedDays = selectedDay ..< day.next;
			}
		} else {
			self.selectedDays = day ..< day.next;
		}
		return true;
	}

	internal mutating func clearSelection () {
		self.selectedDays = .today ..< .today;
	}
}

extension CPCMonthView.UnorderedDaysSelectionHandler: CPCMonthViewSelectionHandler {
	internal var selection: CPCMonthView.Selection {
		return .unordered (self.selectedDays);
	}
	
	internal mutating func dayCellTapped (_ day: CPCDay) -> Bool {
		if (self.selectedDays.contains (day)) {
			self.selectedDays.remove (day);
		} else {
			self.selectedDays.insert (day);
		}
		return true;
	}

	internal mutating func clearSelection () {
		self.selectedDays.removeAll ();
	}
}

extension CPCMonthView.OrderedDaysSelectionHandler: CPCMonthViewSelectionHandler {
	internal var selection: CPCMonthView.Selection {
		return .ordered (self.selectedDays);
	}
	
	internal mutating func dayCellTapped (_ day: CPCDay) -> Bool {
		if let dayIndex = self.selectedDays.index (of: day) {
			self.selectedDays.remove (at: dayIndex);
		} else {
			self.selectedDays.append (day);
		}
		return true;
	}

	internal mutating func clearSelection () {
		self.selectedDays.removeAll ();
	}
}

extension CPCMonthView.DelegatingSelectionHandler: CPCMonthViewSelectionHandler {
	fileprivate typealias SelectionDelegate = CPCMonthViewSelectionDelegate;
	
	internal var selection: CPCMonthView.Selection {
		get {
			return self.delegate?.selection ?? .none;
		}
		set {
			self.delegate?.selection = newValue;
		}
	}
	
	internal func dayCellTapped (_ day: CPCDay) -> Bool {
		guard let delegate = self.delegate else {
			return false;
		}
		
		let method = (delegate.selection.isDaySelected (day) ? delegate.monthView (_:deselect:) : delegate.monthView (_:select:));
		return method (self.monthView, day);
	}
	
	internal func clearSelection () {
		self.delegate?.monthViewDidResetSelection (self.monthView);
	}
}
