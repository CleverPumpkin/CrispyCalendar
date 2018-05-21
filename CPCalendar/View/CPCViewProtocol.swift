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

internal struct CPCViewDayCellStateBackgroundColors {
	private var colors: [CPCDayCellState: UIColor];
	
	internal init () {
		self = [
			.normal: .white,
			.highlighted: UIColor.yellow.withAlphaComponent (0.125),
			.selected: UIColor.yellow.withAlphaComponent (0.25),
			.today: .lightGray,
		];
		self.colors.reserveCapacity (CPCDayCellState.allCases.count);
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

fileprivate extension UIEdgeInsets {
	fileprivate static let defaultMonthTitle = UIEdgeInsets (top: 8.0, left: 8.0, bottom: 8.0, right: 8.0);
}

fileprivate extension UIFont {
	fileprivate static var defaultMonthTitle: UIFont {
		return .preferredFont (forTextStyle: .headline);
	}
	
	fileprivate static var defaultDayCellText: UIFont {
		return .preferredFont (forTextStyle: .body);
	}
}

fileprivate extension UIColor {
	fileprivate static var defaultMonthTitle: UIColor {
		return .darkText;
	}
	
	fileprivate static var defaultDayCellText: UIColor {
		return .darkText;
	}
	
	fileprivate static var defaultSeparator: UIColor {
		return .gray;
	}
}

internal final class CPCViewAppearanceStorage {
	internal var titleFont = UIFont.defaultMonthTitle;
	internal var titleColor = UIColor.defaultMonthTitle;
	internal var titleStyle = CPCViewTitleStyle.default;
	internal var titleMargins = UIEdgeInsets.defaultMonthTitle;
	internal var dayCellFont = UIFont.defaultDayCellText;
	internal var dayCellTextColor = UIColor.defaultDayCellText;
	internal var separatorColor = UIColor.defaultSeparator;
	internal var cellRenderer: CPCDayCellRenderer = CPCDefaultDayCellRenderer ();
	internal var cellBackgroundColors = CPCViewDayCellStateBackgroundColors ();
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

internal extension CPCViewProtocol {
	internal func copyStyle <View> (from otherView: View) where View: CPCViewProtocol {
		self.titleFont = otherView.titleFont;
		self.titleColor = otherView.titleColor;
		self.titleStyle = otherView.titleStyle;
		self.dayCellFont = otherView.dayCellFont;
		self.dayCellTextColor = otherView.dayCellTextColor;
		self.separatorColor = otherView.separatorColor;

		for state in CPCDayCellState.allCases {
			self.setDayCellBackgroundColor (otherView.dayCellBackgroundColor (for: state), for: state);
		}
	}
}

internal protocol CPCViewBackedByAppearanceStorage: AnyObject {
	var appearanceStorage: CPCViewAppearanceStorage { get set };
}

internal extension CPCViewBackedByAppearanceStorage where Self: CPCViewProtocol {
	internal typealias AppearanceStorage = CPCViewAppearanceStorage;
	
	internal func copyStyle <View> (from otherView: View) where View: CPCViewProtocol, View: CPCViewBackedByAppearanceStorage {
		self.appearanceStorage = otherView.appearanceStorage;
	}
}
