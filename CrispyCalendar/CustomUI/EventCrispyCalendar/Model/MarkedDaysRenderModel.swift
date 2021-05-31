//
//  MarkedDaysRenderModel.swift
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
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO marked SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

public struct MarkedDaysRenderModel {
	public let titleModel: MarkedDaysTitleModel
	public let cellModel: MarkedDaysCellModel
	public let dotModel: MarkedDaysDotModel
	public let weekModel: MarkedDaysWeekViewModel
	
	public init(
		titleModel: MarkedDaysTitleModel,
		cellModel: MarkedDaysCellModel,
		dotModel: MarkedDaysDotModel,
		weekModel: MarkedDaysWeekViewModel
	) {
		self.titleModel = titleModel
		self.cellModel = cellModel
		self.dotModel = dotModel
		self.weekModel = weekModel
	}
}

extension MarkedDaysRenderModel {
	static public var demoModel: MarkedDaysRenderModel {
		return MarkedDaysRenderModel(
			titleModel: MarkedDaysTitleModel(
				dayTitleColor: .black,
				dayDisableTitleColor: .lightGray,
				dayWeekendsTitleColor: .black,
				dayTitleFont: .systemFont(ofSize: 17)
			),
			cellModel: MarkedDaysCellModel(
				simpleCellColor: .white,
				markedCellColor: .orange
			),
			dotModel: MarkedDaysDotModel(
				todayDotColor: .black,
				todayDotColorDisabled: .lightGray
			),
			weekModel: MarkedDaysWeekViewModel(
				weekViewBackgroundColor: .white,
				weekViewTextColor: .black,
				weekViewWeekEndColor: .red,
				weekViewBorderColor: .lightGray
			)
		)
	}
	
	
	static public var demoDates: [Date] {
		return [
			Date(),
			Date() + .days(3),
			Date() + .days(13),
			Date() + .days(23),
			Date() + .days(16),
			Date() + .days(17),
			Date() + .days(19),
			Date() + .days(23),
			Date() + .days(27),
			Date() + .days(30)
		]
	}
}
