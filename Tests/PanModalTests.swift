//
//  PanModalTests.swift
//  PanModalTests
//
//  Created by Tosin Afolabi on 2/26/19.
//  Copyright © 2019 PanModal. All rights reserved.
//

import XCTest
@testable import PanModal

/**
 ⚠️ Run tests on iPhone 8 iOS (12.1) Sim
 */

class PanModalTests: XCTestCase {

    class MockViewController: UIViewController, PanModalPresentable {
        var panScrollView: UIScrollView? { return nil }
    }

    class AdjustedMockViewController: UITableViewController, PanModalPresentable {
        var panScrollView: UIScrollView? { return tableView }
    }

    private var vc: AdjustedMockViewController!

    override func setUp() {
        super.setUp()
        vc = AdjustedMockViewController()
    }

    override func tearDown() {
        super.tearDown()
        vc = nil
    }

    func testPresentableDefaults() {

        let vc = MockViewController()

        XCTAssertEqual(vc.springDamping, 0.8)
        XCTAssertEqual(vc.panModalBackgroundColor, UIColor.black.withAlphaComponent(0.7))
        XCTAssertEqual(vc.allowsDragToDismiss, true)
        XCTAssertEqual(vc.allowsTapToDismiss, true)
        XCTAssertEqual(vc.isUserInteractionEnabled, true)
        XCTAssertEqual(vc.isHapticFeedbackEnabled, true)
        XCTAssertEqual(vc.prefersGrabberVisible, false)
        XCTAssertEqual(vc.cornerRadius, 8.0)
        XCTAssertEqual(vc.transitionAnimationOptions, [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState])
    }
}
