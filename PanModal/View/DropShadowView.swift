//
//  DropShadowView.swift
//  PanModal
//
//  Copyright © 2018 Tiny Speck, Inc. All rights reserved.
//

#if os(iOS)
import UIKit

/**
 A view wrapper around the presented view in a PanModal transition.

 This allows us to make modifications to the presented view without
 having to do those changes directly on the view

 https://developer.limneos.net/index.php?ios=15.2.1&framework=UIKitCore.framework&header=UIDropShadowView.h
 */
open class DropShadowView: UIView {

    public let grabber = Grabber()

    public let contentView = UIView()

    var cornerRadius: CGFloat = 0 {
        didSet {
            if cornerRadius > 0 {
                setNeedsLayout()
            } else {
                layer.mask = nil
            }
        }
    }

    var anchoredYPosition: CGFloat = 0 {
        didSet {
            guard anchoredYPosition != oldValue else { return }
            contentView.frame = contentRect
        }
    }

    open override var frame: CGRect {
        didSet {
            contentView.frame = contentRect
        }
    }

    public override init(frame: CGRect = .zero) {
        super.init(frame: frame)

        addSubview(contentView)

        addSubview(grabber)

        grabber.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            grabber.centerXAnchor.constraint(equalTo: centerXAnchor),
            grabber.topAnchor.constraint(equalTo: topAnchor, constant: 5)
        ])

        // Improve performance by rasterizing the layer
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        if cornerRadius > 0 {
            let path = UIBezierPath(
                roundedRect: bounds,
                byRoundingCorners: [.topLeft, .topRight],
                cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
            )

            // Set path as a mask to display optional drag indicator view & rounded corners
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            layer.mask = mask
        }
    }

    private var contentRect: CGRect {
        var rect = bounds
        rect.size.height -= anchoredYPosition
        return rect
    }
}
#endif
