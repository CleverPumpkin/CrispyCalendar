//
//  CPCDatesRange.swift
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

public protocol CPCDateInterval: RangeExpression where Bound == Date {
	var start: Date { get }
	var end: Date { get }
	var duration: TimeInterval { get }
	
	func contains (_ date: Date) -> Bool;
	func contains <R> (_ dateInterval: R) -> Bool where R: RangeExpression, R.Bound == Date;
	func contains <R> (_ dateInterval: R) -> Bool where R: CPCDateInterval;
}

public protocol CPCDateIntervalInitializable: CPCDateInterval {
	init (_ date: Date);
	init <R> (_ other: R) where R: RangeExpression, R.Bound == Date;
	init <R> (_ other: R) where R: CPCDateInterval;
	
	func clamped <R> (to: R) -> Self where R: RangeExpression, R.Bound == Date;
	func clamped <R> (to: R) -> Self where R: CPCDateInterval;
}

public extension CPCDateInterval {
	public var duration: TimeInterval {
		return self.end.timeIntervalSince (self.start);
	}
	
	public func relative <C> (to collection: C) -> Range <Date> where C: Collection, C.Index == Date {
		return self.start ..< self.end;
	}
	
	public func contains (_ date: Date) -> Bool {
		return !((date < self.start) || (date >= self.end));
	}

	public func contains <R> (_ dateInterval: R) -> Bool where R: RangeExpression, R.Bound == Date {
		return self.contains (dateInterval.unwrapped);
	}

	public func contains <R> (_ dateInterval: R) -> Bool where R: CPCDateInterval {
		return ((dateInterval.start >= self.start) && (dateInterval.end <= self.end));
	}
}

public extension CPCDateInterval where Self: Strideable {
	public var prev: Self {
		return self.advanced (by: -1);
	}
	
	public var next: Self {
		return self.advanced (by: 1);
	}
}

public extension CPCDateIntervalInitializable {
	public init (_ date: Date) {
		self.init (date ..< date);
	}
	
	public init <R> (_ other: R) where R: RangeExpression, R.Bound == Date {
		self.init (other.unwrapped);
	}
	
	public func clamped <R> (to other: R) -> Self where R: RangeExpression, R.Bound == Date {
		return self.clamped (to: other.unwrapped);
	}
	
	public func clamped <R> (to other: R) -> Self where R: CPCDateInterval {
		let selfStart = self.start, selfEnd = self.end, otherStart = other.start, otherEnd = other.end;
		if (selfStart >= otherEnd) {
			return Self (otherEnd ..< otherEnd);
		} else if (selfEnd <= otherStart) {
			return Self (otherStart ..< otherStart);
		}
		
		switch (selfStart < otherStart, selfEnd > otherEnd) {
		case (false, false):
			return self;
		case (true, false):
			return Self (otherStart ..< selfEnd);
		case (false, true):
			return Self (selfStart ..< otherEnd);
		case (true, true):
			return Self (other);
		}
	}
}

extension Range: CPCDateInterval where Bound == Date {
	public var start: Date {
		return self.lowerBound;
	}
	
	public var end: Date {
		return self.upperBound;
	}
}

extension Range: CPCDateIntervalInitializable where Bound == Date {
	public init <R> (_ other: R) where R: CPCDateInterval {
		self.init (uncheckedBounds: (lower: other.start, upper: other.end));
	}
}

extension ClosedRange: CPCDateInterval where Bound == Date {
	public var start: Date {
		return self.lowerBound;
	}
	
	public var end: Date {
		return Date (timeIntervalSinceReferenceDate: self.upperBound.timeIntervalSinceReferenceDate.nextUp);
	}
}

extension ClosedRange: CPCDateIntervalInitializable where Bound == Date {
	public init <R> (_ other: R) where R: CPCDateInterval {
		self.init (uncheckedBounds: (lower: other.start, upper:  Date (timeIntervalSinceReferenceDate: other.end.timeIntervalSinceReferenceDate.nextDown)));
	}
}

extension DateInterval: CPCDateIntervalInitializable {
	public init <R> (_ other: R) where R: CPCDateInterval {
		self.init (start: other.start, end: other.end);
	}
}
