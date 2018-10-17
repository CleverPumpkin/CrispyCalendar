//
//  CPCViewSelectionConvenience.swift
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

public extension CPCViewSelection {
	public func isDaySelected (_ day: CPCDay) -> Bool {
		switch (self) {
		case .none:
			return false;
		case .single (let selectedDay):
			return (selectedDay == day);
		case .range (let selectedDays):
			return (selectedDays ~= day);
		case .unordered (let selectedDays):
			return selectedDays.contains (day);
		case .ordered (let selectedDays):
			return selectedDays.contains (day);
		}
	}
	
	public var isEmpty: Bool {
		switch (self) {
		case .none, .single (nil):
			return true;
		case .range (let days):
			return days.isEmpty;
		case .unordered (let days):
			return days.isEmpty;
		case .ordered (let days):
			return days.isEmpty;
		default:
			return false;
		}
	}
	
	private var selectedDays: Set <CPCDay> {
		switch (self) {
		case .none, .single (nil):
			return [];
		case .single (.some (let selectedDay)):
			return [selectedDay];
		case .range (let selectedDays):
			return Set (selectedDays);
		case .unordered (let selectedDays):
			return selectedDays;
		case .ordered (let selectedDays):
			return Set (selectedDays);
		}
	}
	
	public func difference (_ other: CPCViewSelection) -> Set <CPCDay> {
		return self.selectedDays.symmetricDifference (other.selectedDays);
	}
	
	public func clamped <R> (to datesRange: R) -> CPCViewSelection where R: CPCDateInterval {
		switch (self) {
		case .single (.some (let day)) where !datesRange.contains (day):
			return .single (nil)
		case .none, .single:
			return self;
		case .range (let range):
			let lowerBound = range.lowerBound, upperBound = range.upperBound;
			let clampedRange = (lowerBound.start ..< upperBound.start).clamped (to: datesRange);
			return .range (CPCDay (containing: clampedRange.lowerBound, calendarOf: lowerBound) ..< CPCDay (containing: clampedRange.upperBound, calendarOf: lowerBound));
		case .unordered (let days):
			return .unordered (days.filter { datesRange.contains ($0) });
		case .ordered (let days):
			return .ordered (days.filter { datesRange.contains ($0) });
		}
	}
}

public extension CPCViewSelection {
	public static func += (lhs: inout CPCViewSelection, rhs: CPCViewSelection) {
		switch (lhs, rhs) {
		case (let lhs, let rhs) where lhs == rhs:
			return;
		
		case (.none, _), (.single (nil), _):
			lhs = rhs;
			
		case (_, .none), (_, .single (nil)), (_, .unordered ([])), (_, .ordered ([])):
			return;
		case (_, .range (let days)) where days.isEmpty:
			return;

		case (.range (let days), .single (.some (let day))) where days.isEmpty:
			lhs = .range (day ..< day.next);
		case (.range (let days), _) where days.isEmpty:
			lhs = rhs;

		case (.single (.some (let day1)), .single (.some (let day2))):
			if day1.distance (to: day2).magnitude == 1 {
				lhs = .range (Range (bounds: day1, day2));
			} else {
				lhs = .unordered ([day1, day2]);
			}
			
		case (.range (let range), .single (.some (let day))):
			if let contiguousRange = range.contiguousUnion (day) {
				lhs = .range (contiguousRange);
			} else {
				lhs = .unordered (Set ([day] + range));
			}
		
		case (.single (.some /*(let day)*/), .range /*(let range)*/):
			lhs = rhs + lhs; // FIXME: merge with previous parrent when `SR-5377` is fixed.
			
		case (.range (let range1), .range (let range2)):
			if let contiguousRange = range1.contiguousUnion (range2) {
				lhs = .range (contiguousRange);
			} else {
				lhs = .unordered (Set (Array (range1) + range2));
			}
			
		case (.range (let range), .unordered (let days)):
			lhs = .unordered (days.union (range));
			
		case (.unordered /*(let days)*/, .range /*(let range)*/):
			lhs = rhs + lhs; // FIXME: merge with previous parrent when `SR-5377` is fixed.
		
		case (.range (let range), .ordered (let days)):
			lhs = .ordered (range.filter { !days.contains ($0) } + days);
			
		case (.ordered (let days), .range (let range)):
			lhs = .ordered (days.filter { !range.contains ($0) } + range);
			
		case (.unordered (let days), .single (.some (let day))):
			lhs = .unordered (days.union (day));
			
		case  (.single (.some /*(let day)*/), .unordered /*(let days)*/):
			lhs = rhs + rhs; // FIXME: merge with previous parrent when `SR-5377` is fixed.
			
		case (.unordered (let days1), .unordered (let days2)):
			lhs = .unordered (days1.union (days2));
			
		case (.ordered (let days), .single (.some (let day))):
			lhs = .ordered (days.filter { $0 != day } + day);
			
		case (.single (.some (let day)), .ordered (let days)):
			lhs = .ordered (days.contains (day) ? days : day + days);
			
		case (.unordered (let days1), .ordered (let days2)):
			lhs = .ordered (days2 + days1);
			
		case (.ordered (let days1), .unordered (let days2)):
			lhs = .unordered (days2.union (days1));
			
		case (.ordered (let days1), .ordered (let days2)):
			lhs = .ordered (days1.filter { !days2.contains ($0) } + days2);
		}
	}
	
