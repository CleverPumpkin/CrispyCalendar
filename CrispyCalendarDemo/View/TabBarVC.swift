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
		
		let firstViewController = MarkedDaysCrispyCalendarVC(
			markedDays: MarkedDaysRenderModel.demoDates,
			renderModel: MarkedDaysRenderModel.demoModel,
			weekView: CPCWeekView(),
			calendar: Calendar.current) { date in
			// handle tap to date here
			print(date)
		}
		
		let startDate = Date(timeIntervalSince1970: 1682517411)
		let endDate = Date(timeIntervalSince1970: 1714129011)
		
		firstViewController.tabBarItem = UITabBarItem(title: "Marked", image: nil, selectedImage: nil)
		let secondViewController = RoundRectCrispyCalendarVC(
			renderModel: RoundRectRenderModel.demoModel,
			weekView: CPCWeekView(),
			calendar: Calendar.current,
			dateRange: startDate...endDate
		)
		
		secondViewController.selection = .single(.today)
		
		secondViewController.tabBarItem = UITabBarItem(title: "RoundedRect", image: nil, selectedImage: nil)
		
		let thirdViewController = CPCDashboardList()
		thirdViewController.tabBarItem = UITabBarItem(title: "List", image: nil, selectedImage: nil)
		
		let tabBarList = [firstViewController, secondViewController, thirdViewController]

		viewControllers = tabBarList
	}
}
