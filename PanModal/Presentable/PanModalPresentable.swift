//
//  PanModalPresentable.swift
//  PanModal
//
//  Copyright © 2017 Tiny Speck, Inc. All rights reserved.
//

#if os(iOS)
import UIKit

/**
 This is the configuration object for a view controller
 that will be presented using the PanModal transition.
 */
public protocol PanModalPresentable: UIViewController {

    /**
     The scroll view embedded in the view controller.
     Setting this value allows for seamless transition scrolling between the embedded scroll view
     and the pan modal container view.
     */
    var panScrollView: UIScrollView? { get }

    /**
     The `springDamping` value used to determine the amount of 'bounce' seen when transitioning to a detent.

     Default value is 0.8.
     */
    var springDamping: CGFloat { get }

    /**
     The `transitionDuration` value is used to set the speed of animation during a transition, including initial presentation.

     Default value is 0.5.
    */
    var transitionDuration: TimeInterval { get }

    /**
     The animation options used when performing animations on the PanModal, utilized mostly during a transition.

     Default value is `[.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState]`.
    */
    var transitionAnimationOptions: UIView.AnimationOptions { get }

    /**
     The background view color.

     - Note: This is only utilized at the very start of the transition.

     Default value is black with alpha component 0.7.
    */
    var panModalBackgroundColor: UIColor { get }

    /**
     A flag to determine if scrolling should seamlessly transition from the pan modal container view to
     the embedded scroll view once the scroll limit has been reached.

     Default value is false. Unless a scrollView is provided and the content height exceeds the largest detent height.
     */
    var allowsExtendedPanScrolling: Bool { get }

    /**
     A flag to determine if dismissal should be initiated when swiping down on the presented view.

     Return false to fallback to the smallest detent instead of dismissing.

     Default value is true.
     */
    var allowsDragToDismiss: Bool { get }

    /**
     A flag to determine if dismissal should be initiated when tapping on the dimmed background view.

     Default value is true.
     */
    var allowsTapToDismiss: Bool { get }

    /**
     A flag to toggle user interactions on the container view.

     - Note: Return false to forward touches to the presentingViewController.

     Default is true.
    */
    var isUserInteractionEnabled: Bool { get }

    /**
     A flag to determine if haptic feedback should be enabled during presentation.

     Default value is true.
     */
    var isHapticFeedbackEnabled: Bool { get }

    /**
     A flag to determine if a drag indicator should be shown
     above the pan modal container view.

     Default value is true.
     */
    var prefersGrabberVisible: Bool { get }

    /**
     The radius used to round top corners. Set to 0 to disable.

     Default value is 8.0.
     */
    var preferredCornerRadius: CGFloat { get }

    var detents: [PanModalPresentationController.Detent] { get }

    var childForPanModal: PanModalPresentable? { get }

    /**
     Asks the delegate if the pan modal should respond to the pan modal gesture recognizer.
     
     Return false to disable movement on the pan modal but maintain gestures on the presented view.

     Default value is true.
     */
    func shouldRespond(to panModalGestureRecognizer: UIPanGestureRecognizer) -> Bool

    /**
     Notifies the delegate when the pan modal gesture recognizer state is either
     `.began` or `.changed`. This method gives the delegate a chance to prepare
     for the gesture recognizer state change.

     For example, when the pan modal view is about to scroll.

     Default value is an empty implementation.
     */
    func willRespond(to panModalGestureRecognizer: UIPanGestureRecognizer)

    /**
     Asks the delegate if the pan modal gesture recognizer should be prioritized.

     For example, you can use this to define a region
     where you would like to restrict where the pan gesture can start.

     If false, then we rely solely on the internal conditions of when a pan gesture
     should succeed or fail, such as, if we're actively scrolling on the scrollView.

     Default return value is false.
     */
    func shouldPrioritize(panModalGestureRecognizer: UIPanGestureRecognizer) -> Bool

    /**
     Asks the delegate if the pan modal should transition to a new detent.

     Default value is true.
     */
    func shouldTransition(to detent: PanModalPresentationController.Detent) -> Bool

    /**
     Notifies the delegate that the pan modal is about to transition to a new detent.

     Default value is an empty implementation.
     */
    func willTransition(to detent: PanModalPresentationController.Detent)

    /**
     Notifies the delegate that the pan modal is about to be dismissed.

     Default value is an empty implementation.
     */
    func panModalWillDismiss()

    /**
     Notifies the delegate after the pan modal is dismissed.

     Default value is an empty implementation.
     */
    func panModalDidDismiss()
}
#endif
