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

internal func log2i <T> (_ value: T) -> Int where T: BinaryInteger {
	precondition (value > 0, "log2 (\(value)) is undefined");
	
	let words = value.words;
	var iterator = words.makeIterator ();
	guard var lastWord = iterator.next () else {
		return 0;
	}
	var wordsCount = 0;
	while let word = iterator.next () {
		wordsCount += 1;
		lastWord = word;
	}
	
	return (wordsCount - 1) * UInt.bitWidth + log2i (lastWord);
}

internal func log2i <T> (_ value: T) -> Int where T: FixedWidthInteger {
	return T.bitWidth - value.leadingZeroBitCount - 1;
}

internal func concatenateHashValues (_ value1: Int, _ value2: Int, shiftAmount: Int) -> Int {
	return (value1 << shiftAmount) | value2;
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
	
	func mix (values: [Int]) -> Int {
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
		return result;
	}
	
	var result = Int (first);
	var values: AnyRandomAccessCollection = AnyRandomAccessCollection (Array (other));
	while !values.isEmpty {
		let slice: AnyRandomAccessCollection <S.Element>;
		(slice, values) = values.divide (maxLength: resultWidth - 1);
		let prefix = [result] + slice.map { Int ($0) };
		result = mix (values: prefix);
	}
	return result;
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
