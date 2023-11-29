//
//  Grabber.swift
//  PanModal
//
//  Created by Sereivoan Yong on 11/29/23.
//  Copyright © 2023 Detail. All rights reserved.
//

#if os(iOS)
import UIKit

open class Grabber: UIView {

    public override init(frame: CGRect = .zero) {
        super.init(frame: frame)

        backgroundColor = Self.defaultColor
        clipsToBounds = true
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = bounds.height / 2
    }

    open override var intrinsicContentSize: CGSize {
        return CGSize(width: 36, height: 5)
    }

    public static var defaultColor: UIColor {
        let color = UIColor(red: 196/255.0, green: 196/255.0, blue: 199/255.0, alpha: 1)
        if #available(iOS 13.0, *) {
            let darkColor = UIColor(red: 98/255.0, green: 98/255.0, blue: 103/255.0, alpha: 1)
            return UIColor { traitCollection in
                return traitCollection.userInterfaceStyle == .dark ? darkColor : color
            }
        } else {
            return color
        }
    }
}

/*
final class Grabber: UIControl {

    let view = UIVisualEffectView(effect: UIBlurEffect(style: .regular))

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        clipsToBounds = true
        addSubview(view)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = bounds.height / 2

        view.frame = bounds.insetBy(dx: -5, dy: -5)
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 36, height: 5)
    }
}
  */
#endif
