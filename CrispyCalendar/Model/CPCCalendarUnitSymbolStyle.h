//
//  CPCCalendarUnitSymbolStyle.h
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

/**
 Represents style of a localized string representing a calendar unit.
 */
typedef NS_ENUM (NSInteger, CPCCalendarUnitSymbolStyle) {
	/** Full localized name of a calendar unit.
	 */
	CPCCalendarUnitSymbolNormalStyle NS_SWIFT_NAME(normal),
	/** Shortened localized name of calendar unit. Usually consists of just several letters.
	 */
	CPCCalendarUnitSymbolShortStyle NS_SWIFT_NAME(short),
	/** The very shortest localized name for a calendar unit. Usually contains just a single letter.
	 */
	CPCCalendarUnitSymbolVeryShortStyle NS_SWIFT_NAME(veryShort),
} NS_SWIFT_NAME(CPCCalendarUnitSymbolStyle);
