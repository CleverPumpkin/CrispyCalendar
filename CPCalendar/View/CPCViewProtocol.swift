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

public protocol CPCViewProtocol: AnyObject {
	typealias TitleStyle = CPCViewTitleStyle;
	typealias DayCellState = CPCDayCellState;
	typealias Selection = CPCViewSelection;
	typealias CellRenderer = CPCDayCellRenderer;
	
	var titleFont: UIFont { get set };
	var titleColor: UIColor { get set };
	var titleStyle: TitleStyle { get set };
	var titleMargins: UIEdgeInsets { get set };
	var dayCellFont: UIFont { get set };
	var dayCellTextColor: UIColor { get set };
	var separatorColor: UIColor { get set };
	var selection: Selection { get set };
	var cellRenderer: CellRenderer { get set };

	func dayCellBackgroundColor (for state: DayCellState) -> UIColor?;
	func setDayCellBackgroundColor (_ backgroundColor: UIColor?, for state: DayCellState);
}

internal extension UIEdgeInsets {
	internal static let defaultMonthTitle = UIEdgeInsets (top: 8.0, left: 8.0, bottom: 8.0, right: 8.0);
}

internal extension UIFont {
	internal static var defaultMonthTitle: UIFont {
		return .preferredFont (forTextStyle: .headline);
	}
	
	internal static var defaultDayCellText: UIFont {
		return .preferredFont (forTextStyle: .body);
	}
}

internal extension UIColor {
	internal static var defaultMonthTitle: UIColor {
		return .darkText;
	}

	internal static var defaultDayCellText: UIColor {
		return .darkText;
	}

	internal static var defaultSeparator: UIColor {
		return .gray;
	}
}

internal extension CPCViewProtocol {
	internal func copyStyle <View> (from otherView: View) where View: CPCViewProtocol {
		self.copyPrimitiveAttributes (from: otherView);
		self.copyDayCellBackgroundColors (from: otherView);
	}
	
	internal func copyPrimitiveAttributes <View> (from otherView: View) where View: CPCViewProtocol {
		self.titleFont = otherView.titleFont;
		self.titleColor = otherView.titleColor;
		self.titleStyle = otherView.titleStyle;
		self.dayCellFont = otherView.dayCellFont;
		self.dayCellTextColor = otherView.dayCellTextColor;
		self.separatorColor = otherView.separatorColor;
	}
	
	internal func copyDayCellBackgroundColors <View> (from otherView: View) where View: CPCViewProtocol {
		for state in CPCDayCellState.allCases {
			self.setDayCellBackgroundColor (otherView.dayCellBackgroundColor (for: state), for: state);
		}
	}
}

internal struct CPCViewDayCellStateBackgroundColors {
	private var colors: [CPCDayCellState: UIColor];
	
	internal init () {
		self = [
			.normal: .white,
			.highlighted: UIColor.yellow.withAlphaComponent (0.125),
			.selected: UIColor.yellow.withAlphaComponent (0.25),
			.today: .lightGray,
		];
	}
	
	internal init <D> (_ colors: D) where D: Sequence, D.Element == (CPCDayCellState, UIColor) {
		self.colors = Dictionary (uniqueKeysWithValues: colors);
	}
	
	internal subscript (state: CPCDayCellState) -> UIColor? {
		get {
			return self.colors [state];
		}
		set {
			self.colors [state] = newValue;
		}
	}
	
	internal subscript (effective state: CPCDayCellState) -> UIColor? {
		for state in sequence (first: state, next: { $0.parent }) {
			if let result = self [state] {
				return result;
			}
		}
		return nil;
	}
}

extension CPCViewDayCellStateBackgroundColors: ExpressibleByDictionaryLiteral {
	internal typealias Key = CPCDayCellState;
	internal typealias Value = UIColor;
	
	internal init (dictionaryLiteral elements: (CPCDayCellState, UIColor)...) {
		self.colors = Dictionary <Key, Value> (uniqueKeysWithValues: elements);
	}
}

extension CPCViewDayCellStateBackgroundColors: Collection {
	internal typealias Index = Dictionary <Key, Value>.Index;
	internal typealias Element = Dictionary <Key, Value>.Element;
	
	internal var startIndex: Index {
		return self.colors.startIndex;
	}
	
	internal var endIndex: Index {
		return self.colors.endIndex;
	}
	
	internal subscript (position: Index) -> Element {
		return self.colors [position];
	}
	
	internal func index (after i: Index) -> Index {
		return self.colors.index (after: i);
	}
}

internal protocol CPCViewDayCellBackgroundColorsStorage: AnyObject {
	var cellBackgroundColors: DayCellStateBackgroundColors { get set };
}

extension CPCViewDayCellBackgroundColorsStorage {
	public func dayCellBackgroundColor (for state: CPCViewProtocol.DayCellState) -> UIColor? {
		return self.cellBackgroundColors [state];
	}
	
	public func setDayCellBackgroundColor (_ backgroundColor: UIColor?, for state: CPCViewProtocol.DayCellState) {
		self.cellBackgroundColors [state] = backgroundColor;
	}
}

internal extension CPCViewDayCellBackgroundColorsStorage where Self: CPCViewProtocol {
	internal typealias DayCellStateBackgroundColors = CPCViewDayCellStateBackgroundColors;
	
	internal func copyDayCellBackgroundColors <View> (from otherView: View) where View: CPCViewProtocol, View: CPCViewDayCellBackgroundColorsStorage {
		self.cellBackgroundColors = otherView.cellBackgroundColors;
	}
}
