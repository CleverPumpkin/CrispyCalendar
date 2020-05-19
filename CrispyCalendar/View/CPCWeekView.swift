//
//  CPCWeekView.swift
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

/// A view that displays weekday names in order define by current user locale and calendar.
open class CPCWeekView: UIView, CPCViewContentAdjusting {
	private static let fontMetrics = CPCFontMetrics.metrics (for: .callout);
	
	/// The font used to display weekday names.
	@IBInspectable open dynamic var font = UIFont.preferredFont (forTextStyle: .callout) {
		didSet {
			self.effectiveFont = self.scaledFont (self.font, using: CPCWeekView.fontMetrics);
		}
	}
	
	/// The color of rendered weekday symbols.
	@IBInspectable open dynamic var textColor = UIColor.darkText.withAlphaComponent (0.75) {
		didSet {
			if (!self.weekendColorWasCustomized) {
				self.weekendColor = self.textColor;
			}
			self.setNeedsDisplay ();
		}
	};
	
	/// The color of rendered weekday symbols that are considered weekends according to current user settings.
	@IBInspectable open dynamic var weekendColor: UIColor = .darkText {
		didSet {
			self.weekendColorWasCustomized = true;
			self.setNeedsDisplay ();
		}
	};
	
	/// Style of rendered symbols.
	@IBInspectable open dynamic var style: CPCDay.Weekday.Style {
		get { return self.styleValue }
		set {
			self.styleValue = newValue;
			self.setNeedsDisplay ();
		}
	}
	
	open override var intrinsicContentSize: CGSize {
		return CGSize (width: UIView.noIntrinsicMetric, height: self.effectiveFont.lineHeight.rounded (.up, scale: self.separatorWidth));
	}
	
	open var adjustsFontForContentSizeCategory: Bool {
		get { return self.adjustsFontForContentSizeCategoryValue }
		set { self.adjustsFontForContentSizeCategoryValue = newValue }
	}
	
	/// Calendar to be used for weekday order & names.
	open var calendar = Calendar.currentUsed {
		didSet {
			if calendarView?.calendar != self.calendar {
				calendarView?.calendar = self.calendar
			}
			self.setNeedsDisplay()
		}
	}
	
	internal var contentSizeCategoryObserver: NSObjectProtocol?;
	
	internal var calendarView: CPCCalendarView? {
		get { return self.calendarViewPtr?.pointee }
		set {
			if let calendar = newValue?.calendar {
				self.calendar = calendar
			}
			self.calendarViewPtr = UnsafePointer (to: newValue)
		}
	}
	
	private var weekendColorWasCustomized = false;
	private var styleValue = CPCDay.Weekday.Style.short;
	private var calendarViewPtr: UnsafePointer <CPCCalendarView>? {
		didSet { self.setNeedsDisplay () }
	}
	
	/// Font that is actually used for text rendering. It is equivalent to `font` when `adjustsFontForContentSizeCategory` is `false`
	/// and is scaled version of `font` otherwise.
	private var effectiveFont = UIFont.preferredFont (forTextStyle: .callout) {
		didSet {
			if (self.effectiveFont.lineHeight != oldValue.lineHeight) {
				self.invalidateIntrinsicContentSize ();
				self.setNeedsLayout ();
			}
			self.setNeedsDisplay ();
		}
	}
	
	public override init (frame: CGRect) {
		super.init (frame: frame);
		self.commonInit ();
	}
	
	public required init? (coder aDecoder: NSCoder) {
		super.init (coder: aDecoder);
		self.commonInit ();
	}
	
	private func commonInit () {
		self.contentMode = .redraw;
		self.isOpaque = false;
	}
	
	open override func sizeThatFits (_ size: CGSize) -> CGSize {
		return CGSize (width: size.width, height: self.intrinsicContentSize.height);
	}
	
	open override func layoutMarginsDidChange () {
		super.layoutMarginsDidChange ();
		
		switch (self.calendarView?.columnContentInsetReference) {
		case nil, .some (.fromLayoutMargins):
			self.setNeedsDisplay ();
		default:
			break;
		}
	}
	
