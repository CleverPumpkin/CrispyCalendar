//
//  RoundRectCrispyCalendarVC.swift
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

public class RoundRectCrispyCalendarVC: CPCCalendarViewController {
	
	// MARK: - Public Property
	
	public var calendarMaximumDate = Calendar.current.startOfDay(for: Date()) + .days(1) {
		didSet {
			calendarView.maximumDate = calendarMaximumDate
		}
	}
	
	public var currentSelectedDateRange: Range<Date>? {
		guard
			let range = currentSelection,
			let first = range.first,
			let last = range.last else {
			return nil
		}
		return first.calendarDate..<last.calendarDate
	}
	
	// MARK: - Private Property
	
	private let calendar: Calendar
	private let renderModel: RoundRectRenderModel
	
	// MARK: - Initialization / Deinitialization
	
	public init(
		renderModel: RoundRectRenderModel,
		weekView: CPCWeekView,
		calendar: Calendar
	) {
		self.renderModel = renderModel
		self.calendar = calendar
		super.init(nibName: nil, bundle: nil)
		self.weekView = weekView
	}
	
	required init?(coder aDecoder: NSCoder) {
		self.renderModel = RoundRectRenderModel(
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
				endsCellRadius: 4
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
		var calendar = Calendar.current
		calendar.firstWeekday = 2 // monday
		self.calendar = calendar
		super.init(coder: aDecoder)
	}
	
	// MARK: - Internal Methods

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
		calendarView.cellRenderer = RoundRectDayCellRenderer(delegate: self, renderModel: renderModel)
		calendarView.backgroundColor = UIColor.white
		calendarView.calendar = calendar
		calendarView.maximumDate = calendarMaximumDate
		calendarView.titleMargins = UIEdgeInsets(top: 16, left: 16, bottom: 8, right: 16)
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
		weekView.backgroundColor = renderModel.roundRectWeekViewModel.backgroundColor
		weekView.textColor = renderModel.roundRectWeekViewModel.textColor
		weekView.weekendColor = renderModel.roundRectWeekViewModel.weekEndColor
		
		let weekLayer = weekView.layer
		weekLayer.shadowColor = renderModel.roundRectWeekViewModel.shadowColor.cgColor
		weekLayer.shadowOpacity = 0.1
		weekLayer.shadowRadius = 8.0
		weekLayer.shadowOffset = .zero
		
		self.weekView = weekView
	}
	
	private func handleCalendarTap(_ day: CPCDay) {
		setSelectedCells(selected: day)
		calendarView.cellRenderer = RoundRectDayCellRenderer(delegate: self, renderModel: renderModel)
	}
}

// MARK: - CPCCalendarViewSelectionDelegate

extension RoundRectCrispyCalendarVC: CPCCalendarViewSelectionDelegate {
	
	public func calendarView(_ calendarView: CPCCalendarView, shouldSelect day: CPCDay) -> Bool {
		handleCalendarTap(day)
		return true
	}
	
	public func calendarView(_ calendarView: CPCCalendarView, shouldDeselect day: CPCDay) -> Bool {
		handleCalendarTap(day)
		return true
	}
	
	private func setSelectedCells(selected day: CPCDay) {
		guard let selection = currentSelection, selection.count == 1 else {
			calendarView.selection = .range(day ..< day)
			calendarView.select(day)
			return
		}
		
		if selection.count == 1, let first = selection.first, let last = selection.last {
			if first < day {
				calendarView.select(first...day)
			} else if last > day {
				calendarView.selection = .range(day ..< first)
				calendarView.select(day...first)
			}
		}
	}
}

// MARK: - RoundRectDayCellRendererDelegate

extension RoundRectCrispyCalendarVC: RoundRectDayCellRendererDelegate {
	var currentSelection: CountableRange<CPCDay>? {
		guard case let .range(days) = calendarView.selection, !days.isEmpty else { return nil }
		return days
	}
	
	func selectionPosition(for day: CPCDay) -> SelectionPosition {
		guard case let .range(days) = selection, !days.isEmpty else { return .none }
		if days.count == 1 && days.first == day {
			return .single
		} else if let firstDay = days.first, firstDay.calendarDate == day.calendarDate {
			return .first
		} else if let lastDay = days.last, lastDay.calendarDate == day.calendarDate {
			return .last
		} else if days.contains(day) {
			return .middle
		}
		return .none
	}
}
