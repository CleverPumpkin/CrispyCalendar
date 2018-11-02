//
//  CPCDashboardVC.swift
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
import CrispyCalendar

class CPCDashboardVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
	private static let configItems: [ConfigItemProtocol] = [
		DefaultConfigItem (localizedTitle: "No selection", calendarTitle: "Default appearance", initialSelection: .none),
		DefaultConfigItem (localizedTitle: "Single day selection", calendarTitle: "Day selection", initialSelection: .single (nil)),
		DefaultConfigItem (localizedTitle: "Range selection", calendarTitle: "Range selection", initialSelection: .range (.today ..< .today)),
		DefaultConfigItem (localizedTitle: "Multiple days selection (unordered)", calendarTitle: "Unordered selection", initialSelection: .unordered ([])),
		DefaultConfigItem (localizedTitle: "Multiple days selection (ordered)", calendarTitle: "Ordered selection", initialSelection: .ordered ([])),
		CustomSelectionHandlingItem (localizedTitle: "Custom selection handling", calendarTitle: "Custom selection"),
		CustomDrawingItem (localizedTitle: "Custom drawing", calendarTitle: "Custom drawing"),
		WeirdCalendarItem (identifier: .hebrew),
		WeirdCalendarItem (identifier: .chinese),
		WeirdCalendarItem (identifier: .coptic),
		WeirdCalendarItem (identifier: .ethiopicAmeteMihret),
		DefaultConfigItem (
			localizedTitle: "Prev, current & next months",
			calendarTitle: "Constrained dates",
			initialSelection: .single (nil),
			enabledDates: (Date (timeIntervalSinceNow: -30 * 86400.0) ..< Date (timeIntervalSinceNow: 30 * 86400.0))
		),
		ColumnedCalendarItem (localizedTitle: "Columned landscape view", calendarTitle: "Columned landscape view"),
	];
	
	internal override func viewDidLoad () {
		super.viewDidLoad ();
		
		self.navigationItem.title = "CrispyCalendar Demo App";
		self.navigationItem.backBarButtonItem = UIBarButtonItem (title: "", style: .plain, target: nil, action: nil);
		
		let tableView = UITableView (frame: self.view.bounds);
		tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight];
		tableView.dataSource = self;
		tableView.delegate = self;
		tableView.register (UITableViewCell.self, forCellReuseIdentifier: "cell");
		self.view.addSubview (tableView);
	}
	
	internal func tableView (_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return CPCDashboardVC.configItems.count;
	}
	
	internal func tableView (_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell (withIdentifier: "cell", for: indexPath);
		let configItem = CPCDashboardVC.configItems [indexPath.row];
		cell.textLabel?.text = configItem.localizedTitle;
		return cell;
	}
	
	internal func tableView (_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		CPCDashboardVC.configItems [indexPath.row].performAction (for: self);
		tableView.deselectRow (at: indexPath, animated: true);
	}
	
	internal override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return .portrait;
	}
}

private protocol ConfigItemProtocol {
	var localizedTitle: String { get }
	
	func performAction ();
	func performAction (for viewController: UIViewController);
}

extension ConfigItemProtocol {
	fileprivate func performAction (for viewController: UIViewController) {
		self.performAction ();
	}
}

private protocol ConfigItemPushingViewController: ConfigItemProtocol {
	var targetViewController: UIViewController { get }
}

extension ConfigItemPushingViewController {
	fileprivate func performAction () {
		fatalError ("Not implemented");
	}
	
	fileprivate func performAction (for viewController: UIViewController) {
		viewController.navigationController?.pushViewController (self.targetViewController, animated: true);
	}
}

private protocol ConfigItemPushingCalendarController: ConfigItemPushingViewController {
	var calendarViewControllerClass: SelectionTrackingCalendarVC.Type { get };
	var calendarTitle: String { get };
	var initialSelection: CPCViewSelection { get };
	var enabledDates: Range <Date>? { get };
}

extension ConfigItemPushingCalendarController {
	fileprivate var calendarViewControllerClass: SelectionTrackingCalendarVC.Type {
		return SelectionTrackingCalendarVC.self;
	}
	
	fileprivate var targetViewController: UIViewController {
		let result = self.calendarViewControllerClass.init (title: self.calendarTitle);
		result.selection = self.initialSelection;
		result.minimumDate = self.enabledDates?.lowerBound;
		result.maximumDate = self.enabledDates?.upperBound;
		return result;
	}
	
	fileprivate var enabledDates: Range <Date>? {
		return nil;
	}
}

fileprivate extension Bool {
	fileprivate static var random: Bool {
		return arc4random () > UInt32.max / 2;
	}
}

