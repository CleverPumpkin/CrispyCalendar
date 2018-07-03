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

internal protocol ThreadsafeStorageProtocol {
	associatedtype ValueType;
	
	var value: ValueType { get set };
	
	func withStoredValue <T> (perform block: (ValueType) -> T) -> T;
	mutating func withMutableStoredValue <T> (perform block: (inout ValueType) -> T) -> T;
}

internal struct ThreadsafeStorage <Lock, Value> {
	internal typealias ValueType = Value;
	
	private let wrappedLock: LockWrapperProtocol;
	private var valueStorage: Value;
	
	fileprivate init (lock: LockWrapperProtocol, value: Value) {
		self.wrappedLock = lock;
		self.valueStorage = value;
	}
}

internal extension ThreadsafeStorage where Lock == os_unfair_lock {
	internal init (_ value: Value) {
		self.init (lock: UnfairLockWrapper (), value: value);
	}
}

internal extension ThreadsafeStorage where Lock == DispatchSemaphore {
	internal init (_ value: Value) {
		self.init (lock: DispatchSemaphore (asLockWrapper: ()), value: value);
	}
}

internal extension ThreadsafeStorage where Lock == pthread_rwlock_t {
	internal init (_ value: Value) {
		self.init (lock: PThreadRWLockWrapper (), value: value);
	}
}

extension ThreadsafeStorage: ThreadsafeStorageProtocol {
	internal var value: Value {
		get {
			return self.withStoredValue { $0 };
		}
		set {
			self.withMutableStoredValue {
				$0 = newValue;
			};
		}
	}
	
	internal func withStoredValue <T> (perform block: (Value) -> T) -> T {
		self.wrappedLock.beginAccessingValue ();
		let result = block (self.valueStorage);
		self.wrappedLock.endAccessingValue ();
		return result;
	}
	
	internal mutating func withMutableStoredValue <T> (perform block: (inout Value) -> T) -> T {
		self.wrappedLock.beginAccessingValue ();
		let result = block (&self.valueStorage);
		self.wrappedLock.endAccessingValue ();
		return result;
	}
}

internal typealias UnfairThreadsafeStorage <Value> = ThreadsafeStorage <os_unfair_lock, Value>;
internal typealias DispatchSemaphoreStorage <Value> = ThreadsafeStorage <DispatchSemaphore, Value>;
internal typealias PThreadRWLockStorage <Value> = ThreadsafeStorage <pthread_rwlock_t, Value>;

private protocol LockWrapperProtocol: AnyObject {
	func beginAccessingValue ();
	func endAccessingValue ();
	func beginAccessingMutableValue ();
	func endAccessingMutableValue ();
}

extension LockWrapperProtocol {
	fileprivate func beginAccessingMutableValue () {
		self.beginAccessingValue ();
	}
	
	fileprivate func endAccessingMutableValue () {
		self.endAccessingValue ();
	}
}

private final class UnfairLockWrapper: LockWrapperProtocol {
	private var lock: os_unfair_lock;
	
	fileprivate init () {
		self.lock = os_unfair_lock ();
	}
	
	fileprivate func beginAccessingValue () {
		os_unfair_lock_lock (&self.lock);
	}
	
	fileprivate func endAccessingValue () {
		os_unfair_lock_unlock (&self.lock);
	}
}

extension DispatchSemaphore: LockWrapperProtocol {
	fileprivate convenience init (asLockWrapper: ()) {
		self.init (value: 1);
	}

	fileprivate func beginAccessingValue () {
		self.wait ();
	}
	
	fileprivate func endAccessingValue () {
		self.signal ();
	}
}

private final class PThreadRWLockWrapper: LockWrapperProtocol {
	private var lock: pthread_rwlock_t;

	fileprivate init () {
		self.lock = pthread_rwlock_t ();
		pthread_rwlock_init (&self.lock, nil);
	}
	
	deinit {
		pthread_rwlock_destroy (&self.lock);
	}
	
	fileprivate func beginAccessingValue () {
		pthread_rwlock_rdlock (&self.lock);
	}
	
	fileprivate func beginAccessingMutableValue () {
		pthread_rwlock_wrlock (&self.lock);
	}
	
	fileprivate func endAccessingValue () {
		pthread_rwlock_unlock (&self.lock);
	}
}

