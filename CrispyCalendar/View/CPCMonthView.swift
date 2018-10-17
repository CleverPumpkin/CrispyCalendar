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
			guard self.month != oldValue else {
				return;
			}
			self.needsFullAppearanceUpdate = true;
			self.monthDidChange ();
		}
	}
	
	open var enabledRegion: CountableRange <CPCDay>? {
		didSet {
			self.setNeedsFullAppearanceUpdate ();
		}
	}
	
	@IBInspectable open dynamic var titleFont: UIFont {
		get {
			return self.appearanceStorage.titleFont;
		}
		set {
			self.appearanceStorage.titleFont = newValue;
			self.effectiveTitleFont = self.scaledFont (self.titleFont, using: CPCMonthView.titleMetrics);
		}
	}
	@IBInspectable open dynamic var titleColor: UIColor {
		get {
			return self.appearanceStorage.titleColor;
		}
		set {
			self.appearanceStorage.titleColor = newValue;
			self.setNeedsDisplay (self.layout?.titleFrame ?? self.bounds);
		}
	}
	@IBInspectable open dynamic var titleAlignment: NSTextAlignment {
		get {
			return self.appearanceStorage.titleAlignment;
		}
		set {
			guard (self.titleAlignment != newValue) else {
				return;
			}
			self.appearanceStorage.titleAlignment = newValue;
			self.setNeedsDisplay (self.layout?.titleFrame ?? self.bounds);
		}
	}
	open var titleStyle: TitleStyle {
		get {
			return self.appearanceStorage.titleStyle;
		}
		set {
			guard !self.isAppearanceProxy else {
				return self.titleFormat = newValue.rawValue;
			}
			self.appearanceStorage.titleStyle = newValue;
			self.setNeedsDisplay (self.layout?.titleFrame ?? self.bounds);
		}
	}
	@IBInspectable open dynamic var titleMargins: UIEdgeInsets {
		get {
			return self.appearanceStorage.titleMargins;
		}
		set {
			self.appearanceStorage.titleMargins = newValue;
			self.effectiveTitleMargins = self.scaledInsets (self.titleMargins, using: CPCMonthView.titleMetrics);
		}
	}
	
	@IBInspectable open dynamic var dayCellFont: UIFont {
		get {
			return self.appearanceStorage.dayCellFont;
		}
		set {
			self.appearanceStorage.dayCellFont = newValue;
			self.effectiveDayCellFont = self.scaledFont (self.dayCellFont, using: CPCMonthView.dayCellTextMetrics);
		}
	}
	@IBInspectable open dynamic var dayCellTextColor: UIColor {
		get {
			return self.appearanceStorage.dayCellTextColor;
		}
		set {
			self.appearanceStorage.dayCellTextColor = newValue;
			self.setNeedsDisplay (self.layout?.gridFrame ?? self.bounds);
		}
	}
	@IBInspectable open dynamic var separatorColor: UIColor {
		get {
			return self.appearanceStorage.separatorColor;
		}
		set {
			self.appearanceStorage.separatorColor = newValue;
			self.setNeedsDisplay (self.layout?.gridFrame ?? self.bounds);
		}
	}
	
	open var cellRenderer: CPCDayCellRenderer {
		get {
			return self.appearanceStorage.cellRenderer;
		}
		set {
			self.appearanceStorage.cellRenderer = newValue;
			self.setNeedsDisplay (self.layout?.gridFrame ?? self.bounds);
		}
	}
	
	open var selectionDelegate: SelectionDelegateType? {
		get {
			return (self.selectionHandler as? CPCViewDelegatingSelectionHandler)?.delegate as? SelectionDelegateType;
		}
		set {
			if let newValue = newValue {
				let selectionHandler = CPCViewDelegatingSelectionHandler (self);
				selectionHandler.delegate = newValue as AnyObject;
				self.selectionHandler = selectionHandler;
			} else {
				self.selectionHandler = CPCViewSelectionHandler.primitive (for: self.selection);
			}
		}
	}
	
	internal var layout: Layout? {
		if let info = self.layoutStorage, info.isValid (for: self) {
			return info;
		}
		
		self.layoutStorage = Layout (view: self);
		return self.layoutStorage;
	}

	internal var selectionHandler = CPCViewDefaultSelectionHandler {
		didSet {
			self.selectionDidChange (oldValue: oldValue.selection);
		}
	}
	
	internal var effectiveTitleFont: UIFont {
		didSet {
			guard (oldValue.lineHeight != self.effectiveTitleFont.lineHeight) else {
				return self.setNeedsFullAppearanceUpdate ();
			}
			self.setNeedsDisplay (self.layout?.titleFrame ?? self.bounds);
		}
	}
	internal var effectiveTitleMargins: UIEdgeInsets {
		didSet {
			guard (oldValue.top + oldValue.bottom) == (self.effectiveTitleMargins.top + self.effectiveTitleMargins.bottom) else {
				return self.setNeedsFullAppearanceUpdate ();
			}
			self.setNeedsDisplay (self.layout?.titleFrame ?? self.bounds);
		}
	}
	internal var effectiveDayCellFont: UIFont {
		didSet {
			self.setNeedsDisplay (self.layout?.gridFrame ?? self.bounds);
		}
	}
	
	internal var contentSizeCategoryObserver: NSObjectProtocol?;
	internal var appearanceStorage = AppearanceStorage () {
		didSet {
			self.setNeedsFullAppearanceUpdate ();
		}
	}
	internal var monthViewsManager: CPCMonthViewsManager? {
		get {
			return self.monthViewsManagerPtr?.pointee;
		}
		set {
			self.monthViewsManagerPtr = UnsafePointer (to: newValue);
		}
	};
	internal var highlightedDayIndex: CellIndex? {
		didSet {
			self.highlightedDayIndexDidChange (oldValue: oldValue);
		}
	}
	internal var needsFullAppearanceUpdate = true;
	
	private var layoutStorage: Layout?;
	private unowned var aspectRatioConstraint: NSLayoutConstraint;
	private var monthViewsManagerPtr: UnsafePointer <CPCMonthViewsManager>?;
	
	public override init (frame: CGRect) {
		self.aspectRatioConstraint = .placeholder;
		(self.effectiveTitleFont, self.effectiveTitleMargins, self.effectiveDayCellFont) = self.appearanceStorage.monthViewInitializationValues;
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
		(self.effectiveTitleFont, self.effectiveTitleMargins, self.effectiveDayCellFont) = self.appearanceStorage.monthViewInitializationValues;
		super.init (coder: aDecoder);
		self.commonInit ();
	}

	private func commonInit () {
		self.contentMode = .redraw;
		self.isOpaque = false;
		self.clearsContextBeforeDrawing = false;
	}
	
	deinit {
		self.removeFromMultiMonthViewsManager ();
		if let contentSizeCategoryObserver = self.contentSizeCategoryObserver {
			NotificationCenter.default.removeObserver (contentSizeCategoryObserver);
		}
	}
	
	@objc dynamic internal func dayCellBackgroundColor (for backgroundStateValue: Int, isTodayValue: Int) -> UIColor? {
		return self.dayCellBackgroundColorImpl (backgroundStateValue, isTodayValue);
	}
	
	open func dayCellBackgroundColor (for state: DayCellState) -> UIColor? {
		guard !self.isAppearanceProxy else {
			let (backgroundStateValue, isTodayValue) = state.appearanceValues;
			return self.dayCellBackgroundColor (for: backgroundStateValue, isTodayValue: isTodayValue);
		}
		return self.appearanceStorage.cellBackgroundColors [state];
	}
	
	@objc dynamic internal func setDayCellBackgroundColor (_ backgroundColor: UIColor?, for backgroundStateValue: Int, isTodayValue: Int) {
		return self.setDayCellBackgroundColorImpl (backgroundColor, backgroundStateValue, isTodayValue);
	}
	
	open func setDayCellBackgroundColor (_ backgroundColor: UIColor?, for state: DayCellState) {
		guard !self.isAppearanceProxy else {
			let (backgroundStateValue, isTodayValue) = state.appearanceValues;
			return self.setDayCellBackgroundColor (backgroundColor, for: backgroundStateValue, isTodayValue: isTodayValue);
		}
		self.appearanceStorage.cellBackgroundColors [state] = backgroundColor;
		
		switch (state.backgroundState) {
		case .highlighted:
			guard let highlightedIdx = self.highlightedDayIndex, let layout = self.layout else {
				return;
			}
			self.setNeedsDisplay (layout.cellFrames [highlightedIdx]);
		default:
			self.setNeedsDisplay ();
		}
	}

	open override func setContentCompressionResistancePriority (_ priority: UILayoutPriority, for axis: NSLayoutConstraint.Axis) {
		super.setContentCompressionResistancePriority (priority, for: .horizontal);
		super.setContentCompressionResistancePriority (priority, for: .vertical);
		self.setNeedsUpdateConstraints ();
		self.setNeedsLayout ();
	}
	
	open override func updateConstraints () {
		self.aspectRatioConstraint.isActive = false;
		self.aspectRatioConstraint = self.layoutAttributes.map { self.aspectRatioLayoutConstraint (for: $0) } ?? self.heightAnchor.constraint (equalToConstant: 0.0);
		self.aspectRatioConstraint.isActive = true;
		
		super.updateConstraints ();
	}
	
	open override func sizeThatFits (_ size: CGSize) -> CGSize {
		guard let attributes = self.layoutAttributes else {
			return .zero;
		}
		return self.sizeThatFits (size, attributes: attributes);
	}
	
	public func setDefaultCellRendeder () {
		self.cellRenderer = CPCDefaultDayCellRenderer ();
	}

	open override func draw (_ rect: CGRect) {
		super.draw (rect);
		
		self.clearingContext (rect)?.run ();
		self.titleRedrawContext (rect)?.run ();
		self.gridRedrawContext (rect)?.run ();
		self.needsFullAppearanceUpdate = false;
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
		if let updatedHandler = self.selectionHandler.handleTap (day: month [ordinal: touchUpCellIndex.row] [ordinal: touchUpCellIndex.column]) {
			self.selectionHandler = updatedHandler;
			self.selectionDidChange (oldValue: oldSelection);
			self.sendActions (for: .valueChanged);
		}
	}
	
	open override func cancelTracking (with event: UIEvent?) {
		self.highlightedDayIndex = nil;
	}
	
	internal func removeFromMultiMonthViewsManager () {
		self.monthViewsManager?.removeMonthView (self);
	}
	
	private func gridCellIndex (for touch: UITouch?) -> CellIndex? {
		guard
			let layout = self.layout,
			let firstIndex = layout.cellFrames.indices.first,
			let point = touch?.location (in: self),
			let index = layout.cellIndex (at: point),
			layout.cellFrames.indices.contains (index),
			let month = self.month else {
			return nil;
		}
		
		let firstDay = month [ordinal: firstIndex.row] [ordinal: firstIndex.column];
		if let enabledRegion = self.enabledRegion, !enabledRegion.contains (firstDay.advanced (by: firstIndex.distance (to: index))) {
			return nil;
		} else {
			return index;
		}
	}
}

