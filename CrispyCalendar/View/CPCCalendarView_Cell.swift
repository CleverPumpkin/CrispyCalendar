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
	internal typealias Attributes = Layout.Attributes;
	
	internal class Cell: UICollectionViewCell {
		internal override class var requiresConstraintBasedLayout: Bool {
			return false;
		}
		
		internal var monthViewsManager: CPCMonthViewsManager? {
			get { return self.monthViewsManagerPtr?.pointee }
			set { self.monthViewsManagerPtr = UnsafePointer (to: newValue) }
		}
		
		internal var enabledRegion: CountableRange <CPCDay>? {
			get { return self.monthView.enabledRegion }
			set { self.monthView.enabledRegion = newValue }
		}
		
		internal var month: CPCMonth? {
			get { return self.monthView.month }
			set {
				self.monthView.month = newValue;
				self.updateMonthViewManagingStatus ();
			}
		}
		
		private unowned let monthView: CPCMonthView;
		
		private var monthViewsManagerPtr: UnsafePointer <CPCMonthViewsManager>? {
			didSet {
				guard oldValue != self.monthViewsManagerPtr else {
					return;
				}
				self.updateMonthViewManagingStatus ();
			}
		}
		
		private static func makeMonthView (frame: CGRect = .zero) -> CPCMonthView {
			let monthView = CPCMonthView (frame: frame.bounds);
			monthView.autoresizingMask = [.flexibleWidth, .flexibleHeight];
			monthView.usesAspectRatioConstraint = false;
			return monthView;
		}
		
		internal override init (frame: CGRect) {
			let monthView = Cell.makeMonthView (frame: frame);
			self.monthView = monthView;
			super.init (frame: frame);
			self.commonInit (monthView);
		}
		
		internal required init? (coder aDecoder: NSCoder) {
			let monthView = Cell.makeMonthView ();
			self.monthView = monthView;
			super.init (coder: aDecoder);
			monthView.frame = self.contentView.bounds;
			self.commonInit (monthView);
		}
		
		private func commonInit (_ monthView: CPCMonthView) {
			self.contentView.addSubview (monthView);
			self.clipsToBounds = false;
		}
		
		deinit {
			self.monthView.removeFromMultiMonthViewsManager ();
		}
		
		internal override func apply (_ layoutAttributes: UICollectionViewLayoutAttributes) {
			super.apply (layoutAttributes);
			if let attributes = layoutAttributes as? Layout.Attributes {
				let monthView = self.monthView;
				(monthView.drawsLeadingSeparator, monthView.drawsTrailingSeparator) = (attributes.drawsLeadingSeparator, attributes.drawsTrailingSeparator);
			}
		}
		
		internal override func prepareForReuse () {
			super.prepareForReuse ();
			self.monthView.removeFromMultiMonthViewsManager ();
			self.monthViewsManager = nil;
		}
		
		private func updateMonthViewManagingStatus () {
			if let monthViewsManager = self.monthViewsManager, self.monthView.month != nil {
				monthViewsManager.addMonthView (self.monthView);
			} else {
				self.monthView.removeFromMultiMonthViewsManager ();
			}
		}
		
		internal override func preferredLayoutAttributesFitting (_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
			let fittingAttributes = super.preferredLayoutAttributesFitting (layoutAttributes);
			if let viewAttributes = self.monthView.layoutAttributes {
				if let layoutAttributes = layoutAttributes as? Attributes {
					layoutAttributes.aspectRatio = self.monthView.aspectRatioComponents ?? (multiplier: 0.0, constant: 0.0);
				} else {
					let fittingHeight = CPCMonthView.heightThatFits (width: fittingAttributes.size.width, with: viewAttributes);
					fittingAttributes.size.height = fittingHeight;
				}
			}
			return fittingAttributes;
		}
	}
}
