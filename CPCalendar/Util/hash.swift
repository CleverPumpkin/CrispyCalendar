//
//  hash.swift
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

import Foundation

internal extension BinaryInteger {
	internal var usedBitCount: Int {
		guard self > 0 else {
			return (self == 0) ? 0 : self.bitWidth;
		}
		
		let words = self.words;
		var iterator = words.makeIterator ();
		guard var lastWord = iterator.next () else {
			return 0;
		}
		var result = 0;
		while let word = iterator.next () {
			result += UInt.bitWidth;
			lastWord = word;
		}
		return result + lastWord.usedBitCount;
	}
}

internal extension FixedWidthInteger {
	internal var usedBitCount: Int {
		return Self.bitWidth - self.leadingZeroBitCount;
	}
}

internal func hashIntegers <T> (_ first: T, _ other: T...) -> Int where T: FixedWidthInteger {
	return hashIntegers (first, other);
}

internal func hashIntegers <S> (_ values: S) -> Int where S: Sequence, S.Element: FixedWidthInteger {
	var iterator = values.makeIterator ();
	guard let first = iterator.next () else {
		return 0;
	}
	
	return hashIntegers (first, IteratorSequence (iterator));
}

private func hashIntegers <S> (_ first: S.Element, _ other: S) -> Int where S: Sequence, S.Element: FixedWidthInteger {
	let resultWidth = Int.bitWidth;
	
	func mix (values: inout [Int]) {
		let valuesCount = values.count;
		
		var result = 0;
		let (usedBits, remainingBits) = resultWidth.quotientAndRemainder (dividingBy: valuesCount);
		for bitIdx in 0 ..< usedBits {
			let valueMask = 1 << bitIdx;
			for valueIdx in 0 ..< valuesCount {
				result |= (values [valueIdx] & valueMask) << valueIdx;
			}
		}
		let valueMask = 1 << usedBits;
		for valueIdx in 0 ..< remainingBits {
			result |= (values [valueIdx] & valueMask) << valueIdx;
		}
		values.removeAll (keepingCapacity: true);
		values.append (result);
	}
	
	var values = [Int] ();
	values.reserveCapacity (resultWidth);
	values.append (Int (first));
	
	for nextValue in other {
		values.append (Int (nextValue));
		if (values.count == resultWidth) {
			mix (values: &values);
		}
	}

	return values [0];
}

fileprivate extension Collection {
	fileprivate func divide (maxLength: Int) -> (slice: Self.SubSequence, remainder: Self.SubSequence) {
		var index = 0;
		return self.divide { _ in
			index += 1;
			return index < maxLength;
		};
	}

	fileprivate func divide (belongsToSlice predicate: (Element) -> Bool) -> (slice: Self.SubSequence, remainder: Self.SubSequence) {
		for index in self.indices {
			guard predicate (self [index]) else {
				return self.divide (at: index);
			}
		}
		return self.divide (at: self.endIndex);
	}
	
	fileprivate func divide (at index: Index) -> (slice: Self.SubSequence, remainder: Self.SubSequence) {
		let startIndex = self.startIndex, endIndex = self.endIndex;
		switch (index) {
		case let index where index < startIndex:
			return (slice: self [startIndex ..< startIndex], remainder: self [startIndex ..< endIndex]);
		case let index where index >= endIndex:
			return (slice: self [startIndex ..< endIndex], remainder: self [endIndex ..< endIndex]);
		default:
			return (slice: self [startIndex ..< index], remainder: self [index ..< endIndex]);
		}
	}
}

fileprivate extension Collection where Index: BinaryInteger {
	fileprivate func divide (maxLength: Int) -> (slice: Self.SubSequence, remainder: Self.SubSequence) {
		return self.divide (at: numericCast (maxLength));
	}
}
