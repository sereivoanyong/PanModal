//
//  DimmedView.swift
//  PanModal
//
//  Copyright © 2017 Tiny Speck, Inc. All rights reserved.
//

#if os(iOS)
import UIKit

/**
 A dim view for use as an overlay over content you want dimmed.

 https://developer.limneos.net/index.php?ios=15.2.1&framework=UIKitCore.framework&header=UIDimmingView.h
 */
open class DimmingView: UIView {

    /**
     Represents the possible states of the dimmed view.
     max, off or a percentage of dimAlpha.
     */
    enum DimState {

        case max
        case off
        case percent(CGFloat)
    }

    // MARK: - Properties

    /**
     The state of the dimmed view
     */
    var dimState: DimState = .off {
        didSet {
            switch dimState {
            case .max:
                alpha = 1.0
            case .off:
                alpha = 0.0
            case .percent(let percentage):
                alpha = max(0.0, min(1.0, percentage))
            }
        }
    }

    /**
     The closure to be executed when a tap occurs
     */
    var tapHandler: ((UITapGestureRecognizer) -> Void)?

    /**
     Tap gesture recognizer
     */
    lazy private var tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapView))

    // MARK: - Initializers

    public override init(frame: CGRect = .zero) {
        super.init(frame: .zero)
        alpha = 0.0
        addGestureRecognizer(tapGestureRecognizer)
    }

    public required init?(coder: NSCoder) {
        fatalError()
    }

    // MARK: - Event Handlers

    @objc private func didTapView(_ tapGestureRecognizer: UITapGestureRecognizer) {
        tapHandler?(tapGestureRecognizer)
    }
}
#endif