extension CPCMonthView: CPCViewContentAdjusting {
	private static let titleMetrics = CPCFontMetrics.metrics (for: .headline);
	private static let dayCellTextMetrics = CPCFontMetrics.metrics (for: .body);
	
	open var adjustsFontForContentSizeCategory: Bool {
		get { return self.adjustsFontForContentSizeCategoryValue }
		set { self.adjustsFontForContentSizeCategoryValue = newValue }
	}

	internal func adjustValues (for newCategory: UIContentSizeCategory) {
		self.effectiveTitleFont = self.scaledFont (self.titleFont, using: CPCMonthView.titleMetrics, for: newCategory);
		self.effectiveTitleMargins = self.scaledInsets (self.titleMargins, using: CPCMonthView.titleMetrics, for: newCategory);
		self.effectiveDayCellFont = self.scaledFont (self.dayCellFont, using: CPCMonthView.dayCellTextMetrics, for: newCategory);
	}
}

extension CPCMonthView: CPCViewBackedByAppearanceStorage {}

extension CPCMonthView: CPCViewDelegatingSelectionHandling {
	public typealias SelectionDelegateType = CPCMonthViewSelectionDelegate;
	
	open var selection: CPCViewSelection {
		get { return self.selectionHandler.selection }
		set { self.setSelection (newValue) }
	}

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

extension CPCMonthView: CPCFixedAspectRatioView {
	public struct LayoutAttributes: CPCViewLayoutAttributes {
		fileprivate let month: CPCMonth;
		fileprivate let titleHeight: CGFloat;
		fileprivate let separatorWidth: CGFloat;
		
