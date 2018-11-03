//
//  CPCCalendarView_CollectionView.swift
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

import UIKit

internal extension CPCCalendarView {
	internal final class CollectionView: UICollectionView {
		private final class GestureRecognizerTarget: NSObject {
			private unowned let parent: CollectionView;
			
			private var panStartOffset = CGPoint.zero;
			
			private var minimumContentOffset: CGPoint? {
				return self.parent.minimumContentOffset;
			}
			
			private var maximumContentOffset: CGPoint? {
				return self.parent.maximumContentOffset;
			}
			
			fileprivate init (_ parent: CollectionView) {
				self.parent = parent;
				super.init ();
				parent.panGestureRecognizer.removeTarget (nil, action: nil);
				parent.panGestureRecognizer.addTarget (self, action: #selector (gestureRecognizerAction));
			}
			
			@objc private func gestureRecognizerAction (_ gestureRecognizer: UIPanGestureRecognizer) {
				let state = gestureRecognizer.state;
				switch (state) {
				case .began:
					self.panStartOffset = self.parent.contentOffset;
					fallthrough;
					
				case .changed:
					let translation = gestureRecognizer.translation (in: self.parent);
					let unboundedOffset = CGPoint (x: self.panStartOffset.x - translation.x, y: self.panStartOffset.y - translation.y);
					let clampedOffset = self.parent.clampedContentOffset (unboundedOffset);
					
					if (((unboundedOffset.x - clampedOffset.x).magnitude > 1e-3) || ((unboundedOffset.y + clampedOffset.y).magnitude > 1e-3)) {
						self.parent.contentOffset = clampedOffset;
					}
					
				case .failed, .cancelled, .ended:
					let translation = gestureRecognizer.translation (in: self.parent), velocity = gestureRecognizer.velocity (in: self.parent);
					let unboundedOffset = CGPoint (x: self.panStartOffset.x - translation.x, y: self.panStartOffset.y - translation.y);
					let decelerationEndOffset = CGPoint (
						x: decelerationEnd (for: unboundedOffset.x, velocity: velocity.x, decelerationRate: self.parent.decelerationRate, duration: 0.3),
						y: decelerationEnd (for: unboundedOffset.y, velocity: velocity.y, decelerationRate: self.parent.decelerationRate, duration: 0.3)
					);
					let finalContentOffset = self.parent.clampedContentOffset (decelerationEndOffset, trackingState: false);
					let finalTranslation = CGVector (dx: decelerationEndOffset.x - self.parent.contentOffset.x, dy: decelerationEndOffset.y - self.parent.contentOffset.y);
					let animationVelocity = CGVector (
						dx: finalTranslation.dx.magnitude > 1e-3 ? velocity.x / 100.0 / finalTranslation.dx : 0.0,
						dy: finalTranslation.dy.magnitude > 1e-3 ? velocity.y / 100.0 / finalTranslation.dy : 0.0
					);
					let animator = UIViewPropertyAnimator (duration: 0.3, timingParameters: UISpringTimingParameters (dampingRatio: 1.0, initialVelocity: animationVelocity));
					animator.addAnimations { self.parent.contentOffset = finalContentOffset };
					animator.startAnimation ();
					
				case .possible:
					break;
				}
			}
		}
		
		internal var minimumContentOffset: CGPoint?;
		internal var maximumContentOffset: CGPoint?;
		
		private var gestureRecognizerTarget: GestureRecognizerTarget!;
		
		internal override init (frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
			super.init (frame: frame, collectionViewLayout: layout);
			self.gestureRecognizerTarget = GestureRecognizerTarget (self);
		}
		
		internal required init? (coder aDecoder: NSCoder) {
			super.init (coder: aDecoder);
			self.gestureRecognizerTarget = GestureRecognizerTarget (self);
		}

		internal func clampedContentOffset (_ contentOffset: CGPoint) -> CGPoint {
			return self.clampedContentOffset (contentOffset, trackingState: self.isTracking);
		}
		
		internal func clampedContentOffset (_ contentOffset: CGPoint, trackingState isTracking: Bool) -> CGPoint {
			var contentOffset = contentOffset;
			self.clampOffsetComponent (&contentOffset.x, boundingBy: self.minimumContentOffset?.x, trackingState: isTracking, overscrollDetector: <);
			self.clampOffsetComponent (&contentOffset.y, boundingBy: self.minimumContentOffset?.y, trackingState: isTracking, overscrollDetector: <);
			self.clampOffsetComponent (&contentOffset.x, boundingBy: self.maximumContentOffset?.x, trackingState: isTracking, overscrollDetector: >);
			self.clampOffsetComponent (&contentOffset.y, boundingBy: self.maximumContentOffset?.y, trackingState: isTracking, overscrollDetector: >);
			return contentOffset;
		}
		
		private func clampOffsetComponent (_ component: inout CGFloat, boundingBy bound: CGFloat?, trackingState isTracking: Bool, overscrollDetector: (CGFloat, CGFloat) -> Bool) {
			guard let bound = bound, overscrollDetector (component, bound) else {
				return;
			}
			component = (isTracking ? (component + bound) / 2 : bound);
		}
	}
}

private func decelerationEnd (for offsetComponent: CGFloat, velocity: CGFloat, decelerationRate: UIScrollView.DecelerationRate, duration: TimeInterval) -> CGFloat {
	// -T*k*v0/log(-k + 1)
	return offsetComponent + CGFloat (duration) * decelerationRate.rawValue * velocity / log (1 - decelerationRate.rawValue);
}
