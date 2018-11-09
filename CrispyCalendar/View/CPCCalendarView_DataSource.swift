//
//  CPCCalendarView_DataSource.swift
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

internal extension CPCCalendarView {
	internal final class DataSource: NSObject {
		internal static let cellReuseIdentifier = "CellID";

		internal var calendar: CPCCalendarWrapper {
			return self.startingDay.calendarWrapper;
		}
		
		internal var minimumDate: Date?;
		
		internal var maximumDate: Date?;

		internal let startingDay: CPCDay;		
		internal let monthViewsManager: CPCMonthViewsManager;

		private let cache: Cache;
		private let referenceIndexPath: IndexPath;

		internal override convenience init () {
			self.init (statingAt: .today);
		}
		
		internal init (statingAt startingDay: CPCDay) {
			self.startingDay = startingDay;
			self.monthViewsManager = CPCMonthViewsManager ();
			self.referenceIndexPath = IndexPath (referenceForDay: startingDay);
			self.cache = Cache (startingYear: startingDay.containingYear);
			super.init ();
		}
		
		internal convenience init (statingAt startingMonth: CPCMonth) {
			self.init (statingAt: startingMonth.middleDay);
		}
		
		internal convenience init (statingAt startingYear: CPCYear) {
			self.init (statingAt: startingYear.middleDay);
		}
		
		internal init (replacing oldSource: DataSource, calendar: CPCCalendarWrapper) {
			self.startingDay = CPCDay (containing: oldSource.startingDay.start, calendar: calendar);
			self.monthViewsManager = oldSource.monthViewsManager;
			self.referenceIndexPath = IndexPath (referenceForDay: self.startingDay);
			self.cache = Cache (startingYear: self.startingDay.containingYear);
		}
	}
}

extension CPCCalendarView.DataSource: UIScrollViewDelegate {
	internal func scrollViewShouldScrollToTop (_ scrollView: UIScrollView) -> Bool {
		guard let collectionView = scrollView as? UICollectionView else {
			return true;
		}
		self.scrollToToday (collectionView);
		return false;
	}
}

extension CPCCalendarView.DataSource: UICollectionViewDataSource {
	internal func collectionView (_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return .virtualItemsCount;
	}

	internal func collectionView (_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = guarantee (collectionView.dequeueReusableCell (withReuseIdentifier: CPCCalendarView.DataSource.cellReuseIdentifier, for: indexPath) as? CPCCalendarView.Cell);
		cell.monthViewsManager = self.monthViewsManager;
		if let month = self.cachedMonth (for: indexPath) {
			cell.month = month;
		} else {
			self.prepareCacheData (for: indexPath, highPriority: true, collectionView: collectionView);
		}
		return cell;
	}
}

extension CPCCalendarView.DataSource: UICollectionViewDataSourcePrefetching {
	internal func collectionView (_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
		guard let (minIndexPath, maxIndexPath) = indexPaths.minmax () else {
			return;
		}
		if (self.cachedMonth (for: minIndexPath) == nil) {
			self.cache.fetchCacheItems (for: minIndexPath, highPriority: false, completion: self.monthsUpdateHandler (collectionView));
		}
		if (self.cachedMonth (for: maxIndexPath) == nil) {
			self.cache.fetchCacheItems (for: minIndexPath, highPriority: false, completion: self.monthsUpdateHandler (collectionView));
		}
	}
}

internal extension CPCCalendarView.DataSource {
	internal func scrollToToday (_ collectionView: UICollectionView, animated: Bool = true) {
		return self.scroll (collectionView: collectionView,  to: CPCDay (containing: self.scrollToTodayDate, calendar: self.calendar), animated: animated);
	}
	
	internal func scroll (collectionView: UICollectionView, to day: CPCDay, animated: Bool = true) {
		let distance = self.startingMonth.distance (to: day.containingMonth);
		let indexPath = self.referenceIndexPath.offset (by: distance);
		collectionView.scrollToItem (at: indexPath, at: .centeredVertically, animated: animated);
	}
}

extension CPCCalendarView.DataSource: CPCCalendarViewLayoutDelegate {
	internal func referenceIndexPathForCollectionView (_ collectionView: UICollectionView) -> IndexPath {
		return self.referenceIndexPath;
	}
	
	internal func collectionView (_ collectionView: UICollectionView, estimatedAspectRatioComponentsForItemAt indexPath: IndexPath) -> CPCMonthView.AspectRatio {
		let partialAttributes = self.monthViewsManager.monthViewPartialLayoutAttributes (separatorWidth: collectionView.separatorWidth);
		if let month = self.cachedMonth (for: indexPath) {
			return CPCMonthView.aspectRatioComponents (for: CPCMonthView.LayoutAttributes (month: month, partialAttributes: partialAttributes))!;
		}
		
		let aspectRatiosRange = CPCMonthView.aspectRatiosComponentsRange (for: partialAttributes, using: self.calendar.calendar);
		return (
			multiplier: sqrt (aspectRatiosRange.lower.multiplier * aspectRatiosRange.upper.multiplier),
			constant: (aspectRatiosRange.lower.constant + aspectRatiosRange.upper.constant) / 2
		);
	}
	
