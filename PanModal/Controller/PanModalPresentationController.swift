//
//  PanModalPresentationController.swift
//  PanModal
//
//  Copyright © 2019 Tiny Speck, Inc. All rights reserved.
//

#if os(iOS)
import UIKit

/**
 The PanModalPresentationController is the middle layer between the presentingViewController
 and the presentedViewController.

 It controls the coordination between the individual transition classes as well as
 provides an abstraction over how the presented view is presented & displayed.

 For example, we add a drag indicator view above the presented view and
 a background overlay between the presenting & presented view.

 The presented view's layout configuration & presentation is defined using the PanModalPresentable.

 By conforming to the PanModalPresentable protocol & overriding values
 the presented view can define its layout configuration & presentation.

 https://developer.limneos.net/index.php?ios=15.2.1&framework=UIKitCore.framework&header=UISheetPresentationController.h
 */
open class PanModalPresentationController: UIPresentationController {

    private let snapMovementSensitivity: CGFloat = 0.7

    // MARK: - Properties

    /**
     An observation for the scroll view content offset
     */
    private var scrollObservation: NSKeyValueObservation?

    /**
     The y content offset value of the embedded scroll view
     */
    private var scrollViewYOffset: CGFloat = 0

    private var detents: [Detent] = []

    private var selectedDetent: Detent! {
        didSet {
            if let childForPanModal = presented.topMostChildForPanModal {
              childForPanModal.lastSelectedDetent = selectedDetent
            }
        }
    }

    private var yPositions: [Detent.Identifier: CGFloat] = [:]

    /**
     A flag to track if the presented view is animating
     */
    private var isPresentedViewAnimating: Bool = false

    /**
     Determine anchored Y postion based on the `detents.last`
     */
    private var anchoredYPosition: CGFloat = 0

    /**
     A flag to determine if scrolling should seamlessly transition
     from the pan modal container view to the scroll view
     once the scroll limit has been reached.
     */
    private var extendsPanScrolling: Bool = true

    /**
     Configuration object for PanModalPresentationController
     */
    private let presented: PanModalPresentable

    // MARK: - Views

    /**
     A wrapper around the presented view so that we can modify
     the presented view apperance without changing
     the presented view's properties
     */
    public let dropShadowView = DropShadowView()

    /**
     Background view used as an overlay over the presenting view
     */
    public let dimmingView = DimmingView()

    // MARK: - Gesture Recognizers

    /**
     Gesture recognizer to detect & track pan gestures
     */
    lazy private var panGestureRecognizer: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(didPanOnPresentedView(_ :)))
        gesture.minimumNumberOfTouches = 1
        gesture.maximumNumberOfTouches = 1
        gesture.delegate = self
        return gesture
    }()

    // MARK: - Initializer & Deinitializer

    public init(presented: PanModalPresentable, presenting: UIViewController?) {
        self.presented = presented
        super.init(presentedViewController: presented, presenting: presenting)
        delegate = self
        dimmingView.backgroundColor = presented.panModalBackgroundColor
        dimmingView.tapHandler = { [unowned presented] _ in
            if presented.allowsTapToDismiss {
                presented.dismiss(animated: true)
            }
        }
    }

    deinit {
        scrollObservation?.invalidate()
    }

    // MARK: - Lifecycle

    open override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()

        /// `containerViewDidLayoutSubviews()` is called even if the user interface appearance changes
        guard let containerView else { return }
        reloadLayoutConfigurations(in: containerView)
    }

    /**
     Override presented view to return the pan container wrapper
     */
    open override var presentedView: UIView {
        return dropShadowView
    }

    open override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView else {
            return super.frameOfPresentedViewInContainerView
        }
        return CGRect(origin: CGPoint(x: 0, y: yPositions[selectedDetent.identifier] ?? presented.topOffset(containerView: containerView)), size: containerView.bounds.size)
    }

    /**
     Update presented view size in response to size class changes
     */
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { [weak self] context in
            guard let self else { return }
            presentedView.frame = frameOfPresentedViewInContainerView
            dropShadowView.cornerRadius = presented.preferredCornerRadius
        })
    }

    open override func presentationTransitionWillBegin() {
        guard let containerView else { return }

        addDimmingView(to: containerView)
        addDropShadowView(to: containerView)

        guard let coordinator = presented.transitionCoordinator else {
            dimmingView.dimState = .max
            return
        }

        coordinator.animate(alongsideTransition: { [weak self] _ in
            guard let self else { return }
            dimmingView.dimState = .max
            presented.setNeedsStatusBarAppearanceUpdate()
        })
    }

    open override func presentationTransitionDidEnd(_ completed: Bool) {
        if !completed {
            dimmingView.removeFromSuperview()
        }
    }

    open override func dismissalTransitionWillBegin() {
        presented.panModalWillDismiss()

        guard let coordinator = presented.transitionCoordinator else {
            dimmingView.dimState = .off
            return
        }

        /**
         Drag indicator is drawn outside of view bounds
         so hiding it on view dismiss means avoiding visual bugs
         */
        coordinator.animate(alongsideTransition: { [weak self] _ in
            guard let self else { return }
            dropShadowView.grabber.alpha = 0
            dimmingView.dimState = .off
            presentingViewController.setNeedsStatusBarAppearanceUpdate()
        })
    }

    open override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed {
            presented.panModalDidDismiss()
        }
    }
}

