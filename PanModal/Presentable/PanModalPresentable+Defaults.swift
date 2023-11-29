//
//  PanModalPresentable+Defaults.swift
//  PanModal
//
//  Copyright © 2018 Tiny Speck, Inc. All rights reserved.
//

#if os(iOS)
import UIKit

/**
 Default values for the PanModalPresentable.
 */
extension PanModalPresentable {

    public var panScrollView: UIScrollView? {
        loadViewIfNeeded()
        if let topMostChildForPanModal {
            return topMostChildForPanModal.panScrollView
        }
        return view.subviews.first as? UIScrollView ?? view as? UIScrollView
    }

    public var detents: [PanModalPresentationController.Detent] {
        return [
            .init(identifier: .content, height: .content)
        ]
    }

    public var preferredCornerRadius: CGFloat {
        return 12.0
    }

    public var springDamping: CGFloat {
        return 0.8
    }

    public var transitionDuration: TimeInterval {
        return 0.5
    }

    public var transitionAnimationOptions: UIView.AnimationOptions {
        return [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState]
    }

    public var panModalBackgroundColor: UIColor {
      let color = UIColor(white: 0, alpha: 0.12)
      if #available(iOS 13.0, *) {
        let darkColor = UIColor(white: 0, alpha: 0.29)
        return UIColor { traitCollection in
          return traitCollection.userInterfaceStyle == .dark ? darkColor : color
        }
      } else {
        return color
      }
    }

    public var allowsExtendedPanScrolling: Bool {
        guard let panScrollView else { return false }
        panScrollView.layoutIfNeeded()
        return panScrollView.contentSize.height > (panScrollView.frame.height - panScrollView.safeAreaInsets.bottom)
    }

    public var allowsDragToDismiss: Bool {
        return true
    }

    public var allowsTapToDismiss: Bool {
        return true
    }

    public var isUserInteractionEnabled: Bool {
        return true
    }

    public var isHapticFeedbackEnabled: Bool {
        return true
    }

    public var prefersGrabberVisible: Bool {
        return preferredCornerRadius > 0
    }

    public var childForPanModal: PanModalPresentable? {
        return nil
    }

    public func shouldRespond(to panModalGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        return true
    }

    public func willRespond(to panModalGestureRecognizer: UIPanGestureRecognizer) {

    }

    public func shouldTransition(to detent: PanModalPresentationController.Detent) -> Bool {
        return true
    }

    public func shouldPrioritize(panModalGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        return false
    }

    public func willTransition(to detent: PanModalPresentationController.Detent) {

    }

    public func panModalWillDismiss() {

    }

    public func panModalDidDismiss() {

    }
}

extension PanModalPresentable {

    public var topMostChildForPanModal: PanModalPresentable? {
        guard var child = childForPanModal else { return nil }
        while let nextChild = child.childForPanModal {
            child = nextChild
        }
        return child
    }

    /**
     A function wrapper over the animate function in PanModalAnimator.

     This can be used for animation consistency on views within the presented view controller.
     */
    public func panModalAnimate(animations: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        UIView.animate(
            withDuration: transitionDuration,
            delay: 0,
            usingSpringWithDamping: springDamping,
            initialSpringVelocity: 0,
            options: transitionAnimationOptions,
            animations: animations,
            completion: completion
        )
    }
}

extension UINavigationController {

    public var childForPanModal: PanModalPresentable? {
        return topViewController as? PanModalPresentable
    }
}

extension UITabBarController {

    public var childForPanModal: PanModalPresentable? {
        return selectedViewController as? PanModalPresentable
    }
}
#endif