	internal func collectionView (_ collectionView: UICollectionView, startOfSectionFor indexPath: IndexPath) -> IndexPath {
		let month = self.cache.month (for: indexPath), year = month.containingYear, monthIndex = year.index (of: month)!;
		return indexPath.offset (by: year.distance (from: monthIndex, to: year.startIndex));
	}
	
	internal func collectionView (_ collectionView: UICollectionView, endOfSectionFor indexPath: IndexPath) -> IndexPath {
		let month = self.cache.month (for: indexPath), year = month.containingYear, monthIndex = year.index (of: month)!;
		return indexPath.offset (by: year.distance (from: monthIndex, to: year.endIndex));
	}
	
	internal func collectionView (_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		if let cell = cell as? CPCCalendarView.Cell {
			cell.monthViewsManager = self.monthViewsManager;
			cell.month = self.cachedMonth (for: indexPath);
			
			let minimumDay: CPCDay?, maximumDay: CPCDay?;
			if let minimumDate = self.minimumDate {
				minimumDay = CPCDay (containing: minimumDate, calendar: self.calendar);
			} else {
				minimumDay = nil;
			}
			if let maximumDate = self.maximumDate {
				maximumDay = CPCDay (containing: maximumDate, calendar: self.calendar);
			} else {
				maximumDay = nil;
			}
			switch (minimumDay, maximumDay) {
			case (nil, nil):
				cell.enabledRegion = nil;
			case (.some (let minimumDay), nil):
				cell.enabledRegion = minimumDay ..< CPCDay (containing: .distantFuture, calendar: self.calendar);
			case (nil, .some (let maximumDay)):
				cell.enabledRegion = CPCDay (containing: .distantPast, calendar: self.calendar) ..< maximumDay;
			case (.some (let minimumDay), .some (let maximumDay)):
				cell.enabledRegion = minimumDay ..< maximumDay;
			}
		}
	}
}

private extension CPCCalendarView.DataSource {
	private final class Cache {
		private var cachedMonths: FloatingBaseArray <CPCMonth>;
		private var updatesLock = DispatchSemaphore (value: 1);
		private var firstCalculatedIndexPath = UnfairThreadsafeStorage (IndexPath?.none);
		private var lastCalculatedIndexPath = UnfairThreadsafeStorage (IndexPath?.none);

		private let backgroundQueue = DispatchQueue (label: "CPCCalendarDataSourceCache", qos: .default, attributes: .concurrent);
		private let priorityQueue = DispatchQueue (label: "CPCCalendarDataSourceCeche", qos: .userInteractive, attributes: .concurrent);
		
		fileprivate init (startingYear: CPCYear) {
			let prevYear = startingYear.prev, nextYear = startingYear.next;
			self.cachedMonths = FloatingBaseArray (Array (prevYear) + startingYear + nextYear, baseOffset: .zerothVirtualItemIndex - prevYear.count);
		}
		
		fileprivate func cachedMonth (for indexPath: IndexPath) -> CPCMonth? {
			return self.cachedMonths.indices.contains (indexPath.item) ? self.cachedMonths [indexPath.item] : nil;
		}
		
		fileprivate func month (for indexPath: IndexPath) -> CPCMonth {
			let nearestMonthIndex: Int;
			if (indexPath.item < self.cachedMonths.startIndex) {
				nearestMonthIndex = self.cachedMonths.startIndex;
			} else if (indexPath.item >= self.cachedMonths.endIndex) {
				nearestMonthIndex = self.cachedMonths.endIndex - 1;
			} else {
				return self.cachedMonths [indexPath.item];
			}
			
			return self.cachedMonths [nearestMonthIndex].advanced (by: indexPath.item - nearestMonthIndex);
		}
		
		fileprivate func fetchCacheItems (for indexPath: IndexPath, highPriority: Bool, completion: @escaping (_ updated: [IndexPath]) -> ()) {
			let canCalculateEarlierMonths: Bool = self.firstCalculatedIndexPath.withMutableStoredValue {
				if let currentFirstIndexPath = $0, (indexPath >= currentFirstIndexPath) {
					return false;
				}
				$0 = indexPath;
				return true;
			}
			let canCalculateLaterMonths: Bool = self.lastCalculatedIndexPath.withMutableStoredValue {
				if let currentLastIndexPath = $0, (indexPath < currentLastIndexPath) {
					return false;
				}
				$0 = indexPath.offset (by: -1);
				return true;
			}

			guard (canCalculateLaterMonths || canCalculateEarlierMonths), !(self.cachedMonths.indices ~= indexPath.item) else {
				return;
			}
			(highPriority ? self.priorityQueue : self.backgroundQueue).async { self.calculateAndStoreYears (untilReaching: indexPath, completion: completion) };
		}
		
