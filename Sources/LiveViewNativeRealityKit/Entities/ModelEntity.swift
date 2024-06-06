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
            materials: try EntityContentBuilder<E, C>.buildChildren(of: element, forTemplate: "materials", with: MaterialContentBuilder.self, in: context)
        )
        if element.attributeBoolean(for: "generateCollisionShapes") {
            self.generateCollisionShapes(
                recursive: element.attributeBoolean(for: .init(namespace: "generateCollisionShapes", name: "recursive")),
                static: element.attributeBoolean(for: .init(namespace: "generateCollisionShapes", name: "static"))
            )
        }
    }
    
    func applyModelEntityAttributes<R: RootRegistry, E: EntityRegistry, C: ComponentRegistry>(
        from element: ElementNode,
        in context: EntityContentBuilder<E, C>.Context<R>
    ) throws {
        self.model?.mesh = try MeshResource.generate(
            from: EntityContentBuilder<E, C>.buildChildren(of: element, forTemplate: "mesh", with: MeshResourceContentBuilder.self, in: context)
        )
        self.model?.materials = try EntityContentBuilder<E, C>.buildChildren(of: element, forTemplate: "materials", with: MaterialContentBuilder.self, in: context)
    }
}
