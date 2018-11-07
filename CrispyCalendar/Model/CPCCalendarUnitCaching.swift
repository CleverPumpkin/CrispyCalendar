//
//  CPCCalendarUnitCaching.swift
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

// MARK: - Caching interface

internal extension CPCCalendarUnit {
	/// Query calendar units cache for distance between two units.
	///
	/// - Parameter other: Calendar unit to fetch distance to.
	/// - Returns: Distance from this unit to `other` or nil if no such value was previously cached.
	internal func cachedDistance (to other: Self) -> Stride? {
		return self.calendarWrapper.unitSpecificCacheInstance ().calendarUnit (self, distanceTo: other);
	}
	
	/// Cache a distance between two calendar units.
	///
	/// - Parameter distance: Distance between this unit and `other` that is being cached.
	/// - Parameter other: Unit, distance to which is being cached.
	internal func cacheDistance (_ distance: Stride, to other: Self) {
		return self.calendarWrapper.unitSpecificCacheInstance ().calendarUnit (self, cacheDistance: distance, to: other);
	}

	/// Query calendar units cache for a unit that has specific distance from this one.
	///
	/// - Parameter stride: Required distance between units.
	/// - Returns: Unit that has requested distance from this one or nil if no such value was previously cached.
	internal func cachedAdvancedUnit (by stride: Self.Stride) -> Self? {
		return self.calendarWrapper.unitSpecificCacheInstance ().calendarUnit (self, advancedBy: stride);
	}
	
	/// Cache a calendar unit that has specific distance from this one.
	///
	/// - Parameter value: Calendar unit that is being cached.
	/// - Parameter distance: Distance to the unit that is being cached.
	internal func cacheUnitValue (_ value: Self, advancedBy distance: Stride) {
		return self.calendarWrapper.unitSpecificCacheInstance ().calendarUnit (self, cacheUnit: value, asAdvancedBy: distance);
	}
}

internal extension CPCCompoundCalendarUnit {
	/// Query calendar units cache for subunit of a compound calendar unit.
	///
	/// - Parameter index: Index of queried subunit.
	/// - Returns: Subunit at `index`ths place of this unit or nil if no such value was previously cached.
	internal func cachedElement (at index: Index) -> Element? {
		return self.calendarWrapper.unitSpecificCacheInstance ().calendarUnit (self, elementAt: index);
	}
	
	/// Cache a calendar subunit for specified position in this unit.
	///
	/// - Parameter element: Subunit that is being cached.
	/// - Parameter index: Index of cached subunit.
	internal func cacheElement (_ element: Element, for index: Index) {
		return self.calendarWrapper.unitSpecificCacheInstance ().calendarUnit (self, cacheElement: element, for: index);
	}
	
	/// Query calendar units cache for position of subunit in this one.
	///
	/// - Parameter element: Subunit, index of which is requested.
	/// - Returns: Index of given subunit or nil if no such value was previously cached.
	internal func cachedIndex (of element: Element) -> Index? {
		return self.calendarWrapper.unitSpecificCacheInstance ().calendarUnit (self, indexOf: element);
	}
	
	/// Cache position of a subunit inside this one.
	///
	/// - Parameter index: Position of given subunit that is being cached.
	/// - Parameter element: Subunit to cache index for.
	internal func cacheIndex (_ index: Index, for element: Element) {
		return self.calendarWrapper.unitSpecificCacheInstance ().calendarUnit (self, cacheIndex: index, for: element);
	}
}

// MARK: - Caching implementation declarations

internal protocol CPCCalendarUnitSpecificCacheProtocol {
	var count: Int { get };
	
	mutating func purge (factor: Double);
}

private protocol CPCUnusedItemsPurgingCacheProtocol {
	associatedtype KeyType where KeyType: Hashable;
	associatedtype ValueType;
	
	subscript (key: KeyType) -> ValueType? { mutating get set };
}

// MARK: - Cache implementation

internal extension CPCCalendarWrapper {
	internal typealias UnitSpecificCacheProtocol = CPCCalendarUnitSpecificCacheProtocol;
	