		private func determineCalculationAttributes (for indexPath: IndexPath) -> (start: CPCMonth, targetCount: Int, advance: Int)? {
			self.updatesLock.wait ();
			defer { self.updatesLock.signal () }

			if (indexPath.item < self.cachedMonths.startIndex) {
				return (
					start: self.cachedMonths [self.cachedMonths.startIndex],
					targetCount: self.cachedMonths.startIndex - indexPath.item,
					advance: -1
				);
			} else if (indexPath.item >= self.cachedMonths.endIndex) {
				return (
					start: self.cachedMonths [self.cachedMonths.endIndex - 1],
					targetCount: indexPath.item - self.cachedMonths.endIndex + 1,
					advance: 1
				);
			} else {
				return nil;
			}
		}
		
		private func calculateAndStoreYears (untilReaching indexPath: IndexPath, completion: @escaping (_ updated: [IndexPath]) -> ()) {
			guard let (start, targetCount, advance) = self.determineCalculationAttributes (for: indexPath) else {
				return;
			}
			
			var months = [CPCMonth] (), minimumIndexPath: IndexPath?, maximumIndexPath: IndexPath?;
			months.reserveCapacity (targetCount);
			for _ in 0 ..< targetCount {
				months.append ((months.last ?? start).advanced (by: advance));
			}
			let lastMonth = months.last ?? start, lastYear = lastMonth.containingYear, monthIndex = lastYear.index (of: lastMonth)!, endIndexPath: IndexPath;
			if (advance > 0) {
				let additionalMonths = lastYear [lastYear.index (after: monthIndex)...];
				months.append (contentsOf: additionalMonths);
				endIndexPath = indexPath.offset (by: additionalMonths.count)
			} else {
				let additionalMonths = lastYear [..<monthIndex];
				months.append (contentsOf: additionalMonths.reversed ());
				endIndexPath = indexPath.offset (by: -additionalMonths.count);
			}
			
			self.updatesLock.wait ();
			defer { self.updatesLock.signal () }
			
			let indexPaths: [IndexPath];
			if (endIndexPath.item < self.cachedMonths.startIndex) {
				indexPaths = (endIndexPath.item ..< self.cachedMonths.startIndex).map { IndexPath (item: $0, section: 0) };
				self.cachedMonths.prepend (contentsOf: months.suffix (indexPaths.count).reversed ());
			} else if (endIndexPath.item >= self.cachedMonths.endIndex) {
				indexPaths = (self.cachedMonths.endIndex ... endIndexPath.item).map { IndexPath (item: $0, section: 0) };
				self.cachedMonths.append (contentsOf: months.suffix (indexPaths.count));
			} else {
				return;
			}

			DispatchQueue.main.async {
				completion (indexPaths);
			};
		}
	}
}


fileprivate extension CPCCalendarView.DataSource {
	fileprivate var startingMonth: CPCMonth {
		return self.startingDay.containingMonth;
	}
	
	fileprivate var startingYear: CPCYear {
		return self.startingDay.containingYear;
	}
	
	fileprivate func cachedMonth (for indexPath: IndexPath) -> CPCMonth? {
		return self.cache.cachedMonth (for: indexPath);
	}
	
	private func prepareCacheData (for indexPath: IndexPath, highPriority: Bool, collectionView: UICollectionView) {
		self.cache.fetchCacheItems (for: indexPath, highPriority: highPriority, completion: self.monthsUpdateHandler (collectionView));
	}
	
	private func monthsUpdateHandler (_ collectionView: UICollectionView) -> ([IndexPath]) -> () {
		return { [weak self, weak collectionView] indexPaths in
			guard let strongSelf = self else {
				return;
			}
			
			guard let collectionView = collectionView, collectionView.dataSource === strongSelf else {
				return;
			}
			collectionView.reloadItems (at: indexPaths);
		}
	}

	private var scrollToTodayDate: Date {
		if let minimumDate = self.minimumDate, minimumDate.timeIntervalSinceNow > 0.0 {
			return minimumDate;
		} else if let maximumDate = self.maximumDate, maximumDate.timeIntervalSinceNow < 0.0 {
			return maximumDate;
		} else {
			return Date ();
		}
	}
}

fileprivate extension IndexPath {
	fileprivate init (referenceForDay day: CPCDay) {
		self.init (item: .zerothVirtualItemIndex + day.containingYear [ordinal: 0].distance (to: day.containingMonth), section: 0);
	}
}

fileprivate extension Sequence where Element: Comparable {
	fileprivate func minmax () -> (minimum: Element, maximum: Element)? {
		var iterator = self.makeIterator ();
		guard let first = iterator.next () else {
			return nil;
		}
		var result = (minimum: first, maximum: first);
		while let next = iterator.next () {
			result.minimum = Swift.min (result.minimum, next);
			result.maximum = Swift.max (result.maximum, next);
		}
		return result;
	}
}

fileprivate extension CPCCalendarUnit {
	fileprivate var middleDay: CPCDay {
		return CPCDay (containing: self.start + self.duration / 2, calendar: self.calendarWrapper);
	}
}

fileprivate extension Int {
	fileprivate static let virtualItemsCount = 0x40000;
	fileprivate static let zerothVirtualItemIndex = Int.virtualItemsCount / 2;
}
