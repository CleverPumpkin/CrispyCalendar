//
//  CPCDayCellState.swift
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

import Swift

/// State of a single cell for a specific day.
public struct CPCDayCellState: Hashable {
	/// State of a cell that is assigned due to user actions.
	public enum BackgroundState: Int, Hashable {
		/// Normal state of a day cell (not selected, highlighted or disabled).
		case normal;
		/// Highlighted state of a cell (current user touch is inside cell's bounds).
		case highlighted;
		/// Selected state of a cell (cell is part of current selection).
		case selected;
	}
	
	/// State part, corresponding to user actions.
	public let backgroundState: BackgroundState;
	/// State part, indicating that cell is rendering current day.
	public let isToday: Bool;
	
	/// Creates a new cell state from state items.
	///
	/// - Parameters:
	///   - backgroundState: User-dependent state part.
	///   - isToday: Value that indicates that cell renders current day.
	public init (backgroundState: BackgroundState = .normal, isToday: Bool = false) {
		self.backgroundState = backgroundState;
		self.isToday = isToday;
	}
}

public extension CPCDayCellState {
	/// Normal state of a cell that renders any day except current.
	public static let normal = CPCDayCellState ();
	/// Highlighted state of a cell that renders any day except current.
	public static let highlighted = CPCDayCellState (backgroundState: .highlighted);
	/// Selected state of a cell that renders any day except current.
	public static let selected = CPCDayCellState (backgroundState: .selected);
	/// Normal state of a cell that renders current day.
	public static let today = CPCDayCellState (isToday: true);
}

public extension CPCDayCellState.BackgroundState {
	/// `CPCDayCellBackgroundState` value, equivalent to this `CPCDayCellState.BackgroundState` value.
	public var cState: __CPCDayCellBackgroundState {
		switch (self) {
		case .normal:
			return .normal;
		case .highlighted:
			return .highlighted;
		case .selected:
			return .selected;
		}
	}
	
	/// Creates new `CPCDayCellState.BackgroundState` equivalent to a `CPCDayCellBackgroundState` value.
	///
	/// - Parameter cState: `CPCDayCellBackgroundState` value to copy.
	public init (_ cState: __CPCDayCellBackgroundState) {
		switch cState {
		case .normal:
			self = .normal;
		case .highlighted:
			self = .highlighted;
		case .selected:
			self = .selected;
		}
	}
}

extension CPCDayCellState {
	/// `CPCDayCellState` Objective C value, equivalent to this `CPCDayCellState` value.
	public var cState: __CPCDayCellState {
		return __CPCDayCellState (backgroundState: self.backgroundState.cState, isToday: ObjCBool (self.isToday));
	}
	
	/// Creates new `CPCDayCellState` equivalent to a `CPCDayCellState` Objective C value.
	///
	/// - Parameter cState: `CPCDayCellState` Objective C value to copy.
	public init (_ cState: __CPCDayCellState) {
		self.backgroundState = BackgroundState (cState.backgroundState);
		self.isToday = cState.isToday.boolValue;
	}
}

public extension CPCDayCellState {
	public struct AllCases {
		fileprivate init () {}
	}
	
	/// Collection of all values that CPCDayCellState can be equal to.
	public static let allCases = AllCases ();
}

extension CPCDayCellState.AllCases: Collection {
	public typealias Element = CPCDayCellState;

	public struct Index: Comparable {
		private enum Value: Equatable {
			case element (CPCDayCellState);
			case end;
		}
		
		private static let firstBackgroundState = guarantee (CPCDayCellState.BackgroundState (rawValue: 0));
		
		public static func < (lhs: Index, rhs: Index) -> Bool {
			switch (lhs.value, rhs.value) {
			case (.end, _):
				return false;
			case (_, .end):
				return true;
			case (.element (let lhs), .element (let rhs)):
				guard lhs.isToday == rhs.isToday else {
					return rhs.isToday;
				}
				return lhs.backgroundState.rawValue < rhs.backgroundState.rawValue;
			}
		}
		
		fileprivate var element: Element {
			guard case .element (let element) = self.value else {
				preconditionFailure ("Cannot access value at \(self) index in \(CPCDayCellState.AllCases.self)");
			}
			return element;
		}
		
		fileprivate var next: Index {
			guard case .element (let element) = self.value else {
				preconditionFailure ("Cannot advance \(self) index");
			}
			
			if let nextBackgroundState = CPCDayCellState.BackgroundState (rawValue: element.backgroundState.rawValue + 1) {
				return Index (CPCDayCellState (backgroundState: nextBackgroundState, isToday: element.isToday));
			} else {
				return element.isToday ? Index (end: ()) : Index (CPCDayCellState (backgroundState: Index.firstBackgroundState, isToday: true));
			}
		}
		
		private let value: Value;
		
		fileprivate init (start: ()) {
			self.value = .element (CPCDayCellState (backgroundState: Index.firstBackgroundState, isToday: false));
		}

		fileprivate init (end: ()) {
			self.value = .end;
		}
		
		private init (_ state: Element) {
			self.value = .element (state);
		}
	}

	public var startIndex: Index {
		return Index (start: ());
	}
	
	public var endIndex: Index {
		return Index (end: ());
	}
	
	public subscript (position: Index) -> CPCDayCellState {
		return position.element;
	}

	public func index (after i: Index) -> Index {
		return i.next;
	}
}

#if swift(>=4.2)

extension CPCDayCellState.BackgroundState: CaseIterable {}
extension CPCDayCellState: CaseIterable {}

#else

public extension CPCDayCellState.BackgroundState {
	public static let allCases: [CPCDayCellState.BackgroundState] = [.normal, .highlighted, .selected];
}

#endif
