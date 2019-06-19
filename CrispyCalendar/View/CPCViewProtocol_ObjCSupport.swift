//
//  CPCViewProtocol_ObjCSupport.swift
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

import UIKit

extension CPCMonthView {
	/// Exposes `CPCViewTitleStyle.customTemplate` to be used from Objective C code.
	@IBInspectable open dynamic var titleTemplate: String! {
		get { return self.titleStyle.rawValue }
		set { self.titleStyle = .customTemplate (newValue) }
	}

	/// Exposes `CPCViewTitleStyle.custom` to be used from Objective C code.
	@IBInspectable open dynamic var titleFormat: String! {
		get { return self.titleStyle.rawValue }
		set { self.titleStyle = .custom (newValue) }
	}
}

extension CPCMultiMonthsView {
	/// Exposes `CPCViewTitleStyle.customTemplate` to be used from Objective C code.
	@IBInspectable open dynamic var titleTemplate: String! {
		get { return self.titleStyle.rawValue }
		set { self.titleStyle = .customTemplate (newValue) }
	}
	
	/// Exposes `CPCViewTitleStyle.custom` to be used from Objective C code.
	@IBInspectable open dynamic var titleFormat: String! {
		get { return self.titleStyle.rawValue }
		set { self.titleStyle = .custom (newValue) }
	}
}

extension CPCCalendarView {
	/// Exposes `CPCViewTitleStyle.customTemplate` to be used from Objective C code.
	@IBInspectable open dynamic var titleTemplate: String! {
		get { return self.titleStyle.rawValue }
		set { self.titleStyle = .customTemplate (newValue) }
	}
	
	/// Exposes `CPCViewTitleStyle.custom` to be used from Objective C code.
	@IBInspectable open dynamic var titleFormat: String! {
		get { return self.titleStyle.rawValue }
		set { self.titleStyle = .custom (newValue) }
	}
}

/* fileprivate */ extension CPCViewTitleStyle {
	fileprivate static func customTemplate (_ template: String?) -> CPCViewTitleStyle {
		return template.map { self.customTemplate ($0) } ?? .default;
	}
}
