//
//  RoundRectDayCellRenderer.swift
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
import CrispyCalendar

enum SelectionPosition {
	case single
	case first
	case middle
	case last
	case none
	
	var edgeInsets: UIEdgeInsets {
		switch self {
		case .none:
			return UIEdgeInsets(top: -1, left: -1, bottom: -1, right: -1)
		case .single:
			return UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
		case .middle:
			return UIEdgeInsets(top: 2, left: -1, bottom: 2, right: -1)
		case .first:
			return UIEdgeInsets(top: 2, left: 2, bottom: 2, right: -2)
		case .last:
			return UIEdgeInsets(top: 2, left: -2, bottom: 2, right: 2)
		}
	}
}

protocol RoundRectDayCellRendererDelegate: AnyObject {
	var currentSelection: CountableRange<CPCDay>? { get }
	
	func selectionPosition(for day: CPCDay) -> SelectionPosition
}

struct RoundRectDayCellRenderer: CPCDayCellRenderer {
	
	// MARK: - Private types
	
	private enum Constants {
		static let dotOffset: CGFloat = 4
	}
	
	// MARK: - Private vars
	
	private weak var delegate: RoundRectDayCellRendererDelegate?
	private let model: RoundRectRenderModel
	
	// MARK: - Inits
	
	init(delegate: RoundRectDayCellRendererDelegate, renderModel: RoundRectRenderModel) {
		self.delegate = delegate
		self.model = renderModel
	}
	
	// MARK: - CPCDayCellRenderer
	
	func drawCellBackground(in context: Context) {
		context.graphicsContext.setFillColor(model.roundRectCellModel.simpleCellColor.cgColor)
		context.graphicsContext.fill(context.frame.inset(by: SelectionPosition.none.edgeInsets))
		guard let selectionPosition = delegate?.selectionPosition(for: context.day) else { return }
		guard context.state != [], context.state != .disabled else {
			return
		}
		switch selectionPosition {
		case .single:
			drawSingleCell(context, isFilled: true)
		case .first:
			drawFirstSelectionPositionCell(context)
		case .middle:
			drawMiddleCell(context)
		case .last:
			drawLastSelectionPositionCell(context)
		case .none:
			if context.state.contains(.isToday) {
				addDot(context, fillColor: model.roundRectDotModel.todayDotColor)
			}
		}
	}
	
	func drawCellTitle(in context: Context) {
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.alignment = NSTextAlignment.center
		let isWeekend = context.day.weekday.isWeekend
		let foregroundColor: UIColor
		let isEnds: Bool
		if let selectionPosition = delegate?.selectionPosition(for: context.day) {
			isEnds = selectionPosition == .first || selectionPosition == .last || selectionPosition == .single
		} else {
			isEnds = false
		}
		if (context.state.contains(.selected)) && delegate?.currentSelection != nil && isEnds {
			// today selected OR just cell in selected range AND selected range(not single) AND is ends
			foregroundColor = model.roundRectTitleModel.selectedEndsTitleColor
		} else if context.state == .disabled {
			foregroundColor = model.roundRectTitleModel.disableTitleColor
		} else if isWeekend {
			foregroundColor = model.roundRectTitleModel.weekendsTitleColor
		} else {
			foregroundColor = model.roundRectTitleModel.titleColor
		}
		
		let textFontAttributes: [NSAttributedString.Key: Any] = [
			NSAttributedString.Key.font: model.roundRectTitleModel.titleFont,
			NSAttributedString.Key.foregroundColor: foregroundColor,
			NSAttributedString.Key.paragraphStyle: paragraphStyle
		]
		
		drawCellTitle(
			title: context.title,
			attributes: textFontAttributes as NSDictionary,
			frame: context.titleFrame,
			in: context.graphicsContext
		)
	}
	
	// MARK: - Private methods
	
	private func addDot(_ context: Context, fillColor: UIColor) {
		let titleFrame = context.titleFrame
		let dotSize = CGSize(width: 5, height: 5)
		let rect = CGRect(
			x: titleFrame.midX - dotSize.width / 2,
			y: titleFrame.maxY + Constants.dotOffset,
			width: dotSize.width,
			height: dotSize.height
		)
		context.graphicsContext.addEllipse(in: rect)
		context.graphicsContext.setFillColor(fillColor.cgColor)
		context.graphicsContext.drawPath(using: .fill)
	}

	private func drawSingleCell(_ context: Context, isFilled: Bool) {
		drawCellWith(context, corners: .allCorners, insets: SelectionPosition.single.edgeInsets, isFilled: isFilled, color: model.roundRectCellModel.selectedEndsCellColor)
		if context.state.contains(.isToday) {
			addDot(context, fillColor: model.roundRectDotModel.todayDotColorSelected)
		}
	}
	
	private func drawMiddleCell(_ context: Context) {
		let edges = SelectionPosition.middle.edgeInsets
		context.graphicsContext.setFillColor(model.roundRectCellModel.selectedMiddleCellColor.cgColor)
		context.graphicsContext.setStrokeColor(model.roundRectCellModel.selectedMiddleCellColor.cgColor)
		context.graphicsContext.fill(context.frame.inset(by: edges))
		context.graphicsContext.stroke(context.frame.inset(by: edges))
	}
	
	private func drawCellWith(
		_ context: Context,
		corners: UIRectCorner,
		insets: UIEdgeInsets,
		isFilled: Bool,
		color: UIColor
	) {
		let rect = context.frame.inset(by: insets)
		let path = UIBezierPath(
			roundedRect: rect,
			byRoundingCorners: corners,
			cornerRadii: CGSize(
				width: model.roundRectCellModel.endsCellRadius,
				height: model.roundRectCellModel.endsCellRadius
			)
		)
		path.lineWidth = 1
		path.close()
		
		context.graphicsContext.beginPath()
		context.graphicsContext.setStrokeColor(color.cgColor)
		if isFilled {
			context.graphicsContext.setFillColor(color.cgColor)
		}
		context.graphicsContext.addPath(path.cgPath)
		context.graphicsContext.closePath()
		context.graphicsContext.drawPath(using: .fillStroke)
	}
	
	private func drawFirstSelectionPositionCell(_ context: Context) {
		drawCellWith(
			context,
			corners: [.topLeft, .bottomLeft],
			insets: SelectionPosition.first.edgeInsets,
			isFilled: true,
			color: model.roundRectCellModel.selectedEndsCellColor
		)
	}
	
	private func drawLastSelectionPositionCell(_ context: Context) {
		drawCellWith(
			context,
			corners: [.topRight, .bottomRight],
			insets: SelectionPosition.last.edgeInsets,
			isFilled: true,
			color: model.roundRectCellModel.selectedEndsCellColor
		)
		if context.state.contains(.isToday) {
			addDot(context, fillColor: model.roundRectDotModel.todayDotColorSelected)
		}
	}
}
