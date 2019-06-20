//
//  CPCViewSelection.swift
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

import os
import Swift

/// A value that describes view selection mode and currently selected days simultaneously.
public enum CPCViewSelection: Equatable {
	/// Selection is disabled.
	case none;
	/// Single day selection mode; associated value holds currently selected day or `nil` if selection is empty.
	case single (CPCDay?);
	/// Range of dates selection mode; associated value holds currently selected days range (possibly empty).
	case range (CountableRange <CPCDay>);
	/// Arbitrary set of dates selection mode; associated value holds unordered collection of selected dates (possibly empty).
	case unordered (Set <CPCDay>);
	/// Arbitrary array of dates selection mode; associated value holds collection of selected dates (possibly empty) ordered the same way that user did pick them.
	case ordered ([CPCDay]);
}

#if DEBUG
private func logSelectionIsEmptyInconsistencyOnce () {
	struct OnceWrapper {
		fileprivate static let token: Void = {
			os_log ("[CrispyCalendar] Non-empty selection should not produce an empty description, but it just happened. Break on %@ to debug.", type: .error, #function);
		} ();
	}
	
	_ = OnceWrapper.token;
}
#endif

/* fileprivate */ extension Collection where Element: CustomStringConvertible {
	fileprivate func joinedDescription (separator: String = ", ", edgeDelimiters: (String, String)? = nil) -> String {
		let joinedElementDescriptions = self.map { $0.description }.joined (separator: separator);
		guard let edgeDelimiters = edgeDelimiters else {
			return joinedElementDescriptions;
		}
		return edgeDelimiters.0 + joinedElementDescriptions + edgeDelimiters.1;
	}
}

extension CPCViewSelection: CustomStringConvertible, CustomDebugStringConvertible {
	public var description: String {
		switch (self) {
		case .single (.some (let day)):
			return day.description;
		case .range (let days):
			return "[\(days.lowerBound), \(days.upperBound))";
		case .unordered (let days):
			return days.joinedDescription (edgeDelimiters: ("{", "}"));
		case .ordered (let days):
			return days.joinedDescription ();
		default:
#if DEBUG
			if !self.isEmpty {
				logSelectionIsEmptyInconsistencyOnce ();
			}
#endif
			return "";
		}
	}
	
	public var debugDescription: String {
		switch (self) {
		case .none:
			return "<None>";
		case .single (let day):
			return "<Single \(day.debugDescription)>";
		case .range (let range):
			return "<Range: \(range.debugDescription)>";
		case .unordered (let days):
			return "<Unordered: \(days.debugDescription)>";
		case .ordered (let days):
			return "<Ordered: \(days.debugDescription)>";
		}
	}
}

extension CPCViewSelection: ReferenceConvertible {
	public typealias ReferenceType = _ObjectiveCType;
	public typealias _ObjectiveCType = __CPCViewSelection;

	public func _bridgeToObjectiveC () -> __CPCViewSelection {
		switch (self) {
		case .none:
			return __CPCViewSelection.null ();
		case .single (let day):
			return __CPCViewSelection (singleDay: day?.start, calendar: day?.calendar);
		case .range (let range):
			return __CPCViewSelection (datesRange: DateInterval (start: range.lowerBound.start, end: range.upperBound.start), calendar: range.lowerBound.calendar);
		case .unordered (let days):
			return __CPCViewSelection (unorderedDatesSet: Set (days.map { $0.start }), calendar: days.first?.calendar);
		case .ordered (let days):
			return __CPCViewSelection (orderedDatesSet: NSOrderedSet (array: days.map { $0.start }), calendar: days.first?.calendar);
		}
	}
	
	public static func _forceBridgeFromObjectiveC (_ source: __CPCViewSelection, result: inout CPCViewSelection?) {
		guard !source.isNull else {
			return result = CPCViewSelection.none;
		}
		if let calendar = source.calendar {
			if let orderedDates = source.orderedDates {
				result = .ordered (orderedDates.map { CPCDay (containing: $0 as! Date, calendar: calendar) });
			} else if let unorderedDates = source.unorderedDates {
				result = .unordered (Set (unorderedDates.map { CPCDay (containing: $0, calendar: calendar) }));
			} else if let datesInterval = source.datesInterval {
				result = .range (CPCDay (containing: datesInterval.start, calendar: calendar) ..< CPCDay (containing: datesInterval.end, calendar: calendar));
			} else {
				result = .single (source.singleDay.map { CPCDay (containing: $0, calendar: calendar) });
			}
		} else {
			if source.orderedDates != nil {
				result = .ordered ([]);
			} else if source.unorderedDates != nil {
				result = .unordered ([]);
			} else {
				result = .single (nil);
			}
		}
	}
	
	public static func _conditionallyBridgeFromObjectiveC (_ source: __CPCViewSelection, result: inout CPCViewSelection?) -> Bool {
		self._forceBridgeFromObjectiveC (source, result: &result);
		return true;
	}
	
	public static func _unconditionallyBridgeFromObjectiveC (_ source: __CPCViewSelection?) -> CPCViewSelection {
		var result: CPCViewSelection?;
		if let source = source {
			self._forceBridgeFromObjectiveC (source, result: &result);
		}
		return result ?? .none;
	}
}
