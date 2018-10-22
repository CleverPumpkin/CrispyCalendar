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

/// Dictionary-like container
internal struct CPCDayCellStateBasedStorage <Value>: ExpressibleByDictionaryLiteral {
	internal typealias State = CPCDayCellState;
	internal typealias Key = State;

	private var commonValues: ContiguousArray <Value?>;
	private var extraValues: [State: Value]?;
	
	internal init () {
		self.commonValues = ContiguousArray (repeating: nil, count: __CPCDayCellStateCompressedMask + 1);
	}
	
	internal init (dictionaryLiteral elements: (State, Value)...) {
		self.init ();
		
		let extraValues = elements.filter {
			let (state, value) = $0;
			if (state.isCompressible) {
				self.commonValues [state.compressedIndex] = value;
				return false;
			} else {
				return true;
			}
		};
		if (!extraValues.isEmpty) {
			self.extraValues = Dictionary (uniqueKeysWithValues: extraValues);
		}
	}
	
	internal subscript (state: State) -> Value? {
		get {
			guard state.isCompressible else {
				return self.extraValues? [state];
			}
			
			if let result = self.commonValues [state.compressedIndex] {
				return result;
			}
			if (state.contains (.isToday)) {
				return self [state.subtracting (.isToday)];
			} else if (state.contains (.disabled)) {
				return self [state.subtracting (.disabled)];
			} else if (state.contains (.selected)) {
				return self [state.subtracting (.selected)];
			} else if (state.contains (.highlighted)) {
				return self [state.subtracting (.highlighted)];
			} else {
				return nil;
			}
		}
		set {
			if state.isCompressible {
				self.commonValues [state.compressedIndex] = newValue;
			} else {
				var extraValues = self.extraValues ?? [:];
				extraValues [state] = newValue;
				self.extraValues = extraValues;
			}
		}
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
	internal var separatorColor = UIColor.defaultSeparator;
	internal var cellRenderer: CPCDayCellRenderer = CPCDefaultDayCellRenderer ();
	internal var cellTextColors: CPCDayCellStateBasedStorage <UIColor> = [
		[]: UIColor.defaultDayCellText,
	];
	internal var cellBackgroundColors: CPCDayCellStateBasedStorage <UIColor> = [
		[]: .white,
		.highlighted: UIColor.yellow.withAlphaComponent (0.125),
		.selected: UIColor.yellow.withAlphaComponent (0.25),
		.disabled: .darkGray,
		.isToday: .lightGray,
	];
}

/// Views conforming to this protocol perform rendering of calendar cells
public protocol CPCViewProtocol: AnyObject {
	/// The font used to display the title label.
	var titleFont: UIFont { get set };
	/// The color of the month title label.
	var titleColor: UIColor { get set };
	/// The technique to use for aligning the month title.
	var titleAlignment: NSTextAlignment { get set };
	/// Style describing the exact format to use when displaying month name.
	var titleStyle: TitleStyle { get set };
	/// The inset or outset margins for the rectangle around the month title label.
	var titleMargins: UIEdgeInsets { get set };
	/// The font used to display each day's title.
	var dayCellFont: UIFont { get set };
	/// The color of separator lines between days.
	var separatorColor: UIColor { get set };
	/// Value describing currently selected days in this view.
	var selection: Selection { get set };
	/// Renderer that is used to draw each day cell.
	var cellRenderer: CellRenderer { get set };

	/// Returns the day cell text color used for a state.
	///
	/// - Parameter state: The state that uses the text color.
	func dayCellTextColor (for state: DayCellState) -> UIColor?;
	
	/// Sets the text color of the day cell to use for the specified state.
	///
	/// - Parameters:
	///   - textColor: The color of the text to use for the specified state.
	///   - state: The state that uses the specified color.
	func setDayCellTextColor (_ textColor: UIColor?, for state: DayCellState);

	/// Returns the day cell background color used for a state.
	///
	/// - Parameter state: The state that uses the background color.
	func dayCellBackgroundColor (for state: DayCellState) -> UIColor?;
	
	/// Sets the background color of the day cell to use for the specified state.
	///
	/// - Parameters:
	///   - backgroundColor: The color of the background to use for the specified state.
	///   - state: The state that uses the specified color.
	func setDayCellBackgroundColor (_ backgroundColor: UIColor?, for state: DayCellState);
}

public extension CPCViewProtocol {
	/// See `CPCViewTitleStyle`.
	public typealias TitleStyle = CPCViewTitleStyle;
	/// See `CPCDayCellState`.
	public typealias DayCellState = CPCDayCellState;
	/// See `CPCViewSelection`.
	public typealias Selection = CPCViewSelection;
	/// See `CPCDayCellRenderer`.
	public typealias CellRenderer = CPCDayCellRenderer;
	/// See `CPCViewAppearanceStorage`
	internal typealias AppearanceStorage = CPCViewAppearanceStorage;
}
