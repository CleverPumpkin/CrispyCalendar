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

internal enum BoundLocation {
	case emptyRange;
	case beforeLowerBound;
	case inside;
	case afterUpperBound;
}

internal protocol BoundedRangeProtocol: RangeExpression {
	var lowerBound: Bound { get }
	var upperBound: Bound { get }
	var isEmpty: Bool { get }

	init (uncheckedBounds: (lower: Bound, upper: Bound));
	init (bounds bound1: Bound, _ bound2: Bound);
	init (_ range: Self);
	
	func location (of value: Bound) -> BoundLocation;
	
	func formsContiguousUnion (with value: Bound) -> Bool;
	func formsContiguousUnion (with range: Self) -> Bool;
	func contiguousUnion (_ value: Bound) -> Self?;
	func contiguousUnion (_ range: Self) -> Self?;
	func union (_ value: Bound) -> Self;
	func union (_ other: Self) -> Self;
	func clamp (_ value: Bound) -> Bound;
}

extension BoundedRangeProtocol {
	internal var isEmpty: Bool {
		return self.lowerBound == self.upperBound;
	}
	
	internal init (_ range: Self) {
		self = range;
	}
	
	internal init (bounds bound1: Bound, _ bound2: Bound) {
		self.init (uncheckedBounds: ((bound1 <= bound2) ? (lower: bound1, upper: bound2) : (lower: bound2, upper: bound1)));
	}
	
	internal func location (of value: Bound) -> BoundLocation {
		if (self.isEmpty) {
			return .emptyRange;
		}
		
		switch (value) {
		case self:
			return .inside;
		case ...self.lowerBound:
			return .beforeLowerBound;
		case self.upperBound...:
			return .afterUpperBound;
		default:
			fatalError ("[CrispyCalendar] Internal error: cannot determine location of \(value) in \(self)");
		}
	}

	internal func formsContiguousUnion (with value: Bound) -> Bool {
		return (self.isEmpty || self.contains (value) || (self.lowerBound == value) || (self.upperBound == value));
	}

	internal func formsContiguousUnion (with range: Self) -> Bool {
		return self.formsContiguousUnion (with: range.upperBound) || range.formsContiguousUnion (with: self.upperBound);
	}
	
	internal func contiguousUnion (_ value: Bound) -> Self? {
		switch (self.location (of: value)) {
		case .emptyRange:
			return Self (uncheckedBounds: (lower: value, upper: value));
		case .inside:
			return self;
		case .beforeLowerBound, .afterUpperBound:
			return nil;
		}
	}
	
	internal func contiguousUnion (_ range: Self) -> Self? {
		if (self.formsContiguousUnion (with: range.upperBound)) {
			return self.contiguousUnion (range.lowerBound);
		} else if (range.formsContiguousUnion (with: self.upperBound)) {
			return range.contiguousUnion (self.lowerBound);
		} else {
			return nil;
		}
	}

	internal func union (_ value: Bound) -> Self {
		switch (self.location (of: value)) {
		case .emptyRange:
			return Self (uncheckedBounds: (lower: value, upper: value));
		case .inside:
			return self;
		case .beforeLowerBound:
			return Self (uncheckedBounds: (lower: value, upper: self.upperBound));
		case .afterUpperBound:
			return Self (uncheckedBounds: (lower: self.lowerBound, upper: value));
		}
	}
	
	internal func union (_ other: Self) -> Self {
		let otherLower = other.lowerBound, otherUpper = other.upperBound;
		guard otherLower != otherUpper else {
			return self;
		}
		let selfLower = self.lowerBound, selfUpper = self.upperBound;
		guard selfLower != selfUpper else {
			return other;
		}
		
		return Self (uncheckedBounds: (lower: min (selfLower, otherLower), upper: max (selfUpper, otherUpper)));
	}
	
	internal func clamp (_ value: Bound) -> Bound {
		switch (self.location (of: value)) {
		case .emptyRange, .beforeLowerBound:
			return self.lowerBound;
		case .inside:
			return value;
		case .afterUpperBound:
			return self.upperBound;
		}
	}
}