// MARK: - Public Methods

extension PanModalPresentationController {

    /**
     Transition the PanModalPresentationController to the given detent
     */
    public func transition(to detent: Detent) {
        guard presented.shouldTransition(to: detent) else { return }

        presented.willTransition(to: detent)
        selectedDetent = detent
        snap(to: detent)
    }

    /**
     Operations on the scroll view, such as content height changes,
     or when inserting/deleting rows can cause the pan modal to jump,
     caused by the pan modal responding to content offset changes.

     To avoid this, you can call this method to perform scroll view updates,
     with scroll observation temporarily disabled.
     */
    public func performUpdates(_ updates: () -> Void) {
        guard let panScrollView = presented.panScrollView else { return }

        // Pause scroll observer
        scrollObservation?.invalidate()
        scrollObservation = nil

        // Perform updates
        updates()

        // Resume scroll observer
        trackScrolling(panScrollView)
        observe(scrollView: panScrollView)
    }

    /**
     Updates the PanModalPresentationController layout
     based on values in the PanModalPresentable

     - Note: This should be called whenever any
     pan modal presentable value changes after the initial presentation
     */
    public func setNeedsLayoutUpdate() {
        guard let containerView else { return }
        reloadLayoutConfigurations(in: containerView)
        observe(scrollView: presented.panScrollView)
    }
}

// MARK: - Presented View Layout Configuration

extension PanModalPresentationController {

    /**
     Boolean flag to determine if the presented view is anchored
     */
    private var isPresentedViewAnchored: Bool {
        let scale = dropShadowView.traitCollection.displayScale
        return !isPresentedViewAnimating && extendsPanScrolling && dropShadowView.frame.minY.pixelRounded(scale: scale) <= anchoredYPosition.pixelRounded(scale: scale)
    }

    /**
     Adds the presented view to the given container view
     & configures the view elements such as drag indicator, rounded corners
     based on the pan modal presentable.
     */
    private func addDropShadowView(to containerView: UIView) {
        /**
         ⚠️ If this class is NOT used in conjunction with the PanModalPresentationAnimator
         & PanModalPresentable, the presented view should be added to the container view
         in the presentation animator instead of here
         */
        dropShadowView.anchoredYPosition = presented.topOffset(containerView: containerView)
        dropShadowView.frame = containerView.bounds
        containerView.addSubview(dropShadowView)

        presented.view.frame = dropShadowView.contentView.bounds
        presented.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        dropShadowView.contentView.addSubview(presented.view)

        containerView.addGestureRecognizer(panGestureRecognizer)

        dropShadowView.cornerRadius = presented.preferredCornerRadius

        setNeedsLayoutUpdate()
        adjustPanContainerBackgroundColor()
    }

