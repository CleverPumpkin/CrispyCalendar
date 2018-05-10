//
//  ComputedCollection.swift
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

internal struct ComputedCollection <Index, Element, Indices> where Indices: Collection, Indices.Index == Index, Indices.Element == Index, Indices.SubSequence == Indices {
	fileprivate struct Implementation {
		private enum IndicesImplementation {
			case block (() -> Indices);
			case `static` (Indices);
			
			fileprivate var indices: Indices {
				switch (self) {
				case .block (let block):
					return block ();
				case .static (let indices):
					return indices;
				}
			}
		}
		
		private let indicesImplementation: IndicesImplementation;
		private let subscriptImplementation: (Index) -> Element;
	}
	
	private let implementation: Implementation;

	internal init (indices indicesBlock: @escaping () -> Indices, subscript subscriptBlock: @escaping (Index) -> Element) {
		self.implementation = Implementation (indices: indicesBlock, subscript: subscriptBlock);
	}
	
	internal init (indices: Indices, subscript subscriptBlock: @escaping (Index) -> Element) {
		self.implementation = Implementation (indices: indices, subscript: subscriptBlock);
	}
}

fileprivate extension ComputedCollection.Implementation {
	fileprivate init (indices indicesBlock: @escaping () -> Indices, subscript subscriptBlock: @escaping (Index) -> Element) {
		self.indicesImplementation = .block (indicesBlock);
		self.subscriptImplementation = subscriptBlock;
	}
	
	fileprivate init (indices: Indices, subscript subscriptBlock: @escaping (Index) -> Element) {
		self.indicesImplementation = .static (indices);
		self.subscriptImplementation = subscriptBlock;
	}
}

extension ComputedCollection.Implementation: Collection {
	fileprivate var indices: Indices {
		return self.indicesImplementation.indices;
	}
	
	fileprivate var startIndex: Index {
		return self.indices.startIndex;
	}
	
	fileprivate var endIndex: Index {
		return self.indices.endIndex;
	}
	
	fileprivate subscript (position: Index) -> Element {
		return self.subscriptImplementation (position);
	}
	
	fileprivate func index (after i: Index) -> Index {
		return self.indices.index (after: i);
	}
}

extension ComputedCollection: Collection {
	internal var indices: Indices {
		return self.implementation.indices;
	}
	
	internal var startIndex: Index {
		return self.implementation.startIndex;
	}
	
	internal var endIndex: Index {
		return self.implementation.endIndex;
	}
	
	internal subscript (position: Index) -> Element {
		return self.implementation [position];
	}
	
	internal func index (after i: Index) -> Index {
		return self.implementation.index (after: i);
	}
}

extension ComputedCollection.Implementation: BidirectionalCollection where Indices: BidirectionalCollection {
	fileprivate func index (before i: Index) -> Index {
		return self.indices.index (before: i);
	}
}

extension ComputedCollection: BidirectionalCollection where Indices: BidirectionalCollection {
	internal func index (before i: Index) -> Index {
		return self.implementation.index (before: i);
	}
}

extension ComputedCollection.Implementation: RandomAccessCollection where Indices: RandomAccessCollection {}
extension ComputedCollection: RandomAccessCollection where Indices: RandomAccessCollection {}

internal struct ComputedIndices <Element> where Element: Comparable {
	private let managedIndices: [Element];
	internal let endIndex: Element;
	
	internal init (_ indices: [Element], end endIndex: Element) {
		self.managedIndices = indices;
		self.endIndex = endIndex;
	}
}

internal extension ComputedIndices {
	internal init <S> (_ indices: S, end endIndex: S.Element) where S: Sequence, S.Element == Element {
		self.init (Array (indices), end: endIndex);
	}
}

extension ComputedIndices: RandomAccessCollection {
	internal typealias Index = Element;
	internal typealias SubSequence = ComputedIndices;
	
	internal var startIndex: Element {
		return self.managedIndices.first ?? self.endIndex;
	}
	
	internal subscript (position: Index) -> Element {
		return position;
	}
	
	internal func index (after i: Index) -> Index {
		guard let indexIndex = self.managedIndices.index (of: i), indexIndex < self.managedIndices.count - 1 else {
			return self.endIndex;
		}
		return self.managedIndices [indexIndex + 1];
	}

	internal func index (before i: Element) -> Element {
		guard let indexIndex = self.managedIndices.index (of: i), indexIndex > 0 else {
			return self.startIndex;
		}
		return self.managedIndices [indexIndex - 1];
	}
}

internal extension ComputedIndices where Element: Strideable {
	fileprivate static var endIndexForEmptyCollection: Element {
		fatalError ("Cannot instantiate \(self) with empty indices because their element \(Element.self) is not trivially initializable");
	}
	
	internal init <S> (_ indices: S) where S: Sequence, S.Element == Element {
		self.init (Array (indices));
	}
	
	internal init (_ indices: [Element]) {
		self.init (indices, end: indices.last?.advanced (by: 1) ?? ComputedIndices.endIndexForEmptyCollection);
	}
}

internal extension ComputedIndices where Element: Strideable, Element: ExpressibleByNilLiteral {
	fileprivate static var endIndexForEmptyCollection: Element {
		return nil;
	}
}

internal extension ComputedIndices where Element: Strideable, Element: ExpressibleByBooleanLiteral {
	fileprivate static var endIndexForEmptyCollection: Element {
		return false;
	}
}

