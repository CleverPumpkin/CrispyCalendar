//
//  CPCViewMeasuring.swift
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

public protocol CPCViewLayoutAttributes {
	var roundingScale: CGFloat { get }
}

public protocol CPCViewMeasuring {
	associatedtype LayoutAttributes where LayoutAttributes: CPCViewLayoutAttributes;
	
	static func sizeThatFits (_ size: CGSize, with attributes: LayoutAttributes) -> CGSize;
	static func widthThatFits (height: CGFloat, with attributes: LayoutAttributes) -> CGFloat;
	static func heightThatFits (width: CGFloat, with attributes: LayoutAttributes) -> CGFloat;

	var layoutAttributes: LayoutAttributes? { get };
	
	func sizeThatFits (_ size: CGSize, attributes: LayoutAttributes) -> CGSize;
}

public extension CPCViewMeasuring {
	public static func widthThatFits (height: CGFloat, with attributes: LayoutAttributes) -> CGFloat {
		return self.sizeThatFits (CGSize (width: .infinity, height: height), with: attributes).width;
	}
	
	public static func heightThatFits (width: CGFloat, with attributes: LayoutAttributes) -> CGFloat {
		return self.sizeThatFits (CGSize (width: width, height: .infinity), with: attributes).height;
	}
	
	public func sizeThatFits (_ size: CGSize, attributes: LayoutAttributes) -> CGSize {
		return Self.sizeThatFits (size, with: attributes);
	}
}

public protocol CPCFixedAspectRatioView: CPCViewMeasuring {
	/// Returns coefficients of equation ViewHeight = K x ViewWidth + C to fit content.
	///
	/// - Parameter attributes: view-specific layout attributes to perform layout calculations.
	/// - Returns: multiplier K and constant C.
	static func aspectRatioComponents (for attributes: LayoutAttributes) -> (multiplier: CGFloat, constant: CGFloat)?;
}

extension CPCFixedAspectRatioView {
	public static func widthThatFits (height: CGFloat, with attributes: LayoutAttributes) -> CGFloat {
		guard let (multiplier, constant) = self.aspectRatioComponents (for: attributes) else {
			return 0.0;
		}
		
		return ((height - constant) / multiplier).rounded (scale: attributes.roundingScale);
	}

	public static func heightThatFits (width: CGFloat, with attributes: LayoutAttributes) -> CGFloat {
		guard let (multiplier, constant) = self.aspectRatioComponents (for: attributes) else {
			return 0.0;
		}

		return (width * multiplier + constant).rounded (scale: attributes.roundingScale);
	}

	public static func sizeThatFits (_ size: CGSize, with attributes: LayoutAttributes) -> CGSize {
		guard let (multiplier, constant) = self.aspectRatioComponents (for: attributes) else {
			return size;
		}
		
		let scale = attributes.roundingScale, fittingWidth: CGFloat;
		switch (size.constraint) {
		case .none:
			fittingWidth = UIScreen.main.bounds.width;
		case .width (let width), .full (let width, _):
			fittingWidth = width;
		case let .height (height):
			return CGSize (width: ((height - constant) / multiplier).rounded (scale: scale), height: height.rounded (scale: scale));
		}
		
		return CGSize (width: fittingWidth.rounded (scale: scale), height: (fittingWidth * multiplier + constant).rounded (scale: scale));
	}
}

extension CPCFixedAspectRatioView where Self: UIView {
	public func aspectRatioLayoutConstraint (for attributes: LayoutAttributes) -> NSLayoutConstraint {
		let result: NSLayoutConstraint;
		if let (multiplier, constant) = Self.aspectRatioComponents (for: attributes) {
			result = self.heightAnchor.constraint (equalTo: self.widthAnchor, multiplier: multiplier, constant: constant);
		} else {
			result = self.heightAnchor.constraint (equalToConstant: 0.0);
		}
		
		let axis: [UILayoutConstraintAxis] = [.horizontal, .vertical];
		result.priority = UILayoutPriority (rawValue: axis.map {
			(self.contentCompressionResistancePriority (for: $0).rawValue +  self.contentHuggingPriority (for: $0).rawValue) / (2.0 * Float (axis.count))
		}.reduce (0, +));
		return result;
	}
}
