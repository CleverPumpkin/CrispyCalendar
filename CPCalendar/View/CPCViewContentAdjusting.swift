//
//  CPCViewContentAdjusting.swift
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

internal protocol CPCViewContentAdjusting: UIContentSizeCategoryAdjusting {
	var contentSizeCategoryObserver: NSObjectProtocol? { get set }

	func scaledValue (_ value: CGFloat, using fontMetrics: CPCFontMetricsProtocol) -> CGFloat;
	func scaledValue (_ value: CGFloat, using fontMetrics: CPCFontMetricsProtocol, for newCategory: UIContentSizeCategory) -> CGFloat;
	func scaledInsets (_ insets: UIEdgeInsets, using fontMetrics: CPCFontMetricsProtocol) -> UIEdgeInsets;
	func scaledInsets (_ insets: UIEdgeInsets, using fontMetrics: CPCFontMetricsProtocol, for newCategory: UIContentSizeCategory) -> UIEdgeInsets;
	func scaledFont (_ font: UIFont, using fontMetrics: CPCFontMetricsProtocol) -> UIFont;
	func scaledFont (_ font: UIFont, using fontMetrics: CPCFontMetricsProtocol, for newCategory: UIContentSizeCategory) -> UIFont;
	
	func adjustValuesForCurrentContentSizeCategory ();
	func adjustValues (for newCategory: UIContentSizeCategory);
}

extension CPCViewContentAdjusting {
	internal var adjustsFontForContentSizeCategoryValue: Bool {
		get {
			return self.contentSizeCategoryObserver != nil;
		}
		set {
			switch (self.contentSizeCategoryObserver, newValue) {
			case (.some (let observer), false):
				NotificationCenter.default.removeObserver (observer);
			case (nil, true):
				self.adjustValuesForCurrentContentSizeCategory ();
				self.contentSizeCategoryObserver = NotificationCenter.default.addObserver (forName: .UIContentSizeCategoryDidChange, object: nil, queue: nil) { notification in
					if let category = notification.userInfo? [UIContentSizeCategoryNewValueKey] as? UIContentSizeCategory {
						self.adjustValues (for: category);
					} else {
						self.adjustValuesForCurrentContentSizeCategory ();
					}
				};
			default:
				break;
			}
		}
	}

	internal func scaledValue (_ value: CGFloat, using fontMetrics: CPCFontMetricsProtocol) -> CGFloat {
		return self.scaledValue (value, using: fontMetrics, for: UIApplication.shared.preferredContentSizeCategory);
	}
	
	internal func scaledValue (_ value: CGFloat, using fontMetrics: CPCFontMetricsProtocol, for newCategory: UIContentSizeCategory) -> CGFloat {
		return self.adjustsFontForContentSizeCategoryValue ? fontMetrics.scaledValue (value, for: newCategory) : value;
	}
	
	internal func scaledInsets (_ insets: UIEdgeInsets, using fontMetrics: CPCFontMetricsProtocol) -> UIEdgeInsets {
		return self.scaledInsets (insets, using: fontMetrics, for: UIApplication.shared.preferredContentSizeCategory);
	}
	
	internal func scaledInsets (_ insets: UIEdgeInsets, using fontMetrics: CPCFontMetricsProtocol, for newCategory: UIContentSizeCategory) -> UIEdgeInsets {
		return self.adjustsFontForContentSizeCategoryValue ? fontMetrics.scaledInsets (insets, for: newCategory) : insets;
	}
	
	internal func scaledFont (_ font: UIFont, using fontMetrics: CPCFontMetricsProtocol) -> UIFont {
		return self.scaledFont (font, using: fontMetrics, for: UIApplication.shared.preferredContentSizeCategory);
	}
	
	internal func scaledFont (_ font: UIFont, using fontMetrics: CPCFontMetricsProtocol, for newCategory: UIContentSizeCategory) -> UIFont {
		return self.adjustsFontForContentSizeCategoryValue ? fontMetrics.scaledFont (font, for: newCategory) : font;
	}
	
	internal func adjustValuesForCurrentContentSizeCategory () {
		self.adjustValues (for: UIApplication.shared.preferredContentSizeCategory);
	}
}

