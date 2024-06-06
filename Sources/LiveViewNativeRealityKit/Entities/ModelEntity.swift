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
    convenience init<R: RootRegistry>(
        from element: ElementNode,
        in context: EntityContentBuilder.Context<R>
    ) throws {
        self.init(
            mesh: try MeshResource.generate(from: element.attribute(named: "mesh"), on: element),
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

extension MeshResource {
    static func generate(from attribute: Attribute?, on element: ElementNode) throws -> MeshResource {
        guard let value = attribute?.value,
              let name = attribute?.name.name
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        switch value {
        case "box":
            let cornerRadius = (try? element.attributeValue(Float.self, for: .init(namespace: name, name: "cornerRadius"))) ?? 0
            if let size = try? element.attributeValue(Float.self, for: .init(namespace: name, name: "size")) {
                return MeshResource.generateBox(
                    size: size,
                    cornerRadius: cornerRadius
                )
            } else {
                return MeshResource.generateBox(
                    width: try element.attributeValue(Float.self, for: .init(namespace: name, name: "width")),
                    height: try element.attributeValue(Float.self, for: .init(namespace: name, name: "height")),
                    depth: try element.attributeValue(Float.self, for: .init(namespace: name, name: "depth")),
                    cornerRadius: cornerRadius
                )
            }
        case "sphere":
            return MeshResource.generateSphere(
                radius: try element.attributeValue(Float.self, for: .init(namespace: name, name: "radius"))
            )
        case "cone":
            return MeshResource.generateCone(
                height: try element.attributeValue(Float.self, for: .init(namespace: name, name: "height")),
                radius: try element.attributeValue(Float.self, for: .init(namespace: name, name: "radius"))
            )
        case "cylinder":
            return MeshResource.generateCylinder(
                height: try element.attributeValue(Float.self, for: .init(namespace: name, name: "height")),
                radius: try element.attributeValue(Float.self, for: .init(namespace: name, name: "radius"))
            )
        case "plane":
            let cornerRadius = (try? element.attributeValue(Float.self, for: .init(namespace: name, name: "cornerRadius"))) ?? 0
            let width = try element.attributeValue(Float.self, for: .init(namespace: name, name: "width"))
            if let depth = try? element.attributeValue(Float.self, for: .init(namespace: name, name: "depth")) {
                return MeshResource.generatePlane(
                    width: width,
                    depth: depth,
                    cornerRadius: cornerRadius
                )
            } else {
                return MeshResource.generatePlane(
                    width: width,
                    height: try element.attributeValue(Float.self, for: .init(namespace: name, name: "height")),
                    cornerRadius: cornerRadius
                )
            }
        default:
            throw AttributeDecodingError.badValue(Self.self)
        }
    }
}