		public var roundingScale: CGFloat {
			return self.separatorWidth;
		}
		
		public init? (_ view: CPCMonthView) {
			guard let month = view.month, !month.isEmpty else {
				return nil;
			}

			self.init (month: month, separatorWidth: view.separatorWidth, titleFont: view.effectiveTitleFont, titleMargins: view.effectiveTitleMargins);
		}

		public init (month: CPCMonth, separatorWidth: CGFloat, titleFont: UIFont, titleMargins: UIEdgeInsets) {
			self.month = month;
			self.separatorWidth = separatorWidth;
			self.titleHeight = (titleFont.lineHeight.rounded (.up, scale: separatorWidth) + titleMargins.top + titleMargins.bottom).rounded (.up, scale: separatorWidth);
		}
	};
	
	open var layoutAttributes: LayoutAttributes? {
		return LayoutAttributes (self);
	}
	
	open class func aspectRatioComponents (for attributes: LayoutAttributes) -> (multiplier: CGFloat, constant: CGFloat)? {
		/// | gridH = rowN * cellSize + (rowN + 1) * sepW       | gridH = rowN * (cellSize + sepW) + sepW       | gridH - sepW = rowN * (cellSize + sepW)
		/// {                                               <=> {                                           <=> {                                          <=>
		/// | gridW = colN * cellSize + (colsN - 1) * sepW      | gridW = colN * (cellSize + colsN) - sepW      | gridW + sepW = colN * (cellSize + colsN)
		///
		/// <=> (gridH - sepW) / (gridW + sepW) = rowN / colN
		/// let R = rowN / colN, then (gridH - sepW) / (gridW + sepW) = R <=> gridH - sepW = gridW * R + sepW * R <=> gridH = gridW * R + (sepW + 1) * R
		/// View width is equal to grid width; view height = gridW + titleHeight.
		let month = attributes.month, aspectRatio = CGFloat (month.count) / CGFloat (month [0].count);
		return (multiplier: aspectRatio, constant: (attributes.separatorWidth + 1.0) * aspectRatio + attributes.titleHeight);
	}
}

extension CPCMonthView {
	private func setNeedsFullAppearanceUpdate () {
		self.needsFullAppearanceUpdate = true;
		self.setNeedsUpdateConstraints ();
		self.setNeedsLayout ();
		self.setNeedsDisplay ();
	}
	
