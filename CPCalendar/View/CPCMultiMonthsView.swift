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

fileprivate extension RangeReplaceableCollection {
	fileprivate mutating func remove (where predicate: (Element) throws -> Bool) rethrows -> Element? {
		return try self.index (where: predicate).map { self.remove (at: $0) };
	}
}

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
	
	open var selection: Selection {
		get {
			return self.selectionManager.selection;
		}
		set {
			self.selectionManager.selection = newValue;
			self.selectionDidChange ();
		}
	}
	
	internal private (set) var monthViews = UnownedArray <CPCMonthView> ();
	
	private let selectionManager = SelectionManager ();
	private var cellBackgroundColors = DayCellStateBackgroundColors ();
}

extension CPCMultiMonthsView {
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
		monthView.selectionHandler = self.selectionHandler (for: monthView);
		monthView.setNeedsDisplay ();
	}
	
	open func removeMonthView (_ monthView: CPCMonthView) {
		guard let removedView = self.monthViews.remove (where: { $0 === monthView }) else {
			return;
		}
		removedView.selection = .none;
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
	
	private func updateManagedMonthViews (using block: (CPCMonthView) -> ()) {
		self.monthViews.forEach (block);
	}
}

extension CPCMultiMonthsView {
	private final class SelectionManager {
		private struct MonthViewHandler: SelectionHandler {
			fileprivate var selection: Selection {
				return self.monthView.month.map { self.manager.selection.clamped (to: $0) } ?? .none;
			}
			
			private unowned let manager: SelectionManager;
			private unowned let monthView: CPCMonthView;
			
			fileprivate init (_ manager: SelectionManager, for monthView: CPCMonthView) {
				self.manager = manager;
				self.monthView = monthView;
			}
			
			fileprivate func clearSelection () {
				self.manager.clearSelection (in: self.monthView);
			}
			
			fileprivate func dayCellTapped (_ day: CPCDay) -> Bool {
				return self.manager.dayCellTapped (day, in: self.monthView);
			}
		}
		
		fileprivate var selection: Selection {
			get {
				return self.selectionHandler.selection;
			}
			set {
				self.selectionHandler = selection.builtinHandler;
			}
		}
		private var selectionHandler: SelectionHandler = CPCMultiMonthsView.defaultSelectionHandler;
		
		fileprivate func selectionHandler (for monthView: CPCMonthView) -> SelectionHandler {
			return MonthViewHandler (self, for: monthView);
		}

		fileprivate func clearSelection (in monthView: CPCMonthView) {
			monthView.selectionHandler = self.selectionHandler (for: monthView);
		}

		fileprivate func dayCellTapped (_ day: CPCDay, in monthView: CPCMonthView) -> Bool {
			return true; // TODO
		}
	}
	
	private func selectionDidChange () {
		for monthView in self.monthViews {
			monthView.selectionHandler = self.selectionHandler (for: monthView);
		}
	}
	
	private func selectionHandler (for monthView: CPCMonthView) -> SelectionHandler {
		return self.selectionManager.selectionHandler (for: monthView);
	}
}