    /**
     Adds a background color to the pan container view in order to avoid a gap at the bottom during initial view presentation in largest detent (when view bounces)
     */
    private func adjustPanContainerBackgroundColor() {
        dropShadowView.backgroundColor = presented.view.backgroundColor ?? presented.panScrollView?.backgroundColor
    }

    /**
     Adds the background view to the view hierarchy & configures its layout constraints.
     */
    private func addDimmingView(to containerView: UIView) {
        containerView.addSubview(dimmingView)

        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dimmingView.topAnchor.constraint(equalTo: containerView.topAnchor),
            dimmingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            containerView.bottomAnchor.constraint(equalTo: dimmingView.bottomAnchor),
            containerView.trailingAnchor.constraint(equalTo: dimmingView.trailingAnchor)
        ])
    }

    /**
     Calculates & stores the layout anchor points & options
     */
    private func reloadLayoutConfigurations(in containerView: UIView) {
        let presented = presented.topMostChildForPanModal ?? presented
        let unorderedDetents = presented.detents
        yPositions = unorderedDetents.reduce(into: [:]) { yPositions, detent in
            yPositions[detent.identifier] = presented.yPos(for: detent, containerView: containerView)
        }
        detents = unorderedDetents.sorted { yPositions[$0.identifier]! > yPositions[$1.identifier]! }
        selectedDetent = presented.lastSelectedDetent ?? detents.first
        anchoredYPosition = presented.topOffset(containerView: containerView)
        extendsPanScrolling = presented.allowsExtendedPanScrolling
        if let panScrollView = presented.panScrollView {
            scrollViewYOffset = panScrollView.contentOffset.y
        } else {
            scrollViewYOffset = 0
        }
        dropShadowView.grabber.isHidden = !presented.prefersGrabberVisible
        dropShadowView.anchoredYPosition = anchoredYPosition
        dropShadowView.frame = frameOfPresentedViewInContainerView
        containerView.isUserInteractionEnabled = presented.isUserInteractionEnabled
    }
}

// MARK: - Pan Gesture Event Handler

extension PanModalPresentationController {

    /**
     The designated function for handling pan gesture events
     */
    @objc private func didPanOnPresentedView(_ panGestureRecognizer: UIPanGestureRecognizer) {
        guard shouldRespond(to: panGestureRecognizer), let containerView else {
            panGestureRecognizer.setTranslation(.zero, in: panGestureRecognizer.view)
            return
        }

        switch panGestureRecognizer.state {
        case .began, .changed:

            /**
             Respond accordingly to pan gesture translation
             */
            respond(to: panGestureRecognizer)

            /**
             If presentedView is translated above the largest detent threshold, treat as transition
             */
            if dropShadowView.frame.origin.y == anchoredYPosition && extendsPanScrolling {
                presented.willTransition(to: detents.last!)
            }

        default:

            /**
             Use velocity sensitivity value to restrict snapping
             */
            let velocity = panGestureRecognizer.velocity(in: presentedView)

            if isVelocityWithinSensitivityRange(velocity.y) {

                /**
                 If velocity is within the sensitivity range, transition to a detent or dismiss entirely.
                 This allows the user to dismiss directly from large detent instead of going to the small detent first.
                 */
                if velocity.y < 0 {
                    // Check if we're already at largest detent
                    if selectedDetent.identifier == detents.last?.identifier {
                        transition(to: selectedDetent)
                        return
                    }
                    // Transition to larger detent (ignore selected detent)
                    var yPositions = yPositions
                    yPositions[selectedDetent.identifier] = nil
                    if let identifier = nearestDetentId(to: dropShadowView.frame.minY, yPositions: yPositions, dismissal: containerView.bounds.height) {
                        let index = detents.firstIndex(where: { $0.identifier == identifier })!
                        transition(to: detents[index])
                    }

                } else {
                    if let identifier = nearestDetentId(to: dropShadowView.frame.minY, yPositions: yPositions, dismissal: containerView.bounds.height) {
                        let index = detents.firstIndex(where: { $0.identifier == identifier })!
                        if index > 0 {
                            transition(to: detents[index - 1])
                        } else {
                            presented.dismiss(animated: true)
                        }
                    } else {
                        presented.dismiss(animated: true)
                    }
                }

            } else {

                /**
                 The `containerView.bounds.height` is used to determine
                 how close the presented view is to the bottom of the screen
                 */
                if let identifier = nearestDetentId(to: dropShadowView.frame.minY, yPositions: yPositions, dismissal: containerView.bounds.height) {
                    transition(to: detents.first(where: { $0.identifier == identifier })!)
                } else {
                    presented.dismiss(animated: true)
                }
            }
        }
    }