	public static func + (lhs: CPCViewSelection, rhs: CPCViewSelection) -> CPCViewSelection {
		var result = lhs;
		result += rhs;
		return result;
	}

	public static func -= (lhs: inout CPCViewSelection, rhs: CPCViewSelection) {
		switch (lhs, rhs) {
		case (_, .none), (.none, _), (_, .single (nil)), (.single (nil), _), (.unordered ([]), _), (_, .unordered ([])), (.ordered ([]), _), (.ordered ([]), _):
			return;
	
		case (.single (.some (let day)), let subtracted) where subtracted.isDaySelected (day):
			lhs = .single (nil);
		case (.single, _):
			return;
			
		case (.range (let range1), .range (let range2)):
			switch (range1.contains (range2.lowerBound), range1.contains (range2.upperBound)) {
			case (false, false) where range2.contains (range1.lowerBound):
				lhs = .range (range1.lowerBound ..< range1.lowerBound);
			case (false, false):
				break;
			case (false, true):
				lhs = .range (range2.lowerBound ..< range1.upperBound);
			case (true, false):
				lhs -= .range (range1.upperBound ..< range2.lowerBound);
			case (true, true):
				if range1.lowerBound == range2.lowerBound {
					lhs = .range (range2.upperBound ..< range1.upperBound);
				} else if range1.upperBound == range2.upperBound {
					lhs = .range (range1.lowerBound ..< range2.lowerBound);
				} else {
					lhs = .unordered (Set (Array (range1.lowerBound ..< range2.lowerBound) + (range2.upperBound ..< range1.upperBound)));
				}
			}
			
		case (.range (let range), .single (.some (let day))):
			guard range.contains (day) else {
				return;
			}
			if (day.next == range.upperBound) {
				lhs = .range (range.lowerBound ..< day);
			} else if (day == range.lowerBound) {
				lhs = .range (day.next ..< range.upperBound);
			} else {
				lhs = .unordered (Set (range.filter { $0 != day }));
			}
		case (.range (let range), .unordered (let days)):
			lhs = .unordered (Set (range).subtracting (days))
		case (.range (let range), .ordered (let days)):
			lhs = .ordered (range.filter { !days.contains ($0) });

		case (.unordered (let days), .single (.some (let day))):
			lhs = .unordered (days.subtracting (day));
		case (.unordered (let days), .range (let range)):
			lhs = .unordered (days.subtracting (range));
		case (.unordered (let days1), .unordered (let days2)):
			lhs = .unordered (days1.subtracting (days2));
		case (.unordered (let days1), .ordered (let days2)):
			lhs = .unordered (days1.subtracting (days2));

		case (.ordered (let days), .single (.some (let day))):
			lhs = .ordered (days.filter { $0 != day });
		case (.ordered (let days), .range (let range)):
			lhs = .ordered (days.filter { !range.contains ($0) });
		case (.ordered (let days1), .unordered (let days2)):
			lhs = .ordered (days1.filter { !days2.contains ($0) });
		case (.ordered (let days1), .ordered (let days2)):
			lhs = .ordered (days1.filter { !days2.contains ($0) });
		}
	}

	public static func - (lhs: CPCViewSelection, rhs: CPCViewSelection) -> CPCViewSelection {
		var result = lhs;
		result -= rhs;
		return result;
	}
}

extension CPCViewProtocol {
	public var allowsSelection: Bool {
		get {
			return self.selection != .none;
		}
		set {
			guard newValue else {
				return self.selection = .none;
			}
			self.selection = .single (nil);
		}
	}
	
	public func select (_ day: CPCDay) {
		self.selection += .single (day);
	}
	
	public func select <R> (_ range: R) where R: CPCDateInterval {
		self.selection += .range (CPCDay (containing: range.start) ..< CPCDay (containing: range.end));
	}
	
	public func select <R> (_ range: R) where R: RangeExpression, R.Bound == CPCDay {
		self.selection += .range (range.unwrapped);
	}
	
	public func select <R> (_ range: R) where R: RangeExpression, R.Bound == CPCDay, R: RandomAccessCollection, R.Element == CPCDay {
		self.selection += .range (range.unwrapped);
	}
	
	public func select <C> (_ ordered: C) where C: RandomAccessCollection, C.Element == CPCDay {
		self.selection += .ordered (Array (ordered));
	}
	
	public func select <C> (_ unordered: C) where C: Collection, C: SetAlgebra, C.Element == CPCDay {
		self.selection += .unordered (Set (unordered));
	}
	
	public func deselect (_ day: CPCDay) {
		self.selection -= .single (day);
	}
	
	public func deselect <R> (_ range: R) where R: CPCDateInterval {
		self.selection -= .range (CPCDay (containing: range.start) ..< CPCDay (containing: range.end));
	}
	
	public func deselect <R> (_ range: R) where R: RangeExpression, R.Bound == CPCDay {
		self.selection -= .range (range.unwrapped);
	}
	
	public func deselect <R> (_ range: R) where R: RangeExpression, R.Bound == CPCDay, R: RandomAccessCollection, R.Element == CPCDay {
		self.selection -= .range (range.unwrapped);
	}
	
	public func deselect <C> (_ ordered: C) where C: RandomAccessCollection, C.Element == CPCDay {
		self.selection -= .ordered (Array (ordered));
	}
	
	public func deselect <C> (_ unordered: C) where C: Collection, C: SetAlgebra, C.Element == CPCDay {
		self.selection -= .unordered (Set (unordered));
	}
}