internal extension ComputedIndices where Element: Strideable, Element: ExpressibleByIntegerLiteral {
	fileprivate static var endIndexForEmptyCollection: Element {
		return 0;
	}
}

internal extension ComputedIndices where Element: Strideable, Element: ExpressibleByFloatLiteral {
	fileprivate static var endIndexForEmptyCollection: Element {
		return 0.0;
	}
}

internal extension ComputedIndices where Element: Strideable, Element: ExpressibleByStringLiteral {
	fileprivate static var endIndexForEmptyCollection: Element {
		return "";
	}
}

internal extension ComputedIndices where Element: Strideable, Element: ExpressibleByArrayLiteral {
	fileprivate static var endIndexForEmptyCollection: Element {
		return [];
	}
}

internal extension ComputedIndices where Element: Strideable, Element: ExpressibleByDictionaryLiteral {
	fileprivate static var endIndexForEmptyCollection: Element {
		return [:];
	}
}

internal extension ComputedIndices where Element: Strideable, Element: RangeReplaceableCollection {
	fileprivate static var endIndexForEmptyCollection: Element {
		return Element ();
	}
}

internal typealias ComputedArray <Index, Element> = ComputedCollection <Index, Element, ComputedIndices <Index>> where Index: Strideable;

extension ComputedCollection where Index: Strideable, Indices == ComputedIndices <Index> {
	internal init <S> (_ indices: S, subscript subscriptBlock: @escaping (Index) -> Element) where S: Sequence, S.Element == Index {
		self.init (indices: Indices (indices), subscript: subscriptBlock);
	}

	internal init (_ indices: [Index], subscript subscriptBlock: @escaping (Index) -> Element) {
		self.init (indices: Indices (indices), subscript: subscriptBlock);
	}
}

extension ComputedCollection where Index: Strideable, Index: ExpressibleByNilLiteral, Indices == ComputedIndices <Index> {
	internal init <S> (_ indices: S, subscript subscriptBlock: @escaping (Index) -> Element) where S: Sequence, S.Element == Index {
		self.init (indices: Indices (indices), subscript: subscriptBlock);
	}
	
	internal init (_ indices: [Index], subscript subscriptBlock: @escaping (Index) -> Element) {
		self.init (indices: Indices (indices), subscript: subscriptBlock);
	}
}

extension ComputedCollection where Index: Strideable, Index: ExpressibleByBooleanLiteral, Indices == ComputedIndices <Index> {
	internal init <S> (_ indices: S, subscript subscriptBlock: @escaping (Index) -> Element) where S: Sequence, S.Element == Index {
		self.init (indices: Indices (indices), subscript: subscriptBlock);
	}
	
	internal init (_ indices: [Index], subscript subscriptBlock: @escaping (Index) -> Element) {
		self.init (indices: Indices (indices), subscript: subscriptBlock);
	}
}

extension ComputedCollection where Index: Strideable, Index: ExpressibleByIntegerLiteral, Indices == ComputedIndices <Index> {
	internal init <S> (_ indices: S, subscript subscriptBlock: @escaping (Index) -> Element) where S: Sequence, S.Element == Index {
		self.init (indices: Indices (indices), subscript: subscriptBlock);
	}
	
	internal init (_ indices: [Index], subscript subscriptBlock: @escaping (Index) -> Element) {
		self.init (indices: Indices (indices), subscript: subscriptBlock);
	}
}

extension ComputedCollection where Index: Strideable, Index: ExpressibleByFloatLiteral, Indices == ComputedIndices <Index> {
	internal init <S> (_ indices: S, subscript subscriptBlock: @escaping (Index) -> Element) where S: Sequence, S.Element == Index {
		self.init (indices: Indices (indices), subscript: subscriptBlock);
	}
	
	internal init (_ indices: [Index], subscript subscriptBlock: @escaping (Index) -> Element) {
		self.init (indices: Indices (indices), subscript: subscriptBlock);
	}
}

extension ComputedCollection where Index: Strideable, Index: ExpressibleByStringLiteral, Indices == ComputedIndices <Index> {
	internal init <S> (_ indices: S, subscript subscriptBlock: @escaping (Index) -> Element) where S: Sequence, S.Element == Index {
		self.init (indices: Indices (indices), subscript: subscriptBlock);
	}
	
	internal init (_ indices: [Index], subscript subscriptBlock: @escaping (Index) -> Element) {
		self.init (indices: Indices (indices), subscript: subscriptBlock);
	}
}

extension ComputedCollection where Index: Strideable, Index: ExpressibleByArrayLiteral, Indices == ComputedIndices <Index> {
	internal init <S> (_ indices: S, subscript subscriptBlock: @escaping (Index) -> Element) where S: Sequence, S.Element == Index {
		self.init (indices: Indices (indices), subscript: subscriptBlock);
	}
	
	internal init (_ indices: [Index], subscript subscriptBlock: @escaping (Index) -> Element) {
		self.init (indices: Indices (indices), subscript: subscriptBlock);
	}
}

extension ComputedCollection where Index: Strideable, Index: ExpressibleByDictionaryLiteral, Indices == ComputedIndices <Index> {
	internal init <S> (_ indices: S, subscript subscriptBlock: @escaping (Index) -> Element) where S: Sequence, S.Element == Index {
		self.init (indices: Indices (indices), subscript: subscriptBlock);
	}
	
	internal init (_ indices: [Index], subscript subscriptBlock: @escaping (Index) -> Element) {
		self.init (indices: Indices (indices), subscript: subscriptBlock);
	}
}
