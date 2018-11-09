//
//  CPCCalendarUnit_CalendarWrapper.swift
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

/// Wraps a Calendar instance into a reference type to enable short-circuit equality evaluation using identity operator.
internal final class CPCCalendarWrapper: NSObject {
	private static var instances = UnfairThreadsafeStorage (UnownedDictionary <Calendar, CPCCalendarWrapper> ());
	
	internal static var currentUsed: CPCCalendarWrapper {
		return Calendar.currentUsed.wrapped ();
	}
	
	/// Wrapped Calendar instance
	internal let calendar: Calendar;
	private let calendarHashValue: Int;
	
	internal override var hash: Int {
		return self.calendarHashValue;
	}

	internal var unitSpecificCaches = UnfairThreadsafeStorage ([ObjectIdentifier: AnyObject & UnitSpecificCacheProtocol] ());
	internal var commonUnitCaches = UnfairThreadsafeStorage ([ObjectIdentifier: AnyObject & CommonUnitValuesCacheProtocol] ());
	
	private var lastCachesPurgeTimestamp = Date.timeIntervalSinceReferenceDate;
	private var mainRunLoopObserver: CFRunLoopObserver?;
	private var mainRunLoopObserverRefCount = 0;
	
	internal static func == (lhs: CPCCalendarWrapper, rhs: CPCCalendarWrapper) -> Bool {
		return (lhs === rhs);
	}
	
	fileprivate static func wrap (_ calendar: Calendar) -> CPCCalendarWrapper {
		return self.instances.withMutableStoredValue {
			if let existingWrapper = $0 [calendar] {
				return existingWrapper;
			}
			
			let wrapper = CPCCalendarWrapper (calendar);
			$0 [calendar] = wrapper;
			return wrapper;
		};
	}
	
	/// Initializes a new CalendarWrapper
	///
	/// - Parameter calendar: Calendar to wrap
	private init (_ calendar: Calendar) {
		self.calendar = calendar;
		self.calendarHashValue = calendar.hashValue;
		super.init ();
	}
	
	deinit {
		self.unscheduleGarbageCollector ();
		CPCCalendarWrapper.instances.withMutableStoredValue { [unowned self] caches in
			caches [self.calendar] = nil;
		};
	}
	
	internal func retainGarbageCollector () {
		guard Thread.isMainThread else {
			return DispatchQueue.main.sync (execute: self.retainGarbageCollector);
		}
		if (self.mainRunLoopObserverRefCount == 0) {
			self.scheduleGarbageCollector ();
		}
		self.mainRunLoopObserverRefCount += 1;
	}
	
	internal func releaseGarbageCollector () {
		guard Thread.isMainThread else {
			return DispatchQueue.main.sync (execute: self.releaseGarbageCollector);
		}
		guard self.mainRunLoopObserverRefCount > 0 else {
			return;
		}
		self.mainRunLoopObserverRefCount -= 1;
		if (self.mainRunLoopObserverRefCount == 0) {
			self.unscheduleGarbageCollector ();
		}
	}
	
	private func scheduleGarbageCollector () {
		var context = Unmanaged <CPCCalendarWrapper>.makeRunLoopObserverContext (observer: self);
		let observer = CFRunLoopObserverCreate (kCFAllocatorDefault, CFRunLoopActivity.beforeWaiting.rawValue, true, 0, CPCCalendarViewMainRunLoopObserver, &context);
		self.mainRunLoopObserver = observer;
		CFRunLoopAddObserver (CFRunLoopGetMain (), observer, CFRunLoopMode.commonModes);
	}
	
	private func unscheduleGarbageCollector () {
		if let mainRunLoopObserver = self.mainRunLoopObserver {
			CFRunLoopRemoveObserver (CFRunLoopGetMain (), mainRunLoopObserver, CFRunLoopMode.commonModes);
			self.mainRunLoopObserver = nil;
		};
		self.purgeCacheIfNeeded ();
		self.invalidateCommonUnitsCaches ();
		DateFormatter.eraseCachedFormatters (calendar: self);
	}
	
	internal override func isEqual (_ object: Any?) -> Bool {
		return self === object as? CPCCalendarWrapper;
	}
	
	internal func mainRunLoopWillStartWaiting () {
		let currentTimestamp = Date.timeIntervalSinceReferenceDate;
		guard (currentTimestamp - self.lastCachesPurgeTimestamp) > 10.0 else {
			return;
		}
		self.lastCachesPurgeTimestamp = currentTimestamp;
		self.purgeCacheIfNeeded ();
	}
}

private func CPCCalendarViewMainRunLoopObserver (observer: CFRunLoopObserver!, activity: CFRunLoopActivity, calendarPtr: UnsafeMutableRawPointer?) {
	guard let calendarWrapper = calendarPtr.map ({ Unmanaged <CPCCalendarWrapper>.fromOpaque ($0).takeUnretainedValue () }) else {
		return;
	}
	calendarWrapper.mainRunLoopWillStartWaiting ();
}

public extension Calendar {
	internal func wrapped () -> CPCCalendarWrapper {
		return CPCCalendarWrapper.wrap (self);
	}
}

fileprivate extension Unmanaged {
	fileprivate static func makeRunLoopObserverContext (observer: Instance) -> CFRunLoopObserverContext {
		return CFRunLoopObserverContext (
			version: 0,
			info: self.passUnretained (observer).toOpaque (),
			retain: { Unmanaged <AnyObject>.retain ($0) },
			release: { Unmanaged <AnyObject>.release ($0) },
			copyDescription: { Unmanaged <AnyObject>.copyDescription ($0) }
		);
	}
}

private extension Unmanaged {
	private static func retain (_ opaque: UnsafeRawPointer?) -> UnsafeRawPointer? {
		return UnsafeRawPointer (opaque.map { Unmanaged.fromOpaque ($0).retain ().toOpaque () });
	}
	
	private static func release (_ opaque: UnsafeRawPointer?) {
		opaque.map { Unmanaged.fromOpaque ($0).release () };
	}

	private static func copyDescription (_ opaque: UnsafeRawPointer?) -> Unmanaged <CFString>? {
		guard let opaque = opaque, let object = Unmanaged.fromOpaque (opaque).takeUnretainedValue () as? CustomStringConvertible else {
			return nil;
		}
		return Unmanaged <CFString>.passRetained (object.description as CFString);
	}
}
