//
//  ModelEntity.swift
//
//
//  Created by Carson Katri on 6/6/24.
//

import LiveViewNative
import LiveViewNativeCore
import RealityKit

extension ModelEntity {
    convenience init<R: RootRegistry, E: EntityRegistry, C: ComponentRegistry>(
        from element: ElementNode,
        in context: EntityContentBuilder<E, C>.Context<R>
    ) throws {
        self.init(
            mesh: try MeshResource.generate(
                from: EntityContentBuilder<E, C>.buildChildren(of: element, forTemplate: "mesh", with: MeshResourceContentBuilder.self, in: context)
            ),
            materials: [try element.attributeValue(AnyMaterial.self, for: "material")]
        )
        if element.attributeBoolean(for: "generateCollisionShapes") {
            self.generateCollisionShapes(
                recursive: element.attributeBoolean(for: .init(namespace: "generateCollisionShapes", name: "recursive")),
                static: element.attributeBoolean(for: .init(namespace: "generateCollisionShapes", name: "static"))
            )
        }
    }
}
