//
//  AnchorEntity.swift
//
//
//  Created by Carson Katri on 6/6/24.
//

import LiveViewNative
import RealityKit

extension AnchorEntity {
    convenience init(from element: ElementNode, in context: EntityContentBuilder.Context<some RootRegistry>) throws {
        if let world = try? element.attributeValue(SIMD3<Float>.self, for: "world") {
            self.init(world: world)
        } else {
            let target = try element.attributeValue(AnchoringComponent.Target.self, for: "target")
            if let trackingMode = try? element.attributeValue(AnchoringComponent.TrackingMode.self, for: "trackingMode") {
                self.init(
                    target,
                    trackingMode: trackingMode
                )
            } else {
                self.init(target)
            }
        }
    }
}
