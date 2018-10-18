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

#if !swift(>=4.2)
/// A type that provides a collection of all of its values.
public protocol CaseIterable {
	/// A type that can represent a collection of all values of this type.
	associatedtype AllCases = [Self] where AllCases: Collection AllCases.Element == Self;

	/// A collection of all values of this type.
	public static var allCases: AllCases { get }
}
#endif

/// State of a single cell for a specific day.
public struct CPCDayCellState: Hashable, CaseIterable {
	public static let allCases = [false, true].flatMap { isToday in BackgroundState.allCases.map { CPCDayCellState (backgroundState: $0, isToday: isToday) } };
	
	/// State of a cell that is assigned due to user actions.
	public enum BackgroundState: Int, Hashable, CaseIterable {
		/// Normal state of a day cell (not selected, highlighted or disabled).
		case normal;
		/// Highlighted state of a cell (current user touch is inside cell's bounds).
		case highlighted;
		/// Selected state of a cell (cell is part of current selection).
		case selected;
		/// Disabled state of a cell (cell is displayed but cannot be a part of selection).
		case disabled;
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
	/// Disabled state of a cell that renders any day except current.
	public static let disabled = CPCDayCellState (backgroundState: .disabled);
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
		case .disabled:
			return .disabled;
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
		case .disabled:
			self = .disabled;
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

#if !swift(>=4.2)

public extension CPCDayCellState.BackgroundState {
	public static let allCases: [CPCDayCellState.BackgroundState] = [.normal, .highlighted, .selected, .disabled];
}

#endif
