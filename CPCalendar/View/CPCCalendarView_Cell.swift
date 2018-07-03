//
//  CPCCalendarView_Cell.swift
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

extension CPCCalendarView {
	internal class Cell: UICollectionViewCell {
		internal weak var monthViewsManager: CPCMonthViewsManager? {
			didSet {
				guard self.monthViewsManager !== oldValue else {
					return;
				}
				
				if let monthViewsManager = self.monthViewsManager {
					monthViewsManager.addMonthView (self.monthView);
				} else {
					self.monthView.removeFromManagingView ();
				}
			}
		}
		
		private unowned let monthView: CPCMonthView;
		
		private static func makeMonthView (frame: CGRect = .zero) -> CPCMonthView {
			let monthView = CPCMonthView (frame: frame.bounds);
			monthView.autoresizingMask = [.flexibleWidth, .flexibleHeight];
			return monthView;
		}
		
		internal override init (frame: CGRect) {
			let monthView = Cell.makeMonthView (frame: frame);
			self.monthView = monthView;
			super.init (frame: frame);
			self.contentView.addSubview (monthView);
		}
		
		internal required init? (coder aDecoder: NSCoder) {
			let monthView = Cell.makeMonthView ();
			self.monthView = monthView;
			super.init (coder: aDecoder);
			monthView.frame = self.contentView.bounds;
			self.contentView.addSubview (monthView);
		}
		
		internal override func apply (_ layoutAttributes: UICollectionViewLayoutAttributes) {
			super.apply (layoutAttributes);
			self.monthView.month = (layoutAttributes as? Layout.Attributes)?.month;
		}
		
		internal override func prepareForReuse () {
			super.prepareForReuse ();
			self.monthView.removeFromManagingView ();
		}
	}
}
