//
//  PanModalPresentable+LayoutHelpers.swift
//  PanModal
//
//  Copyright © 2018 Tiny Speck, Inc. All rights reserved.
//

#if os(iOS)
import UIKit

/**
 ⚠️ [Internal Only] ⚠️
 Helper extensions that handle layout in the PanModalPresentationController
 */
extension PanModalPresentable {

    func yPos(for detent: PanModalPresentationController.Detent, containerView: UIView) -> CGFloat {
        return max(
            topMargin(from: detent.height, containerView: containerView),
            topMargin(from: .max, containerView: containerView)
        ) + topOffset(containerView: containerView)
    }

    /**
     The offset between the top of the screen and the top of the pan modal container view.
     */
    func topOffset(containerView: UIView) -> CGFloat {
        return containerView.safeAreaInsets.top + 18
    }

    /**
     Use the container view for relative positioning as this view's frame
     is adjusted in PanModalPresentationController
     */
    private func bottomYPos(containerView: UIView) -> CGFloat {
        return containerView.bounds.size.height - topOffset(containerView: containerView)
    }

    /**
     Converts a given pan modal height value into a y position value
     calculated from top of view
     */
    private func topMargin(from height: PanModalHeight, containerView: UIView) -> CGFloat {
        switch height {
        case .max(let topInset):
            return topInset

        case .fixed(let height):
            return bottomYPos(containerView: containerView) - (height + containerView.safeAreaInsets.bottom)

        case .scrollingContent:
            guard let panScrollView else {
                return 0
            }
            panScrollView.layoutIfNeeded()
            let panScrollViewSafeAreaInsets = panScrollView.safeAreaInsets
            return bottomYPos(containerView: containerView) - (panScrollView.contentSize.height + panScrollViewSafeAreaInsets.top + containerView.safeAreaInsets.bottom)

        case .intrinsicContent:
            let targetSize = CGSize(width: containerView.bounds.width, height: UIView.layoutFittingCompressedSize.height)
            let presented = childForPanModal ?? self
            let intrinsicHeight = presented.view.systemLayoutSizeFitting(targetSize).height
            return bottomYPos(containerView: containerView) - (intrinsicHeight + containerView.safeAreaInsets.bottom)

        case .content:
            if panScrollView != nil {
                return topMargin(from: .scrollingContent, containerView: containerView)
            } else {
                return topMargin(from: .intrinsicContent, containerView: containerView)
            }
        }
    }
}
#endif
