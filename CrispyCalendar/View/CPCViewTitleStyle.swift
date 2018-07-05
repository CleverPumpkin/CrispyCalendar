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

/// A value that holds information about formatting month titles.
public struct CPCViewTitleStyle: Hashable, RawRepresentable, ExpressibleByStringLiteral {
	public typealias RawValue = String;
	public typealias StringLiteralType = String;

	/// Month titles are not rendered.
	public static let none = CPCViewTitleStyle.custom;
	
	/// Short title format: one-digit month number and full year.
	public static var short: CPCViewTitleStyle {
		return .customTemplate (__CPCViewTitleStyle.short.rawValue);
	};
	/// Medium title format: two-digit zero-padded month number and full year.
	public static var medium: CPCViewTitleStyle {
		return .customTemplate (__CPCViewTitleStyle.medium.rawValue);
	};
	/// Long title format: abbreviated month name and full year.
	public static var long: CPCViewTitleStyle {
		return .customTemplate (__CPCViewTitleStyle.long.rawValue);
	};
	/// Full title format: full month name and full year.
	public static var full: CPCViewTitleStyle {
		return .customTemplate (__CPCViewTitleStyle.full.rawValue);
	};
	
	/// Default month title format, which is used when no format was explicitly set.
	public static var `default`: CPCViewTitleStyle {
		return .full;
	}
	
	/// Create a new month title format using date format template.
	///
	/// - Parameters:
	///   - template: Date format template compatible with DateFormatter.
	///   - locale: Locale to evaluate format template. Defaults to current locale.
	/// - Returns: Month title format that matches supplied parameters or `nil` if format template is invalid.
	public static func customTemplate (_ template: String, locale: Locale = .current) -> CPCViewTitleStyle! {
		return CPCViewTitleStyle (templateValue: template, locale: locale);
	}

	/// Create a new month title format using exact date format.
	///
	/// - Parameter format: Date format to use for month title.
	/// - Returns: Month title format that uses exact date `format`.
	public static func custom (_ format: String) -> CPCViewTitleStyle {
		return CPCViewTitleStyle (rawValue: format);
	}
	
	public let rawValue: String;
	
	public init (rawValue: String) {
		self.rawValue = rawValue;
	}
	
	/// Creates a new month title format from a string literal.
	///
	/// Firstly, given `stringLiteral` is evaluated as a date format template with current locale.
	/// If this evaluation fails, `stringLiteral` is used as an exact date format.
	///
	/// - Parameter stringLiteral: Requested date template format or an exact date format.
	public init (stringLiteral: String) {
		if let result = CPCViewTitleStyle (templateValue: stringLiteral) {
			self = result;
		} else {
			self.init (rawValue: stringLiteral);
		}
	}
	
	/// Create a new month title format using date format template.
	///
	/// - Parameters:
	///   - template: Date format template compatible with DateFormatter.
	///   - locale: Locale to evaluate format template. Defaults to current locale.
	public init? (templateValue template: String, locale: Locale = .current) {
		guard let rawValue = DateFormatter.dateFormat (fromTemplate: template, options: 0, locale: locale) else {
			return nil;
		}
		self.init (rawValue: rawValue);
	}
} 
