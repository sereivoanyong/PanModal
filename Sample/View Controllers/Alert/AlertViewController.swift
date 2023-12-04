//
//  AlertViewController.swift
//  PanModal
//
//  Created by Stephen Sowole on 2/26/19.
//  Copyright © 2019 PanModal. All rights reserved.
//

import UIKit

class AlertViewController: UIViewController, PanModalPresentable {

    let alertViewHeight: CGFloat = 68

    let alertView: AlertView = {
        let alertView = AlertView()
        alertView.layer.cornerRadius = 10
        return alertView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    private func setupView() {
        view.addSubview(alertView)
        alertView.translatesAutoresizingMaskIntoConstraints = false
        alertView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        alertView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        alertView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        alertView.heightAnchor.constraint(equalToConstant: alertViewHeight).isActive = true
    }

    // MARK: - PanModalPresentable

    var panScrollView: UIScrollView? {
        return nil
    }

    var detents: [PanModalPresentationController.Detent] {
        return [
            .init(identifier: .medium, height: .fixed(alertViewHeight)),
            .init(identifier: .max, height: .max)
        ]
    }

    var panModalBackgroundColor: UIColor {
        return UIColor.black.withAlphaComponent(0.1)
    }

    var prefersGrabberVisible: Bool {
        return true
    }

    var isUserInteractionEnabled: Bool {
        return true
    }
}
