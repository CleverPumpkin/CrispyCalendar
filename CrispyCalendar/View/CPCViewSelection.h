//
//  CPCViewSelection.h
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_REFINED_FOR_SWIFT
@interface CPCViewSelection: NSObject <NSCopying>

@property (nonatomic, readonly, getter = isNull) BOOL null;
@property (nonatomic, readonly, nullable) NSCalendar *calendar;
@property (nonatomic, readonly, nullable) NSDate *singleDay;
@property (nonatomic, readonly, nullable) NSDateInterval *datesInterval;
@property (nonatomic, readonly, nullable) NSSet <NSDate *> *unorderedDates;
@property (nonatomic, readonly, nullable) NSOrderedSet <NSDate *> *orderedDates;

+ (instancetype) nullSelection;

+ (instancetype) new NS_UNAVAILABLE;
- (instancetype) init NS_UNAVAILABLE;

- (instancetype) initWithSingleDay: (NSDate *__nullable) day calendar: (NSCalendar *__nullable) calendar;
- (instancetype) initWithDatesRange: (NSDateInterval *) datesInterval calendar: (NSCalendar *) calendar;
- (instancetype) initWithUnorderedDatesSet: (NSSet <NSDate *> *) datesSet calendar: (NSCalendar *__nullable) calendar;
- (instancetype) initWithOrderedDatesSet: (NSOrderedSet <NSDate *> *) datesSet calendar: (NSCalendar *__nullable) calendar;

@end

NS_ASSUME_NONNULL_END
