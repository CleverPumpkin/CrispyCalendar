//
//  MarkedDaysTitleModel.swift
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

public struct MarkedDaysTitleModel {
	public let titleColor: UIColor
	public let disableTitleColor: UIColor
	public let weekendsTitleColor: UIColor
	public let daySelectedTitleColor: UIColor
	public let titleFont: UIFont
	
	public init(
		dayTitleColor: UIColor,
		dayDisableTitleColor: UIColor,
		dayWeekendsTitleColor: UIColor,
		daySelectedTitleColor: UIColor,
		dayTitleFont: UIFont
	) {
		self.titleColor = dayTitleColor
		self.disableTitleColor = dayDisableTitleColor
		self.weekendsTitleColor = dayWeekendsTitleColor
		self.daySelectedTitleColor = daySelectedTitleColor
		self.titleFont = dayTitleFont
	}
}

extension MarkedDaysTitleModel {
	static public var demoModel: MarkedDaysTitleModel {
		return MarkedDaysTitleModel(
			dayTitleColor: .black,
			dayDisableTitleColor: .lightGray,
			dayWeekendsTitleColor: .black,
			daySelectedTitleColor: .white,
			dayTitleFont: .systemFont(ofSize: 17)
		)
	}
}
