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
 C/Objective C counterpart for `CPCDayCellState.State`.
 */
typedef NS_OPTIONS (NSUInteger, CPCDayCellState) {
	/** Normal state of a day cell (not selected, highlighted or disabled).
	 */
	CPCDayCellStateNormal = 0 << 0,
	/** Highlighted state of a cell (current user touch is inside cell's bounds).
	 */
	CPCDayCellStateHighlighted = 1 << 0,
	/** Selected state of a cell (cell is part of current selection).
	 */
	CPCDayCellStateSelected = 2 << 0,
	/** Disabled state of a cell (cell is displayed but cannot be a part of selection).
	 */
	CPCDayCellStateDisabled = 3 << 0,
	/** State flag corresponding to a situaton where day cell is set with current day.
	 *
	 * Rationale is quite obvious: firstly, "today" value in Date & Time-related frameworks
	 * is very frequently special-cased or at least exhibits slighlty different
	 * UI/UX; secondly, any CPU-bound calculations are better off somewhere else than
	 * inside drawing/layout code.
	 * Anyway, Time Profiler is also suporting my theoretizations giving by yealding
	 * incredible and suspicious 2049x improvements …in some other code from some
	 * other people. But seriously speaking, I did not bother to measure minor (but
	 * definnitely measurable) ~2-5% improvements gained just here and was more focused
	 * on overall library code performance.
	 */
	CPCDayCellStateIsToday = 1 << 8,
	
	// TODO: introduce application-private states (see UIControlStateApplication)
};

NS_REFINED_FOR_SWIFT
#if __cplusplus
contextpr
#endif
static NSInteger const CPCBackgroundDayCellStateBits = 2,
                       CPCBackgroundDayCellStateMask = (1 << CPCBackgroundDayCellStateBits) - 1;

NS_REFINED_FOR_SWIFT
#if __cplusplus
contextpr
#endif
static NSInteger const CPCDayCellStateIsTodayBits = 1,
                       CPCDayCellStateStateIsTodayMask = (1 << NBBY);

NS_REFINED_FOR_SWIFT
#if __cplusplus
contextpr
#endif
static NSInteger const CPCDayCellStateBitsInvalid = ~(CPCBackgroundDayCellStateMask | CPCDayCellStateStateIsTodayMask),
                       CPCDayCellStateCompressedMask = (CPCDayCellStateStateIsTodayMask >> (NBBY - CPCBackgroundDayCellStateBits)) | CPCBackgroundDayCellStateMask;

NS_INLINE NS_REFINED_FOR_SWIFT BOOL CPCDayCellStateIsCompressible (CPCDayCellState const state) {
	return !(state & CPCDayCellStateBitsInvalid);
}

NS_INLINE NS_REFINED_FOR_SWIFT NSInteger CPCDayCellStateGetPerfectHash (CPCDayCellState const state) {
	NSCAssert (CPCDayCellStateIsCompressible (state), @"Perfect hash is unavailable for non-compressable states");
	return (state & CPCBackgroundDayCellStateMask) | ((state & CPCDayCellStateStateIsTodayMask) >> (NBBY - CPCBackgroundDayCellStateBits));
}

NS_INLINE NS_REFINED_FOR_SWIFT CPCDayCellState CPCDayCellStateFromPerfectHash (NSInteger const hash) {
	NSCAssert (!(hash & CPCDayCellStateCompressedMask), @"Invalid perfect hash of a state");
	return (hash & CPCBackgroundDayCellStateMask) | ((hash << (NBBY - CPCBackgroundDayCellStateBits)) & CPCDayCellStateStateIsTodayMask);
}

NS_INLINE NS_REFINED_FOR_SWIFT NSInteger CPCDayCellStateGetHash (CPCDayCellState const state) {
	return (CPCDayCellStateIsCompressible (state) ? CPCDayCellStateGetPerfectHash (state) : (state & CPCDayCellStateBitsInvalid));
}
