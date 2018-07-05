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

/// Protocol that hides Dynamic Font implementation differences between iOS 10 and iOS 11+.
internal protocol CPCFontMetricsProtocol {
	/// Get an arbitrary scaled value for current content size category.
	///
	/// - Parameter value: Value to scale.
	/// - Returns: `value`, scaled according to user-selected content size category.
	func scaledValue (_ value: CGFloat) -> CGFloat;
	/// Get an arbitrary scaled value for a given `contentSizeCategory`.
	///
	/// - Parameters:
	///   - value: Value to scale.
	///   - contentSizeCategory: Content size category to scale for.
	/// - Returns: `value`, scaled according to given content size category.
	func scaledValue (_ value: CGFloat, for contentSizeCategory: UIContentSizeCategory) -> CGFloat;
	
	/// Get insets, scaled for current content size category.
	///
	/// - Parameter insets: Insets to scale.
	/// - Returns: `insets`, scaled according to user-selected content size category.
	func scaledInsets (_ insets: UIEdgeInsets) -> UIEdgeInsets;
	/// Get insets, scaled for a given `contentSizeCategory`.
	///
	/// - Parameters:
	///   - insets: Insets to scale.
	///   - contentSizeCategory: Content size category to scale for.
	/// - Returns: `insets`, scaled according to given content size category.
	func scaledInsets (_ insets: UIEdgeInsets, for contentSizeCategory: UIContentSizeCategory) -> UIEdgeInsets;
	
	/// Get font, scaled for current content size category.
	///
	/// - Parameter font: Font to scale.
	/// - Returns: `font`, scaled according to user-selected content size category.
	func scaledFont (_ font: UIFont) -> UIFont;
	/// Get font, scaled for a given `contentSizeCategory`.
	///
	/// - Parameters:
	///   - font: Font to scale.
	///   - contentSizeCategory: Content size category to scale for.
	/// - Returns: `font`, scaled according to given content size category.
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

/// Container for various `CPCFontMetricsProtocol` implementations.
internal struct CPCFontMetrics {
	/// `CPCFontMetricsProtocol` implementation backed by `UIFontMetrics` (iOS 11.0+).
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
	
	/// `CPCFontMetricsProtocol` implementation that relies on system font metrics (iOS 10.3 and older).
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
	
	/// Creates new `CPCFontMetricsProtocol` instance that scales values according to a specific text style.
	///
	/// - Parameter textStyle: Text style that is used to scale various values.
	/// - Returns: An instance of `FontMetrics` (iOS 11.0+) or `LegacyFontMetrics` (iOS 10.3 and older).
	internal static func metrics (for textStyle: UIFontTextStyle) -> CPCFontMetricsProtocol {
		if #available (iOS 11.0, *) {
			return FontMetrics (style: textStyle);
		} else {
			return LegacyFontMetrics (textStyle: textStyle);
		}
	}
	
	private init () {}
}
