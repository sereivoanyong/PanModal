//
//  PanModalPresentationAnimator.swift
//  PanModal
//
//  Copyright © 2019 Tiny Speck, Inc. All rights reserved.
//

#if os(iOS)
import UIKit

/**
 Handles the animation of the presentedViewController as it is presented or dismissed.

 This is a vertical animation that
 - Animates up from the bottom of the screen
 - Dismisses from the top to the bottom of the screen

 This can be used as a standalone object for transition animation,
 but is primarily used in the PanModalPresentationDelegate for handling pan modal transitions.

 - Note: The presentedViewController can conform to PanModalPresentable to adjust its starting position through manipulating the smallest detent.
 */

final class PanModalPresentationAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    // MARK: - Properties

    let presented: PanModalPresentable

    /**
     Haptic feedback generator (during presentation)
     */
    private let feedbackGenerator = UISelectionFeedbackGenerator()

    // MARK: - Initializers

    init(presented: PanModalPresentable) {
        self.presented = presented
        super.init()
        feedbackGenerator.prepare()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return presented.transitionDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        assert(transitionContext.viewController(forKey: .to) == presented)

        let presentedView = transitionContext.view(forKey: .to)!

        // Move presented view offscreen (from the bottom)
        let finalFrame = transitionContext.finalFrame(for: presented)
        var currentFrame = finalFrame
        currentFrame.origin.y = transitionContext.containerView.frame.height
        presentedView.frame = currentFrame

        // Haptic feedback
        if presented.isHapticFeedbackEnabled {
            feedbackGenerator.selectionChanged()
        }

        presented.panModalAnimate(
            animations: {
                presentedView.frame = finalFrame
            },
            completion: { didComplete in
                transitionContext.completeTransition(didComplete)
            }
        )
    }
}

final class PanModalDismissalAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    let dismissed: PanModalPresentable

    init(dismissed: PanModalPresentable) {
        self.dismissed = dismissed
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return dismissed.transitionDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        assert(transitionContext.viewController(forKey: .from) == dismissed)

        let presentedView = transitionContext.view(forKey: .from)!

        dismissed.panModalAnimate(
            animations: {
                presentedView.frame.origin.y = transitionContext.containerView.frame.height
            },
            completion: { [unowned self] didComplete in
                dismissed.view.removeFromSuperview()
                transitionContext.completeTransition(didComplete)
            }
        )
    }
}
#endif
