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
	///
	/// - normal: Normal state of a day cell (not selected, highlighted or disabled).
	/// - highlighted: Highlighted state of a cell (current user touch is inside cell's bounds).
	/// - selected: Selected state of a cell (cell is part of current selection).
	public enum BackgroundState {
		case normal;
		case highlighted;
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

extension CPCDayCellState.BackgroundState {
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
	public var cState: __CPCDayCellState {
		return __CPCDayCellState (backgroundState: self.backgroundState.cState, isToday: ObjCBool (self.isToday));
	}
	
	public init (_ cState: __CPCDayCellState) {
		self.backgroundState = BackgroundState (cState.backgroundState);
		self.isToday = cState.isToday.boolValue;
	}
}

public extension CPCDayCellState {
	public typealias AllCases = [CPCDayCellState];
	
	/// Collection of all values that CPCDayCellState can be equal to.
	public static let allCases: AllCases = BackgroundState.allCases.flatMap { [
		CPCDayCellState (backgroundState: $0, isToday: false),
		CPCDayCellState (backgroundState: $0, isToday: true),
	]};
}

#if swift(>=4.2)

extension CPCDayCellState.BackgroundState: CaseIterable {}
extension CPCDayCellState: CaseIterable {}

#else

public extension CPCDayCellState.BackgroundState {
	public static let allCases: [CPCDayCellState.BackgroundState] = [.normal, .highlighted, .selected];
}

#endif
