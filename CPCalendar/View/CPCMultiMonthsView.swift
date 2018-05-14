//
//  CPCMultiMonthsView.swift
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

open class CPCMultiMonthsView: UIView, CPCViewProtocol {
	@IBInspectable open var font = CPCMultiMonthsView.defaultFont {
		didSet {
			self.updateManagedMonthViews { $0.font = self.font };
		}
	}
	
	@IBInspectable open var titleColor = CPCMultiMonthsView.defaultTitleColor {
		didSet {
			self.updateManagedMonthViews { $0.titleColor = self.titleColor };
		}
	}
	
	@IBInspectable open var separatorColor = CPCMonthView.defaultSeparatorColor {
		didSet {
			self.updateManagedMonthViews { $0.separatorColor = self.separatorColor };
		}
	}
	
	open var selection = Selection.none;
	
	internal private (set) var monthViews = UnownedArray <CPCMonthView> ();
	private var cellBackgroundColors = DayCellStateBackgroundColors ();

	open func addMonthView (_ monthView: CPCMonthView) {
		self.insertMonthView (monthView, at: self.monthViews.count);
	}
	
	open func insertMonthView (_ monthView: CPCMonthView, at index: Int) {
		if (index == self.monthViews.count) {
			self.addSubview (monthView);
			self.monthViews.append (monthView);
		} else {
			self.insertSubview (monthView, belowSubview: self.monthViews [index]);
			self.monthViews.insert (monthView, at: index);
		}
		
		monthView.font = self.font;
		monthView.titleColor = self.titleColor;
		monthView.separatorColor = self.separatorColor;
		monthView.cellBackgroundColors = self.cellBackgroundColors;
		monthView.setNeedsDisplay ();
	}
	
	open func removeMonthView (_ monthView: CPCMonthView) {
		guard let viewIndex = self.monthViews.index (where: { $0 === monthView }) else {
			return;
		}
		self.monthViews.remove (at: viewIndex);
	}
	
	open override func willRemoveSubview (_ subview: UIView) {
		super.willRemoveSubview (subview);
		
		guard let monthView = subview as? CPCMonthView else {
			return;
		}
		self.removeMonthView (monthView);
	}
}

extension CPCMultiMonthsView {
	open func dayCellBackgroundColor (for state: DayCellState) -> UIColor? {
		return self.cellBackgroundColors.color (for: state);
	}
	
	open func setDayCellBackgroundColor(_ backgroundColor: UIColor?, for state: DayCellState) {
		self.cellBackgroundColors.setColor (backgroundColor, for: state);
		self.updateManagedMonthViews { $0.setDayCellBackgroundColor (backgroundColor, for: state) };
	}
	
	private func updateManagedMonthViews (using block: (CPCViewProtocol) -> ()) {
		self.monthViews.forEach (block);
	}
}
