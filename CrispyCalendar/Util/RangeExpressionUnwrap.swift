//
//  RangeExpressionUnwrap.swift
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

private protocol RangeExpressionUnwrap: RandomAccessCollection where Index == Element {}

extension RangeExpressionUnwrap {
	fileprivate subscript (position: Index) -> Index {
		return position;
	}
}

extension RangeExpressionUnwrap where Index: BinaryInteger {
	fileprivate func index (after i: Index) -> Index {
		return i + 1;
	}
	
	fileprivate func index (before i: Index) -> Index {
		return i - 1;
	}
}

extension RangeExpressionUnwrap where Index: FixedWidthInteger {
	fileprivate var startIndex: Index {
		return Index.min;
	}
	
	fileprivate var endIndex: Index {
		return Index.max;
	}
}

extension RangeExpressionUnwrap where Index == Date {
	fileprivate var startIndex: Index {
		return Date.distantPast;
	}
	
	fileprivate var endIndex: Index {
		return Date.distantFuture;
	}

	fileprivate func index (after i: Index) -> Index {
		return Date (timeIntervalSinceReferenceDate: i.timeIntervalSinceReferenceDate.nextUp);
	}
	
	fileprivate func index (before i: Index) -> Index {
		return Date (timeIntervalSinceReferenceDate: i.timeIntervalSinceReferenceDate.nextDown);
	}
}

extension RangeExpressionUnwrap where Index == CPCDay {
	fileprivate var startIndex: Index {
		return CPCDay (containing: .distantPast);
	}
	
	fileprivate var endIndex: Index {
		return CPCDay (containing: .distantFuture);
	}
	
	fileprivate func index (after i: Index) -> Index {
		return i.next;
	}
	
	fileprivate func index (before i: Index) -> Index {
		return i.prev;
	}
}

extension RangeExpression where Bound: FixedWidthInteger {
	internal var unwrapped: Range <Bound> {
		return self.relative (to: Bound.min ..< Bound.max);
	}
}

fileprivate struct DateRangeExpressionUnwrap: RangeExpressionUnwrap {
	fileprivate typealias Index = Date;
}

extension RangeExpression where Bound == Date {
	internal var unwrapped: Range <Bound> {
		return self.relative (to: DateRangeExpressionUnwrap ());
	}
}

fileprivate struct CPCDayRangeExpressionUnwrap: RangeExpressionUnwrap {
	fileprivate typealias Index = CPCDay;
}

extension RangeExpression where Bound == CPCDay {
	internal var unwrapped: Range <Bound> {
		return self.relative (to: CPCDayRangeExpressionUnwrap ());
	}
}
