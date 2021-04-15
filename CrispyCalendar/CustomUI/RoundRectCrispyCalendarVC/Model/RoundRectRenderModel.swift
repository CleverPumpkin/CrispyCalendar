//
//  CustomRenderModel.swift
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

import UIKit

public struct RoundRectRenderModel {
	public let roundRectTitleModel: RoundRectTitleModel
	public let roundRectCellModel: RoundRectCellModel
	public let roundRectDotModel: RoundRectDotModel
	public let roundRectWeekViewModel: RoundRectWeekViewModel
	
	public init(
		roundRectTitleModel: RoundRectTitleModel,
		roundRectCellModel: RoundRectCellModel,
		roundRectDotModel: RoundRectDotModel,
		roundRectWeekViewModel: RoundRectWeekViewModel
	) {
		self.roundRectTitleModel = roundRectTitleModel
		self.roundRectCellModel = roundRectCellModel
		self.roundRectDotModel = roundRectDotModel
		self.roundRectWeekViewModel = roundRectWeekViewModel
	}
}

extension RoundRectRenderModel {
	static var demoModel: RoundRectRenderModel {
		return RoundRectRenderModel(
			roundRectTitleModel: RoundRectTitleModel(
				titleColor: .black,
				selectedEndsTitleColor: .white,
				selectedMiddleTitleColor: .lightGray,
				disableTitleColor: .lightGray,
				weekendsTitleColor: .black,
				titleFont: .systemFont(ofSize: 17)
			),
			roundRectCellModel: RoundRectCellModel(
				simpleCellColor: .white,
				selectedEndsCellColor: .blue,
				selectedMiddleCellColor: .lightGray,
				endsCellRadius: 8
			),
			roundRectDotModel: RoundRectDotModel(
				todayDotColor: .red,
				todayDotColorSelected: .white
			),
			roundRectWeekViewModel: RoundRectWeekViewModel(
				shadowColor: .black,
				backgroundColor: .white,
				textColor: .black,
				weekEndColor: .black
			)
		)
	}
}
