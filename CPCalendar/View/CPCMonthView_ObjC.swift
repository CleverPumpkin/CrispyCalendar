//
//  CPCMonthView+ObjC.swift
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

extension CPCMonthView.DayCellState.BackgroundState {
	public var cState: __CPCMonthViewDayCellBackgroundState {
		switch (self) {
		case .normal:
			return .normal;
		case .highlighted:
			return .highlighted;
		case .selected:
			return .selected;
		}
	}
	
	public init (_ cState: __CPCMonthViewDayCellBackgroundState) {
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

extension CPCMonthView.DayCellState {
	public var cState: __CPCMonthViewDayCellState {
		return __CPCMonthViewDayCellState (backgroundState: self.backgroundState.cState, isToday: ObjCBool (self.isToday));
	}
	
	public init (_ cState: __CPCMonthViewDayCellState) {
		self.backgroundState = BackgroundState (cState.backgroundState);
		self.isToday = cState.isToday.boolValue;
	}
}

extension CPCMonthView {
	@objc open func dayCellBackgroundColor (for state: __CPCMonthViewDayCellState) -> UIColor? {
		return self.dayCellBackgroundColor (for: DayCellState (state));
	}
	
	@objc open func setDayCellBackgroundColor (_ backgroundColor: UIColor?, for state: __CPCMonthViewDayCellState) {
		self.setDayCellBackgroundColor (backgroundColor, for: DayCellState (state));
	}
}
