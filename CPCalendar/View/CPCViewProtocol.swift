//
//  CPCViewProtocol.swift
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

public enum CPCViewSelection: Equatable {
	case none;
	case single (CPCDay?);
	case range (CountableRange <CPCDay>);
	case unordered (Set <CPCDay>);
	case ordered ([CPCDay]);
}

public extension CPCViewSelection {
	public func isDaySelected (_ day: CPCDay) -> Bool {
		switch (self) {
		case .none:
			return false;
		case .single (let selectedDay):
			return (selectedDay == day);
		case .range (let selectedDays):
			return (selectedDays ~= day);
		case .unordered (let selectedDays):
			return selectedDays.contains (day);
		case .ordered (let selectedDays):
			return selectedDays.contains (day);
		}
	}
	
	private var selectedDays: Set <CPCDay> {
		switch (self) {
		case .none, .single (nil):
			return [];
		case .single (.some (let selectedDay)):
			return [selectedDay];
		case .range (let selectedDays):
			return Set (selectedDays);
		case .unordered (let selectedDays):
			return selectedDays;
		case .ordered (let selectedDays):
			return Set (selectedDays);
		}
	}
	
	public func difference (_ other: CPCViewSelection) -> Set <CPCDay> {
		return self.selectedDays.symmetricDifference (other.selectedDays);
	}
	
	public func clamped <R> (to datesRange: R) -> CPCViewSelection where R: CPCDateInterval {
		let startDate = datesRange.start, endDate = datesRange.end;
		switch (self) {
		case .single (.some (let day)) where !datesRange.contains (day):
			return .single (nil)
		case .none, .single:
			return self;
		case .range (let range):
			let lowerBound = range.lowerBound, upperBound = range.upperBound, calendar = lowerBound.calendar;
			let clampedRange = (lowerBound.start ..< range.upperBound.end).clamped (to: datesRange);
			return .range (CPCDay (containing: clampedRange.lowerBound, calendar: calendar) ..< CPCDay (containing: clampedRange.upperBound, calendar: calendar));
		case .unordered (let days):
			return .unordered (days.filter { datesRange.contains ($0) });
		case .ordered (let days):
			return .ordered (days.filter { datesRange.contains ($0) });
		}
	}
}

fileprivate extension CPCDayCellState {
	fileprivate var parent: CPCDayCellState? {
		if self.isToday {
			return CPCDayCellState (backgroundState: self.backgroundState, isToday: false);
		}
		
		switch (self.backgroundState) {
		case .selected, .highlighted:
			return CPCDayCellState (backgroundState: .normal, isToday: false);
		case .normal:
			return nil;
		}
	}
}

internal struct CPCViewDayCellStateBackgroundColors {
	private static let defaultColors: [CPCDayCellState: UIColor] = [
		.normal: .white,
		.highlighted: UIColor.yellow.withAlphaComponent (0.125),
		.selected: UIColor.yellow.withAlphaComponent (0.25),
		.today: .lightGray,
	];
	
	private var colors: [CPCDayCellState: UIColor];

	internal init () {
		self.colors = CPCViewDayCellStateBackgroundColors.defaultColors;
	}
	
	internal init <D> (_ colors: D) where D: Sequence, D.Element == (CPCDayCellState, UIColor) {
		self.colors = Dictionary (uniqueKeysWithValues: colors);
	}
	
	internal func color (for state: CPCDayCellState) -> UIColor? {
		return self.colors [state];
	}
	
	internal func effectiveColor (for state: CPCDayCellState) -> UIColor? {
		for state in sequence (first: state, next: { $0.parent }) {
			if let backgroundColor = self.colors [state] {
				return backgroundColor;
			}
		}
		return nil;
	}
	
	internal mutating func setColor (_ backgroundColor: UIColor?, for state: CPCDayCellState) {
		self.colors [state] = backgroundColor;
	}
}

public protocol CPCViewProtocol: AnyObject {
	typealias DayCellState = CPCDayCellState;
	typealias Selection = CPCViewSelection;
	
	var font: UIFont { get set };
	var titleColor: UIColor { get set };
	var separatorColor: UIColor { get set };
	var selection: Selection { get set };

	func dayCellBackgroundColor (for state: DayCellState) -> UIColor?;
	func setDayCellBackgroundColor (_ backgroundColor: UIColor?, for state: DayCellState);
}

extension CPCViewProtocol {
	internal typealias DayCellStateBackgroundColors = CPCViewDayCellStateBackgroundColors;
	internal typealias SelectionHandler = CPCMonthViewSelectionHandler;
	
	internal static var defaultFont: UIFont {
		return .systemFont (ofSize: UIFont.systemFontSize);
	}
	
	internal static var defaultTitleColor: UIColor {
		return .darkText;
	}
	
	internal static var defaultSeparatorColor: UIColor {
		return .gray;
	}
}
