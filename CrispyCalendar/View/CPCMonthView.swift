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

/* fileprivate */ extension NSLayoutConstraint {
	fileprivate static let placeholder = UIView ().widthAnchor.constraint (equalToConstant: 0.0);
}

/// Use a selection delegate (a custom object that implements this protocol) to modify behavior
/// of a view when user interacts with it.
public protocol CPCMonthViewSelectionDelegate: AnyObject {
	/// Selected days associated with this view.
	var selection: CPCViewSelection { get set };
	
	/// This method is called after view selection is being reset programmatically (e. g. by changing represented month).
	///
	/// - Parameter monthView: View for which selection was reset.
	func monthViewDidClearSelection (_ monthView: CPCMonthView);
	
	/// Tells the delegate that a specific cell is about to be selected by user.
	///
	/// The delegate must updated stored `selection` value according to the desired selection scheme
	/// and return whether the resulting selection was somehow changed.
	///
	/// - Parameters:
	///   - monthView: View to handle user interaction for.
	///   - day: Day value rendered by the interacted cell.
	/// - Returns: `true` if user actions have lead to an updated selection value; otherwise, `false`.
	func monthView (_ monthView: CPCMonthView, shouldSelect day: CPCDay) -> Bool;
	
	/// Tells the delegate that a specific cell is about to be deselected by user.
	///
	/// The delegate must updated stored `selection` value according to the desired selection scheme
	/// and return whether the resulting selection was somehow changed.
	///
	/// - Parameters:
	///   - monthView: View to handle user interaction for.
	///   - day: Day value rendered by the interacted cell.
	/// - Returns: `true` if user actions have lead to an updated selection value; otherwise, `false`.
	func monthView (_ monthView: CPCMonthView, shouldDeselect day: CPCDay) -> Bool;
}

/// A view that is optimized for rendering a single month's days grid and a title.
open class CPCMonthView: UIControl, CPCViewProtocol {
	private typealias CPCViewSelectionHandlerObject = AnyObject & CPCViewSelectionHandlerProtocol;
	
	/// Month that is currently being rendered by this view.
	open var month: CPCMonth? {
		didSet {
			guard self.month != oldValue else {
				return;
			}
			self.monthDidChange ();
		}
	}
	
	/// Represents subset of the given month which should be rendered by the view.
	open var enabledRegion: CountableRange <CPCDay>? {
		didSet {
			if (oldValue != self.enabledRegion) {
				self.setNeedsFullAppearanceUpdate ();
			}
		}
	}
	
	@IBInspectable open dynamic var titleFont: UIFont {
		get { return self.effectiveAppearanceStorage.titleFont }
		set {
			self.appearanceStorage.titleFont = newValue;
			self.titleFontDidUpdate ();
		}
	}
	@IBInspectable open dynamic var titleColor: UIColor {
		get { return self.effectiveAppearanceStorage.titleColor }
		set {
			self.appearanceStorage.titleColor = newValue;
			self.titleAppearanceDidUpdate ();
		}
	}
	@IBInspectable open dynamic var titleAlignment: NSTextAlignment {
		get { return self.effectiveAppearanceStorage.titleAlignment }
		set {
			guard (self.titleAlignment != newValue) else {
				return;
			}
			self.appearanceStorage.titleAlignment = newValue;
			self.titleAppearanceDidUpdate ();
		}
	}
	open var titleStyle: TitleStyle {
		get { return self.effectiveAppearanceStorage.titleStyle }
		set {
			guard !self.isAppearanceProxy else {
				return self.titleFormat = newValue.rawValue;
			}
			self.appearanceStorage.titleStyle = newValue;
			self.titleAppearanceDidUpdate ();
		}
	}
	@IBInspectable open dynamic var titleMargins: UIEdgeInsets {
		get { return self.effectiveAppearanceStorage.titleMargins }
		set {
			self.appearanceStorage.titleMargins = newValue;
			self.titleMarginsDidUpdate ();
		}
	}
	