internal extension BoundedRangeProtocol where Bound: Strideable {
	internal var span: Bound.Stride {
		return self.lowerBound.distance (to: self.upperBound);
	}
	
	internal func formsContiguousUnion (with value: Bound) -> Bool {
		let lowerBound = self.lowerBound, upperBound = self.upperBound;
		switch (value) {
		case _ where lowerBound == upperBound, lowerBound ... upperBound:
			return true;
		case upperBound.advanced (by: 1):
			return self.contains (upperBound);
		case lowerBound.advanced (by: -1):
			return self.contains (lowerBound);
		default:
			return false;
		}
	}
	
	internal func contiguousUnion (_ value: Bound) -> Self? {
		let lowerBound = self.lowerBound, upperBound = self.upperBound;
		switch (value) {
		case _ where self.isEmpty:
			return Self (uncheckedBounds: (lower: value, upper: value));
		case self:
			return self;
		case lowerBound.advanced (by: -1) where self.contains (lowerBound), lowerBound:
			return Self (uncheckedBounds: (lower: lowerBound.advanced (by: -1), upper: upperBound));
		case upperBound.advanced (by: 1) where self.contains (upperBound), upperBound:
			return Self (uncheckedBounds: (lower: lowerBound, upper: upperBound.advanced (by: 1)));
		default:
			return nil;
		}
	}
	
	internal func clamp (_ value: Bound) -> Bound {
		let lowerBound = self.lowerBound, upperBound = self.upperBound;
		switch (value) {
		case _ where lowerBound == upperBound:
			return lowerBound;
		case self:
			return value;
		case ...lowerBound:
			return (self.contains (lowerBound) ? lowerBound : lowerBound.advanced (by: 1));
		case upperBound...:
			return (self.contains (upperBound) ? upperBound : upperBound.advanced (by: -1));
		default:
			fatalError ("[CrispyCalendar] Internal error: cannot clamp \(value) to \(self)");
		}
	}
}

internal protocol RangeBaseProtocol: BoundedRangeProtocol {
	init <R> (_ range: R) where R: RangeBaseProtocol, R.Bound == Bound;
}

extension RangeBaseProtocol {
	internal init <R> (_ range: R) where R: RangeBaseProtocol, R.Bound == Bound {
		self.init (uncheckedBounds: (lower: range.lowerBound, upper: range.upperBound));
	}
}

extension Range: RangeBaseProtocol {}
#if !compiler(>=4.2)
extension CountableRange: RangeBaseProtocol {}
#endif

internal protocol ClosedRangeBaseProtocol: BoundedRangeProtocol {
	init <R> (_ range: R) where R: ClosedRangeBaseProtocol, R.Bound == Bound;
}

extension ClosedRangeBaseProtocol {
	internal init <R> (_ range: R) where R: ClosedRangeBaseProtocol, R.Bound == Bound {
		self.init (uncheckedBounds: (lower: range.lowerBound, upper: range.upperBound));
	}
}

extension ClosedRange: ClosedRangeBaseProtocol {}
#if !compiler(>=4.2)
extension CountableClosedRange: ClosedRangeBaseProtocol {}
#endif

#if !swift(>=4.2)
internal extension RangeBaseProtocol where Bound: BinaryInteger {
	internal init <R> (_ range: R) where R: RangeExpression, R.Bound: FixedWidthInteger {
		self.init (Range <R.Bound> (range));
	}
}

internal extension RangeBaseProtocol where Bound: FixedWidthInteger, Bound.Stride: SignedInteger {
	internal init <R> (_ range: R) where R: RangeExpression, R.Bound == Bound {
		self.init (range.unwrapped);
	}
}

internal extension ClosedRangeBaseProtocol where Bound: BinaryInteger {
	internal init <R> (_ range: R) where R: RangeExpression, R.Bound: FixedWidthInteger {
		self.init (Range <R.Bound> (range));
	}
}

internal extension ClosedRangeBaseProtocol where Bound: FixedWidthInteger, Bound.Stride: SignedInteger {
	internal init <R> (_ range: R) where R: RangeExpression, R.Bound == Bound {
		self.init (range.unwrapped);
	}
}
#endif

