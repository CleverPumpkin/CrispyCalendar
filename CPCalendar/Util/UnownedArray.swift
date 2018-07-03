//
//  UnownedStorage.swift
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

internal struct UnownedStorage <Element> where Element: AnyObject {
	internal unowned let value: Element;
}

internal struct UnownedArray <Element> where Element: AnyObject {
	private var storage: [UnownedStorage <Element>];
}

internal struct UnownedDictionary <Key, Value> where Key: Hashable, Value: AnyObject {
	private var storage: [Key: UnownedStorage <Value>];
}

extension UnownedArray: MutableCollection, RangeReplaceableCollection {
	internal typealias Index = Array <Element>.Index;

	internal var startIndex: Index {
		return self.storage.startIndex;
	}
	
	internal var endIndex: Index {
		return self.storage.endIndex;
	}

	internal subscript (position: Index) -> Element {
		get {
			return self.storage [position].value;
		}
		set (newValue) {
			self.storage [position] = UnownedStorage (value: newValue);
		}
	}
	
	internal init () {
		self.storage = [];
	}
	
	internal func index (after i: Index) -> Index {
		return self.storage.index (after: i);
	}
	
	internal func index (before i: Index) -> Index {
		return self.storage.index (before: i);
	}
	
	internal mutating func replaceSubrange <C, R> (_ subrange: R, with newElements: C) where C: Collection, C.Element == Element, R: RangeExpression, R.Bound == Index {
		self.storage.replaceSubrange (subrange, with: newElements.map { UnownedStorage (value: $0) });
	}
}

extension UnownedDictionary: Collection, ExpressibleByDictionaryLiteral {
	internal typealias Index = Dictionary <Key, UnownedStorage <Value>>.Index;
	internal typealias Element = (key: Key, value: Value);
	
	internal var startIndex: Index {
		return self.storage.startIndex;
	}
	
	internal var endIndex: Index {
		return self.storage.endIndex;
	}
	
	internal init () {
		self.storage = [:];
	}
	
	internal init (dictionaryLiteral elements: (Key, Value)...) {
		self.storage = Dictionary (uniqueKeysWithValues: elements.map { (key: $0.0, value: UnownedStorage (value: $0.1) ) });
	}
	
	internal subscript (key: Key) -> Value? {
		get {
			return self.storage [key]?.value;
		}
		set {
			self.storage [key] = newValue.map { UnownedStorage (value: $0) };
		}
	}
	
	internal subscript (position: Index) -> (key: Key, value: Value) {
		let (key, value) = self.storage [position];
		return (key: key, value: value.value);
	}
	
	internal func index (after i: Index) -> Index {
		return self.storage.index (after: i);
	}
}
