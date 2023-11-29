//
//  PanModalPresentationController.Detent.swift
//  PanModal
//
//  Created by Sereivoan Yong on 12/2/23.
//  Copyright © 2023 Detail. All rights reserved.
//

#if os(iOS)
import UIKit

extension PanModalPresentationController.Detent {

    public struct Identifier: RawRepresentable, Hashable {

        public let rawValue: String

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
}

extension PanModalPresentationController.Detent.Identifier {

    public static let content = Self("CONTENT")

    public static let medium = Self("Medium") // Short

    public static let large = Self("LARGE") // Long

    public static let max = Self("MAX")
}

extension PanModalPresentationController {

    final public class Detent: Equatable, CustomStringConvertible {

        public let identifier: Identifier
        public let height: PanModalHeight

        public init(identifier: PanModalPresentationController.Detent.Identifier, height: PanModalHeight) {
            self.identifier = identifier
            self.height = height
        }

        public static func == (lhs: PanModalPresentationController.Detent, rhs: PanModalPresentationController.Detent) -> Bool {
            return lhs.identifier == rhs.identifier && lhs.height == rhs.height
        }

      public var description: String {
        return "\(identifier.rawValue) \(height)"
      }
    }
}
#endif
