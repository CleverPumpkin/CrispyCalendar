//
//  ThreadsafeStorage.swift
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

import Swift
import os.lock
import Dispatch

internal protocol ThreadsafeStorageLockWrapper {
	func lock ();
	func unlock ();
}

internal protocol ThreadsafeStorageLock {
	func makeLockWrapper () -> ThreadsafeStorageLockWrapper;
}

private protocol ThreadsafeStorageLockObject: ThreadsafeStorageLock, AnyObject {
	func lock ();
	func unlock ();
}

private protocol ThreadsafeStorageLockValue: ThreadsafeStorageLock {
	static func lock (_ lock: inout Self);
	static func unlock (_ lock: inout Self);
}

private struct UnavailableLockWrapper: ThreadsafeStorageLockWrapper {
	fileprivate init () {
		fatalError ();
	}
	
	internal func lock () {}
	internal func unlock () {}
}

private struct ThreadsafeStorageLockObjectWrapper <Lock>: ThreadsafeStorageLockWrapper where Lock: ThreadsafeStorageLockObject {
	private let lockObject: Lock;
	
	fileprivate init (_ lock: Lock) {
		self.lockObject = lock;
	}

	internal func lock () {
		self.lockObject.lock ();
	}
	
	internal func unlock () {
		self.lockObject.unlock ();
	}
}

private final class ThreadsafeStorageLockValueWrapper <Lock>: ThreadsafeStorageLockWrapper where Lock: ThreadsafeStorageLockValue {
	private var lockValue: Lock;
	
	fileprivate init (_ lock: Lock) {
		self.lockValue = lock;
	}

	internal func lock () {
		Lock.lock (&self.lockValue);
	}
	
	internal func unlock () {
		Lock.unlock (&self.lockValue);
	}
}

internal protocol ThreadsafeStorageProtocol {
	associatedtype ValueType;
	
	func withStoredValue <T> (perform block: (ValueType) -> T) -> T;
	mutating func withMutableStoredValue <T> (perform block: (inout ValueType) -> T) -> T;
}

internal struct ThreadsafeStorage <Lock, Value> {
	internal typealias LockType = Lock;
	internal typealias ValueType = Value;
	
	private var lockWrapper: ThreadsafeStorageLockWrapper;
	private var value: Value;
	
	private init (lockWrapper: ThreadsafeStorageLockWrapper, value: Value) {
		self.lockWrapper = lockWrapper;
		self.value = value;
	}
}

extension ThreadsafeStorage: ThreadsafeStorageProtocol where Lock: ThreadsafeStorageLock {
	internal init (_ value: ValueType) {
		fatalError ("Cannot instantiate \(ThreadsafeStorage.self) with Lock == \(Lock.self)");
	}
	
	private init (lock: Lock, value: ValueType) {
		self.init (lockWrapper: lock.makeLockWrapper (), value: value);
	}
	
	internal func withStoredValue <T> (perform block: (Value) -> T) -> T {
		self.lockWrapper.lock ();
		defer {
			self.lockWrapper.unlock ();
		}
		
		return block (self.value);
	}

	internal mutating func withMutableStoredValue <T> (perform block: (inout Value) -> T) -> T {
		self.lockWrapper.lock ();
		defer {
			self.lockWrapper.unlock ();
		}
		
		return block (&self.value);
	}
}

extension os_unfair_lock: ThreadsafeStorageLockValue {
	fileprivate static func lock (_ lock: inout os_unfair_lock) {
		os_unfair_lock_lock (&lock);
	}

	fileprivate static func unlock (_ lock: inout os_unfair_lock) {
		os_unfair_lock_unlock (&lock);
	}
	
	internal func makeLockWrapper () -> ThreadsafeStorageLockWrapper {
		return ThreadsafeStorageLockValueWrapper (self);
	}
}

internal extension ThreadsafeStorage where Lock == os_unfair_lock {
	internal init (_ value: Value) {
		self.init (lock: os_unfair_lock (), value: value);
	}
}

internal typealias UnfairThreadsafeStorage <Value> = ThreadsafeStorage <os_unfair_lock, Value>;

extension DispatchSemaphore: ThreadsafeStorageLockObject {
	fileprivate func lock () {
		self.wait ();
	}
	
	fileprivate func unlock () {
		self.signal ();
	}
	
	internal func makeLockWrapper () -> ThreadsafeStorageLockWrapper {
		return ThreadsafeStorageLockObjectWrapper (self);
	}
}

extension ThreadsafeStorage where Lock == DispatchSemaphore {
	internal init (_ value: Value) {
		self.init (lock: DispatchSemaphore (value: 1), value: value);
	}
}
