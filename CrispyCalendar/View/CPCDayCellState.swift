//
//  CPCDayCellState.swift
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

#if !swift(>=4.2)
/// A type that provides a collection of all of its values.
public protocol CaseIterable {
	/// A type that can represent a collection of all values of this type.
	associatedtype AllCases = [Self] where AllCases: Collection AllCases.Element == Self;

	/// A collection of all values of this type.
	public static var allCases: AllCases { get }
}
#endif

extension CPCDayCellState: Hashable {
#if swift(>=4.2)
	public func hash (into hasher: inout Hasher) {
		hasher.combine (self.rawValue);
	}
#else
	public var hashValue: Int {
		return self.rawValue;
	}
#endif
}

extension CPCDayCellState: CaseIterable {
	public typealias AllCases = [CPCDayCellState];
	
	public static let allCases = (0 ... __CPCDayCellStateCompressedMask).map {
		return CPCDayCellState (compresedIndex: $0);
	};
}

internal extension CPCDayCellState {
	internal var isCompressible: Bool {
		return __CPCDayCellStateIsCompressible (self);
	}
	
	internal var compressedIndex: Int {
		return __CPCDayCellStateGetPerfectHash (self);
	}
	
	internal init (compresedIndex: Int) {
		self = __CPCDayCellStateFromPerfectHash (compresedIndex);
	}
}
