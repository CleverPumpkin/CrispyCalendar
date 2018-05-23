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

open class CPCWeekView: UIView, CPCViewContentAdjusting {
	private static let fontMetrics = CPCFontMetrics.metrics (for: .callout);
	
	@IBInspectable open var font = UIFont.preferredFont (forTextStyle: .callout) {
		didSet {
			self.effectiveFont = self.scaledFont (self.font, using: CPCWeekView.fontMetrics);
		}
	}
	
	@IBInspectable open var textColor = UIColor.darkText.withAlphaComponent (0.75) {
		didSet {
			self.setNeedsDisplay ();
		}
	};
	
	@IBInspectable open var weekendColor: UIColor = .darkText {
		didSet {
			self.setNeedsDisplay ();
		}
	};
	
	open var style = CPCDay.Style.default {
		didSet {
			self.setNeedsDisplay ();
		}
	}
	
	open override var intrinsicContentSize: CGSize {
		return CGSize (width: UIViewNoIntrinsicMetric, height: (self.style == .none) ? 0.0 : self.font.lineHeight);
	}
	
	open var adjustsFontForContentSizeCategory: Bool {
		get { return self.adjustsFontForContentSizeCategoryValue }
		set { self.adjustsFontForContentSizeCategoryValue = newValue }
	}
	
	internal var contentSizeCategoryObserver: NSObjectProtocol?;
	
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
		let style = self.style, week = CPCWeek.current, font = self.effectiveFont, lineHeight = font.lineHeight, scale = self.separatorWidth;
		let cellOriginY = (self.bounds.midY - lineHeight / 2).rounded (.down, scale: scale);
		let cellWidth = self.bounds.width / CGFloat (week.count), cellHeight = lineHeight.rounded (.up, scale: scale);
		let weekdayAttributes: [NSAttributedStringKey: Any] = [
			.font: font,
			.foregroundColor: self.textColor,
			.paragraphStyle: NSParagraphStyle.centeredWithMiddleTruncation,
		];
		let weekendAttributes: [NSAttributedStringKey: Any] = {
			var result = weekdayAttributes;
			result [.foregroundColor] = self.weekendColor;
			return result;
		} ();
		
		var lastX = CGFloat (0.0);
		for dayIndex in 0 ..< week.count {
			let day = week [dayIndex], frame = CGRect (x: lastX, y: cellOriginY, width: (cellWidth * CGFloat (dayIndex + 1)) - lastX, height: cellHeight);
			NSAttributedString (string: day.symbol (style: style, standalone: true), attributes: day.isWeekend ? weekendAttributes : weekdayAttributes).draw (in: frame);
			lastX = frame.maxX;
		}
	}
	
	internal func adjustValues (for newCategory: UIContentSizeCategory) {
		self.effectiveFont = self.scaledFont (self.font, using: CPCWeekView.fontMetrics, for: newCategory);
	}
}

extension CPCWeekView {
	@IBInspectable open var cStyle: __CPCCalendarUnitSymbolStyle {
		get { return self.style.cStyle }
		set { self.style = CPCDay.Style (newValue) }
	}
}
