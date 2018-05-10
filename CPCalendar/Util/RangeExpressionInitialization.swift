//
//  RangeExpressionBoundsCollection.swift
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

import Swift

private struct RangeExpressionBoundsCollection <Bound>: Collection where Bound: FixedWidthInteger {
	fileprivate typealias Index = Bound;
	fileprivate typealias Element = Bound;
	
	fileprivate var startIndex: Bound {
		return Bound.min;
	}
	
	fileprivate var endIndex: Bound {
		return Bound.max;
	}
	
	fileprivate subscript (position: Bound) -> Bound {
		return position;
	}

	fileprivate func index (after i: Bound) -> Bound {
		return i + 1;
	}
}

internal protocol BoundedRangeProtocol {
	associatedtype Bound where Bound: Comparable;
	
	var lowerBound: Bound { get }
	var upperBound: Bound { get }

	init (uncheckedBounds: (lower: Bound, upper: Bound));
}

extension BoundedRangeProtocol {
	internal init (_ range: Self) {
		self = range;
	}
	
	internal func union (_ value: Bound) -> Self {
		return Self (uncheckedBounds: (lower: min (self.lowerBound, value), upper: max (self.upperBound, value)));
	}
	
	internal func union (_ other: Self) -> Self {
		return Self (uncheckedBounds: (lower: min (self.lowerBound, other.lowerBound), upper: max (self.upperBound, other.upperBound)));
	}
	
	internal func clamp (_ value: Bound) -> Bound {
		switch (value) {
		case value where value < self.lowerBound:
			return self.lowerBound;
		case value where value > self.upperBound:
			return self.upperBound;
		default:
			return value;
		}
	}
}

internal extension BoundedRangeProtocol where Bound: Strideable {
	internal var span: Bound.Stride {
		return self.lowerBound.distance (to: self.upperBound);
	}
}

internal protocol RangeBaseProtocol: BoundedRangeProtocol {
	init <R> (_ range: R) where R: RangeExpression, R.Bound == Bound, R: RangeBaseProtocol;
}

extension RangeBaseProtocol {
	internal init <R> (_ range: R) where R: RangeExpression, R.Bound == Bound, R: RangeBaseProtocol {
		self.init (uncheckedBounds: (lower: range.lowerBound, upper: range.upperBound));
	}
}

extension RangeBaseProtocol where Bound: Strideable, Bound.Stride: BinaryInteger {
	internal func clamp (_ value: Bound) -> Bound {
		return (self.lowerBound ... self.upperBound.advanced (by: -1)).clamp (value);
	}
}

extension Range: RangeBaseProtocol {}
extension CountableRange: RangeBaseProtocol {}

internal protocol ClosedRangeBaseProtocol: BoundedRangeProtocol {
	init <R> (_ range: R) where R: RangeExpression, R.Bound == Bound, R: ClosedRangeBaseProtocol;
}

extension ClosedRangeBaseProtocol {
	internal init <R> (_ range: R) where R: RangeExpression, R.Bound == Bound, R: ClosedRangeBaseProtocol {
		self.init (uncheckedBounds: (lower: range.lowerBound, upper: range.upperBound));
	}
}

extension ClosedRange: ClosedRangeBaseProtocol {}
extension CountableClosedRange: ClosedRangeBaseProtocol {}

internal extension RangeBaseProtocol where Bound: BinaryInteger {
	internal init <R> (_ range: R) where R: RangeExpression, R.Bound: FixedWidthInteger {
		self.init (Range <R.Bound> (range));
	}
}

internal extension RangeBaseProtocol where Bound: FixedWidthInteger {
	internal init <R> (_ range: R) where R: RangeExpression, R.Bound == Bound {
		self.init (range.relative (to: RangeExpressionBoundsCollection ()));
	}
}

internal extension ClosedRangeBaseProtocol where Bound: BinaryInteger {
	internal init <R> (_ range: R) where R: RangeExpression, R.Bound: FixedWidthInteger {
		self.init (Range <R.Bound> (range));
	}
}

internal extension ClosedRangeBaseProtocol where Bound: FixedWidthInteger {
	internal init <R> (_ range: R) where R: RangeExpression, R.Bound == Bound {
		self.init (range.relative (to: RangeExpressionBoundsCollection ()));
	}
}
