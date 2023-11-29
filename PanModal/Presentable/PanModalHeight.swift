//
//  PanModalHeight.swift
//  PanModal
//
//  Copyright © 2019 Tiny Speck, Inc. All rights reserved.
//

#if os(iOS)
import UIKit

/**
 An enum that defines the possible states of the height of a pan modal container view for a given detent.
 */
public enum PanModalHeight: Equatable {

    /**
     Sets the height to be the max height with a specified top inset.
     - Note: A value of 0 is equivalent to .max
     */
    case max(topInset: CGFloat)

    /**
     Sets the height to be the specified content height
     */
    case fixed(CGFloat)

    /**
     Sets the height to be the content height of `panScrollView`
     */
    case scrollingContent

    /**
     Sets the height to be the intrinsic content height
     */
    case intrinsicContent

    case content

    public static var max: Self {
        return max(topInset: 0)
    }
}
#endif