private class SelectionTrackingCalendarVC: CPCCalendarViewController {
	private unowned let selectionLabel: UILabel;
	
	private var selectionObserver: NSKeyValueObservation!;
	
	fileprivate required init (title: String) {
		let selectionLabel = UILabel ();
		self.selectionLabel = selectionLabel;
		super.init (nibName: nil, bundle: nil);
		self.commonInit (title: title, selectionLabel: selectionLabel);
	}
	
	fileprivate required init? (coder aDecoder: NSCoder) {
		let selectionLabel = UILabel ();
		self.selectionLabel = selectionLabel;
		super.init (coder: aDecoder);
		self.commonInit (title: self.title ?? "", selectionLabel: selectionLabel);
	}
	
	private func commonInit (title: String, selectionLabel: UILabel) {
		let titleLabel = UILabel ();
		titleLabel.translatesAutoresizingMaskIntoConstraints = false;
		titleLabel.font = .systemFont (ofSize: 17.0, weight: .medium);
		titleLabel.text = title;
		titleLabel.textAlignment = .center;
		
		selectionLabel.translatesAutoresizingMaskIntoConstraints = false;
		selectionLabel.font = .systemFont (ofSize: 14.0);
		selectionLabel.textAlignment = .center;
		self.updateNavigationBarPrompt ();
		
		let titleView = UIStackView (arrangedSubviews: [titleLabel, selectionLabel]);
		titleView.axis = .vertical;
		titleView.translatesAutoresizingMaskIntoConstraints = false;
		if #available (iOS 11.0, *) {
			self.navigationItem.titleView = titleView;
		} else {
			final class ContainerView: UIView {
				override var intrinsicContentSize: CGSize {
					return self.subviews.first?.intrinsicContentSize ?? .zero;
				}
				
				override func layoutSubviews () {
					self.invalidateIntrinsicContentSize ();
					super.layoutSubviews ();
				}
			}
			
			let titleContainerView = ContainerView (frame: CGRect (origin: .zero, size: titleView.systemLayoutSizeFitting (UIView.layoutFittingCompressedSize)));
			titleContainerView.clipsToBounds = false;
			titleContainerView.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin, .flexibleRightMargin, .flexibleBottomMargin];
			titleContainerView.addSubview (titleView);
			NSLayoutConstraint.activate ([
				titleView.centerXAnchor.constraint (equalTo: titleContainerView.centerXAnchor),
				titleView.centerYAnchor.constraint (equalTo: titleContainerView.centerYAnchor),
			]);
			
			self.navigationItem.titleView = titleContainerView;
		}
	}
	
	fileprivate override var selection: CPCViewSelection {
		didSet {
			self.updateNavigationBarPrompt ();
		}
	}
	
	fileprivate override func selectionDidChange () {
		self.updateNavigationBarPrompt ();
	}
	
	fileprivate override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return .portrait;
	}

	private func updateNavigationBarPrompt () {
		let selectionDescription = self.selection.description;
		self.selectionLabel.text = "Selection: \(selectionDescription.isEmpty ? "none" : selectionDescription)";
	}
}

private class CustomSelectionHandlingVC: SelectionTrackingCalendarVC, CPCCalendarViewSelectionDelegate {
	fileprivate override func viewDidLoad () {
		super.viewDidLoad ();
		self.calendarView.selectionDelegate = self;
	}
	
	fileprivate func calendarView (_ calendarView: CPCCalendarView, shouldSelect day: CPCDay) -> Bool {
		guard Bool.random else {
			print ("Not selecting \(day)");
			return false;
		}
		
		print ("Selecting \(day)");
		guard case .unordered (let oldValue) = self.selection else {
			fatalError ("WTF");
		}
		self.selection = .unordered (oldValue.union ([day]));
		return true;
	}
	
	fileprivate func calendarView (_ calendarView: CPCCalendarView, shouldDeselect day: CPCDay) -> Bool {
		guard Bool.random else {
			print ("Not deselecting \(day)");
			return false;
		}
		
		print ("Deselecting \(day)");
		guard case .unordered (let oldValue) = self.selection else {
			fatalError ("WTF");
		}
		self.selection = .unordered (oldValue.filter { $0 != day });
		return true;
	}
}

fileprivate extension UIColor {
	fileprivate static var random: UIColor {
		let r = CGFloat (arc4random ()) / CGFloat (UInt32.max);
		let g = CGFloat (arc4random ()) / CGFloat (UInt32.max);
		let b = CGFloat (arc4random ()) / CGFloat (UInt32.max);
		let a = 0.4 * CGFloat (arc4random ()) / CGFloat (UInt32.max);
		return UIColor (red: r, green: g, blue: b, alpha: a);
	}
}

