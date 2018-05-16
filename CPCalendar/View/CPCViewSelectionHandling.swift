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

internal protocol CPCViewSelectionHandlerProtocol {
	typealias Selection = CPCViewSelection;
	
	var selection: Selection { get };
	
	mutating func clearSelection ();
	mutating func dayCellTapped (_ day: CPCDay) -> Bool;
}

internal let CPCViewDefaultSelectionHandler: CPCViewSelectionHandlerProtocol = CPCViewSelectionHandler.primitive (for: .none);

internal protocol CPCViewSelectionHandling: AnyObject {
	typealias SelectionHandler = CPCViewSelectionHandlerProtocol;
	
	var selectionHandler: SelectionHandler { get set };
	var isSelectionEnabled: Bool { get };
	
	func select (_ day: CPCDay?);
	func select <R> (_ range: R) where R: CPCDateInterval;
	func select <R> (_ range: R) where R: RangeExpression, R.Bound == CPCDay;
	func select <C> (_ ordered: C) where C: RandomAccessCollection, C.Element == CPCDay;
	func select <C> (_ unordered: C) where C: Collection, C: SetAlgebra, C.Element == CPCDay;
}

extension CPCViewSelectionHandling {
	public typealias Selection = CPCViewSelection;
	
	public var selection: CPCViewSelection {
		get {
			return self.selectionHandler.selection;
		}
		set {
			self.selectionHandler = CPCViewSelectionHandler.primitive (for: selection);
		}
	}
	
	public var isSelectionEnabled: Bool {
		return self.selection != .none;
	}
	
	public func select (_ day: CPCDay?) {
		self.selection = .single (day);
	}
	
	public func select <R> (_ range: R) where R: CPCDateInterval {
		let unwrappedRange = range.unwrapped;
		let daysRange: Range <CPCDay> = CPCDay (containing: unwrappedRange.lowerBound) ..< CPCDay (containing: unwrappedRange.upperBound)
		self.select (daysRange);
	}
	
	public func select <R> (_ range: R) where R: RangeExpression, R.Bound == CPCDay {
		
	}
	
	public func select <C> (_ ordered: C) where C: RandomAccessCollection, C.Element == CPCDay {
		self.selection = .ordered (Array (ordered));
	}
	
	public func select <C> (_ unordered: C) where C: Collection, C: SetAlgebra, C.Element == CPCDay {
		self.selection = .unordered (Set (unordered));
	}
}

fileprivate enum CPCViewSelectionHandler {}

extension CPCViewSelectionHandler {
	fileprivate static func primitive (for selection: CPCViewSelection) -> CPCViewSelectionHandlerProtocol {
		struct Disabled: CPCViewSelectionHandlerProtocol {
			fileprivate var selection: Selection {
				return .none;
			}
			
			fileprivate mutating func dayCellTapped (_ day: CPCDay) -> Bool {
				return false;
			}
			
			fileprivate init () {}

			fileprivate mutating func clearSelection () {}
		}
		
		struct Single: CPCViewSelectionHandlerProtocol {
			fileprivate var selection: Selection {
				return .single (self.selectedDay);
			}
			
			private var selectedDay: CPCDay?;
			
			fileprivate init (_ selectedDay: CPCDay?) {
				self.selectedDay = selectedDay;
			}

			fileprivate mutating func dayCellTapped (_ day: CPCDay) -> Bool {
				if (day == self.selectedDay) {
					self.selectedDay = nil;
				} else {
					self.selectedDay = day;
				}
				return true;
			}
			
			fileprivate mutating func clearSelection () {
				self.selectedDay = nil;
			}
		}
		
		struct Range: CPCViewSelectionHandlerProtocol {
			fileprivate var selection: Selection {
				return .range (self.selectedDays);
			}
			
			private var selectedDays: CountableRange <CPCDay>;
			
			fileprivate init (_ selectedDays: CountableRange <CPCDay> = .today ..< .today) {
				self.selectedDays = selectedDays;
			}

			fileprivate mutating func dayCellTapped (_ day: CPCDay) -> Bool {
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
			
			fileprivate mutating func clearSelection () {
				self.selectedDays = .today ..< .today;
			}
		}
		
		struct Unordered: CPCViewSelectionHandlerProtocol {
			fileprivate var selection: Selection {
				return .unordered (self.selectedDays);
			}
			
			private var selectedDays: Set <CPCDay>;
			
			fileprivate init (_ selectedDays: Set <CPCDay> = Set ()) {
				self.selectedDays = selectedDays;
			}

			fileprivate mutating func dayCellTapped (_ day: CPCDay) -> Bool {
				if (self.selectedDays.contains (day)) {
					self.selectedDays.remove (day);
				} else {
					self.selectedDays.insert (day);
				}
				return true;
			}
			
			fileprivate mutating func clearSelection () {
				self.selectedDays.removeAll ();
			}
		}
		
		struct Ordered: CPCViewSelectionHandlerProtocol {
			fileprivate var selection: Selection {
				return .ordered (self.selectedDays);
			}
			
			private var selectedDays: [CPCDay];
			
			fileprivate init (_ selectedDays: [CPCDay] = []) {
				self.selectedDays = selectedDays;
			}

			fileprivate mutating func dayCellTapped (_ day: CPCDay) -> Bool {
				if let dayIndex = self.selectedDays.index (of: day) {
					self.selectedDays.remove (at: dayIndex);
				} else {
					self.selectedDays.append (day);
				}
				return true;
			}
			
			fileprivate mutating func clearSelection () {
				self.selectedDays.removeAll ();
			}
		}
		
		switch (selection) {
		case .none:
			return Disabled ();
		case .single (let day):
			return Single (day);
		case .range (let range):
			return Range (range);
		case .unordered (let days):
			return Unordered (days);
		case .ordered (let days):
			return Ordered (days);
		}
	}
}

internal protocol CPCViewDelegatingSelectionHandling: CPCViewSelectionHandling {
	associatedtype SelectionDelegateType;
	