	@available (iOS 11.0, *)
	open override func safeAreaInsetsDidChange () {
		super.safeAreaInsetsDidChange ();

		switch (self.calendarView?.columnContentInsetReference) {
		case nil, .some (.fromSafeAreaInsets):
			self.setNeedsDisplay ();
		default:
			break;
		}
	}
	
	open override func draw (_ rect: CGRect) {
		let columnCount: Int, columnContentInset: UIEdgeInsets, leading: CGFloat, width: CGFloat;
		if let calendarView = self.calendarView {
			columnCount = calendarView.columnCount;
			columnContentInset = calendarView.columnContentInset;
			
			let contentInset: UIEdgeInsets;
			if #available (iOS 11.0, *) {
				contentInset = calendarView.adjustedContentInset;
			} else {
				contentInset = calendarView.contentInset;
			}
			let boundsWidth = calendarView.bounds.width;
			switch (calendarView.columnContentInsetReference) {
			case .fromContentInset:
				leading = contentInset.left;
				width = boundsWidth - contentInset.width;
			case .fromLayoutMargins:
				leading = max (calendarView.layoutMargins.left, contentInset.left);
				width = boundsWidth - max (calendarView.layoutMargins.right, contentInset.right) - leading;
			case .fromSafeAreaInsets:
				if #available (iOS 11.0, *) {
					leading = max (calendarView.safeAreaInsets.left, contentInset.left);
					width = boundsWidth - max (calendarView.safeAreaInsets.right, contentInset.right) - leading;
				} else {
					leading = contentInset.left;
					width = boundsWidth - contentInset.width;
				}
			}
		} else {
			columnCount = 1;
			columnContentInset = .zero;
			if #available (iOS 11.0, *) {
				leading = self.safeAreaInsets.left;
				width = self.bounds.width - self.safeAreaInsets.width;
			} else {
				leading = 0.0;
				width = self.bounds.width;
			}
		}

		let columnLeading = columnContentInset.left, columnWidthInset = columnContentInset.width, boundsHeight = self.bounds.height;
		for column in 0 ..< columnCount {
			let columnCount = CGFloat (columnCount);
			self.drawSingleWeek (in: CGRect (
				x: fma (CGFloat (column) / columnCount, width, leading + columnLeading),
				y: 0.0,
				width: width / columnCount - columnWidthInset,
				height: boundsHeight
			));
		}
	}
	
	private func drawSingleWeek (in rect: CGRect) {
		let isContentsFlipped = self.effectiveUserInterfaceLayoutDirection == .rightToLeft;
		let style = self.style, week = CPCWeek.current (using: self.calendar), font = self.effectiveFont, lineHeight = font.lineHeight, scale = self.separatorWidth;
		let cellOriginY = (rect.midY - lineHeight / 2).rounded (.down, scale: scale);
		let cellWidth = rect.width / CGFloat (week.count) * (isContentsFlipped ? -1.0 : 1.0), cellHeight = lineHeight.rounded (.up, scale: scale);
		let weekdayAttributes: [NSAttributedString.Key: Any] = [
			.font: font,
			.foregroundColor: self.textColor,
			.paragraphStyle: NSParagraphStyle.centeredWithMiddleTruncation,
		];
		let weekendAttributes: [NSAttributedString.Key: Any] = {
			var result = weekdayAttributes;
			result [.foregroundColor] = self.weekendColor;
			return result;
		} ();
		
		var frame = CGRect (x: 0.0, y: cellOriginY, width: cellWidth, height: cellHeight);
		for day in 0 ..< week.count {
			let weekday = week [ordinal: day].weekday;
			frame.origin.x = fma (cellWidth, CGFloat (day), isContentsFlipped ? rect.maxX : rect.minX);
			NSAttributedString (string: weekday.symbol (style: style, standalone: true), attributes: weekday.isWeekend ? weekendAttributes : weekdayAttributes).draw (in: frame.standardized);
		}
	}
	
	internal func adjustValues (for newCategory: UIContentSizeCategory) {
		self.effectiveFont = self.scaledFont (self.font, using: CPCWeekView.fontMetrics, for: newCategory);
	}
}
