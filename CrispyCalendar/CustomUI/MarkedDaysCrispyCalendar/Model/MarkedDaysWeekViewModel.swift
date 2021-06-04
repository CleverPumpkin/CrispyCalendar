//
//  MarkedDaysWeekViewModel.swift
//  Copyright © 2021 Cleverpumpkin, Ltd. All rights reserved.
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

public struct MarkedDaysWeekViewModel {
	public let backgroundColor: UIColor
	public let textColor: UIColor
	public let weekEndColor: UIColor
	public let borderColor: UIColor
	
	public init(
		weekViewBackgroundColor: UIColor,
		weekViewTextColor: UIColor,
		weekViewWeekEndColor: UIColor,
		weekViewBorderColor: UIColor
	) {
		self.backgroundColor = weekViewBackgroundColor
		self.textColor = weekViewTextColor
		self.weekEndColor = weekViewWeekEndColor
		self.borderColor = weekViewBorderColor
	}
}

extension MarkedDaysWeekViewModel {
	static public var demoModel: MarkedDaysWeekViewModel {
		return MarkedDaysWeekViewModel(
			weekViewBackgroundColor: .white,
			weekViewTextColor: .black,
			weekViewWeekEndColor: .red,
			weekViewBorderColor: .lightGray
		)
	}
}