    /**
     Determine if the pan modal should respond to the gesture recognizer.

     If the pan modal is already being dragged & the delegate returns false, ignore until
     the recognizer is back to it's original state (.began)

     ⚠️ This is the only time we should be cancelling the pan modal gesture recognizer
     */
    private func shouldRespond(to panGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        guard presented.shouldRespond(to: panGestureRecognizer) || !(panGestureRecognizer.state == .began || panGestureRecognizer.state == .cancelled) else {
            panGestureRecognizer.isEnabled = false
            panGestureRecognizer.isEnabled = true
            return false
        }
        return !shouldFail(panGestureRecognizer: panGestureRecognizer)
    }

    /**
     Communicate intentions to presentable and adjust subviews in containerView
     */
    private func respond(to panGestureRecognizer: UIPanGestureRecognizer) {
        presented.willRespond(to: panGestureRecognizer)

        var yDisplacement = panGestureRecognizer.translation(in: presentedView).y

        /**
         If the presentedView is not anchored to largest detent, reduce the rate of movement above the threshold
         */
        if dropShadowView.frame.origin.y < yPositions[detents.last!.identifier]! {
            yDisplacement /= 2
        }
        adjust(toYPosition: dropShadowView.frame.origin.y + yDisplacement)

        panGestureRecognizer.setTranslation(.zero, in: presentedView)
    }

    /**
     Determines if we should fail the gesture recognizer based on certain conditions

     We fail the presented view's pan gesture recognizer if we are actively scrolling on the scroll view.
     This allows the user to drag whole view controller from outside scrollView touch area.

     Unfortunately, cancelling a gestureRecognizer means that we lose the effect of transition scrolling
     from one view to another in the same pan gesture so don't cancel
     */
    private func shouldFail(panGestureRecognizer: UIPanGestureRecognizer) -> Bool {

        /**
         Allow api consumers to override the internal conditions &
         decide if the pan gesture recognizer should be prioritized.

         ⚠️ This is the only time we should be cancelling the panScrollView recognizer,
         for the purpose of ensuring we're no longer tracking the scrollView
         */
        guard !shouldPrioritize(panGestureRecognizer: panGestureRecognizer) else {
            presented.panScrollView?.panGestureRecognizer.isEnabled = false
            presented.panScrollView?.panGestureRecognizer.isEnabled = true
            return false
        }

        guard isPresentedViewAnchored, let panScrollView = presented.panScrollView, panScrollView.contentOffset.y > -panScrollView.adjustedContentInset.top else { return false }

        let location = panGestureRecognizer.location(in: presentedView)
        return panScrollView.frame.contains(location) || panScrollView.isScrolling
    }

    /**
     Determine if the presented view's panGestureRecognizer should be prioritized over
     embedded scrollView's panGestureRecognizer.
     */
    private func shouldPrioritize(panGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        return panGestureRecognizer.state == .began && presented.shouldPrioritize(panModalGestureRecognizer: panGestureRecognizer)
    }

    /**
     Check if the given velocity is within the sensitivity range
     */
    private func isVelocityWithinSensitivityRange(_ velocity: CGFloat) -> Bool {
        return (abs(velocity) - (1000 * (1 - snapMovementSensitivity))) > 0
    }

