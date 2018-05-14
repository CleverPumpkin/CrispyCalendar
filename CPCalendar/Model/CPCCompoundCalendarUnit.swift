//
//  CPCCompoundCalendarUnit.swift
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

import Foundation

internal protocol CPCCompoundCalendarUnit: CPCCalendarUnit, RandomAccessCollection where Element: CPCCalendarUnit, Index == Int {
	var smallerUnitRange: Range <Int> { get };
}

private protocol CPCCompoundCalendarUnitSpecificCacheProtocol {
	var count: Int { get };
	
	func purge (factor: Double);
}

private final class CPCCalendarUnitElementsCache {
	private typealias UnitSpecificCacheProtocol = CPCCompoundCalendarUnitSpecificCacheProtocol;
	
	private final class UnitSpecificCache <Unit>: UnitSpecificCacheProtocol where Unit: CPCCompoundCalendarUnit {
		private struct UnusedItemsPurgingCache <Key, Value> where Key: Hashable {
			private struct ValueWrapper {
				fileprivate let value: Value;
				fileprivate let usageCount: Int;
			}
			
			fileprivate var count: Int {
				return self.values.count;
			}
			
			private var values: [Key: ValueWrapper] = {
				var result = [Key: ValueWrapper] ();
				result.reserveCapacity (CPCCalendarUnitElementsCache.cacheSizeThreshold);
				return result;
			} ();
			
			fileprivate init () {}
			
			fileprivate subscript (key: Key) -> Value? {
				mutating get {
					guard let value = self.values [key] else {
						return nil;
					}
					
					self.values [key] = ValueWrapper (value: value.value, usageCount: value.usageCount + 1);
					return value.value;
				}
				set {
					if let newValue = newValue {
						self.values [key] = ValueWrapper (value: newValue, usageCount: 0);
					} else {
						self.values [key] = nil;
					}
				}
			}
			
			fileprivate mutating func purge (factor: Double) {
				guard let maxUsageCount = self.values.max (by: { $0.value.usageCount < $1.value.usageCount })?.value.usageCount else {
					return;
				}
				
				let threshold = (Double (maxUsageCount) * factor).integerRounded (.down);
				self.values = self.values.filter { $0.value.usageCount >= threshold };
			}
		}
		
		private struct UnitValuesKey: Hashable {
			private let unit: Unit;
			private let index: Unit.Index;
			
			fileprivate var hashValue: Int {
				return concatenateHashValues (self.unit.hashValue, self.index, shiftAmount: log2i (self.unit.endIndex) + 1);
			}
			
			fileprivate init (_ unit: Unit, index: Unit.Index) {
				self.unit = unit;
				self.index = index;
			}
		}
		
		private struct UnitIndexesKey: Hashable {
			private let unit: Unit;
			private let element: Unit.Element;
			
			fileprivate var hashValue: Int {
				return hashIntegers (self.element.hashValue, self.unit.hashValue);
			}
			
			fileprivate init (_ unit: Unit, element: Unit.Element) {
				self.unit = unit;
				self.element = element;
			}
		}
		
		fileprivate static var instance: UnitSpecificCache {
			return CPCCalendarUnitElementsCache.shared.unitSpecificCaches.withMutableStoredValue { caches in
				let typeID = ObjectIdentifier (Unit.self);
				if let existingCache = caches [typeID] as? UnitSpecificCache {
					return existingCache;
				}
				let instance = UnitSpecificCache ();
				caches [typeID] = instance;
				return instance;
			};
		}
		
		fileprivate var count: Int {
			return self.smallerUnitValuesCache.withStoredValue { $0.count } + self.smallerUnitIndexesCache.withStoredValue { $0.count };
		}
		
		private var smallerUnitValuesCache = UnfairThreadsafeStorage (UnusedItemsPurgingCache <UnitValuesKey, Unit.Element> ());
		private var smallerUnitIndexesCache = UnfairThreadsafeStorage (UnusedItemsPurgingCache <UnitIndexesKey, Unit.Index> ());
		
		private init () {}
		
		fileprivate func calendarUnit (_ unit: Unit, elementAt index: Unit.Index) -> Unit.Element? {
			return self.smallerUnitValuesCache.withMutableStoredValue { $0 [UnitValuesKey (unit, index: index)] };
		}
		
		fileprivate func calendarUnit (_ unit: Unit, cacheElement element: Unit.Element, for index: Unit.Index) {
			return self.smallerUnitValuesCache.withMutableStoredValue { $0 [UnitValuesKey (unit, index: index)] = element };
		}
		
