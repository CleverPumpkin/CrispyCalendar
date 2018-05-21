//
//  CPCDayCellRenderer.swift
//  Copyright © 2018 Cleverpumpkin, Ltd. All rights reserved.
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

public protocol CPCDayCellRenderingContext {
	var graphicsContext: CGContext { get };
	var day: CPCDay { get };
	var state: CPCDayCellState { get };
	var backgroundColor: UIColor? { get };
	var frame: CGRect { get }
	var title: String { get };
	var titleAttributes: [NSAttributedStringKey: Any] { get };
	var titleFrame: CGRect { get };
}

public protocol CPCDayCellRenderer {
	func drawCell (in context: CPCDayCellRenderingContext);
	func drawCellBackground (in context: CPCDayCellRenderingContext);
	func drawCellTitle (in context: CPCDayCellRenderingContext);
}

public extension CPCDayCellRenderer {
	public func drawCell (in context: CPCDayCellRenderingContext) {
		self.drawCellBackground (in: context);
		self.drawCellTitle (in: context);
	}
	
	public func drawCellBackground (in context: CPCDayCellRenderingContext) {
		self.drawCellBackground (state: context.state, color: context.backgroundColor, frame: context.frame, in: context.graphicsContext);
	}
	
	public func drawCellBackground (state: CPCDayCellState, color: UIColor?, frame: CGRect, in context: CGContext) {
		guard state != .normal, let color = color else {
			return;
		}
		
		context.saveGState ();
		context.setFillColor (color.cgColor);
		context.fill (frame);
		context.restoreGState ();
	}
	
	public func drawCellTitle (in context: CPCDayCellRenderingContext) {
		self.drawCellTitle (title: context.title, attributes: context.titleAttributes, frame: context.titleFrame, in: context.graphicsContext);
	}
	
	public func drawCellTitle (title: String, attributes: [NSAttributedStringKey: Any], frame: CGRect, in context: CGContext) {
		UIGraphicsPushContext (context);
		context.saveGState ();
		defer {
			context.restoreGState ();
			UIGraphicsPopContext ();
		}
		
		NSAttributedString (string: title, attributes: attributes).draw (in: frame);
	}
}

internal struct CPCDefaultDayCellRenderer: CPCDayCellRenderer {}