    private func snap(to detent: Detent) {
        let yPos = yPositions[detent.identifier]!
        presented.panModalAnimate(
            animations: { [weak self] in
                self?.adjust(toYPosition: yPos)
                self?.isPresentedViewAnimating = true
            },
            completion: { [weak self] didComplete in
                self?.isPresentedViewAnimating = !didComplete
            }
        )
    }

    /**
     Sets the y position of the presentedView & adjusts the backgroundView.
     */
    private func adjust(toYPosition yPos: CGFloat) {
        dropShadowView.frame.origin.y = max(yPos, anchoredYPosition)

        guard dropShadowView.frame.origin.y > yPositions[detents.first!.identifier]! else {
            dimmingView.dimState = .max
            return
        }

        let yDisplacementFromShortDetent = dropShadowView.frame.origin.y - yPositions[detents.first!.identifier]!

        /**
         Once presentedView is translated below smallest detent, calculate yPos relative to bottom of screen
         and apply percentage to backgroundView alpha
         */
        dimmingView.dimState = .percent(1 - (yDisplacementFromShortDetent / dropShadowView.frame.height))
    }

    /**
     Finds the nearest detent idenfier to a given y or nil if `dismissal` is the nearest

     - Parameters:
        - number: reference float we are trying to find the closest value to
        - dismissal: the value to compare and return nil if it's the nearest
     */
    private func nearestDetentId(to yOffset: CGFloat, yPositions: [Detent.Identifier: CGFloat], dismissal: CGFloat) -> Detent.Identifier? {
        if let nearestYPositionByDetentId = yPositions.min(by: { abs(yOffset - $0.value) < abs(yOffset - $1.value) }) {
            if abs(yOffset - dismissal) < abs(yOffset - nearestYPositionByDetentId.value) {
                return nil
            }
            return nearestYPositionByDetentId.key
        }
        return nil
    }
}

// MARK: - UIScrollView Observer

extension PanModalPresentationController {

    /**
     Creates & stores an observer on the given scroll view's content offset.
     This allows us to track scrolling without overriding the scrollView delegate
     */
    private func observe(scrollView: UIScrollView?) {
        scrollObservation?.invalidate()
        scrollObservation = scrollView?.observe(\.contentOffset, options: .old) { [weak self] scrollView, change in
            guard let self, containerView != nil else { return }
            /**
             Incase we have a situation where we have two containerViews in the same presentation
             */
            didPanOnScrollView(scrollView, change: change)
        }
    }

    /**
     Scroll view content offset change event handler

     Also when scrollView is scrolled to the top, we disable the scroll indicator
     otherwise glitchy behaviour occurs

     This is also shown in Apple Maps (reverse engineering)
     which allows us to seamlessly transition scrolling from the panContainerView to the scrollView
     */
    private func didPanOnScrollView(_ scrollView: UIScrollView, change: NSKeyValueObservedChange<CGPoint>) {
        guard !presented.isBeingDismissed, !presented.isBeingPresented else { return }

        let isPresentedViewAnchored = isPresentedViewAnchored
        if !isPresentedViewAnchored && scrollView.contentOffset.y > -scrollView.adjustedContentInset.top {

            /**
             Hold the scrollView in place if we're actively scrolling and not handling top bounce
             */
            haltScrolling(scrollView)

        } else if scrollView.isScrolling || isPresentedViewAnimating {

            if isPresentedViewAnchored {
                /**
                 While we're scrolling upwards on the scrollView, store the last content offset position
                 */
                trackScrolling(scrollView)
            } else {
                /**
                 Keep scroll view in place while we're panning on main view
                 */
                haltScrolling(scrollView)
            }

        } else if presented.view is UIScrollView && !isPresentedViewAnimating && scrollView.contentOffset.y <= -scrollView.adjustedContentInset.top {

            /**
             In the case where we drag down quickly on the scroll view and let go, `handleScrollViewTopBounce` adds a nice elegant touch.
             */
            handleScrollViewTopBounce(scrollView: scrollView, change: change)
        } else {
            trackScrolling(scrollView)
        }
    }

