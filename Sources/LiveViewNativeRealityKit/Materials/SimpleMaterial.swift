//
//  SimpleMaterial.swift
//
//
//  Created by Carson Katri on 6/6/24.
//

import LiveViewNative
import SwiftUI
import RealityKit

extension SimpleMaterial {
    init(from element: ElementNode) throws {
        self.init(
            color: UIColor(try element.attributeValue(SwiftUI.Color.self, for: "color")),
            roughness: .float((try? element.attributeValue(Float.self, for: "roughness")) ?? 0),
            isMetallic: element.attributeBoolean(for: "isMetallic")
        )
    }
}
