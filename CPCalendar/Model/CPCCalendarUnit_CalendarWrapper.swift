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
	private static var instances = UnfairThreadsafeStorage (UnownedDictionary <Calendar, CPCCalendarWrapper> ());
	
	/// Wrapped Calendar instance
	internal let calendar: Calendar;
	private let calendarHashValue: Int;
	
#if swift(>=4.2)
	internal func hash (into hasher: inout Hasher) {
		hasher.combine (self.calendarHashValue);
	}
#else
	internal var hashValue: Int {
		return self.calendarHashValue;
	}
#endif

	internal var unitSpecificCaches = UnfairThreadsafeStorage ([ObjectIdentifier: UnitSpecificCacheProtocol] ());

	internal static func == (lhs: CPCCalendarWrapper, rhs: CPCCalendarWrapper) -> Bool {
		return (lhs === rhs);
	}
	
	fileprivate static func wrap (_ calendar: Calendar) -> CPCCalendarWrapper {
		return self.instances.withMutableStoredValue {
			if let existingWrapper = $0 [calendar] {
				return existingWrapper;
			}
			
			let wrapper = CPCCalendarWrapper (calendar);
			$0 [calendar] = wrapper;
			return wrapper;
		};
	}
	
	/// Initializes a new CalendarWrapper
	///
	/// - Parameter calendar: Calendar to wrap
	private init (_ calendar: Calendar) {
		self.calendar = calendar;
		self.calendarHashValue = calendar.hashValue;
	}
	
	deinit {
		CPCCalendarWrapper.instances.withMutableStoredValue {
			$0 [self.calendar] = nil;
		};
	}
}

public extension Calendar {
	internal func wrapped () -> CPCCalendarWrapper {
		return CPCCalendarWrapper.wrap (self);
	}
}
