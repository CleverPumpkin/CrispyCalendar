//
//  CPCDashboardVC.swift
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

class CPCDashboardVC: CPCCalendarViewController {
	
	// MARK: - Internal Property

	private let calendar: Calendar = {
		var calendar = Calendar.current
		calendar.firstWeekday = 5
		return calendar
	}()
	
	// MARK: - Internal Methods
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.calendarView.separatorColor = .clear
		self.calendarView.titleAlignment = .left
		self.calendarView.cellRenderer = CellRenderer()
		self.calendarView.selectionDelegate = self
		self.calendarView.columnCount = 1
		self.calendarView.backgroundColor = UIColor.white
		self.calendarView.titleColor = UIColor.black
		self.calendarView.calendar = calendar

		let weekView = CPCWeekView(frame: CGRect(origin: .zero, size: CGSize(width: view.bounds.width, height: 0.0)))
		weekView.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
		weekView.backgroundColor = UIColor.white
		weekView.backgroundColor = UIColor.white
		weekView.textColor = UIColor.black
		self.weekView = weekView
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		switch selection {
		case .single(let day):
			guard let day = day else {
				return
			}
			self.calendarView.scrollTo(day: day, animated: true)
		default:
			break
		}
	}
	
	// MARK: - Private methods
	
	private struct CellRenderer: CPCDayCellRenderer {
		func drawCell(in context: Self.Context) {
			context.graphicsContext.setFillColor(UIColor.white.cgColor)
			context.graphicsContext.fill(context.frame)
			self.drawCellBackground(in: context)
			self.drawCellTitle(in: context)
		}
		
		func drawCellBackground(in context: Self.Context) {
			guard context.state != [] else {
				return
			}
			context.graphicsContext.setFillColor(
				context.state == .isToday ?
					UIColor.lightGray.cgColor :
					UIColor(red: 255 / 255, green: 164 / 255, blue: 0, alpha: 1).cgColor
			)
			context.graphicsContext.setLineWidth(0)
			context.graphicsContext.addPath(
				UIBezierPath(
					roundedRect: context.frame.inset(by: UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)),
					cornerRadius: 4
				).cgPath
			)
			context.graphicsContext.drawPath(using: .fillStroke)
		}
		
		func drawCellTitle(in context: Self.Context) {
			let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
			paragraphStyle.alignment = NSTextAlignment.center
			
			let textColor = context.day.weekday.isWeekend ? UIColor.gray : UIColor.black
			let textFontAttributes : [NSAttributedString.Key: Any] = [
				NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16),
				NSAttributedString.Key.foregroundColor : context.state == .selected ? UIColor.white : textColor,
				NSAttributedString.Key.paragraphStyle : paragraphStyle
			]
			
			drawCellTitle(
				title: context.title,
				attributes: textFontAttributes as NSDictionary,
				frame: context.titleFrame,
				in: context.graphicsContext
			)
		}
	}
}

extension CPCDashboardVC: CPCCalendarViewSelectionDelegate {
	func calendarView(_ calendarView: CPCCalendarView, shouldSelect day: CPCDay) -> Bool {
		print(day)
		calendarView.selection = .single(day)
		return true
	}

	func calendarView(_ calendarView: CPCCalendarView, shouldDeselect day: CPCDay) -> Bool {
		print(day)
		self.selection = .single(nil)
		return true
	}
}

