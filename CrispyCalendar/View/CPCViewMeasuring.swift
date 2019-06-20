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

/* fileprivate */ extension CGSize {
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
		UIView.noIntrinsicMetric,
		UITableView.automaticDimension,
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

/// A type that can be used to calculate size of a view conforming to `CPCViewMeasuring`
public protocol CPCViewLayoutAttributes {
	/// Scale factor to use for resulting frames/sizes rounding. Typically should be equal to `1.0 / UIScreen.main.nativeScale`.
	var roundingScale: CGFloat { get }
}

/// A view type that is capable of calculating fitting size for instances statically.
public protocol CPCViewMeasuring {
	/// A type containing information required for view size calculations.
	associatedtype LayoutAttributes where LayoutAttributes: CPCViewLayoutAttributes;
	
	/// Asks the view type to calculate and return the size for its instance that best fits the specified size.
	///
	/// - Parameters:
	///   - size: The size for which the view type should calculate its best-fitting size.
	///   - attributes: Additional attributes to be taken into consideration by view type when calculating best-fitting size.
	/// - Returns: A new size that is adequate for given input parameters.
	static func sizeThatFits (_ size: CGSize, with attributes: LayoutAttributes) -> CGSize;
	
	/// Asks the view type to calculate and return width for its instance given a specific height constraint.
	///
	/// - Note: Default implementation calls `sizeThatFits (_:with:)` with infinite width.
	/// - Parameters:
	///   - height: The height for which the view type should calculate its best-fitting width.
	///   - attributes: Additional attributes to be taken into consideration by view type when calculating best-fitting width.
	/// - Returns: A new width that is adequate for given input parameters.
	static func widthThatFits (height: CGFloat, with attributes: LayoutAttributes) -> CGFloat;
	
	/// Asks the view type to calculate and return height for its instance given a specific width constraint.
	///
	/// - Note: Default implementation calls `sizeThatFits (_:with:)` with infinite height.
	/// - Parameters:
	///   - width: The width for which the view type should calculate its best-fitting height.
	///   - attributes: Additional attributes to be taken into consideration by view type when calculating best-fitting height.
	/// - Returns: A new height that is adequate for given input parameters.
	static func heightThatFits (width: CGFloat, with attributes: LayoutAttributes) -> CGFloat;

	/// Current layout attributes associated with this view instance.
	var layoutAttributes: LayoutAttributes? { get };
	
	/// Asks the view to calculate and return the size that best fits the specified size.
	///
	/// - Note: Default implementation calls type method with same name.
	/// - Parameters:
	///   - size: The size for which the view should calculate its best-fitting size.
	///   - attributes: Additional attributes to be taken into consideration when calculating best-fitting size.
	/// - Returns: A new size that is adequate for given input parameters.
	func sizeThatFits (_ size: CGSize, attributes: LayoutAttributes) -> CGSize;
}

/* public */ extension CPCViewMeasuring {
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

/// A view type that sizes instances using linear equation.
public protocol CPCFixedAspectRatioView: CPCViewMeasuring {
	/// Tuple representing multiplier `K` and constant `C` of a linear equation.
	typealias AspectRatio = (multiplier: CGFloat, constant: CGFloat);
	
	/// Returns coefficients of equation `ViewHeight = K x ViewWidth + C` to fit content.
	///
	/// - Parameter attributes: View-specific layout attributes to perform layout calculations.
	/// - Returns: Multiplier K and constant C.
	static func aspectRatioComponents (for attributes: LayoutAttributes) -> AspectRatio?;
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
	/// Initialize `NSLayoutConstraint` expressing dependency between view dimensions.
	///
	/// - Parameter attributes: Attributes for which instance aspect ratio is calculated.
	/// - Returns: A new `NSLayoutConstraint` that ensures adequate sizing of this view.
	public func aspectRatioLayoutConstraint (for attributes: LayoutAttributes) -> NSLayoutConstraint {
		let result: NSLayoutConstraint;
		if let (multiplier, constant) = Self.aspectRatioComponents (for: attributes) {
			result = self.heightAnchor.constraint (equalTo: self.widthAnchor, multiplier: multiplier, constant: constant);
		} else {
			result = self.heightAnchor.constraint (equalToConstant: 0.0);
		}
		
		let axis: [NSLayoutConstraint.Axis] = [.horizontal, .vertical];
		result.priority = UILayoutPriority (rawValue: axis.map {
			(self.contentCompressionResistancePriority (for: $0).rawValue +  self.contentHuggingPriority (for: $0).rawValue) / (2.0 * Float (axis.count))
		}.reduce (0, +));
		return result;
	}
}

#if !swift(>=4.2)
/* internal */ extension UIView {
	internal static let noIntrinsicMetric = UIViewNoIntrinsicMetric;
}

/* fileprivate */ extension UITableView {
	fileprivate static let automaticDimension = UITableViewAutomaticDimension;
}
#endif
