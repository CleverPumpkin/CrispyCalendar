//
//  CPCCalendarUnitBackingType.swift
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

/// Common protocol for types that are suitable as backing storage of `CPCCalendarUnit` instances.
internal protocol CPCCalendarUnitBackingType: Hashable {
	/// Type for which this one serves as a backing storage.
	associatedtype BackedType where BackedType: CPCCalendarUnit;

	/// Creates a new storage for a calendar unit that contains a specific date.
	///
	/// - Parameters:
	///   - date: The date that should be contained in the backed calendar unit.
	///   - calendar: Calendar to perform calculations with.
	init (containing date: Date, calendar: Calendar);
	/// Get an earliest date that is contained in a backed calendar unit.
	///
	/// - Parameter calendar: Calendar to perform calculations with.
	/// - Returns: Earliest date of the represented calendar unit.
	func startDate (using calendar: Calendar) -> Date;

	/// Calculate distance between this value and other one, measured in the unit's durations.
	///
	/// - Parameters:
	///   - other: An instance of backing value to calculate distance to.
	///   - calendar: Calendar to perform calculations with.
	/// - Returns: Number of represented calendar units between starts of corresponding date intervals.
	func distance (to other: Self, using calendar: Calendar) -> Int;
	/// Calculate a backing value with specific distance from represented one.
	///
	/// - Parameters:
	///   - value: Distance from this value.
	///   - calendar: Calendar to perform calculations with.
	/// - Returns: Instance of backing value for which represented unit's `start` date is advanced by `value` unit durations.
	func advanced (by value: Int, using calendar: Calendar) -> Self;
}

/// Expresses that a type can be initialized using `DateComponents`.
internal protocol ExpressibleByDateComponents {
	/// Collection of `Calendar.Component`s that are required for proper initialization of this type's instances.
	static var requiredComponents: Set <Calendar.Component> { get };
	
	/// Creates a new instance from `DateComponents`.
	///
	/// - Parameter dateComponents: Date components to initialize from.
	init (_ dateComponents: DateComponents);
}

/// Expresses that a type can be represented as `DateComponents`.
internal protocol DateComponentsConvertible {
	/// Convert instance to a `DateComponents`.
	///
	/// - Parameter calendar: Calendar for resulting components.
	/// - Returns: Newly created `DateComponents` containing values from this instance.
	func dateComponents (_ calendar: Calendar) -> DateComponents;
}

extension CPCCalendarUnitBackingType where Self: ExpressibleByDateComponents {
	internal init (containing date: Date, calendar: Calendar) {
		self.init (calendar.dateComponents (Self.requiredComponents, from: date));
	}
}

extension CPCCalendarUnitBackingType where Self: DateComponentsConvertible {
	internal func startDate (using calendar: Calendar) -> Date {
		return guarantee (self.dateComponents (calendar).date);
	}
	
	internal func distance (to other: Self, using calendar: Calendar) -> Int {
		let selfComps = self.dateComponents (calendar), otherComps = other.dateComponents (calendar), backedUnit = BackedType.representedUnit;
		return guarantee (calendar.dateComponents ([backedUnit], from: selfComps, to: otherComps).value (for: backedUnit));
	}
}

extension CPCCalendarUnitBackingType where Self: ExpressibleByDateComponents, Self: DateComponentsConvertible {
	internal func advanced (by value: Int, using calendar: Calendar) -> Self {
		guard (value != 0) else {
			return self;
		}
		
		let advancedUnitStart = guarantee (calendar.date (byAdding: BackedType.representedUnit, value: value, to: self.startDate (using: calendar)));
		return Self (calendar.dateComponents (Self.requiredComponents, from: advancedUnitStart));
	}
}
