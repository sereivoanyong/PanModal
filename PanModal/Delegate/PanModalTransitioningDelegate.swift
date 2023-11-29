//
//  PanModalTransitioningDelegate.swift
//  PanModal
//
//  Copyright © 2019 Tiny Speck, Inc. All rights reserved.
//

#if os(iOS)
import UIKit

/**
 The PanModalPresentationDelegate conforms to the various transition delegates
 and vends the appropriate object for each transition controller requested.

 Usage:
 ```
 viewController.modalPresentationStyle = .custom
 _ = viewController.panModalPresentationController
 ```
 */
final class PanModalTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {

    /**
     Returns a modal presentation animator configured for the presenting state
     */
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let presented = presented as? PanModalPresentable else { return nil }
        return PanModalPresentationAnimator(presented: presented)
    }

    /**
     Returns a modal presentation animator configured for the dismissing state
     */
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let dismissed = dismissed as? PanModalPresentable else { return nil }
        return PanModalDismissalAnimator(dismissed: dismissed)
    }

    /**
     Returns a modal presentation controller to coordinate the transition from the presenting
     view controller to the presented view controller.

     Changes in size class during presentation are handled via the adaptive presentation delegate
     */
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        guard let presented = presented as? PanModalPresentable else { return nil }
        return PanModalPresentationController(presented: presented, presenting: presenting)
    }
}
#endif
