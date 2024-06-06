//
//  OpacityComponent.swift
//
//
//  Created by Carson Katri on 6/6/24.
//

import LiveViewNative
import RealityKit

extension OpacityComponent {
    init(from element: ElementNode, in context: ComponentContentBuilder.Context<some RootRegistry>) throws {
        self.init(
            opacity: (try? element.attributeValue(Float.self, for: "opacity")) ?? 1
        )
    }
}
