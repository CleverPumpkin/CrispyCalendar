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

extension CPCViewSelection: CustomStringConvertible {
	public var description: String {
		switch (self) {
		case .none:
			return "none";
		case .single (nil):
			return "nil";
		case .single (.some (let day)):
			return "\(day.description)";
		case .range (let range):
			return "<Range: \(range.isEmpty ? "empty" : "\(range.lowerBound.description) ..< \(range.upperBound.description)")>";
		case .unordered (let days):
			return "<Unordered: \(days.isEmpty ? "empty" : "\(days.sorted ().map { $0.description }.joined (separator: ", "))")>";
		case .ordered (let days):
			return "<Ordered: \(days.isEmpty ? "empty" : "\(days.sorted ().map { $0.description }.joined (separator: ", "))")>";
		}
	}
}
