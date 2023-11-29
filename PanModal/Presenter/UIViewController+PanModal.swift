//
//  UIViewController+PanModalPresenterProtocol.swift
//  PanModal
//
//  Copyright © 2019 Tiny Speck, Inc. All rights reserved.
//

#if os(iOS)
import UIKit

extension UIViewController {

    private static var panModalTransitioningDelegateKey: Void?
  
    public var panModalPresentationController: PanModalPresentationController? {
        guard modalPresentationStyle == .custom else { return nil }
        if objc_getAssociatedObject(self, &Self.panModalTransitioningDelegateKey) == nil {
            let panModalTransitioningDelegate = PanModalTransitioningDelegate()
            objc_setAssociatedObject(self, &Self.panModalTransitioningDelegateKey, panModalTransitioningDelegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            transitioningDelegate = panModalTransitioningDelegate
        }
        return presentationController as? PanModalPresentationController
    }

    /**
     A flag that returns true if the topmost view controller in the navigation stack
     was presented using the custom PanModal transition

     - Warning: ⚠️ Calling `presentationController` in this function may cause a memory leak. ⚠️

     In most cases, this check will be used early in the view lifecycle and unfortunately,
     there's an Apple bug that causes multiple presentationControllers to be created if
     the presentationController is referenced here and called too early resulting in
     a strong reference to this view controller and in turn, creating a memory leak.
     */
    public var isPanModalPresented: Bool {
        return (transitioningDelegate as? PanModalTransitioningDelegate) != nil
    }

    /**
     Configures a view controller for presentation using the PanModal transition

     - Parameters:
        - viewControllerToPresent: The view controller to be presented
        - sourceView: The view containing the anchor rectangle for the popover.
        - sourceRect: The rectangle in the specified view in which to anchor the popover.
        - completion: The block to execute after the presentation finishes. You may specify nil for this parameter.

     - Note: sourceView & sourceRect are only required for presentation on an iPad.
     */
    public func presentPanModal(_ viewControllerToPresent: PanModalPresentable, animated: Bool, completion: (() -> Void)? = nil) {
        viewControllerToPresent.modalPresentationStyle = .custom
        _ = viewControllerToPresent.panModalPresentationController
        present(viewControllerToPresent, animated: animated, completion: completion)
    }
}
#endif
