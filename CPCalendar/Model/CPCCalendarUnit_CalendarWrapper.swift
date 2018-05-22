//
//  CPCCalendarUnit_CalendarWrapper.swift
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

/// Wraps a Calendar instance into a reference type to enable short-circuit equality evaluation using identity operator.
internal final class CPCCalendarWrapper: Hashable {
	/// Wrapped Calendar instance
	internal let calendar: Calendar;
	internal let hashValue: Int;
	
	internal static func == (lhs: CPCCalendarWrapper, rhs: CPCCalendarWrapper) -> Bool {
		return (lhs === rhs) || (lhs.calendar == rhs.calendar);
	}

	/// Initializes a new CalendarWrapper
	///
	/// - Parameter calendar: Calendar to wrap
	fileprivate init (_ calendar: Calendar) {
		self.calendar = calendar;
		self.hashValue = calendar.hashValue;
	}
}

extension CPCCalendarUnit {
	internal typealias CalendarWrapper = CPCCalendarWrapper;

	/// Creates a new calendar unit that contains a given date according to supplied calendar.
	///
	/// - Parameters:
	///   - date: Date to perform calculations for.
	///   - calendar: Calendar to perform calculations with.
	public init (containing date: Date, calendar: Calendar) {
		self.init (containing: date, calendar: CalendarWrapper (calendar));
	}
}
