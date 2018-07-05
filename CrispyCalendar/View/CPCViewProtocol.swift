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

fileprivate extension BinaryInteger {
	fileprivate var usedBitCount: Int {
		guard self > 0 else {
			return (self == 0) ? 0 : self.bitWidth;
		}
		
		let words = self.words;
		var iterator = words.makeIterator ();
		guard var lastWord = iterator.next () else {
			return 0;
		}
		var result = 0;
		while let word = iterator.next () {
			result += UInt.bitWidth;
			lastWord = word;
		}
		return result + lastWord.usedBitCount;
	}
}

fileprivate extension FixedWidthInteger {
	fileprivate var usedBitCount: Int {
		return Self.bitWidth - self.leadingZeroBitCount;
	}
}

internal extension CPCDayCellState {
	internal var appearanceValues: (Int, Int) {
		return (self.backgroundState.rawValue, self.isToday ? 1 : 0);
	}
}

fileprivate extension CPCDayCellState {
	fileprivate static let isTodayIndexMask = 1 << BackgroundState.requiredBitCount;
	fileprivate static let requiredBitCount = BackgroundState.requiredBitCount + 1;
	
	fileprivate init (_ backgroundStateValue: Int, _ isTodayValue: Int) {
		self.init (backgroundState: BackgroundState (rawValue: backgroundStateValue)!, isToday: isTodayValue != 0);
	}
}

fileprivate extension CPCDayCellState.BackgroundState {
	fileprivate static let requiredBitCount = (allCases.count - 1).usedBitCount;
}

/// Dictionary-like container
internal struct CPCViewDayCellStateBackgroundColors {
	private typealias BackgroundColors = CPCViewDayCellStateBackgroundColors;
	private typealias State = CPCDayCellState;
	
	private static let capacity = 1 << CPCDayCellState.requiredBitCount;
	private static let stateIndexBounds = 0 ..< BackgroundColors.capacity;
	
	private static let `default`: BackgroundColors = [
		.normal: .white,
		.highlighted: UIColor.yellow.withAlphaComponent (0.125),
		.selected: UIColor.yellow.withAlphaComponent (0.25),
		.disabled: .darkGray,
		.today: .lightGray,
	];
	
	private static func stateIndex (for state: State, message: @autoclosure () -> String, file: StaticString = #file, line: Int = #line, function: String = #function) -> Int {
		let stateIndex = state.backgroundState.rawValue | (state.isToday ? CPCDayCellState.isTodayIndexMask : 0), stateIndexBounds = self.stateIndexBounds;
		precondition (stateIndexBounds ~= stateIndex, "\(file):\(line) (\(function)): \(message ()): state index \(stateIndex) is out of bounds \(stateIndexBounds)");
		return stateIndex;
	}
	
	private var colors: ContiguousArray <UIColor?>;
	
	internal init () {
		self = BackgroundColors.default;
	}
	
	internal init <D> (_ colors: D) where D: Sequence, D.Element == (CPCDayCellState, UIColor) {
		var colorsStorage = ContiguousArray <UIColor?> (repeating: nil, count: CPCViewDayCellStateBackgroundColors.capacity);
		for (state, color) in colors {
			colorsStorage [BackgroundColors.stateIndex (for: state, message: "Cannot set initial color for state \(state)")] = color;
		}
		self.colors = colorsStorage;
	}
	
	internal subscript (state: CPCDayCellState) -> UIColor? {
		get {
			return self.colors [BackgroundColors.stateIndex (for: state, message: "Cannot retrieve color for state \(state)")];
		}
		set {
			self.colors [BackgroundColors.stateIndex (for: state, message: "Cannot store color for state \(state)")] = newValue;
		}
	}
}

extension CPCViewDayCellStateBackgroundColors: ExpressibleByDictionaryLiteral {
	internal typealias Key = CPCDayCellState;
	internal typealias Value = UIColor;
	
	internal init (dictionaryLiteral elements: (CPCDayCellState, UIColor)...) {
		self.init (elements);
	}
}

extension CPCViewDayCellStateBackgroundColors: Collection {
	internal typealias Index = CPCDayCellState.AllCases.Index;
	internal typealias Element = (key: CPCDayCellState, value: UIColor?);
	
	internal var startIndex: Index {
		return CPCDayCellState.allCases.startIndex;
	}
	
	internal var endIndex: Index {
		return CPCDayCellState.allCases.endIndex;
	}
	
	internal subscript (position: Index) -> Element {
		let state = CPCDayCellState.allCases [position];
		return (key: state, value: self [state]);
	}
	
	internal func index (after i: Index) -> Index {
		return CPCDayCellState.allCases.index (after: i);
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

internal extension NSObjectProtocol {
	internal var isAppearanceProxy: Bool {
		guard let selfClass = object_getClass (self) else {
			return true;
		}
		return !selfClass.isSubclass (of: Self.self);
	}
}

internal final class CPCViewAppearanceStorage {
	internal var titleFont = UIFont.defaultMonthTitle;
	internal var titleColor = UIColor.defaultMonthTitle;
	internal var titleAlignment = NSTextAlignment.center;
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
	var titleAlignment: NSTextAlignment { get set };
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
		self.titleAlignment = otherView.titleAlignment;
		self.titleStyle = otherView.titleStyle;
		self.dayCellFont = otherView.dayCellFont;
		self.dayCellTextColor = otherView.dayCellTextColor;
		self.separatorColor = otherView.separatorColor;

		for state in CPCDayCellState.allCases {
			self.setDayCellBackgroundColor (otherView.dayCellBackgroundColor (for: state), for: state);
		}
	}
	
	internal func dayCellBackgroundColorImpl (_ backgroundStateValue: Int, _ isTodayValue: Int) -> UIColor? {
		return self.dayCellBackgroundColor (for: CPCDayCellState (backgroundStateValue, isTodayValue));
	}
	
	internal func setDayCellBackgroundColorImpl (_ backgroundColor: UIColor?, _ backgroundStateValue: Int, _ isTodayValue: Int) {
		return self.setDayCellBackgroundColor (backgroundColor, for: CPCDayCellState (backgroundStateValue, isTodayValue));
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