	@IBInspectable open dynamic var dayCellFont: UIFont {
		get { return self.effectiveAppearanceStorage.dayCellFont }
		set {
			self.appearanceStorage.dayCellFont = newValue;
			self.dayCellFontDidUpdate ();
		}
	}
	@IBInspectable open dynamic var separatorColor: UIColor {
		get { return self.effectiveAppearanceStorage.separatorColor }
		set {
			self.appearanceStorage.separatorColor = newValue;
			self.gridAppearanceDidUpdate ();
		}
	}
	
	@IBInspectable open dynamic var separatorWidth: CGFloat {
		get { return self.effectiveAppearanceStorage.separatorWidth }
		set {
			self.appearanceStorage.separatorWidth = newValue;
			self.gridAppearanceDidUpdate ();
		}
	}
	
	/// A boolean flag indicating whether view leading separator must be drawn.
	@IBInspectable open dynamic var drawsLeadingSeparator = false {
		didSet {
			if self.drawsTrailingSeparator != oldValue {
				self.gridAppearanceDidUpdate ();
			}
		}
	}
	
	/// A boolean flag indicating whether view trailing separator must be drawn.
	@IBInspectable open dynamic var drawsTrailingSeparator = false {
		didSet {
			if self.drawsTrailingSeparator != oldValue {
				self.gridAppearanceDidUpdate ();
			}
		}
	}
	
	open var cellRenderer: CPCDayCellRenderer {
		get { return self.effectiveAppearanceStorage.cellRenderer }
		set {
			self.appearanceStorage.cellRenderer = newValue;
			self.gridAppearanceDidUpdate ();
		}
	}
	
