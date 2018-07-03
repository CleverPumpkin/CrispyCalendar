//
//  CPCCalendarViewController.swift
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

public protocol CPCCalendarViewControllerSelectionDelegate: AnyObject {
	var selection: CPCViewSelection { get set };
	
	func calendarViewController (_ calendarViewController: CPCCalendarViewController, shouldSelect day: CPCDay) -> Bool;
	func calendarViewController (_ calendarViewController: CPCCalendarViewController, shouldDeselect day: CPCDay) -> Bool;
}

private protocol SelectionStorageProtocol {
	var selection: CPCViewSelection { get set };
}

private enum SelectionStorage {
	private struct ProxyingStorage: SelectionStorageProtocol {
		private unowned let viewController: CPCCalendarViewController;
		
		fileprivate var selection: CPCViewSelection {
			get {
				return self.viewController.calendarView.selection;
			}
			set {
				self.viewController.calendarView.selection = newValue;
			}
		}
		
		fileprivate init (for viewController: CPCCalendarViewController) {
			self.viewController = viewController;
		}
	}
	
	private struct RegularStorage: SelectionStorageProtocol {
		fileprivate var selection: CPCViewSelection;
	}

	fileprivate static func make <T> (for viewController: T) -> SelectionStorageProtocol where T: CPCCalendarViewController {
		if viewController is CPCCalendarViewSelectionDelegate {
			return RegularStorage (selection: .none);
		} else {
			return ProxyingStorage (for: viewController);
		}
	}
}

open class CPCCalendarViewController: UIViewController {
	private final class ViewDelegate: CPCCalendarViewSelectionDelegate {
		fileprivate weak var viewControllerDelegate: CPCCalendarViewControllerSelectionDelegate?;

		private unowned let viewController: CPCCalendarViewController;
		
		fileprivate init (_ viewControllerDelegate: CPCCalendarViewControllerSelectionDelegate, for viewController: CPCCalendarViewController) {
			self.viewController = viewController;
			self.viewControllerDelegate = viewControllerDelegate;
		}
		
		fileprivate var selection: CPCViewSelection {
			get {
				return self.viewControllerDelegate?.selection ?? .none;
			}
			set {
				self.viewControllerDelegate?.selection = newValue;
			}
		}
		
		fileprivate func calendarView (_ calendarView: CPCCalendarView, shouldSelect day: CPCDay) -> Bool {
			return self.viewControllerDelegate?.calendarViewController (self.viewController, shouldSelect: day) ?? false;
		}
		
		fileprivate func calendarView (_ calendarView: CPCCalendarView, shouldDeselect day: CPCDay) -> Bool {
			return self.viewControllerDelegate?.calendarViewController (self.viewController, shouldDeselect: day) ?? false;
		}
	}
	
	open weak var selectionDelegate: CPCCalendarViewControllerSelectionDelegate? {
		get {
			return self.viewDelegate?.viewControllerDelegate;
		}
		set {
			self.viewDelegate = self.selectionDelegate.map { ViewDelegate ($0, for: self) };
			self.calendarView.selectionDelegate = self.viewDelegate;
		}
	}
	
	open override var view: UIView! {
		willSet (newView) {
			guard let newValue = newView as? CPCCalendarView else {
				fatalError ("\(CPCCalendarViewController.self) is designed to manage \(CPCCalendarView.self) instances; \(newView) is given");
			}
			if self.isViewLoaded {
				self.calendarView.calendarViewController = nil;
			}
			newValue.calendarViewController = self;
		}
	}
	
	open var calendarView: CPCCalendarView {
		return unsafeDowncast (self.view);
	}
	
	open var weekView: CPCWeekView!;
	
	open var selection: CPCViewSelection {
		get {
			return self.selectionStorage.selection;
		}
		set {
			self.selectionStorage.selection = newValue;
		}
	}
	
	private var selectionStorage: SelectionStorageProtocol!;
	private var viewDelegate: ViewDelegate?;
	
	public override init (nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init (nibName: nil, bundle: nil);
		self.selectionStorage = SelectionStorage.make (for: self);
	}
	
	public required init? (coder aDecoder: NSCoder) {
		super.init (coder: aDecoder);
		self.selectionStorage = SelectionStorage.make (for: self);
	}
	
	open override func loadView () {
		let view = CPCCalendarView (frame: UIScreen.main.bounds);
		view.backgroundColor = .white;
		
		let weekView = CPCWeekView (frame: CGRect (origin: .zero, size: CGSize (width: view.bounds.width, height: 0.0)));
		weekView.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin];
		weekView.backgroundColor = .gray;
		view.addSubview (weekView);
		
		let weekViewLayer = weekView.layer;
		weekViewLayer.shadowColor = UIColor (white: 0.0, alpha: 1.0).cgColor;
		weekViewLayer.shadowOpacity = 0.1;
		weekViewLayer.shadowRadius = 8.0;
		weekViewLayer.shadowOffset = .zero;

		self.view = view;
		self.weekView = weekView;
	}
	
	open override func viewWillLayoutSubviews () {
		super.viewWillLayoutSubviews ();
		self.layoutWeekView ();
	}
	
	open override func didMove (toParentViewController parent: UIViewController?) {
		super.didMove (toParentViewController: parent);
		self.layoutWeekView ();
	}
	
	@available (iOS 11.0, *)
	open override func viewSafeAreaInsetsDidChange () {
		super.viewSafeAreaInsetsDidChange ();
		self.layoutWeekView ();
	}
	
	open func selectionDidChange () {}
	
	private func layoutWeekView () {
		let weekView = self.weekView!, weekViewTop: CGFloat;
		if #available (iOS 11.0, *) {
			weekViewTop = self.view.safeAreaInsets.top + self.additionalSafeAreaInsets.top;
		} else {
			weekViewTop = self.topLayoutGuide.length;
		}
		let fittingSize = self.view.bounds.size;
		weekView.frame = CGRect (x: 0.0, y: weekViewTop, width: fittingSize.width, height: weekView.sizeThatFits (fittingSize).height + 15.0);
	}
}