	fileprivate class UnitSpecificCacheBase <Unit>: UnitSpecificCacheProtocol where Unit: CPCCalendarUnit {
		private final class UnusedItemsPurgingCache <Key, Value>: CPCUnusedItemsPurgingCacheProtocol where Key: Hashable {
			fileprivate typealias KeyType = Key;
			fileprivate typealias ValueType = Value;
			
			private struct ValueWrapper {
				fileprivate let value: Value;
				fileprivate let usageCount: Int;
			}
			
			fileprivate var count: Int {
				return self.values.count;
			}
			
			private var values: [Key: ValueWrapper] = {
				var result = [Key: ValueWrapper] ();
				result.reserveCapacity (CPCCalendarWrapper.cacheSizeThreshold);
				return result;
			} ();
			
			fileprivate init () {}
			
			fileprivate subscript (key: Key) -> Value? {
				get {
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
			
			fileprivate func purge (factor: Double) {
				guard let maxUsageCount = self.values.max (by: { $0.value.usageCount < $1.value.usageCount })?.value.usageCount else {
					return;
				}
				
				let threshold = (Double (maxUsageCount) * factor).integerRounded (.down);
				let filteredValues = self.values.filter { $0.value.usageCount >= threshold };
				self.values.removeAll (keepingCapacity: true);
				for (key, value) in filteredValues {
					self.values [key] = value;
				}
			}
		}
		
		fileprivate struct ThreadsafePurgingCacheStorage <KeyComplement, Value>: CPCCalendarUnitSpecificCacheProtocol, CPCUnusedItemsPurgingCacheProtocol
			where KeyComplement: Hashable {
			
			fileprivate typealias KeyType = Key;
			fileprivate typealias ValueType = Value;
			
			fileprivate struct Key: Hashable {
				private let unit: Unit;
				private let complementValue: KeyComplement;
				
				fileprivate init (_ unit: Unit, pairedWith complementValue: KeyComplement) {
					self.unit = unit;
					self.complementValue = complementValue;
				}
			}
			
			fileprivate var count: Int {
				return self.storage.withStoredValue { $0.count };
			}
			
			private var storage = UnfairThreadsafeStorage (UnusedItemsPurgingCache <Key, Value> ());
			
			fileprivate subscript (key: Key) -> Value? {
				get { return self.storage.withStoredValue { $0 [key] } }
				set { self.storage.withMutableStoredValue { $0 [key] = newValue } }
			}
			
			fileprivate mutating func purge (factor: Double) {
				self.storage.withMutableStoredValue { $0.purge (factor: factor) };
			}
		}
		
		fileprivate var count: Int {
			var result = 0;
			self.enumerateSubcaches { (subcache: CPCCalendarUnitSpecificCacheProtocol) in result += subcache.count };
			return result;
		}
		
		private unowned let calendarWrapper: CPCCalendarWrapper;
		
		fileprivate required init (_ calendarWrapper: CPCCalendarWrapper) {
			self.calendarWrapper = calendarWrapper;
		}
		
		fileprivate func purge (factor: Double) {
			self.enumerateSubcaches { (subcache: inout CPCCalendarUnitSpecificCacheProtocol) in
				subcache.purge (factor: factor);
			};
		}
		
		fileprivate func enumerateSubcaches (using block: (CPCCalendarUnitSpecificCacheProtocol) -> ()) -> () {
			self.enumerateSubcaches { (subcache: inout CPCCalendarUnitSpecificCacheProtocol) in
				block (subcache);
			};
		}
		
		fileprivate func enumerateSubcaches (using block: (inout CPCCalendarUnitSpecificCacheProtocol) -> ()) -> () {}
	}
	
	fileprivate class UnitSpecificCache <Unit>: UnitSpecificCacheBase <Unit> where Unit: CPCCalendarUnit {
		private typealias UnitDistancesStorage = ThreadsafePurgingCacheStorage <Unit, Unit.Stride>;
		private typealias UnitAdvancesStorage = ThreadsafePurgingCacheStorage <Unit.Stride, Unit>;
		
		private var distancesCache = UnitDistancesStorage ();
		private var advancedUnitsCache = UnitAdvancesStorage ();
		
		fileprivate func calendarUnit (_ unit: Unit, distanceTo otherUnit: Unit) -> Unit.Stride? {
			return self.distancesCache [UnitDistancesStorage.Key (unit, pairedWith: otherUnit)];
		}
		
		fileprivate func calendarUnit (_ unit: Unit, cacheDistance distance: Unit.Stride, to otherUnit: Unit) {
			self.distancesCache [UnitDistancesStorage.Key (unit, pairedWith: otherUnit)] = distance;
			self.distancesCache [UnitDistancesStorage.Key (otherUnit, pairedWith: unit)] = -distance;
			self.advancedUnitsCache [UnitAdvancesStorage.Key (unit, pairedWith: distance)] = otherUnit;
			self.advancedUnitsCache [UnitAdvancesStorage.Key (otherUnit, pairedWith: -distance)] = unit;
		}
		
		fileprivate func calendarUnit (_ unit: Unit, advancedBy value: Unit.Stride) -> Unit? {
			return self.advancedUnitsCache [UnitAdvancesStorage.Key (unit, pairedWith: value)];
		}
		
		fileprivate func calendarUnit (_ unit: Unit, cacheUnit otherUnit: Unit, asAdvancedBy value: Unit.Stride) {
			self.advancedUnitsCache [UnitAdvancesStorage.Key (unit, pairedWith: value)] = otherUnit;
			self.advancedUnitsCache [UnitAdvancesStorage.Key (otherUnit, pairedWith: -value)] = unit;
			self.distancesCache [UnitDistancesStorage.Key (unit, pairedWith: otherUnit)] = value;
			self.distancesCache [UnitDistancesStorage.Key (otherUnit, pairedWith: unit)] = -value;
		}
		
		fileprivate override func enumerateSubcaches (using block: (CPCCalendarUnitSpecificCacheProtocol) -> ()) -> () {
			block (self.advancedUnitsCache);
			block (self.distancesCache);
		}
		
		fileprivate override func enumerateSubcaches (using block: (inout CPCCalendarUnitSpecificCacheProtocol) -> ()) -> () {
			super.enumerateSubcaches (using: block);
			
			var currentCache: CPCCalendarUnitSpecificCacheProtocol;
			currentCache = self.distancesCache; block (&currentCache); self.distancesCache = currentCache as! UnitDistancesStorage;
			currentCache = self.advancedUnitsCache; block (&currentCache); self.advancedUnitsCache = currentCache as! UnitAdvancesStorage;
		}
	}
	
	fileprivate final class CompoundUnitSpecificCache <Unit>: UnitSpecificCache <Unit> where Unit: CPCCompoundCalendarUnit {
		private typealias UnitValuesStorage = ThreadsafePurgingCacheStorage <Unit.Index, Unit.Element>;
		private typealias UnitIndexesStorage = ThreadsafePurgingCacheStorage <Unit.Element, Unit.Index>;
		
		private var smallerUnitValuesCache = UnitValuesStorage ();
		private var smallerUnitIndexesCache = UnitIndexesStorage ();
		
		fileprivate func calendarUnit (_ unit: Unit, elementAt index: Unit.Index) -> Unit.Element? {
			return self.smallerUnitValuesCache [UnitValuesStorage.Key (unit, pairedWith: index)];
		}
		
		fileprivate func calendarUnit (_ unit: Unit, cacheElement element: Unit.Element, for index: Unit.Index) {
			self.smallerUnitValuesCache [UnitValuesStorage.Key (unit, pairedWith: index)] = element;
			self.smallerUnitIndexesCache [UnitIndexesStorage.Key (unit, pairedWith: element)] = index;
		}
		
		fileprivate func calendarUnit (_ unit: Unit, indexOf element: Unit.Element) -> Unit.Index? {
			return self.smallerUnitIndexesCache [UnitIndexesStorage.Key (unit, pairedWith: element)];
		}
		
		fileprivate func calendarUnit (_ unit: Unit, cacheIndex index: Unit.Index, for element: Unit.Element) {
			self.smallerUnitIndexesCache [UnitIndexesStorage.Key (unit, pairedWith: element)] = index;
			self.smallerUnitValuesCache [UnitValuesStorage.Key (unit, pairedWith: index)] = element;
		}
		
		fileprivate override func enumerateSubcaches (using block: (CPCCalendarUnitSpecificCacheProtocol) -> ()) -> () {
			super.enumerateSubcaches (using: block);

			block (self.smallerUnitValuesCache);
			block (self.smallerUnitIndexesCache);
		}
		
		fileprivate override func enumerateSubcaches (using block: (inout CPCCalendarUnitSpecificCacheProtocol) -> ()) -> () {
			super.enumerateSubcaches (using: block);
			
			var currentCache: CPCCalendarUnitSpecificCacheProtocol;
			currentCache = self.smallerUnitValuesCache; block (&currentCache); self.smallerUnitValuesCache = currentCache as! UnitValuesStorage;
			currentCache = self.smallerUnitIndexesCache; block (&currentCache); self.smallerUnitIndexesCache = currentCache as! UnitIndexesStorage;
		}
	}

	private static let cacheSizeThreshold = 20480;
	private static let cachePurgeFactor = 0.5;
	
	private var currentCacheSize: Int {
		return self.unitSpecificCaches.withStoredValue { $0.values.reduce (0) { $0 + $1.count } };
	}

	internal func purgeCacheIfNeeded () {
		if (self.currentCacheSize > CPCCalendarWrapper.cacheSizeThreshold) {
			self.unitSpecificCaches.withMutableStoredValue {
				for key in $0.keys {
					$0 [key]?.purge (factor: CPCCalendarWrapper.cachePurgeFactor);
				}
			};
		}
	}

	fileprivate func unitSpecificCacheInstance <Unit, Cache> () -> Cache where Cache: CompoundUnitSpecificCache <Unit> {
		return self.unitSpecificCacheInstanceImpl ();
	}
	
	fileprivate func unitSpecificCacheInstance <Unit, Cache> () -> Cache where Cache: UnitSpecificCache <Unit> {
		return self.unitSpecificCacheInstanceImpl ();
	}
	
	private func unitSpecificCacheInstanceImpl <Unit, Cache> () -> Cache where Cache: UnitSpecificCacheBase <Unit> {
		return self.unitSpecificCaches.withMutableStoredValue { caches in
			let typeID = ObjectIdentifier (Unit.self);
			if let existingCache = caches [typeID] as? Cache {
				return existingCache;
			}
			let instance = Cache (self);
			caches [typeID] = instance;
			return instance;
		};
	}
}
