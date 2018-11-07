//
//  CPCCalendarUnitsStorage.h
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

#ifndef CPCCalendarUnitsStorage_h
#define CPCCalendarUnitsStorage_h

#include <stdint.h>
#include <assert.h>
#include <CoreFoundation/CFBase.h>

#pragma pack (push, 1)

struct CPCDayBackingStorage {
	intptr_t era: 20;
	intptr_t year: 28;
	intptr_t month: 8;
	intptr_t day: 8;
} CF_REFINED_FOR_SWIFT;
typedef struct CPCDayBackingStorage CPCDayBackingStorage;

#if __LP64__

#pragma pack (push, 4)

struct CPCMonthBackingStorage {
	intptr_t era: 20;
	intptr_t year: 28;
	intptr_t month: 8;
} CF_REFINED_FOR_SWIFT;
typedef struct CPCMonthBackingStorage CPCMonthBackingStorage;

struct CPCYearBackingStorage {
	intptr_t era: 20;
	intptr_t year: 28;
} CF_REFINED_FOR_SWIFT;
typedef struct CPCYearBackingStorage CPCYearBackingStorage;

#pragma pack (pop)

CF_INLINE CF_SWIFT_NAME (CPCMonthBackingStorage.init(containing:))
CPCMonthBackingStorage CPCDayBackingStorageGetMonthStorage (CPCDayBackingStorage storage) {
	return *((CPCMonthBackingStorage *) &storage);
}

CF_INLINE CF_SWIFT_NAME (CPCYearBackingStorage.init(containing:))
CPCYearBackingStorage CPCDayBackingStorageGetYearStorage (CPCDayBackingStorage storage) {
	return *((CPCYearBackingStorage *) &storage);
}

CF_INLINE CF_SWIFT_NAME (CPCYearBackingStorage.init(containing:))
CPCYearBackingStorage CPCMonthBackingStorageGetYearStorage (CPCMonthBackingStorage storage) {
	return *((CPCYearBackingStorage *) &storage);
}

#else

typedef CF_ENUM (uintptr_t, CPCYearMonthStorageLayout) {
	CPCYearMonthStorageLayoutDefault = 0,
	CPCYearMonthStorageLayoutJapanese = 2,
	CPCYearMonthStorageLayoutChinese = 3,
} CF_REFINED_FOR_SWIFT;

union CPCYearMonthStorage {
	struct {
		CPCYearMonthStorageLayout const layout: 2;
		intptr_t opaque: 30;
	};
	
	struct {
		CPCYearMonthStorageLayout layoutID: 2;
		uintptr_t era: 1;
		intptr_t year: 25;
		uintptr_t month: 4;
	} _defaultLayout;

	struct {
		CPCYearMonthStorageLayout layoutID: 2;
		uintptr_t era: 8;
		intptr_t year: 18;
		uintptr_t month: 4;
	} _japaneseLayout;

	struct {
		CPCYearMonthStorageLayout layoutID: 2;
		uintptr_t era: 19;
		intptr_t year: 6;
		intptr_t month: 5;
	} _chineseLayout;
} CF_SWIFT_UNAVAILABLE ("Implementation details");
typedef union CPCYearMonthStorage CPCYearMonthStorage;

struct CPCMonthBackingStorage {
	CPCYearMonthStorage storage;
} CF_REFINED_FOR_SWIFT;
typedef struct CPCMonthBackingStorage CPCMonthBackingStorage;

struct CPCYearBackingStorage {
	CPCYearMonthStorage storage;
} CF_REFINED_FOR_SWIFT;
typedef struct CPCYearBackingStorage CPCYearBackingStorage;

CF_INLINE CF_SWIFT_UNAVAILABLE ("Implementation details")
CPCYearMonthStorage CPCYearMonthStorageMake (intptr_t era, intptr_t year, intptr_t month, CPCYearMonthStorageLayout layout) {
	switch (layout) {
		case CPCYearMonthStorageLayoutDefault:
			return (CPCYearMonthStorage) { ._defaultLayout = { .layoutID = layout, .era = era, .year = year, .month = month } };
		case CPCYearMonthStorageLayoutJapanese:
			return (CPCYearMonthStorage) { ._japaneseLayout = { .layoutID = layout, .era = era, .year = year, .month = month } };
		case CPCYearMonthStorageLayoutChinese:
			return (CPCYearMonthStorage) { ._chineseLayout = { .layoutID = layout, .era = era, .year = year, .month = month } };
	}
}

CF_INLINE CF_SWIFT_UNAVAILABLE ("Implementation details")
intptr_t CPCYearMonthStorageGetEra (CPCYearMonthStorage storage) {
	switch (storage.layout) {
		case CPCYearMonthStorageLayoutDefault:
			return storage._defaultLayout.era;
		case CPCYearMonthStorageLayoutJapanese:
			return storage._japaneseLayout.era;
		case CPCYearMonthStorageLayoutChinese:
			return storage._chineseLayout.era;
	}
}

CF_INLINE CF_SWIFT_UNAVAILABLE ("Implementation details")
intptr_t CPCYearMonthStorageGetYear (CPCYearMonthStorage storage) {
	switch (storage.layout) {
		case CPCYearMonthStorageLayoutDefault:
			return storage._defaultLayout.year;
		case CPCYearMonthStorageLayoutJapanese:
			return storage._japaneseLayout.year;
		case CPCYearMonthStorageLayoutChinese:
			return storage._chineseLayout.year;
	}
}