	/// The object that acts as the selection delegate of this view.
	open var selectionDelegate: CPCMonthViewSelectionDelegate? {
		get {
			return (self.selectionHandler as? CPCViewDelegatingSelectionHandler)?.delegate as? CPCMonthViewSelectionDelegate;
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
	
	internal let appearanceStorage = AppearanceStorage ();
	
	internal var isContentsFlippedHorizontally: Bool {
		return self.effectiveUserInterfaceLayoutDirection == .rightToLeft;
	}
	
	internal var effectiveAppearanceStorage: AppearanceStorage {
		return self.monthViewsManager?.appearanceStorage ?? self.appearanceStorage;
	}
	internal var monthViewsManager: CPCMonthViewsManager? {
		get { return self.monthViewsManagerPtr?.pointee }
		set {
			guard self.monthViewsManager !== newValue else {
				return;
			}
			self.monthViewsManagerPtr = UnsafePointer (to: newValue);
		}
	};
	internal var highlightedDayIndex: CellIndex? {
		didSet {
			self.highlightedDayIndexDidChange (oldValue: oldValue);
		}
	}
	internal var needsFullAppearanceUpdate = true;
	internal var contentSizeCategoryObserver: NSObjectProtocol?;
	internal var usesAspectRatioConstraint = true {
		didSet {
			self.setNeedsUpdateConstraints ();
		}
	}

	private var layoutStorage: Layout?;
	private unowned var aspectRatioConstraint: NSLayoutConstraint;
	private var monthViewsManagerPtr: UnsafePointer <CPCMonthViewsManager>? {
		didSet {
			self.titleFontDidUpdate ();
			self.titleMarginsDidUpdate ();
			self.dayCellFontDidUpdate ();
			self.setNeedsFullAppearanceUpdate ();
		}
	}
	
	public override init (frame: CGRect) {
		self.aspectRatioConstraint = .placeholder;
		(self.effectiveTitleFont, self.effectiveTitleMargins, self.effectiveDayCellFont) = self.appearanceStorage.monthViewInitializationValues;
		super.init (frame: frame);
		self.commonInit ();
	}
	
	/// Initializes and returns a newly allocated view object with the specified months to be rendered and frame rectangle.
	///
	/// - Parameters:
	///   - frame: Frame to be used by this view.
	///   - month: Month value to be rendered by the view.
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
	
	@objc (dayCellTextColorForState:)
	open dynamic func dayCellTextColor (for state: DayCellState) -> UIColor? {
		return self.effectiveAppearanceStorage.cellTextColors [state];
	}
	
	@objc (setDayCellTextColor:forState:)
	open dynamic func setDayCellTextColor (_ backgroundColor: UIColor?, for state: DayCellState) {
		self.appearanceStorage.cellTextColors [state] = backgroundColor;
		self.gridAppearanceDidUpdate (for: state);
	}

	@objc (dayCellBackgroundColorForState:)
	open dynamic func dayCellBackgroundColor (for state: DayCellState) -> UIColor? {
		return self.effectiveAppearanceStorage.cellBackgroundColors [state];
	}
	
	@objc (setDayCellBackgroundColor:forState:)
	open dynamic func setDayCellBackgroundColor (_ backgroundColor: UIColor?, for state: DayCellState) {
		self.appearanceStorage.cellBackgroundColors [state] = backgroundColor;
		self.gridAppearanceDidUpdate (for: state);
	}

	open override func setContentCompressionResistancePriority (_ priority: UILayoutPriority, for axis: NSLayoutConstraint.Axis) {
		super.setContentCompressionResistancePriority (priority, for: .horizontal);
		super.setContentCompressionResistancePriority (priority, for: .vertical);
		self.setNeedsUpdateConstraints ();
		self.setNeedsLayout ();
	}
	
	open override func updateConstraints () {
		self.aspectRatioConstraint.isActive = false;
		if (self.usesAspectRatioConstraint) {
			self.aspectRatioConstraint = self.layoutAttributes.map { self.aspectRatioLayoutConstraint (for: $0) } ?? self.heightAnchor.constraint (equalToConstant: 0.0);
			self.aspectRatioConstraint.isActive = true;
		} else {
			self.aspectRatioConstraint = .placeholder;
		}
		
		super.updateConstraints ();
	}
	
	open override func sizeThatFits (_ size: CGSize) -> CGSize {
		guard let attributes = self.layoutAttributes else {
			return .zero;
		}
		return self.sizeThatFits (size, attributes: attributes);
	}
	
	/// Discard a custom cell renderer that was set previously and use standard one supplied by the library.
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

extension CPCMonthView: CPCViewDelegatingSelectionHandling {
	/// See `selection`.
	@objc (selection)
	open var _objcBridgedSelection: __CPCViewSelection {
		get { return self.selection as __CPCViewSelection }
		set { self.selection = newValue as CPCViewSelection }
	}

	open var selection: CPCViewSelection {
		get { return self.selectionHandler.selection }
		set { self.setSelection (newValue) }
	}

	internal func selectionValue (of delegate: CPCMonthViewSelectionDelegate) -> Selection {
		return delegate.selection;
	}
	
	internal func setSelectionValue (_ selection: Selection, in delegate: CPCMonthViewSelectionDelegate) {
		delegate.selection = selection;
	}
	
	internal func resetSelection (in delegate: CPCMonthViewSelectionDelegate) {
		delegate.monthViewDidClearSelection (self);
	}
	
	internal func handlerShouldSelectDayCell (_ day: CPCDay, delegate: CPCMonthViewSelectionDelegate) -> Bool {
		return delegate.monthView (self, shouldSelect: day);
	}
	
	internal func handlerShouldDeselectDayCell (_ day: CPCDay, delegate: CPCMonthViewSelectionDelegate) -> Bool {
		return delegate.monthView (self, shouldDeselect: day);
	}
}

extension CPCMonthView: CPCFixedAspectRatioView {
	/// This type groups various non-calendric layout attributes into single structure.
	public struct PartialLayoutAttributes {
		fileprivate let titleHeight: CGFloat;
		fileprivate let scale: CGFloat;
		
		/// Initializes new non-calendric layout attributes instance.
		///
		/// - Parameters:
		///   - separatorWidth: Width of separator lines of the measured view. Typically is equal to `roundingScale`.
		///   - titleFont: Font that the measure view would use to render month title.
		///   - titleMargins: Additional month view title insets/outsets.
		public init (scale: CGFloat, titleFont: UIFont, titleMargins: UIEdgeInsets) {
			self.scale = scale;
			self.titleHeight = (titleFont.lineHeight.rounded (.up, scale: scale) + titleMargins.top + titleMargins.bottom).rounded (.up, scale: scale);
		}
	};

	public struct LayoutAttributes: CPCViewLayoutAttributes {
		public var roundingScale: CGFloat {
			return self.partialAttributes.scale;
		}
		
		fileprivate let weekLength: Int;
		fileprivate let weekCount: Int;
		
		fileprivate var titleHeight: CGFloat {
			return self.partialAttributes.titleHeight;
		}
		
		private let partialAttributes: PartialLayoutAttributes;

		/// Initializes layout attributes to match currently use values in the specified view.
		public init? (_ view: CPCMonthView) {
			guard let month = view.month, !month.isEmpty else {
				return nil;
			}

			self.init (month: month, scale: view.pixelSize, titleFont: view.effectiveTitleFont, titleMargins: view.effectiveTitleMargins);
		}

		/// Initializes layout attributes for a specific month view.
		///
		/// - Parameters:
		///   - month: Month to be rendered by the measured view.
		///   - separatorWidth: Width of separator lines of the measured view. Typically is equal to `roundingScale`.
		///   - titleFont: Font that the measure view would use to render month title.
		///   - titleMargins: Additional month view title insets/outsets.
		public init (month: CPCMonth, scale: CGFloat, titleFont: UIFont, titleMargins: UIEdgeInsets) {
			self.init (month: month, partialAttributes: PartialLayoutAttributes (scale: scale, titleFont: titleFont, titleMargins: titleMargins));
		}

		/// Initializes layout attributes for a specific month view and other non-calendric partial attributes.
		///
		/// - Parameters:
		///   - month: Month to be rendered by the measured view.
		///   - partialAttributes: Non-ccalendric layout attributes.
		public init (month: CPCMonth, partialAttributes: PartialLayoutAttributes) {
			self.init (weekLength: month [ordinal: 0].count, weekCount: month.count, partialAttributes: partialAttributes);
		}
		
		fileprivate init (weekLength: Int, weekCount: Int, partialAttributes: PartialLayoutAttributes) {
			self.weekLength = weekLength;
			self.weekCount = weekCount;
			self.partialAttributes = partialAttributes;
		}
	};
	
	open var layoutAttributes: LayoutAttributes? {
		return LayoutAttributes (self);
	}
	
	open var aspectRatioComponents: AspectRatio? {
		return self.layoutAttributes.flatMap { CPCMonthView.aspectRatioComponents (for: $0) };
	}
	
	open class func aspectRatioComponents (for attributes: LayoutAttributes) -> AspectRatio? {
		/// | gridH = rowN * cellSize + (rowN + 1) * sepW      | gridH = rowN * (cellSize + sepW) + sepW      | gridH - sepW = rowN * (cellSize + sepW)
		/// {                                              <=> {                                          <=> {                                          <=>
		/// | gridW = colN * cellSize + (colN + 1) * sepW      | gridW = colN * (cellSize + sepW) + sepW      | gridW - sepW = colN * (cellSize + sepW)
		///
		/// <=> (gridH - sepW) / (gridW - sepW) = rowN / colN
		/// let R = rowN / colN, then (gridH - sepW) / (gridW - sepW) = R <=> gridH - sepW = gridW * R - sepW * R <=> gridH = gridW * R + (1 - sepW) * R
		/// View width is equal to grid width; view height = gridW + titleHeight.
		let aspectRatio = CGFloat (attributes.weekCount) / CGFloat (attributes.weekLength);
		return (multiplier: aspectRatio, constant: (1.0 - attributes.roundingScale) * aspectRatio + attributes.titleHeight);
	}
	
	/// Returns range of possible aspect ratio components that the month view may use for various months.
	///
	/// - Parameters:
	///   - partialAttributes: Non-calendric month view layout attributes to be used for measuring.
	///   - calendar: Calendar to use for calculations.
	/// - Returns: Minimum and maximum aspect ratio multipliers for a month view, paired with corresponding constants.
	open class func aspectRatiosComponentsRange (for partialAttributes: PartialLayoutAttributes, using calendar: Calendar) -> (lower: AspectRatio, upper: AspectRatio) {
		let weeksCountSpan = calendar.estimateSpan (of: .weekOfMonth, in: .month);
		let weekLengthsSpan = calendar.estimateSpan (of: .weekday, in: .weekOfYear);
		
		// Force-unwrap is safe here, `CPCMonthView.aspectRatioComponents (for:)` does not actually return optional values.
		return (
			lower: self.aspectRatioComponents (for: LayoutAttributes (
				weekLength: weekLengthsSpan.upperBound,
				weekCount: weeksCountSpan.lowerBound,
				partialAttributes: partialAttributes
			))!,
			upper: self.aspectRatioComponents (for: LayoutAttributes (
				weekLength: weekLengthsSpan.lowerBound,
				weekCount: weeksCountSpan.upperBound,
				partialAttributes: partialAttributes
			))!
		);
	}
}

/* internal */ extension CPCMonthView {
	internal func titleFontDidUpdate () {
		self.effectiveTitleFont = self.scaledFont (self.titleFont, using: CPCMonthView.titleMetrics);
	}
	
	internal func titleMarginsDidUpdate () {
		self.effectiveTitleMargins = self.scaledInsets (self.titleMargins, using: CPCMonthView.titleMetrics);
	}
	
	internal func titleAppearanceDidUpdate () {
		if (self.needsFullAppearanceUpdate) {
			return;
		}
		self.setNeedsDisplay (self.layout?.titleFrame ?? self.bounds);
	}
	
	internal func dayCellFontDidUpdate () {
		self.effectiveDayCellFont = self.scaledFont (self.dayCellFont, using: CPCMonthView.dayCellTextMetrics);
	}
	
	internal func gridAppearanceDidUpdate () {
		if (self.needsFullAppearanceUpdate) {
			return;
		}
		self.setNeedsDisplay (self.layout?.gridFrame ?? self.bounds);
	}
	
	internal func gridAppearanceDidUpdate (for state: DayCellState) {
		if (self.needsFullAppearanceUpdate) {
			return;
		}
		guard let month = self.month, let layout = self.layout else {
			return;
		}
		
		if (state.contains ([])) {
			return self.gridAppearanceDidUpdate ();
		}
		
		let today = CPCDay.today (using: month.calendarWrapper);
		if state.contains (.isToday), month.contains (today), let todayCellIndex = layout.cellIndex (for: today) {
			self.setNeedsDisplay (layout.cellFrames [todayCellIndex]);
		}
		if state.contains (.selected) {
			for day in self.selection.difference (.none) {
				guard let cellIdx = layout.cellIndex (for: day) else {
					continue;
				}
				self.setNeedsDisplay (layout.cellFrames [cellIdx]);
			}
		}
		if state.contains (.highlighted), let highlightedIdx = self.highlightedDayIndex {
			self.setNeedsDisplay (layout.cellFrames [highlightedIdx]);
		}
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
		self.setNeedsFullAppearanceUpdate ();
		self.highlightedDayIndex = nil;
		self.enabledRegion = nil;
		self.selectionHandler = self.selectionHandler.clearingSelection ();
	}
	
	private func highlightedDayIndexDidChange (oldValue: CellIndex?) {
		guard !self.needsFullAppearanceUpdate else {
			return;
		}
		
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
		guard !self.needsFullAppearanceUpdate else {
			return;
		}
		guard let layout = self.layout else {
			return;
		}
		let selectionDiff = self.selection.difference (oldValue);
		guard !selectionDiff.isEmpty else {
			return;
		}
		
		for day in selectionDiff {
			guard let cellIndex = layout.cellIndex (for: day) else {
				continue;
			}
			self.setNeedsDisplay (layout.cellFrames [cellIndex]);
		}
	}
}

/* fileprivate */ extension Calendar {
	fileprivate func estimateSpan (of unit: Calendar.Component, in other: Calendar.Component) -> ClosedRange <Int> {
		if let minRange = self.minimumRange (of: unit), let maxRange = self.maximumRange (of: unit) {
			return minRange.count ... maxRange.count;
		} else if let currentRange = self.range (of: unit, in: other, for: Date ()) {
			return currentRange.count ... currentRange.count;
		} else {
			// Just some safety fallbacks, previous two cases should always return a valid value
			switch (unit) {
			case .weekOfMonth:
				return 4 ... 6;
			case .weekday:
				return 7 ... 7;
			default:
				return 1 ... 1;
			}
		}
	}
}

/* fileprivate */ extension CPCViewAppearanceStorage {
	fileprivate var monthViewInitializationValues: (UIFont, UIEdgeInsets, UIFont) {
		return (self.titleFont, self.titleMargins, self.dayCellFont);
	}
}
