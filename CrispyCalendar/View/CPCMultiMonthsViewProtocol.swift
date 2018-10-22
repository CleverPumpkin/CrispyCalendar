//
//  CPCMonthViewsManager.swift
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

internal protocol CPCMultiMonthsViewProtocol: AnyObject {
	var monthViewsManager: CPCMonthViewsManager { get }
}

internal extension CPCMultiMonthsViewProtocol {
	internal var unownedMonthViews: UnownedArray <CPCMonthView> {
		return self.monthViewsManager.unownedMonthViews;
	}
	
	internal func updateManagedMonthViews (using block: (CPCMonthView) -> ()) {
		self.monthViewsManager.updateManagedMonthViews (using: block);
	}
}

internal extension CPCMultiMonthsViewProtocol where Self: CPCViewDelegatingSelectionHandling {
	internal var selectionHandler: SelectionHandler {
		get { return self.monthViewsManager.multiSelectionHandler }
		set { self.monthViewsManager.setMultiSelectionHandler (newValue) }
	}
}

internal final class CPCMonthViewsManager {
	internal var selectionDidChangeBlock: (() -> ())? {
		didSet {
			switch (self.selectionDidChangeBlock, oldValue) {
			case (.none, .some):
				self.updateManagedMonthViews { $0.addTarget (self, action: #selector (monthViewValueChanged), for: .valueChanged) };
			case (.some, .none):
				self.updateManagedMonthViews { $0.removeTarget (self, action: #selector (monthViewValueChanged), for: .valueChanged) };
			case (.none, .none), (.some, .some):
				break;
			}
		}
	}

	internal let appearanceStorage = CPCViewAppearanceStorage ();

	fileprivate private (set) var unownedMonthViews = UnownedArray <CPCMonthView> ();
	fileprivate var multiSelectionHandler = CPCViewDefaultSelectionHandler;
	
	internal func prepareForContainerDeallocation () {
		self.monthViews.forEach (self.unassociateMonthView);
	}
}

internal extension CPCMonthViewsManager {
	internal var monthViews: [CPCMonthView] {
		return Array (self.unownedMonthViews);
	}
	
	internal func addMonthView (_ monthView: CPCMonthView) {
		monthView.removeFromMultiMonthViewsManager ();
		self.unownedMonthViews.append (monthView);
		if (self.selectionDidChangeBlock != nil) {
			monthView.addTarget (self, action: #selector (monthViewValueChanged), for: .valueChanged);
		}
		monthView.monthViewsManager = self;
		monthView.cellRenderer = self.appearanceStorage.cellRenderer;
		monthView.selectionHandler = self.selectionHandler (for: monthView);
		monthView.setNeedsDisplay ();
	}
	
	internal func removeMonthView (_ monthView: CPCMonthView) {
		guard let removedView = self.unownedMonthViews.remove (where: { $0 === monthView }) else {
			return;
		}
		self.unassociateMonthView (removedView);
	}
	
	internal func updateManagedMonthViews (using block: (CPCMonthView) -> ()) {
		self.unownedMonthViews.forEach (block);
	}
	
	@objc private func monthViewValueChanged () {
		self.selectionDidChangeBlock? ();
	}
	
	private func unassociateMonthView (_ monthView: CPCMonthView) {
		monthView.removeTarget (self, action: #selector (monthViewValueChanged), for: .valueChanged);
		monthView.selectionHandler = CPCViewDefaultSelectionHandler;
		monthView.monthViewsManager = nil;
	}
}

extension CPCMonthViewsManager: CPCViewProtocol {
	internal var titleFont: UIFont {
		get { return self.appearanceStorage.titleFont }
		set {
			self.appearanceStorage.titleFont = newValue;
			self.updateManagedMonthViews { $0.titleFontDidUpdate () };
		}
	}
	
	internal var titleColor: UIColor {
		get { return self.appearanceStorage.titleColor }
		set {
			self.appearanceStorage.titleColor = newValue;
			self.updateManagedMonthViews { $0.titleAppearanceDidUpdate () };
		}
	}
	
	internal var titleAlignment: NSTextAlignment {
		get { return self.appearanceStorage.titleAlignment }
		set {
			self.appearanceStorage.titleAlignment = newValue;
			self.updateManagedMonthViews { $0.titleAppearanceDidUpdate () };
		}
	}
	
	internal var titleStyle: TitleStyle {
		get { return self.appearanceStorage.titleStyle }
		set {
			self.appearanceStorage.titleStyle = newValue;
			self.updateManagedMonthViews { $0.titleAppearanceDidUpdate () };
		}
	}
	
	internal var titleMargins: UIEdgeInsets {
		get { return self.appearanceStorage.titleMargins }
		set {
			self.appearanceStorage.titleMargins = newValue;
			self.updateManagedMonthViews { $0.titleMarginsDidUpdate () };
		}
	}
	
	internal var dayCellFont: UIFont {
		get { return self.appearanceStorage.dayCellFont }
		set {
			self.appearanceStorage.dayCellFont = newValue;
			self.updateManagedMonthViews { $0.dayCellFontDidUpdate () };
		}
	}
	
	internal var separatorColor: UIColor {
		get { return self.appearanceStorage.separatorColor }
		set {
			self.appearanceStorage.separatorColor = newValue;
			self.updateManagedMonthViews { $0.gridAppearanceDidUpdate () };
		}
	}
	
	internal var cellRenderer: CellRenderer {
		get { return self.appearanceStorage.cellRenderer }
		set {
			self.appearanceStorage.cellRenderer = newValue;
			self.updateManagedMonthViews { $0.gridAppearanceDidUpdate () };
		}
	}
	
	internal func dayCellTextColor (for state: DayCellState) -> UIColor? {
		return self.appearanceStorage.cellTextColors [state];
	}
	
	internal func setDayCellTextColor (_ textColor: UIColor?, for state: DayCellState) {
		self.appearanceStorage.cellTextColors [state] = textColor;
		self.updateManagedMonthViews { $0.gridAppearanceDidUpdate (for: state) };
	}

	internal func dayCellBackgroundColor (for state: DayCellState) -> UIColor? {
		return self.appearanceStorage.cellBackgroundColors [state];
	}
	
	internal func setDayCellBackgroundColor(_ backgroundColor: UIColor?, for state: DayCellState) {
		self.appearanceStorage.cellBackgroundColors [state] = backgroundColor;
		self.updateManagedMonthViews { $0.gridAppearanceDidUpdate (for: state) };
	}
}

internal extension CPCMonthViewsManager {
	private struct MonthViewHandler: CPCViewSelectionHandlerProtocol {
		fileprivate let selection: Selection;
		fileprivate unowned let monthView: CPCMonthView;
		
		private unowned let parent: CPCMonthViewsManager;
		
		fileprivate init (_ parent: CPCMonthViewsManager, for monthView: CPCMonthView) {
			self.parent = parent;
			self.monthView = monthView;
			self.selection = monthView.month.map { parent.selection.clamped (to: $0) } ?? .none;
		}
		
		fileprivate func clearingSelection () -> MonthViewHandler {
			return self;
		}
		
		fileprivate func handleTap (day: CPCDay) -> CPCViewSelectionHandlerProtocol? {
			return self.parent.selectionHandler (self, handleTapOn: day);
		}
	}
	
	internal var selection: CPCViewSelection {
		get { return self.multiSelectionHandler.selection }
		set { self.multiSelectionHandler = CPCViewSelectionHandler.primitive (for: newValue) }
	}
	
	internal var selectionHandler: CPCViewSelectionHandlerProtocol {
		get { return self.multiSelectionHandler }
		set { self.setMultiSelectionHandler (newValue) }
	}
	
	fileprivate func selectionHandler (for monthView: CPCMonthView) -> CPCViewSelectionHandlerProtocol {
		return MonthViewHandler (self, for: monthView);
	}
	
	fileprivate func setMultiSelectionHandler (_ multiSelectionHandler: CPCViewSelectionHandlerProtocol, sender: CPCMonthView? = nil) {
		self.multiSelectionHandler = multiSelectionHandler;
		for monthView in self.unownedMonthViews where monthView !== sender {
			monthView.selectionHandler = self.selectionHandler (for: monthView);
		}
	}
	
	private func selectionHandler (_ handler: MonthViewHandler, handleTapOn day: CPCDay) -> CPCViewSelectionHandlerProtocol? {
		guard let newHandler = self.multiSelectionHandler.handleTap (day: day) else {
			return nil;
		}
		let monthView = handler.monthView;
		self.setMultiSelectionHandler (newHandler, sender: monthView);
		return self.selectionHandler (for: monthView);
	}
}

fileprivate extension RangeReplaceableCollection {
	fileprivate mutating func remove (where predicate: (Element) throws -> Bool) rethrows -> Element? {
		return try self.index (where: predicate).map { self.remove (at: $0) };
	}
}
