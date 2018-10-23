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
	
	/// Calendar to be used for weekday order & names.
	open var calendar = Calendar.currentUsed {
		didSet {
			self.setNeedsDisplay ();
		}
	}
	
	/// Style of rendered symbols.
	open var style: CPCDay.Weekday.Style {
		get {
			return self.styleValue;
		}
		set {
			guard !self.isAppearanceProxy else {
				return self.cStyle = newValue.cStyle;
			}
			self.styleValue = newValue;
			self.setNeedsDisplay ();
		}
	}
	
	@IBInspectable open dynamic var columnCount = 1 {
		didSet {
			self.setNeedsDisplay ();
		}
	}
	
	@IBInspectable open dynamic var columnContentInsets = UIEdgeInsets.zero {
		didSet {
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
	
	internal var contentSizeCategoryObserver: NSObjectProtocol?;
	
	private var weekendColorWasCustomized = false;
	private var styleValue = CPCDay.Weekday.Style.short;
	
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
	
	open override func draw (_ rect: CGRect) {
		let columnCount = CGFloat (self.columnCount), boundsSize = self.bounds.standardized.size;
		let columnLeftInset = self.columnContentInsets.left, columnWidthInset = columnLeftInset + self.columnContentInsets.right;
		for column in 0 ..< self.columnCount {
			self.drawSingleWeek (in: CGRect (
				x: columnLeftInset + CGFloat (column) / columnCount * boundsSize.width,
				y: 0.0,
				width: boundsSize.width / columnCount - columnWidthInset,
				height: boundsSize.height
			));
		}
	}
	
	private func drawSingleWeek (in rect: CGRect) {
		let style = self.style, week = CPCWeek (containing: Date (), calendar: self.calendar), font = self.effectiveFont, lineHeight = font.lineHeight, scale = self.separatorWidth;
		let cellOriginY = (rect.midY - lineHeight / 2).rounded (.down, scale: scale);
		let cellWidth = rect.width / CGFloat (week.count), cellHeight = lineHeight.rounded (.up, scale: scale);
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
		
		var lastX = rect.minX;
		for dayIndex in week.indices {
			let weekday = week [dayIndex].weekday, frame = CGRect (x: lastX, y: cellOriginY, width: rect.minX + (cellWidth * CGFloat (dayIndex)) - lastX, height: cellHeight);
			NSAttributedString (string: weekday.symbol (style: style, standalone: true), attributes: weekday.isWeekend ? weekendAttributes : weekdayAttributes).draw (in: frame);
			lastX = frame.maxX;
		}
	}
	
	internal func adjustValues (for newCategory: UIContentSizeCategory) {
		self.effectiveFont = self.scaledFont (self.font, using: CPCWeekView.fontMetrics, for: newCategory);
	}
}

extension CPCWeekView {
	/// Style value that can be accessed from Objective C code.
	@IBInspectable open dynamic var cStyle: __CPCCalendarUnitSymbolStyle {
		get { return self.style.cStyle }
		set { self.style = CPCDay.Weekday.Style (newValue) }
	}
}
