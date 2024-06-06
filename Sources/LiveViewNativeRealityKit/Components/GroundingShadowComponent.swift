//
//  GroundingShadowComponent.swift
//
//
//  Created by Carson Katri on 6/6/24.
//

import LiveViewNative
import RealityKit

extension GroundingShadowComponent {
    init(from element: ElementNode, in context: ComponentContentBuilder.Context<some RootRegistry>) throws {
        self.init(
            castsShadow: element.attributeBoolean(for: "castsShadow")
        )
    }
}
