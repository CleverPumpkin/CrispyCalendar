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

public struct CPCDayCellState: Hashable {
	public enum BackgroundState: Int {
		case normal;
		case highlighted;
		case selected;
	}
	
	public let backgroundState: BackgroundState;
	public let isToday: Bool;
	
	
	public init (backgroundState: BackgroundState = .normal, isToday: Bool = false) {
		self.backgroundState = backgroundState;
		self.isToday = isToday;
	}
}

public extension CPCDayCellState {
	public static let normal = CPCDayCellState ();
	public static let highlighted = CPCDayCellState (backgroundState: .highlighted);
	public static let selected = CPCDayCellState (backgroundState: .selected);
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