		fileprivate func calendarUnit (_ unit: Unit, indexOf element: Unit.Element) -> Unit.Index? {
			return self.smallerUnitIndexesCache.withMutableStoredValue { $0 [UnitIndexesKey (unit, element: element)] };
		}
		
		fileprivate func calendarUnit (_ unit: Unit, cacheIndex index: Unit.Index, for element: Unit.Element) {
			return self.smallerUnitIndexesCache.withMutableStoredValue { $0 [UnitIndexesKey (unit, element: element)] = index };
		}
		
		fileprivate func purge (factor: Double) {
			self.smallerUnitValuesCache.withMutableStoredValue {
				$0.purge (factor: factor);
			}
			self.smallerUnitIndexesCache.withMutableStoredValue {
				$0.purge (factor: factor);
			}
		}
	}

	fileprivate static let shared = CPCCalendarUnitElementsCache ();
	private static let cacheSizeThreshold = 20480;
	private static let cachePurgeFactor = 0.5;
	
	private var unitSpecificCaches = UnfairThreadsafeStorage ([ObjectIdentifier: UnitSpecificCacheProtocol] ());
	
	private var currentCacheSize: Int {
		return self.unitSpecificCaches.withStoredValue { $0.values.reduce (0) { $0 + $1.count } };
	}
	
	fileprivate func calendarUnit <Unit> (_ unit: Unit, elementAt index: Unit.Index) -> Unit.Element? where Unit: CPCCompoundCalendarUnit {
		return UnitSpecificCache <Unit>.instance.calendarUnit (unit, elementAt: index);
	}
	
	fileprivate func calendarUnit <Unit> (_ unit: Unit, cacheElement element: Unit.Element, for index: Unit.Index) where Unit: CPCCompoundCalendarUnit {
		self.purgeCacheIfNeeded ();
		return UnitSpecificCache <Unit>.instance.calendarUnit (unit, cacheElement: element, for: index);
	}
	
	fileprivate func calendarUnit <Unit> (_ unit: Unit, indexOf element: Unit.Element) -> Unit.Index? where Unit: CPCCompoundCalendarUnit {
		return UnitSpecificCache <Unit>.instance.calendarUnit (unit, indexOf: element);
	}
	
	fileprivate func calendarUnit <Unit> (_ unit: Unit, cacheIndex index: Unit.Index, for element: Unit.Element) where Unit: CPCCompoundCalendarUnit {
		self.purgeCacheIfNeeded ();
		return UnitSpecificCache <Unit>.instance.calendarUnit (unit, cacheIndex: index, for: element);
	}
	
	private func purgeCacheIfNeeded () {
		if (self.currentCacheSize > CPCCalendarUnitElementsCache.cacheSizeThreshold) {
			self.unitSpecificCaches.withMutableStoredValue { $0.values.forEach { $0.purge (factor: CPCCalendarUnitElementsCache.cachePurgeFactor) } };
		}
	}
}

extension CPCCompoundCalendarUnit {
	internal static func smallerUnitRange (for value: UnitBackingType, using calendar: Calendar) -> Range <Int> {
		return guarantee (calendar.range (of: Element.representedUnit, in: self.representedUnit, for: value.date (using: calendar)));
	}
	
	public var startIndex: Int {
		return self.smallerUnitRange.lowerBound;
	}
	
	public var endIndex: Int {
		return self.smallerUnitRange.upperBound;
	}
	
	public func index (of element: Element) -> Index? {
		if let cachedResult = CPCCalendarUnitElementsCache.shared.calendarUnit (self, indexOf: element) {
			return cachedResult;
		}
		
		let calendar = resultingCalendarForOperation (for: self, element);
		let startDate = self.startDate, elementStartDate = element.startDate;
		guard calendar.isDate (startDate, equalTo: elementStartDate, toGranularity: Self.representedUnit) else {
			return nil;
		}
		let result = guarantee (calendar.dateComponents ([Element.representedUnit], from: startDate, to: elementStartDate).value (for: Element.representedUnit));
		
		CPCCalendarUnitElementsCache.shared.calendarUnit (self, cacheIndex: result, for: element);
		return result;
	}

	public subscript (position: Int) -> Element {
		if let cachedResult = CPCCalendarUnitElementsCache.shared.calendarUnit (self, elementAt: position) {
			return cachedResult;
		}
		
		let result = Element (containing: self.startDate, calendar: self.calendar).advanced (by: position - self.smallerUnitRange.lowerBound);
		
		CPCCalendarUnitElementsCache.shared.calendarUnit (self, cacheElement: result, for: position);
		return result;
	}
	
	public subscript (ordinal position: Int) -> Element {
		return self [position + self.smallerUnitRange.lowerBound];
	}
}