	var selectionDelegate: SelectionDelegateType? { get set }
	
	func selectionValue (of delegate: SelectionDelegateType) -> Selection;
	func setSelectionValue (_ selection: Selection, in delegate: SelectionDelegateType);
	
	func resetSelection (in delegate: SelectionDelegateType);
	func handlerShouldSelectDayCell (_ day: CPCDay, delegate: SelectionDelegateType) -> Bool;
	func handlerShouldDeselectDayCell (_ day: CPCDay, delegate: SelectionDelegateType) -> Bool;
}

extension CPCViewDelegatingSelectionHandling {
	private typealias CPCViewDelegatingSelectionHandler = CPCViewSelectionHandler.Delegating <Self>;
	
	public var selectionDelegate: SelectionDelegateType? {
		get {
			return (self.selectionHandler as? CPCViewDelegatingSelectionHandler)?.delegate as? SelectionDelegateType;
		}
		set {
			if let newValue = newValue {
				var selectionHandler = CPCViewDelegatingSelectionHandler (self);
				selectionHandler.delegate = newValue as AnyObject;
				self.selectionHandler = selectionHandler;
			} else {
				self.selectionHandler = CPCViewSelectionHandler.primitive (for: self.selection);
			}
		}
	}
	
	public var selection: CPCViewSelection {
		get {
			return self.selectionHandler.selection;
		}
		set {
			if var selectionHandler = self.selectionHandler as? CPCViewDelegatingSelectionHandler {
				selectionHandler.selection = newValue;
			} else {
				self.selectionHandler = CPCViewSelectionHandler.primitive (for: newValue);
			}
		}
	}
}

extension CPCViewSelectionHandler {
	fileprivate struct Delegating <View>: CPCViewSelectionHandlerProtocol where View: CPCViewDelegatingSelectionHandling {
		fileprivate weak var delegate: AnyObject?;
		
		fileprivate var selection: Selection {
			get {
				return self.performWithDelegate { self.view.selectionValue (of: $0) } ?? .none;
			}
			set {
				let view = self.view;
				self.performWithDelegate { view.setSelectionValue (newValue, in: $0) };
			}
		}
		
		private unowned let view: View;
		
		fileprivate init (_ view: View) {
			self.view = view;
		}
		
		fileprivate func clearSelection () {
			self.performWithDelegate { self.view.resetSelection (in: $0) };
		}
		
		fileprivate func dayCellTapped (_ day: CPCDay) -> Bool {
			return self.performWithDelegate { (self.selection.isDaySelected (day) ? self.view.handlerShouldDeselectDayCell : self.view.handlerShouldSelectDayCell) (day, $0) } ?? false;
		}
		
		private func performWithDelegate <T> (_ block: (View.SelectionDelegateType) -> T) -> T? {
			guard let delegate = self.delegate as? View.SelectionDelegateType else {
				return nil;
			}
			return block (delegate);
		}
	}
}
