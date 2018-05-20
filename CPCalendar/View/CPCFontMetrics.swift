//
//  CPCFontMetrics.swift
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

internal protocol CPCFontMetricsProtocol {
	func scaledValue (_ value: CGFloat) -> CGFloat;
	func scaledValue (_ value: CGFloat, for contentSizeCategory: UIContentSizeCategory) -> CGFloat;
	
	func scaledInsets (_ insets: UIEdgeInsets) -> UIEdgeInsets;
	func scaledInsets (_ insets: UIEdgeInsets, for contentSizeCategory: UIContentSizeCategory) -> UIEdgeInsets;
	
	func scaledFont (_ font: UIFont) -> UIFont;
	func scaledFont (_ font: UIFont, for contentSizeCategory: UIContentSizeCategory) -> UIFont;
}

extension CPCFontMetricsProtocol {
	internal func scaledValue (_ value: CGFloat) -> CGFloat {
		return self.scaledValue (value, for: UIApplication.shared.preferredContentSizeCategory);
	}
	
	internal func scaledInsets (_ insets: UIEdgeInsets) -> UIEdgeInsets {
		return self.scaledInsets (insets, for: UIApplication.shared.preferredContentSizeCategory);
	}
	
	internal func scaledInsets (_ insets: UIEdgeInsets, for contentSizeCategory: UIContentSizeCategory) -> UIEdgeInsets {
		let scaleBlock: (CGFloat) -> CGFloat = { self.scaledValue ($0, for: contentSizeCategory) };
		return UIEdgeInsets (top: scaleBlock (insets.top), left: scaleBlock (insets.left), bottom: scaleBlock (insets.bottom), right: scaleBlock (insets.right));
	}
	
	internal func scaledFont (_ font: UIFont) -> UIFont {
		return self.scaledFont (font, for: UIApplication.shared.preferredContentSizeCategory);
	}
	
	internal func scaledFont (_ font: UIFont, for contentSizeCategory: UIContentSizeCategory) -> UIFont {
		return font.withSize (self.scaledValue (font.pointSize, for: contentSizeCategory));
	}
}

internal struct CPCFontMetrics {
	@available (iOS 11.0, *)
	private struct FontMetrics: CPCFontMetricsProtocol {
		private let fontMetrics: UIFontMetrics;
		
		private init (_ fontMetrics: UIFontMetrics) {
			self.fontMetrics = fontMetrics;
		}
		
		fileprivate init (style: UIFontTextStyle) {
			self.init (UIFontMetrics (forTextStyle: style));
		}
		
		fileprivate func scaledValue (_ value: CGFloat) -> CGFloat {
			return self.fontMetrics.scaledValue (for: value);
		}
		
		fileprivate func scaledValue (_ value: CGFloat, for contentSizeCategory: UIContentSizeCategory) -> CGFloat {
			return self.fontMetrics.scaledValue (for: value, compatibleWith: UITraitCollection (preferredContentSizeCategory: contentSizeCategory));
		}
		
		fileprivate func scaledFont (_ font: UIFont) -> UIFont {
			return self.fontMetrics.scaledFont (for: font);
		}
		
		fileprivate func scaledFont (_ font: UIFont, for contentSizeCategory: UIContentSizeCategory) -> UIFont {
			return self.fontMetrics.scaledFont (for: font, compatibleWith: UITraitCollection (preferredContentSizeCategory: contentSizeCategory));
		}
	}
	
	private struct LegacyFontMetrics: CPCFontMetricsProtocol {
		private let textStyle: UIFontTextStyle;
		
		fileprivate init (textStyle: UIFontTextStyle) {
			self.textStyle = textStyle;
		}

		fileprivate func scaledValue (_ value: CGFloat) -> CGFloat {
			let scaledSystemFont = UIFont.preferredFont (forTextStyle: self.textStyle);
			let baseSystemFont = UIFont.preferredFont (forTextStyle: self.textStyle, compatibleWith: UITraitCollection (preferredContentSizeCategory: .medium));
			return value / baseSystemFont.pointSize * scaledSystemFont.pointSize;
		}
		
		fileprivate func scaledValue (_ value: CGFloat, for contentSizeCategory: UIContentSizeCategory) -> CGFloat {
			let scaledSystemFont = UIFont.preferredFont (forTextStyle: self.textStyle, compatibleWith: UITraitCollection (preferredContentSizeCategory: contentSizeCategory));
			let baseSystemFont = UIFont.preferredFont (forTextStyle: self.textStyle, compatibleWith: UITraitCollection (preferredContentSizeCategory: .medium));
			return value / baseSystemFont.pointSize * scaledSystemFont.pointSize;
		}
	}
	
	internal static func metrics (for textStyle: UIFontTextStyle) -> CPCFontMetricsProtocol {
		if #available (iOS 11.0, *) {
			return FontMetrics (style: textStyle);
		} else {
			return LegacyFontMetrics (textStyle: textStyle);
		}
	}
	
	private init () {}
}
