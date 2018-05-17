//
//  CPCMonthView.swift
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

fileprivate extension NSLayoutConstraint {
	fileprivate static let placeholder = UIView ().widthAnchor.constraint (equalToConstant: 0.0);
}

fileprivate extension CGSize {
	fileprivate enum Constraint {
		case none;
		case width (CGFloat);
		case height (CGFloat);
		case full (width: CGFloat, height: CGFloat);
	}
	
	private static let unconstrainedDimensionValues: Set <CGFloat> = [
		CGFloat (Float.greatestFiniteMagnitude),
		CGFloat (Double.greatestFiniteMagnitude),
		CGFloat.greatestFiniteMagnitude,
		CGFloat (Int.max),
		CGFloat (UInt.max),
		CGFloat (Int32.max),
		CGFloat (UInt32.max),
		UIViewNoIntrinsicMetric,
		UITableViewAutomaticDimension,
		0.0,
	];
	private static let saneAspectRatiosRange = CGFloat (1e-3) ... CGFloat (1e3);
	
	private static func isDimensionConstrained (_ value: CGFloat, relativeTo other: CGFloat) -> Bool {
		return (value.isFinite && !CGSize.unconstrainedDimensionValues.contains (value) && CGSize.saneAspectRatiosRange.contains (value / other));
	}
	
	fileprivate var constraint: Constraint {
		let width = self.width, height = self.height;
		if (CGSize.isDimensionConstrained (width, relativeTo: height)) {
			if (CGSize.isDimensionConstrained (height, relativeTo: width)) {
				return .full (width: width, height: height);
			} else {
				return .width (width);
			}
		} else {
			if (CGSize.isDimensionConstrained (height, relativeTo: width)) {
				return .height (height);
			} else {
				return .none;
			}
		}
	}
}

public protocol CPCMonthViewSelectionDelegate: AnyObject {
	var selection: CPCViewSelection { get set };
	
	func monthViewDidClearSelection (_ monthView: CPCMonthView);
	func monthView (_ monthView: CPCMonthView, shouldSelect day: CPCDay) -> Bool;
	func monthView (_ monthView: CPCMonthView, shouldDeselect day: CPCDay) -> Bool;
}

open class CPCMonthView: UIControl, CPCViewProtocol {
	private typealias CPCViewSelectionHandlerObject = AnyObject & CPCViewSelectionHandlerProtocol;
	
	open class override var requiresConstraintBasedLayout: Bool {
		return true;
	}
	
	open var month: CPCMonth? {
		didSet {
			self.monthDidChange ();
		}
	}
	
	@IBInspectable open var font = CPCMonthView.defaultFont;
	@IBInspectable open var titleColor = CPCMonthView.defaultTitleColor;
	@IBInspectable open var separatorColor = CPCMonthView.defaultSeparatorColor;
	
	internal var selectionHandler = CPCViewDefaultSelectionHandler {
		didSet {
			self.selectionDidChange (oldValue: oldValue.selection);
		}
	}
	
	internal var gridLayoutInfo: GridLayoutInfo? {
		if let info = self.gridLayoutInfoStorage, info.isValid (for: self) {
			return info;
		}
		
		self.gridLayoutInfoStorage = GridLayoutInfo (view: self);
		return self.gridLayoutInfoStorage;
	}
	private var gridLayoutInfoStorage: GridLayoutInfo?;

	internal var highlightedDayIndex: CellIndex? {
		didSet {
			self.highlightedDayIndexDidChange (oldValue: oldValue);
		}
	}
	
	internal var cellBackgroundColors = DayCellStateBackgroundColors ();
	
	private unowned var aspectRatioConstraint: NSLayoutConstraint;
	
	/// Computes coefficients of equation ViewHeight = K x ViewWidth + C to maintain square-ish day cells
	///
	/// - Parameter month: Month to perform calculations for.
	/// - Parameter separatorWidth: Intercell separators width/height.
	/// - Returns: multiplier K and constant C.
	open class func aspectRatioComponents (for month: CPCMonth?, separatorWidth: CGFloat) -> (multiplier: CGFloat, constant: CGFloat)? {
		guard let month = month, !month.isEmpty else {
			return nil;
		}
		
