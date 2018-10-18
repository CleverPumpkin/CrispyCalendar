//
//  CPCDayCellState.h
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
 C/Objective C counterpart for `CPCDayCellState.BackgroundState`.
 */
typedef NS_ENUM (uint8_t, CPCDayCellBackgroundState) {
	/** Normal cell state, equivalent of `CPCDayCellState.BackgroundState.normal`.
	 */
	CPCDayCellBackgroundStateNormal,
	/** Highlighted cell state, equivalent of `CPCDayCellState.BackgroundState.highlighted`.
	 */
	CPCDayCellBackgroundStateHighlighted,
	/** Selected cell state, equivalent of `CPCDayCellState.BackgroundState.selected`.
	 */
	CPCDayCellBackgroundStateSelected,
	/** Selected cell state, equivalent of `CPCDayCellState.BackgroundState.disabled`.
	 */
	CPCDayCellBackgroundStateDisabled,
} NS_REFINED_FOR_SWIFT;

/**
 C/Objective C counterpart for `CPCDayCellState`.
 */
typedef struct {
	/**
	 State part, corresponding to user actions.
	 */
	CPCDayCellBackgroundState const backgroundState;
	/**
	 State part, indicating that cell is rendering current day.
	 */
	BOOL const isToday;
} CPCDayCellState NS_REFINED_FOR_SWIFT;

/**
 Creates a new cell state from state items.

 @param backgroundState User-dependent state part.
 @param isToday Value that indicates that cell renders current day.
 @return Full cell state with items initialized accordingly.
 */
NS_INLINE NS_REFINED_FOR_SWIFT CPCDayCellState CPCDayCellStateMake (CPCDayCellBackgroundState const backgroundState, BOOL const isToday) {
	return (CPCDayCellState) { .backgroundState = backgroundState, .isToday = isToday };
}
