//
//  CPCCalendarUnitSymbol.swift
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

public enum CPCCalendarUnitSymbolStyle {
	case normal;
	case short;
	case veryShort;
	
	public static let `default` = normal;
}

public protocol CPCCalendarUnitSymbol {
	func symbol (style: CPCCalendarUnitSymbolStyle, standalone: Bool) -> String;
}

public extension CPCCalendarUnitSymbol {
	public func symbol () -> String {
		return self.symbol (style: .default, standalone: false);
	}
	
	func symbol (standalone: Bool) -> String {
		return self.symbol (style: .default, standalone: standalone);

	}
	
	func symbol (style: CPCCalendarUnitSymbolStyle) -> String {
		return self.symbol (style: style, standalone: false);
	}
}

internal protocol CPCCalendarUnitSymbolImpl: CPCCalendarUnit, CPCCalendarUnitSymbol {
	static func unitSymbols (calendar: Calendar, style: CPCCalendarUnitSymbolStyle, standalone: Bool) -> [String];
	
	var unitOrdinalValue: Int { get };
}

extension CPCCalendarUnitSymbolImpl {
	public func symbol (style: CPCCalendarUnitSymbolStyle, standalone: Bool) -> String {
		return Self.unitSymbols (calendar: self.calendar, style: style, standalone: standalone) [self.unitOrdinalValue];
	}
}
