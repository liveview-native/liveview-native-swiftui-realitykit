//
//  GroundingShadowComponent.swift
//
//
//  Created by Carson Katri on 6/6/24.
//

import LiveViewNative
import RealityKit

extension GroundingShadowComponent {
    init(from element: ElementNode, in context: _ComponentContentBuilder<some ComponentRegistry>.Context<some RootRegistry>) throws {
        self.init(
            castsShadow: element.attributeBoolean(for: "castsShadow")
        )
    }
}