		/// | height = rowN * cellSize + (rowN + 1) * sepW      | height = rowN * (cellSize + sepW) + sepW      | height - sepW = rowN * (cellSize + sepW)
		/// {                                               <=> {                                           <=> {                                          <=>
		/// | width = colN * cellSize + (colsN - 1) * sepW      | width = colN * (cellSize + colsN) - sepW      | width + sepW = colN * (cellSize + colsN)
		///
		/// <=> (height - sepW) / (width + sepW) = rowN / colN
		/// let R = rowN / colN, then (height - sepW) / (width + sepW) = R <=> height - sepW = width * R + sepW * R <=> height = width * R + (sepW + 1) * R
		let aspectRatio = CGFloat (month.count) / CGFloat ( month [0].count);
		return (multiplier: aspectRatio, constant: (separatorWidth + 1.0) * aspectRatio);
	}
		
	open class func sizeThatFits (_ size: CGSize, for month: CPCMonth?, with separatorWidth: CGFloat) -> CGSize {
		guard let (multiplier, constant) = self.aspectRatioComponents (for: month, separatorWidth: separatorWidth) else {
			return size;
		}
		
		let fittingWidth: CGFloat;
		switch (size.constraint) {
		case .none:
			fittingWidth = UIScreen.main.bounds.width;
		case .width (let width), .full (let width, _):
			fittingWidth = width;
		case let .height (height):
			return CGSize (width: ((height - constant) / multiplier).rounded (scale: separatorWidth), height: height.rounded (scale: separatorWidth));
		}
		
		return CGSize (width: fittingWidth.rounded (scale: separatorWidth), height: (fittingWidth * multiplier + constant).rounded (scale: separatorWidth));
	}
	
	public override init (frame: CGRect) {
		self.aspectRatioConstraint = .placeholder;
		super.init (frame: frame);
		self.commonInit ();
	}
	
	public convenience init (frame: CGRect, month: CPCMonth?) {
		self.init (frame: frame);
		
		if let month = month {
			self.month = month;
			self.monthDidChange ();
		}
	}
	
	public required init? (coder aDecoder: NSCoder) {
		self.aspectRatioConstraint = .placeholder;
		super.init (coder: aDecoder);
		self.commonInit ();
	}

	private func commonInit () {
		self.contentMode = .redraw;
		self.isOpaque = false;
		self.clearsContextBeforeDrawing = false;
	}

	open override func setContentCompressionResistancePriority (_ priority: UILayoutPriority, for axis: UILayoutConstraintAxis) {
		super.setContentCompressionResistancePriority (priority, for: .horizontal);
		super.setContentCompressionResistancePriority (priority, for: .vertical);
		self.setNeedsUpdateConstraints ();
		self.setNeedsLayout ();
	}
	
	open override func updateConstraints () {
		self.aspectRatioConstraint.isActive = false;
		
		let aspectRatioConstraint: NSLayoutConstraint;
		if let (multiplier, constant) = type (of: self).aspectRatioComponents (for: self.month, separatorWidth: self.separatorWidth) {
			aspectRatioConstraint = self.heightAnchor.constraint (equalTo: self.widthAnchor, multiplier: multiplier, constant: constant);
		} else {
			aspectRatioConstraint = self.heightAnchor.constraint (equalToConstant: 0.0);
		}
		aspectRatioConstraint.priority = self.contentCompressionResistancePriority (for: .vertical);
		aspectRatioConstraint.isActive = true;
		self.aspectRatioConstraint = aspectRatioConstraint;
		
		super.updateConstraints ();
	}
	
	open override func sizeThatFits (_ size: CGSize) -> CGSize {
		return type (of: self).sizeThatFits (size, for: self.month, with: self.separatorWidth);
	}

	open override func draw (_ rect: CGRect) {
		super.draw (rect);
		RedrawContext (redrawing: rect, in: self)?.run ();
	}
	
	open override func beginTracking (_ touch: UITouch, with event: UIEvent?) -> Bool {
		guard super.beginTracking (touch, with: event) else {
			return false;
		}
		self.highlightedDayIndex = self.gridCellIndex (for: touch);
		return true;
	}
	
	open override func continueTracking (_ touch: UITouch, with event: UIEvent?) -> Bool {
		guard super.continueTracking (touch, with: event) else {
			return false;
		}
		self.highlightedDayIndex = self.gridCellIndex (for: touch);
		return true;
	}
	
