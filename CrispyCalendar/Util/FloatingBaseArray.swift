//
//  FloatingBaseArray.swift
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

internal typealias FloatingBaseArraySlice <Element> = Slice <FloatingBaseArray <Element>>;

internal struct FloatingBaseArray <Element> {
	private var backing: ContiguousArray <Element>;
	private var baseOffset: Int;
}

extension FloatingBaseArray: MutableCollection, RandomAccessCollection {
	internal typealias Index = ContiguousArray <Element>.Index;
	internal typealias SubSequence = Slice <FloatingBaseArray>;
	
	internal var startIndex: Index {
		return self.backing.startIndex + self.baseOffset;
	}
	
	internal var endIndex: Index {
		return self.backing.endIndex + self.baseOffset;
	}
	
	internal func index (after i: Index) -> Index {
		return self.backing.index (after: i - self.baseOffset) + self.baseOffset;
	}

	internal func index (before i: Index) -> Index {
		return self.backing.index (before: i - self.baseOffset) + self.baseOffset;
	}

	internal subscript (position: Index) -> Element {
		get { return self.backing [position - self.baseOffset] }
		set { self.backing [position - self.baseOffset] = newValue }
	}

	internal subscript (bounds: Range <Index>) -> Slice <FloatingBaseArray> {
		get { return Slice (base: self, bounds: bounds) }
		set { self.backing.replaceSubrange (bounds.offset (by: self.baseOffset), with: newValue) }
	}
}

internal extension FloatingBaseArray /* RangeReplacementCollection subset */ {
	internal init (baseOffset: Int = 0) {
		self.backing = ContiguousArray ();
		self.baseOffset = baseOffset;
	}

	internal init (_ other: FloatingBaseArray) {
		self.backing = other.backing;
		self.baseOffset = other.baseOffset;
	}

	internal init <S> (_ elements: S, baseOffset: Int = 0) where S: Sequence, S.Element == Element {
		self.backing = ContiguousArray (elements);
		self.baseOffset = baseOffset;
	}
	
	internal mutating func append (_ newElement: Element) {
		self.backing.append (newElement);
	}
	
	internal mutating func append <S> (contentsOf newElements: S) where S: Sequence, S.Element == Element {
		self.backing.append (contentsOf: newElements);
	}
	
	internal mutating func prepend (_ newElement: Element) {
		self.backing.insert (newElement, at: self.backing.startIndex);
		self.baseOffset -= 1;
	}
	
	internal mutating func prepend <C> (contentsOf newElements: C) where C: Collection, C.Element == Element {
		self.backing.insert (contentsOf: newElements, at: self.backing.startIndex);
		self.baseOffset -= newElements.count;
	}
	
	internal mutating func popLast () -> Element? {
		return self.isEmpty ? nil : self.removeLast ();
	}
	
	internal mutating func removeLast () -> Element {
		return self.backing.removeLast ();
	}
	
	internal mutating func removeLast (_ k: Int) {
		return self.backing.removeLast (k);
	}
	
	internal mutating func popFirst () -> Element? {
		return self.isEmpty ? nil : self.removeFirst ();
	}
	
	internal mutating func removeFirst () -> Element {
		self.baseOffset += 1;
		return self.backing.removeFirst ();
	}
	
	internal mutating func removeFirst (_ k: Int) {
		self.baseOffset += k;
		return self.backing.removeFirst (k);
	}

	internal mutating func reserveCapacity (_ capacity: Int) {
		self.backing.reserveCapacity (capacity);
	}
}

extension FloatingBaseArray: ExpressibleByArrayLiteral {
	internal typealias ArrayLiteralElement = Element;
	
	internal init (arrayLiteral elements: Element...) {
		self.init (elements);
	}
}

internal extension FloatingBaseArray {
	func withUnsafeBufferPointer <R> (_ body: (UnsafeBufferPointer<Element>) throws -> R) rethrows -> R {
		return try self.backing.withUnsafeBufferPointer (body);
	}
}

internal extension Range where Bound: Strideable {
	internal func offset (by offset: Bound.Stride) -> Range {
		return self.lowerBound.advanced (by: offset) ..< self.upperBound.advanced (by: offset);
	}
}

internal extension FloatingBaseArray where Element: NSObject, Element: NSCopying {
	internal init (_ other: FloatingBaseArray, copyItems: Bool) {
		if (copyItems) {
			self.init (other.backing, baseOffset: other.baseOffset, copyItems: true);
		} else {
			self.init (other);
		}
	}

	internal init <S> (_ elements: S, baseOffset: Int = 0, copyItems: Bool) where S: Sequence, S.Element == Element {
		guard copyItems else {
			self.init (elements, baseOffset: baseOffset);
			return;
		}
		
		self.init (baseOffset: baseOffset);
		self.backing.reserveCapacity (elements.underestimatedCount);
		for element in elements {
			self.backing.append (element.copy () as! Element);
		}
	}
}
