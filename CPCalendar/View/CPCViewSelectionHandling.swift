//
//  CPCViewSelectionHandling.swift
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
	
	func clearingSelection () -> Self;
	func handleTap (day: CPCDay) -> CPCViewSelectionHandlerProtocol?;
}

internal protocol CPCPrimitiveSelectionHandler: CPCViewSelectionHandlerProtocol {
	init ();
}

internal extension CPCPrimitiveSelectionHandler {
	internal func clearingSelection () -> Self {
		return Self ();
	}
}

internal let CPCViewDefaultSelectionHandler: CPCViewSelectionHandlerProtocol = CPCViewSelectionHandler.primitive (for: .none);

internal protocol CPCViewSelectionHandling: AnyObject {
	typealias SelectionHandler = CPCViewSelectionHandlerProtocol;
	
	var selectionHandler: SelectionHandler { get set };
}

extension CPCViewSelectionHandling {
	public typealias Selection = CPCViewSelection;
	
	public var selection: CPCViewSelection {
		get {
			return self.selectionHandler.selection;
		}
		set {
			self.selectionHandler = CPCViewSelectionHandler.primitive (for: newValue);
		}
	}	
}

fileprivate enum CPCViewSelectionHandler {}

extension CPCViewSelectionHandler {
	fileprivate static func primitive (for selection: CPCViewSelection) -> CPCViewSelectionHandlerProtocol {
		struct Disabled: CPCPrimitiveSelectionHandler {
			fileprivate var selection: Selection {
				return .none;
			}
			
			fileprivate init () {}

			fileprivate func handleTap (day: CPCDay) -> CPCViewSelectionHandlerProtocol? {
				return nil;
			}
			
			fileprivate mutating func clearSelection () {}
		}
		
		struct Single: CPCPrimitiveSelectionHandler {
			fileprivate var selection: Selection {
				return .single (self.selectedDay);
			}
			
			private let selectedDay: CPCDay?;
			
			fileprivate init () {
				self.init (nil);
			}
			
			fileprivate init (_ selectedDay: CPCDay?) {
				self.selectedDay = selectedDay;
			}

			fileprivate func handleTap (day: CPCDay) -> CPCViewSelectionHandlerProtocol? {
				return Single ((day == self.selectedDay) ? nil : day);
			}
		}
		
		struct Range: CPCPrimitiveSelectionHandler {
			fileprivate var selection: Selection {
				return .range (self.selectedDays);
			}
			
			private let selectedDays: CountableRange <CPCDay>;
			
			fileprivate init () {
				self.init (.today ..< .today);
			}
			
			fileprivate init (_ selectedDays: CountableRange <CPCDay>) {
				self.selectedDays = selectedDays;
			}

			fileprivate func handleTap (day: CPCDay) -> CPCViewSelectionHandlerProtocol? {
				let newRange: CountableRange <CPCDay>;
				if (self.selectedDays.count == 1) {
					let selectedDay = self.selectedDays.lowerBound;
					if (day < selectedDay) {
						newRange = day ..< selectedDay.next;
					} else {
						newRange = selectedDay ..< day.next;
					}
				} else {
					newRange = day ..< day.next;
				}
				return Range (newRange);
			}
		}
		
		struct Unordered: CPCPrimitiveSelectionHandler {
			fileprivate var selection: Selection {
				return .unordered (self.selectedDays);
			}
			
			private var selectedDays: Set <CPCDay>;

			fileprivate init () {
				self.init ([]);
			}

			fileprivate init (_ selectedDays: Set <CPCDay> = Set ()) {
				self.selectedDays = selectedDays;
			}

			fileprivate func handleTap (day: CPCDay) -> CPCViewSelectionHandlerProtocol? {
				return Unordered (self.selectedDays.contains (day) ? self.selectedDays.filter { $0 != day } : self.selectedDays.union (CollectionOfOne (day)));
			}
		}
		
		struct Ordered: CPCPrimitiveSelectionHandler {
			fileprivate var selection: Selection {
				return .ordered (self.selectedDays);
			}
			
			private var selectedDays: [CPCDay];

			fileprivate init () {
				self.init ([]);
			}

			fileprivate init (_ selectedDays: [CPCDay] = []) {
				self.selectedDays = selectedDays;
			}

			fileprivate func handleTap (day: CPCDay) -> CPCViewSelectionHandlerProtocol? {
				return Ordered (self.selectedDays.contains (day) ? self.selectedDays.filter { $0 != day } : self.selectedDays + CollectionOfOne (day));
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
				let selectionHandler = CPCViewDelegatingSelectionHandler (self);
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
			if let selectionHandler = self.selectionHandler as? CPCViewDelegatingSelectionHandler {
				selectionHandler.selection = newValue;
			} else {
				self.selectionHandler = CPCViewSelectionHandler.primitive (for: newValue);
			}
		}
	}
}

extension CPCViewSelectionHandler {
	fileprivate final class Delegating <View>: CPCViewSelectionHandlerProtocol where View: CPCViewDelegatingSelectionHandling {
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
		
		fileprivate func clearingSelection () -> Self {
			self.performWithDelegate { self.view.resetSelection (in: $0) };
			return self;
		}
		
		fileprivate func handleTap (day: CPCDay) -> CPCViewSelectionHandlerProtocol? {
			let method = (self.selection.isDaySelected (day) ? self.view.handlerShouldDeselectDayCell : self.view.handlerShouldSelectDayCell);
			return self.performWithDelegate { method (day, $0) }.map { _ in self };
		}
		
		private func performWithDelegate <T> (_ block: (View.SelectionDelegateType) -> T) -> T? {
			guard let delegate = self.delegate as? View.SelectionDelegateType else {
				return nil;
			}
			return block (delegate);
		}
	}
}