	open override func endTracking (_ touch: UITouch?, with event: UIEvent?) {
		self.highlightedDayIndex = nil;
		guard let touch = touch, let month = self.month, let touchUpCellIndex = self.gridCellIndex (for: touch) else {
			return;
		}
		
		let oldSelection = self.selectionHandler.selection;
		if let updatedhandler = self.selectionHandler.handleTap (day: month [ordinal: touchUpCellIndex.row] [ordinal: touchUpCellIndex.column]) {
			self.selectionHandler = updatedhandler;
			self.selectionDidChange (oldValue: oldSelection);
		}
	}
	
	open override func cancelTracking (with event: UIEvent?) {
		self.highlightedDayIndex = nil;
	}
	
	private func gridCellIndex (for touch: UITouch?) -> CellIndex? {
		guard
			let layoutInfo = self.gridLayoutInfo,
			let point = touch?.location (in: self),
			let index = layoutInfo.cellIndex (at: point),
			layoutInfo.cellFrames.indices.contains (index) else {
			return nil;
		}
		
		return index;
	}
}

extension CPCMonthView: CPCViewDelegatingSelectionHandling {
	public typealias SelectionDelegateType = CPCMonthViewSelectionDelegate;

	internal func selectionValue (of delegate: SelectionDelegateType) -> Selection {
		return delegate.selection;
	}
	
	internal func setSelectionValue (_ selection: Selection, in delegate: SelectionDelegateType) {
		delegate.selection = selection;
	}
	
	internal func resetSelection (in delegate: SelectionDelegateType) {
		delegate.monthViewDidClearSelection (self);
	}
	
	internal func handlerShouldSelectDayCell (_ day: CPCDay, delegate: SelectionDelegateType) -> Bool {
		return delegate.monthView (self, shouldSelect: day);
	}
	
	internal func handlerShouldDeselectDayCell (_ day: CPCDay, delegate: SelectionDelegateType) -> Bool {
		return delegate.monthView (self, shouldDeselect: day);
	}
}

extension CPCMonthView {
	private func monthDidChange () {
		self.highlightedDayIndex = nil;
		self.selectionHandler = self.selectionHandler.clearingSelection ();
		self.setNeedsUpdateConstraints ();
		self.setNeedsDisplay ();
	}
	
	private func highlightedDayIndexDidChange (oldValue: CellIndex?) {
		guard oldValue != self.highlightedDayIndex else {
			return;
		}
		
		if let oldValue = oldValue, let oldValueFrame = self.gridLayoutInfo?.cellFrames [oldValue] {
			self.setNeedsDisplay (oldValueFrame);
		}
		if let newValue = self.highlightedDayIndex, let newValueFrame = self.gridLayoutInfo?.cellFrames [newValue] {
			self.setNeedsDisplay (newValueFrame);
		}
	}
	
	private func selectionDidChange (oldValue: Selection) {
		guard let layoutInfo = self.gridLayoutInfo, let month = self.month, let firstDayIndex = layoutInfo.cellFrames.indices.first else {
			return;
		}
		
		let firstDay = month [ordinal: firstDayIndex.row] [ordinal: firstDayIndex.column], selectionDiff = self.selection.difference (oldValue);
		guard !selectionDiff.isEmpty else {
			return;
		}
		
		for day in selectionDiff {
			self.setNeedsDisplay (layoutInfo.cellFrames [firstDayIndex.advanced (by: firstDay.distance (to: day))]);
		}
	}
}

extension CPCMonthView {
	open func dayCellBackgroundColor (for state: DayCellState) -> UIColor? {
		return self.cellBackgroundColors.color (for: state);
	}
	
	open func setDayCellBackgroundColor (_ backgroundColor: UIColor?, for state: DayCellState) {
		self.cellBackgroundColors.setColor (backgroundColor, for: state);
		
		switch (state.backgroundState) {
		case .highlighted:
			guard let highlightedIdx = self.highlightedDayIndex, let layoutInfo = self.gridLayoutInfo else {
				return;
			}
			self.setNeedsDisplay (layoutInfo.cellFrames [highlightedIdx]);
		default:
			self.setNeedsDisplay ();
		}
	}
}