	private func monthDidChange () {
		self.highlightedDayIndex = nil;
		self.enabledRegion = nil;
		self.selectionHandler = self.selectionHandler.clearingSelection ();
		self.setNeedsFullAppearanceUpdate ();
	}
	
	private func highlightedDayIndexDidChange (oldValue: CellIndex?) {
		guard oldValue != self.highlightedDayIndex else {
			return;
		}
		
		if let oldValue = oldValue, let oldValueFrame = self.layout?.cellFrames [oldValue] {
			self.setNeedsDisplay (oldValueFrame);
		}
		if let newValue = self.highlightedDayIndex, let newValueFrame = self.layout?.cellFrames [newValue] {
			self.setNeedsDisplay (newValueFrame);
		}
	}
	
	private func selectionDidChange (oldValue: Selection) {
		guard let layout = self.layout, let month = self.month, let firstDayIndex = layout.cellFrames.indices.first else {
			return;
		}
		
		let firstDay = month [ordinal: firstDayIndex.row] [ordinal: firstDayIndex.column], selectionDiff = self.selection.difference (oldValue);
		guard !selectionDiff.isEmpty else {
			return;
		}
		
		for day in selectionDiff {
			self.setNeedsDisplay (layout.cellFrames [firstDayIndex.advanced (by: firstDay.distance (to: day))]);
		}
	}
}

fileprivate extension CPCViewAppearanceStorage {
	fileprivate var monthViewInitializationValues: (UIFont, UIEdgeInsets, UIFont) {
		return (self.titleFont, self.titleMargins, self.dayCellFont);
	}
}