private class CustomDrawingVC: SelectionTrackingCalendarVC {
	private struct CellRenderer: CPCDayCellRenderer {
		fileprivate func drawCell (in context: CPCDayCellRenderer.Context) {
			let ctx = context.graphicsContext;
			
			ctx.setFillColor (UIColor.random.cgColor);
			ctx.fill (context.frame);
			ctx.setFillColor (UIColor.random.cgColor);
			ctx.fill (context.titleFrame);
			
			self.drawCellTitle (in: context);
		}
	}
	
	fileprivate override func viewDidLoad() {
		super.viewDidLoad ();
		self.calendarView.cellRenderer = CellRenderer ();
	}
}

private class WeirdCalendarVC: SelectionTrackingCalendarVC {
	fileprivate var identifier: Calendar.Identifier;
	
	fileprivate init (identifier: Calendar.Identifier) {
		self.identifier = identifier;
		super.init (title: Locale (identifier: "en_US_POSIX").localizedString (for: identifier) ?? "\(identifier)");
	}
	
	fileprivate required init? (coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	fileprivate required init(title: String) {
		fatalError("init(title:) has not been implemented")
	}
	
	fileprivate override func viewDidLoad () {
		super.viewDidLoad ();
		
		var calendar = Calendar (identifier: self.identifier);
		calendar.locale = Bundle.main.preferredLocalizations.first.map (Locale.init) ?? Locale.current;
		self.calendarView.calendar = calendar;
		self.weekView.calendar = calendar;
	}
}

private class ColumnedCalendarVC: SelectionTrackingCalendarVC {
	fileprivate override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return [.portrait, .landscapeLeft, .landscapeRight];
	}
	
	fileprivate override func viewDidLoad () {
		super.viewDidLoad ();
		self.updateLayout (for: self.view.bounds.size);
	}
	
	fileprivate override func viewWillTransition (to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition (to: size, with: coordinator);
		self.updateLayout (for: size);
	}
	
	private func updateLayout (for size: CGSize) {
		if (size.width > size.height) {
			self.columnCount = 2;
			self.columnContentInset = UIEdgeInsets (top: 8.0, left: 8.0, bottom: 8.0, right: 8.0);
		} else {
			self.columnCount = 1;
			self.columnContentInset = .zero;
		}
	}
}

private struct DefaultConfigItem: ConfigItemPushingCalendarController {
	fileprivate let localizedTitle: String;
	fileprivate let calendarTitle: String;
	fileprivate let initialSelection: CPCViewSelection;
	fileprivate let enabledDates: Range <Date>?;
	
	fileprivate init (localizedTitle: String, calendarTitle: String, initialSelection: CPCViewSelection, enabledDates: Range <Date>? = nil) {
		self.localizedTitle = localizedTitle;
		self.calendarTitle = calendarTitle;
		self.initialSelection = initialSelection;
		self.enabledDates = enabledDates;
	}
}

private struct CustomSelectionHandlingItem: ConfigItemPushingCalendarController {
	fileprivate let localizedTitle: String;
	fileprivate let calendarTitle: String;
	
	fileprivate var calendarViewControllerClass: SelectionTrackingCalendarVC.Type {
		return CustomSelectionHandlingVC.self;
	}

	fileprivate var initialSelection: CPCViewSelection {
		return .unordered ([]);
	}
}

private struct CustomDrawingItem: ConfigItemPushingCalendarController {
	fileprivate let localizedTitle: String;
	fileprivate let calendarTitle: String;
	
	fileprivate var calendarViewControllerClass: SelectionTrackingCalendarVC.Type {
		return CustomDrawingVC.self;
	}
	
	fileprivate var initialSelection: CPCViewSelection {
		return .none;
	}
}

private struct WeirdCalendarItem: ConfigItemPushingViewController {
	fileprivate var localizedTitle: String {
		return Locale (identifier: "en_US_POSIX").localizedString (for: self.identifier) ?? "\(self.identifier)";
	}
	
	fileprivate let identifier: Calendar.Identifier;
	
	fileprivate var targetViewController: UIViewController {
		let result = WeirdCalendarVC (identifier: self.identifier);
		result.identifier = self.identifier;
		result.selection = .range (.today ..< .today);
		return result;
	}
}

private struct ColumnedCalendarItem: ConfigItemPushingCalendarController {
	fileprivate let localizedTitle: String;
	fileprivate let calendarTitle: String;

	fileprivate var calendarViewControllerClass: SelectionTrackingCalendarVC.Type {
		return ColumnedCalendarVC.self;
	}
	
	fileprivate var initialSelection: CPCViewSelection {
		return .none;
	}
}
