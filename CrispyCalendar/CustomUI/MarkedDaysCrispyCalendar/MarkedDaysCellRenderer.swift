//
//  MarkedDaysCellRenderer.swift
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

enum SelectionPosition {
	case marked
	case selectedAndMarked
	case disabled
}

protocol MarkedDaysCellRendererDelegate: AnyObject {
	var currentSelection: CPCDay? { get }
	
	func selectionPosition(for day: CPCDay) -> SelectionPosition
}

struct MarkedDaysCellRenderer: CPCDayCellRenderer {
	
	// MARK: - Private types
	
	private enum Constants {
		static let dotOffset: CGFloat = 2
		static let edgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
		static let cellRadius = 4
	}
	
	// MARK: - Private properties
	
	private let model: MarkedDaysRenderModel
	
	private weak var delegate: MarkedDaysCellRendererDelegate?
	
	// MARK: - Inits
	
	init(delegate: MarkedDaysCellRendererDelegate, renderModel: MarkedDaysRenderModel) {
		self.delegate = delegate
		self.model = renderModel
	}
	
	// MARK: - CPCDayCellRenderer
	
	func drawCellBackground(in context: Context) {
		context.graphicsContext.setFillColor(model.cellModel.unmarkedCellColor.cgColor)
		context.graphicsContext.fill(context.frame.inset(by: Constants.edgeInsets))
		guard let selectionPosition = delegate?.selectionPosition(for: context.day) else { return }
		switch selectionPosition {
		case .marked:
			drawSingleCell(context, isFilled: false)
		case .selectedAndMarked:
			drawSingleCell(context, isFilled: true)
		case .disabled:
			break
		}
		if context.state.contains(.isToday) {
			let dotColor = selectionPosition == .disabled ? model.dotModel.dotColorDisabled : model.dotModel.dotColor
			addDot(context, fillColor: dotColor)
		}
	}
	
	func drawCellTitle(in context: Context) {
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.alignment = NSTextAlignment.center
		var foregroundColor: UIColor = model.titleModel.titleColor
		if let selectionPosition = delegate?.selectionPosition(for: context.day) {
			switch selectionPosition {
			case .marked,
				 .selectedAndMarked:
				foregroundColor = model.titleModel.titleColor
			case .disabled:
				foregroundColor = model.titleModel.disableTitleColor
			}
		}
		let textFontAttributes: [NSAttributedString.Key: Any] = [
			NSAttributedString.Key.font: model.titleModel.titleFont,
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
	
	public func drawCellTitle(
		title: NSString,
		attributes: NSDictionary,
		frame: CGRect,
		in context: CGContext
	) {
		guard let stringAttributes = attributes as? [NSAttributedString.Key: Any] else {
			title.draw(in: frame, withAttributes: nil)
			return
		}
		title.draw(in: frame, withAttributes: stringAttributes)
	}
	
	// MARK: - Private methods
	
	private func drawSingleCell(_ context: Context, isFilled: Bool) {
		drawCellWith(
			context,
			corners: .allCorners,
			insets: Constants.edgeInsets,
			isFilled: isFilled,
			color: model.cellModel.markedCellColor
		)
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
				width: Constants.cellRadius,
				height: Constants.cellRadius
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
	
	private func addDot(_ context: Context, fillColor: UIColor) {
		let titleFrame = context.titleFrame
		let dotSize = model.dotModel.dotSize
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
}