CF_INLINE CF_SWIFT_UNAVAILABLE ("Implementation details")
intptr_t CPCYearMonthStorageGetMonth (CPCYearMonthStorage storage) {
	switch (storage.layout) {
		case CPCYearMonthStorageLayoutDefault:
			return storage._defaultLayout.month;
		case CPCYearMonthStorageLayoutJapanese:
			return storage._japaneseLayout.month;
		case CPCYearMonthStorageLayoutChinese:
			return storage._chineseLayout.month;
	}
}

CF_INLINE CF_SWIFT_NAME (CPCMonthBackingStorage.init(era:year:month:layout:))
CPCMonthBackingStorage CPCMonthBackingStorageMake (intptr_t era, intptr_t year, intptr_t month, CPCYearMonthStorageLayout layout) {
	return (CPCMonthBackingStorage) { .storage = CPCYearMonthStorageMake (era, year, month, layout) };
}

CF_INLINE CF_SWIFT_NAME (CPCMonthBackingStorage.init(containing:layout:))
CPCMonthBackingStorage CPCDayBackingStorageGetMonthStorage (CPCDayBackingStorage storage, CPCYearMonthStorageLayout layout) {
	return CPCMonthBackingStorageMake (storage.era, storage.year, storage.month, layout);
}

CF_INLINE CF_SWIFT_NAME (getter:CPCMonthBackingStorage.era(self:))
intptr_t CPCMonthBackingStorageGetEra (CPCMonthBackingStorage storage) {
	return CPCYearMonthStorageGetEra (storage.storage);
}

CF_INLINE CF_SWIFT_NAME (getter:CPCMonthBackingStorage.year(self:))
intptr_t CPCMonthBackingStorageGetYear (CPCMonthBackingStorage storage) {
	return CPCYearMonthStorageGetYear (storage.storage);
}

CF_INLINE CF_SWIFT_NAME (getter:CPCMonthBackingStorage.month(self:))
intptr_t CPCMonthBackingStorageGetMonth (CPCMonthBackingStorage storage) {
	return CPCYearMonthStorageGetMonth (storage.storage);
}

CF_INLINE CF_SWIFT_NAME (getter:CPCMonthBackingStorage.layout(self:))
CPCYearMonthStorageLayout CPCMonthBackingStorageGetLayout (CPCMonthBackingStorage storage) {
	return storage.storage.layout;
}

CF_INLINE CF_SWIFT_NAME (CPCYearBackingStorage.init(era:year:layout:))
CPCYearBackingStorage CPCYearBackingStorageMake (intptr_t era, intptr_t year, CPCYearMonthStorageLayout layout) {
	return (CPCYearBackingStorage) { .storage = CPCYearMonthStorageMake (era, year, 0, layout) };
}

CF_INLINE CF_SWIFT_NAME (CPCYearBackingStorage.init(containing:layout:))
CPCYearBackingStorage CPCDayBackingStorageGetYearStorage (CPCDayBackingStorage storage, CPCYearMonthStorageLayout layout) {
	return CPCYearBackingStorageMake (storage.era, storage.year, layout);
}

CF_INLINE CF_SWIFT_NAME (getter:CPCYearBackingStorage.era(self:))
intptr_t CPCYearBackingStorageGetEra (CPCYearBackingStorage storage) {
	return CPCYearMonthStorageGetEra (storage.storage);
}

CF_INLINE CF_SWIFT_NAME (getter:CPCYearBackingStorage.year(self:))
intptr_t CPCYearBackingStorageGetYear (CPCYearBackingStorage storage) {
	return CPCYearMonthStorageGetYear (storage.storage);
}

CF_INLINE CF_SWIFT_NAME (getter:CPCYearBackingStorage.layout(self:))
CPCYearMonthStorageLayout CPCYearBackingStorageGetLayout (CPCYearBackingStorage storage) {
	return storage.storage.layout;
}

CF_INLINE CF_SWIFT_NAME (CPCYearBackingStorage.init(containing:))
CPCYearBackingStorage CPCMonthBackingStorageGetYearStorage (CPCMonthBackingStorage storage) {
	return (CPCYearBackingStorage) { .storage = storage.storage };
}

#endif

#pragma pack (pop)

CF_INLINE CF_SWIFT_NAME (getter:CPCDayBackingStorage.rawValue(self:))
int64_t CPCDayBackingStorageGetRawValue (CPCDayBackingStorage storage) {
	union {
		CPCDayBackingStorage storage;
		int64_t rawValue;
	} helper = { .storage = storage };
	return helper.rawValue;
}
				
CF_INLINE CF_SWIFT_NAME (getter:CPCMonthBackingStorage.rawValue(self:))
int64_t CPCMonthBackingStorageGetRawValue (CPCMonthBackingStorage storage) {
	union {
		CPCMonthBackingStorage storage;
		intptr_t rawValue;
	} helper = { .storage = storage };
	return helper.rawValue;
}
				
CF_INLINE CF_SWIFT_NAME (getter:CPCYearBackingStorage.rawValue(self:))
int64_t CPCYearBackingStorageGetRawValue (CPCYearBackingStorage storage) {
	union {
		CPCYearBackingStorage storage;
		intptr_t rawValue;
	} helper = { .storage = storage };
	return helper.rawValue;
}
				
static_assert (sizeof (CPCDayBackingStorage) == sizeof (uint64_t), "Invalid sizeof (CPCDayBackingStorage)");
static_assert (sizeof (CPCMonthBackingStorage) == sizeof (intptr_t), "Invalid sizeof (CPCMonthBackingStorage)");
static_assert (sizeof (CPCYearBackingStorage) == sizeof (intptr_t), "Invalid sizeof (CPCYearBackingStorage)");

#endif /* CPCCalendarUnitsStorage_h */
