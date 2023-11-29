//
//  TabBarController.swift
//  PanModalDemo
//
//  Created by Sereivoan Yong on 12/3/23.
//  Copyright © 2023 Detail. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController, PanModalPresentable {

    override func viewDidLoad() {
      super.viewDidLoad()

        viewControllers = [NavigationController()]
    }
}
