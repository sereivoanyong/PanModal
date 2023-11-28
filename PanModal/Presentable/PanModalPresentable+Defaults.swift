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
public extension PanModalPresentable {

    var topOffset: CGFloat {
        return topLayoutOffset + 21.0
    }

    var shortFormHeight: PanModalHeight {
        return longFormHeight
    }

    var longFormHeight: PanModalHeight {
        guard let panScrollView else { return .maxHeight }
        // called once during presentation and stored
        panScrollView.layoutIfNeeded()
        return .contentHeight(panScrollView.contentSize.height)
    }

    var cornerRadius: CGFloat {
        return 8.0
    }

    var springDamping: CGFloat {
        return 0.8
    }

    var transitionDuration: TimeInterval {
        return Self.defaultTransitionDuration
    }

    var transitionAnimationOptions: UIView.AnimationOptions {
        return [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState]
    }

    var panModalBackgroundColor: UIColor {
        return UIColor.black.withAlphaComponent(0.7)
    }

    var dragIndicatorBackgroundColor: UIColor {
        return UIColor.lightGray
    }

    var scrollIndicatorInsets: UIEdgeInsets {
        let top = shouldRoundTopCorners ? cornerRadius : 0
        return UIEdgeInsets(top: top, left: 0, bottom: bottomLayoutOffset, right: 0)
    }

    var anchorModalToLongForm: Bool {
        return true
    }

    var allowsExtendedPanScrolling: Bool {
        guard let panScrollView else { return false }
        panScrollView.layoutIfNeeded()
        return panScrollView.contentSize.height > (panScrollView.frame.height - bottomLayoutOffset)
    }

    var allowsDragToDismiss: Bool {
        return true
    }

    var allowsTapToDismiss: Bool {
        return true
    }

    var isUserInteractionEnabled: Bool {
        return true
    }

    var isHapticFeedbackEnabled: Bool {
        return true
    }

    var shouldRoundTopCorners: Bool {
        return isPanModalPresented
    }

    var showDragIndicator: Bool {
        return shouldRoundTopCorners
    }

    func shouldRespond(to panModalGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        return true
    }

    func willRespond(to panModalGestureRecognizer: UIPanGestureRecognizer) {

    }

    func shouldTransition(to state: PanModalPresentationController.PresentationState) -> Bool {
        return true
    }

    func shouldPrioritize(panModalGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        return false
    }

    func willTransition(to state: PanModalPresentationController.PresentationState) {

    }

    func panModalWillDismiss() {

    }

    func panModalDidDismiss() {

    }
}
#endif
