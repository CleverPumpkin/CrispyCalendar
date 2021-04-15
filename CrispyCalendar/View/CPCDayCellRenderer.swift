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

/// A set of methods that provide contextual information for drawing a single day cell in a month view.
public protocol CPCDayCellRenderingContext {
	/// Graphical context that should be used for custom drawing.
	var graphicsContext: CGContext { get };
	/// Day that is represented by the cell.
	var day: CPCDay { get };
	/// State of the cell.
	var state: CPCDayCellState { get };
	/// Background color.
	var backgroundColor: UIColor? { get };
	/// Cell frame.
	var frame: CGRect { get }
	/// Cell title.
	var title: NSString { get };
	/// Cell title attributes.
	var titleAttributes: NSDictionary { get };
	/// Cell title frame.
	var titleFrame: CGRect { get };
}

/// A type that is able to render a cell of a month view, representing an arbitrary day.
public protocol CPCDayCellRenderer {
	/// Fully renders content of cell, representing a specific day. Default implementation calls `drawCellBackground (in:)` and `drawCellTitle (in:)`, in that order.
	///
	/// - Note: Graphical context is guaranteed to be cleared and than filled with background color for `CPCDayCellState.normal` inside cell's frame.
	/// - Important: Drawing code is not restricted by cell frame (e. g. graphical context is not clipped to this rect) but doing so may lead to
	///              undesired consequences. For example, border cells _are_ implicitly clipped at some of their edges because redraw context
	///              does perform clipping that matches redrawn area.
	/// - Important: Cell separators drawing code is called _after_ cell content drawing code, so you shouldn't worry that you can accidentally mess
	///              them up. Area under separators is not cleared before drawing so they do blend with anything that was drawn inside a cell.
	///
	/// - Parameter context: Cell rendering context.
	func drawCell (in context: Context);
	/// Renders background of a day cell. Default implementation calls `drawCellBackground (state:color:frame:in:)` with corresponding values of `context`.
	///
	/// - Parameter context: Cell rendering context.
	func drawCellBackground (in context: Context);
	/// Renders title of a day cell. Default implementation calls `drawCellTitle (title:attributes:frame:in:)` with corresponding values of `context`.
	///
	/// - Parameter context: Cell rendering context.
	func drawTitleForCell (in context: Context);
}

/* public */ extension CPCDayCellRenderer {
	/// - SeeAlso: `CPCDayCellRenderingContext`.
	public typealias Context = CPCDayCellRenderingContext;

	public func drawCell (in context: Context) {
		self.drawCellBackground (in: context);
		self.drawTitleForCell (in: context);
	}
	
	public func drawCellBackground (in context: Context) {
		self.drawCellBackground (state: context.state, color: context.backgroundColor, frame: context.frame, in: context.graphicsContext);
	}
	
	/// Default implementation of day cell background drawing. Fills `frame` of `context` with `color` if `state` != `CPCDayCellState.normal`.
	///
	/// - Parameters:
	///   - state: Cell state.
	///   - color: Target background color.
	///   - frame: Cell frame.
	///   - context: Graphics context to draw in.
	public func drawCellBackground (state: CPCDayCellState, color: UIColor?, frame: CGRect, in context: CGContext) {
		guard state != [], let color = color else {
			return;
		}
		
		context.saveGState ();
		context.setFillColor (color.cgColor);
		context.fill (frame);
		context.restoreGState ();
	}
	
	public func drawTitleForCell (in context: Context) {
		self.drawCellTitle (title: context.title, attributes: context.titleAttributes, frame: context.titleFrame, in: context.graphicsContext);
	}
	
	/// Default implementation of day cell title drawing. Renders `title` with `attributes` in `frame` of `context`.
	///
	/// - Parameters:
	///   - title: Cell title (day number).
	///   - attributes: Cell title attributes, e.g. foreground color or font.
	///   - frame: Cell title target frame.
	///   - context: Graphics context to draw in.
	public func drawCellTitle (title: NSString, attributes: NSDictionary, frame: CGRect, in context: CGContext) {
		__CrispyCalendar_CPCDayCellRenderer_drawCellTitle (title, attributes, frame, context);
	}
}

/// Default implementation of `CPCDayCellRenderer`. Does not override any of `CPCDayCellRenderer`'s implementations.
internal struct CPCDefaultDayCellRenderer: CPCDayCellRenderer {}
