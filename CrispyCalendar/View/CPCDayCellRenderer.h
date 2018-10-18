//
//  CPCDayCellRenderer.h
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

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((always_inline)) NS_REFINED_FOR_SWIFT void CrispyCalendar_CPCDayCellRenderer_drawCellTitle (id title, id attributes, CGRect const frame, CGContextRef context) {
	CGSize const titleSize = [(NSString *) title sizeWithAttributes:(NSDictionary <NSAttributedStringKey, id> *) attributes];
	// TODO: RTL
	CGPoint const titleOrigin = {
		.x = round (CGRectGetMidX (frame) - titleSize.width / 2),
		.y = round (CGRectGetMidY (frame) - titleSize.height / 2),
	};
	[(NSString *) title drawAtPoint:titleOrigin withAttributes:(NSDictionary <NSAttributedStringKey, id> *) attributes];
}

NS_ASSUME_NONNULL_END
