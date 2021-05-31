//
//  EventCrispyCalendarVC.swift
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

public class MarkedDaysCrispyCalendarVC: CPCCalendarViewController {
	
	// MARK: - Public properties
	
	public var currentSelectedDate: Date? {
		return currentSelection?.calendarDate
	}
	
	// MARK: - Private properties
	
	private let calendar: Calendar
	private let renderModel: MarkedDaysRenderModel
	private var markedDays: [CPCDay] 
	
	// MARK: - Initialization / Deinitialization
	
	public init(
		markedDays: [Date],
		renderModel: MarkedDaysRenderModel,
		weekView: CPCWeekView,
		calendar: Calendar
	) {
		self.markedDays = markedDays.map { $0.crispyDay }
		self.renderModel = renderModel
		self.calendar = calendar
		super.init(nibName: nil, bundle: nil)
		self.weekView = weekView
	}
	
	required init?(coder aDecoder: NSCoder) {
		var calendar = Calendar.current
		calendar.firstWeekday = 2 // Monday
		self.calendar = calendar
		self.renderModel = MarkedDaysRenderModel(
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
		self.markedDays = []
		super.init(coder: aDecoder)
	}
	
	// MARK: - Public Methods
	
	public func setSelectedDay(_ day: Date) {
		
	}
	
	public func setMarkedDays(_ days: [Date]) {
		markedDays = days.map { $0.crispyDay }
	}

	public override func viewDidLoad() {
		super.viewDidLoad()
		setupCalendarView()
		setupWeekView()
	}
	
	public override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		switch selection {
		case .single(let day):
			guard let day = day else { return }
			self.calendarView.scrollTo(day: day, animated: true)
		default:
			break
		}
	}
	
	// MARK: - Private methods
	
	private func setupCalendarView() {
		calendarView.separatorColor = .clear
		calendarView.titleAlignment = .left
		calendarView.layer.borderWidth = 0
		calendarView.selectionDelegate = self
		calendarView.columnCount = 1
		calendarView.cellRenderer = MarkedDaysCellRenderer(delegate: self, renderModel: renderModel)
		calendarView.backgroundColor = UIColor.white
		calendarView.calendar = calendar
		calendarView.titleMargins = UIEdgeInsets(top: 16, left: 16, bottom: 8, right: 16)
		if let minDate = self.markedDays.min() {
			setSelectedCells(selected: minDate)
			handleCalendarTap(minDate)
		}
	}
	
	private func setupWeekView() {
		let weekView = CPCWeekView(
			frame: CGRect(
				x: .zero,
				y: .zero,
				width: view.bounds.width,
				height: .zero)
		)
		weekView.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
		weekView.backgroundColor = renderModel.weekModel.weekViewBackgroundColor
		weekView.textColor = renderModel.weekModel.weekViewTextColor
		weekView.weekendColor = renderModel.weekModel.weekViewWeekEndColor
		weekView.layer.borderWidth = 1
		weekView.layer.borderColor = renderModel.weekModel.weekViewBorderColor.cgColor
		self.weekView = weekView
	}
	

	private func handleCalendarTap(_ day: CPCDay) {
		setSelectedCells(selected: day)
		calendarView.cellRenderer = MarkedDaysCellRenderer(delegate: self, renderModel: renderModel)
	}
	
	private func isDayIsMarked(_ day: CPCDay) -> Bool {
		return markedDays.map({ $0.backingValue }).contains(day.backingValue)
	}
}

// MARK: - CPCCalendarViewSelectionDelegate

extension MarkedDaysCrispyCalendarVC: CPCCalendarViewSelectionDelegate {
	
	public func calendarView(_ calendarView: CPCCalendarView, shouldSelect day: CPCDay) -> Bool {
		guard isDayIsMarked(day) else {
			return false
		}
		handleCalendarTap(day)
		return true
	}
	
	public func calendarView(_ calendarView: CPCCalendarView, shouldDeselect day: CPCDay) -> Bool {
		guard isDayIsMarked(day) else {
			return false
		}
		handleCalendarTap(day)
		return true
	}
	
	private func setSelectedCells(selected day: CPCDay) {
		calendarView.setSelection(.single(day))
	}
}

// MARK: - EventDayCellRendererDelegate

extension MarkedDaysCrispyCalendarVC: MarkedDaysCellRendererDelegate {
	var currentSelection: CPCDay? {
		guard case let .single(day) = calendarView.selection else {
			return nil
		}
		return day
	}
	
	func selectionPosition(for day: CPCDay) -> SelectionPosition {
		if isDayIsMarked(day) && day.backingValue == currentSelection?.backingValue {
			return .selectedAndMarked
		} else if isDayIsMarked(day) {
			return .marked
		} else {
			return .disabled
		}
	}
}