    /**
     Halts the scroll of a given scroll view & anchors it at the `scrollViewYOffset`
     */
    private func haltScrolling(_ scrollView: UIScrollView) {
        scrollView.setContentOffset(CGPoint(x: 0, y: scrollViewYOffset), animated: false)
        scrollView.showsVerticalScrollIndicator = false
    }

    /**
     As the user scrolls, track & save the scroll view y offset.
     This helps halt scrolling when we want to hold the scroll view in place.
     */
    private func trackScrolling(_ scrollView: UIScrollView) {
        scrollViewYOffset = max(scrollView.contentOffset.y, -scrollView.adjustedContentInset.top)
        scrollView.showsVerticalScrollIndicator = true
    }

    /**
     To ensure that the scroll transition between the scrollView & the modal
     is completely seamless, we need to handle the case where content offset is negative.

     In this case, we follow the curve of the decelerating scroll view.
     This gives the effect that the modal view and the scroll view are one view entirely.

     - Note: This works best where the view behind view controller is a UIScrollView.
     So, for example, a UITableViewController.
     */
    private func handleScrollViewTopBounce(scrollView: UIScrollView, change: NSKeyValueObservedChange<CGPoint>) {
        guard let oldYValue = change.oldValue?.y, scrollView.isDecelerating else { return }

        let yOffset = max(scrollView.contentOffset.y, -scrollView.adjustedContentInset.top)
        let presentedSize = containerView?.frame.size ?? .zero

        /**
         Decrease the view bounds by the y offset so the scroll view stays in place
         and we can still get updates on its content offset
         */
        dropShadowView.bounds.size = CGSize(width: presentedSize.width, height: presentedSize.height + (yOffset - scrollView.adjustedContentInset.top))

        if oldYValue > yOffset {
            /**
             Move the view in the opposite direction to the decreasing bounds
             until half way through the deceleration so that it appears
             as if we're transferring the scrollView drag momentum to the entire view
             */
            dropShadowView.frame.origin.y = yPositions[detents.last!.identifier]! - (yOffset - scrollView.adjustedContentInset.top)
        } else {
            scrollViewYOffset = -scrollView.adjustedContentInset.top
            snap(to: detents.last!)
        }

        scrollView.showsVerticalScrollIndicator = false
    }
}

// MARK: - UIGestureRecognizerDelegate

extension PanModalPresentationController: UIGestureRecognizerDelegate {

    /**
     Do not require any other gesture recognizers to fail
     */
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }

    /**
     Allow simultaneous gesture recognizers only when the other gesture recognizer's view
     is the pan scrollable view
     */
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return otherGestureRecognizer.view == presented.panScrollView
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension PanModalPresentationController: UIAdaptivePresentationControllerDelegate {

    /**
     - Note: We do not adapt to size classes due to the introduction of the UIPresentationController
     & deprecation of UIPopoverController (iOS 9), there is no way to have more than one
     presentation controller in use during the same presentation

     This is essential when transitioning from .popover to .custom on iPad split view... unless a custom popover view is also implemented
     (popover uses UIPopoverPresentationController & we use PanModalPresentationController)
     */

    /**
     Dismisses the presented view controller
     */
    public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}

private var lastSelectedDetentKey: Void?

extension PanModalPresentable {

    fileprivate var lastSelectedDetent: PanModalPresentationController.Detent? {
        get { return objc_getAssociatedObject(self, &lastSelectedDetentKey) as? PanModalPresentationController.Detent }
        set { objc_setAssociatedObject(self, &lastSelectedDetentKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

// MARK: - Helper Extensions

extension UIScrollView {

    /**
     A flag to determine if a scroll view is scrolling
     */
    fileprivate var isScrolling: Bool {
        return isDragging && !isDecelerating || isTracking
    }
}

extension CGFloat {

    @usableFromInline
    func pixelRounded(scale: CGFloat) -> CGFloat {
        return (rounded() * scale) / scale
    }
}
#endif
