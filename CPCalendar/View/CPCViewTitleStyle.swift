//
//  CPCViewTitleStyle.swift
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

public struct CPCViewTitleStyle: Equatable, Hashable, RawRepresentable, ExpressibleByStringLiteral {
	public typealias RawValue = String;
	public typealias StringLiteralType = String;

	public static let none = CPCViewTitleStyle.custom;
	
	public static var short: CPCViewTitleStyle {
		return .customTemplate (__CPCViewTitleStyle.short.rawValue);
	};
	public static var medium: CPCViewTitleStyle {
		return .customTemplate (__CPCViewTitleStyle.medium.rawValue);
	};
	public static var long: CPCViewTitleStyle {
		return .customTemplate (__CPCViewTitleStyle.long.rawValue);
	};
	public static var full: CPCViewTitleStyle {
		return .customTemplate (__CPCViewTitleStyle.full.rawValue);
	};
	
	public static var `default`: CPCViewTitleStyle {
		return .full;
	}
	
	public static func customTemplate (_ template: String, locale: Locale = .current) -> CPCViewTitleStyle! {
		return CPCViewTitleStyle (templateValue: template, locale: locale);
	}

	public static func custom (_ format: String) -> CPCViewTitleStyle {
		return CPCViewTitleStyle (rawValue: format);
	}
	
	public let rawValue: String;
	
	public var hashValue: Int {
		return self.rawValue.hashValue;
	}
	
	public init (rawValue: String) {
		self.rawValue = rawValue;
	}
	
	public init (stringLiteral: String) {
		if let result = CPCViewTitleStyle (templateValue: stringLiteral) {
			self = result;
		} else {
			self.init (rawValue: stringLiteral);
		}
	}
	
	public init? (templateValue template: String, locale: Locale = .current) {
		guard let rawValue = DateFormatter.dateFormat (fromTemplate: template, options: 0, locale: locale) else {
			return nil;
		}
		self.init (rawValue: rawValue);
	}
} 
