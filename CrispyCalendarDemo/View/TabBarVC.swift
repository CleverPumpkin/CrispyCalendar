//
//  TabBarVC.swift
//  Copyright © 2020 Cleverpumpkin, Ltd. All rights reserved.
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
import CrispyCalendar

class TabBarVC: UITabBarController {

	override func viewDidLoad() {
		super.viewDidLoad()
		
		let model = RoundRectRenderModel(
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
		
		let test2 = CPCWeekView()
		var calendar = Calendar.current
		calendar.firstWeekday = 5
		let firstViewController = RoundRectCrispyCalendarVC(renderModel: model, weekView: test2, calendar: calendar)
		firstViewController.tabBarItem = UITabBarItem(title: "Calendar", image: nil, selectedImage: nil)

		let secondViewController = CPCDashboardList()
		secondViewController.tabBarItem = UITabBarItem(title: "List", image: nil, selectedImage: nil)

		let tabBarList = [firstViewController, secondViewController]

		viewControllers = tabBarList
	}

}
