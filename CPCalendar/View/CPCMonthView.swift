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

public protocol CPCMonthViewSelectionDelegate: AnyObject {
	var selection: CPCMonthView.Selection { get set };
	
	func monthViewDidResetSelection (_ monthView: CPCMonthView);
	func monthView (_ monthView: CPCMonthView, select day: CPCDay) -> Bool;
	func monthView (_ monthView: CPCMonthView, deselect day: CPCDay) -> Bool;
}

public extension CPCMonthView {
	public typealias SelectionDelegate = CPCMonthViewSelectionDelegate;
	
	public enum Selection: Equatable {
		case none;
		case single (CPCDay?);
		case range (CountableRange <CPCDay>);
		case unordered (Set <CPCDay>);
		case ordered ([CPCDay]);
	}

	public struct DayCellState: Hashable {
		public enum BackgroundState: Int {
			case normal;
			case highlighted;
			case selected;
		}
		
		public let backgroundState: BackgroundState;
		public let isToday: Bool;


		public init (backgroundState: BackgroundState = .normal, isToday: Bool = false) {
			self.backgroundState = backgroundState;
			self.isToday = isToday;
		}
	}
}

public extension CPCMonthView.Selection {
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
	
	public func difference (_ other: CPCMonthView.Selection) -> Set <CPCDay> {
		return self.selectedDays.symmetricDifference (other.selectedDays);
	}
}

public extension CPCMonthView.DayCellState {
	public static let normal = CPCMonthView.DayCellState ();
	public static let highlighted = CPCMonthView.DayCellState (backgroundState: .highlighted);
	public static let selected = CPCMonthView.DayCellState (backgroundState: .selected);
	public static let today = CPCMonthView.DayCellState (isToday: true);
}

open class CPCMonthView: UIControl {
	internal typealias SelectionHandler = CPCMonthViewSelectionHandler;
	
	open class override var requiresConstraintBasedLayout: Bool {
		return true;
	}
	
	open var month: CPCMonth? {
		didSet {
			self.monthDidChange ();
		}
	}
	
	@IBInspectable open var font: UIFont = .systemFont (ofSize: UIFont.systemFontSize);
	@IBInspectable open var titleColor = UIColor.darkText;
	@IBInspectable open var separatorColor = UIColor.gray;
	
	internal var selectionHandler = CPCMonthView.defaultSelectionHandler {
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
	
	internal var dayCellBackgroundColors: [DayCellState: UIColor] = [
		.normal: .white,
		.highlighted: UIColor.yellow.withAlphaComponent (0.125),
		.selected: UIColor.yellow.withAlphaComponent (0.25),
		.today: .lightGray,
	];
	
	private unowned var aspectRatioConstraint: NSLayoutConstraint;

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
		if self.aspectRatioConstraint != .placeholder {
			self.aspectRatioConstraint.isActive = false;
		}
		
		let aspectRatioConstraint: NSLayoutConstraint;
		if let layoutInfo = self.gridLayoutInfo {
			// | height = rowN * cellSize + (rowN + 1) * sepW      | height = rowN * (cellSize + sepW) + sepW      | height - sepW = rowN * (cellSize + sepW)
			// {                                               <=> {                                           <=> {                                          <=>
			// | width = colN * cellSize + (colsN - 1) * sepW      | width = colN * (cellSize + colsN) - sepW      | width + sepW = colN * (cellSize + colsN)
			//
			// <=> (height - sepW) / (width + sepW) = rowN / colN
			// let R = rowN / colN, then (height - sepW) / (width + sepW) = R <=> height - sepW = width * R + sepW * R <=> height = width * R + (sepW + 1) * R
			let cellIndices = layoutInfo.cellFrames.indices;
			let aspectRatio = CGFloat (cellIndices.rows.count) / CGFloat (cellIndices.columns.count);
			aspectRatioConstraint = self.heightAnchor.constraint (
				equalTo: self.widthAnchor,
				multiplier: aspectRatio,
				constant: (aspectRatio + 1.0) * layoutInfo.separatorWidth
			);
		} else {
			aspectRatioConstraint = self.heightAnchor.constraint (equalToConstant: 0.0);
		}
		aspectRatioConstraint.priority = self.contentCompressionResistancePriority (for: .vertical);
		aspectRatioConstraint.isActive = true;
		self.aspectRatioConstraint = aspectRatioConstraint;
		
		super.updateConstraints ();
	}

	open override func draw (_ rect: CGRect) {
		super.draw (rect);
		RedrawContext (redrawing: rect, in: self)?.run ();
	}
	
	open override func beginTracking (_ touch: UITouch, with event: UIEvent?) -> Bool {
		guard super.beginTracking (touch, with: event) else {
			return false;
		}
		self.highlightedDayIndex = self.gridLayoutInfo?.cellIndex (at: touch.location (in: self));
		return true;
	}
	
	open override func continueTracking (_ touch: UITouch, with event: UIEvent?) -> Bool {
		guard super.continueTracking (touch, with: event) else {
			return false;
		}
		self.highlightedDayIndex = self.gridLayoutInfo?.cellIndex (at: touch.location (in: self));
		return true;
	}
	
	open override func endTracking (_ touch: UITouch?, with event: UIEvent?) {
		self.highlightedDayIndex = nil;
		guard let touch = touch, let month = self.month, let touchUpCellIndex = self.gridLayoutInfo?.cellIndex (at: touch.location (in: self)) else {
			return;
		}
		
		let oldSelection = self.selectionHandler.selection;
		if (self.selectionHandler.dayCellTapped (month [ordinal: touchUpCellIndex.row] [ordinal: touchUpCellIndex.column])) {
			self.selectionDidChange (oldValue: oldSelection);
		}
	}
	
	open override func cancelTracking (with event: UIEvent?) {
		self.highlightedDayIndex = nil;
	}
}

extension CPCMonthView {
	private func monthDidChange () {
		self.highlightedDayIndex = nil;
		self.selectionHandler.clearSelection ();
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
		return self.dayCellBackgroundColors [state];
	}
	
	open func setDayCellBackgroundColor (_ backgroundColor: UIColor?, for state: DayCellState) {
		self.dayCellBackgroundColors [state] = backgroundColor;
		
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
