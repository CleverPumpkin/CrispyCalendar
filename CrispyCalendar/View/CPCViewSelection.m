//
//  CPCViewSelection.m
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

#import "CPCViewSelection.h"

@interface CPCViewSelection () {
	NSCalendar *_calendar;
	id _value;
}

- (instancetype) initWithValue: (id) value calendar: (NSCalendar *) calendar NS_DESIGNATED_INITIALIZER;

@end

@implementation CPCViewSelection

+ (instancetype) nullSelection {
	static CPCViewSelection *nullSelection = nil;
	static dispatch_once_t onceToken;
	dispatch_once (&onceToken, ^{
		nullSelection = [[CPCViewSelection alloc] initWithValue:nil calendar:nil];
	});
	return nullSelection;
}

- (BOOL) isNull {
	return (self == [CPCViewSelection nullSelection]);
}

- (NSDate *) singleDay {
	return [_value isKindOfClass:[NSDate class]] ? _value : nil;
}

- (NSDateInterval *) datesInterval {
	return [_value isKindOfClass:[NSDateInterval class]] ? _value : nil;
}

- (NSSet <NSDate *> *) unorderedDates {
	return [_value isKindOfClass:[NSSet <NSDate *> class]] ? _value : nil;
}

- (NSOrderedSet <NSDate *> *) orderedDates {
	return [_value isKindOfClass:[NSOrderedSet <NSDate *> class]] ? _value : nil;
}

- (instancetype) initWithSingleDay: (NSDate *) day calendar: (NSCalendar *) calendar {
	return [self initWithValue:day calendar:calendar];
}

- (instancetype) initWithDatesRange: (NSDateInterval *) datesInterval calendar: (NSCalendar *) calendar {
	return [self initWithValue:datesInterval calendar:calendar];
}

- (instancetype) initWithUnorderedDatesSet: (NSSet <NSDate *> *) datesSet calendar: (NSCalendar *) calendar {
	return [self initWithValue:datesSet calendar:calendar];
}

- (instancetype) initWithOrderedDatesSet: (NSOrderedSet <NSDate *> *) datesSet calendar: (NSCalendar *) calendar {
	return [self initWithValue:datesSet calendar:calendar];
}

- (instancetype) initWithValue: (id) value calendar: (NSCalendar *) calendar {
	if (self = [super init]) {
		_calendar = calendar;
		_value = value;
	}
	return self;
}

- (id) copyWithZone: (NSZone *) zone {
	return self;
}

@end
