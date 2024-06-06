//
//  PhysicsBodyComponent.swift
//
//
//  Created by Carson Katri on 6/6/24.
//

import LiveViewNative
import LiveViewNativeCore
import RealityKit

extension PhysicsBodyComponent {
    init(from element: ElementNode, in context: ComponentContentBuilder.Context<some RootRegistry>) throws {
        if let mass = try? element.attributeValue(Float.self, for: "mass") {
            self.init(
                shapes: try ComponentContentBuilder.buildChildren(of: element, with: ShapeResourceContentBuilder.self, in: context),
                mass: mass,
                material: try? PhysicsMaterialResource.generate(from: element.attribute(named: "material"), on: element),
                mode: (try? element.attributeValue(PhysicsBodyMode.self, for: "mode")) ?? .dynamic
            )
        } else {
            self.init(
                material: try? PhysicsMaterialResource.generate(from: element.attribute(named: "material"), on: element),
                mode: (try? element.attributeValue(PhysicsBodyMode.self, for: "mode")) ?? .dynamic
            )
        }
    }
}

extension PhysicsMaterialResource {
    static func generate(from attribute: Attribute?, on element: ElementNode) throws -> PhysicsMaterialResource {
        guard let value = attribute?.value
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        switch value {
        case "generate":
            if let staticFriction = try? element.attributeValue(Float.self, for: "staticFriction"),
               let dynamicFriction = try? element.attributeValue(Float.self, for: "dynamicFriction"),
               let restitution = try? element.attributeValue(Float.self, for: "restitution")
            {
                return .generate(staticFriction: staticFriction, dynamicFriction: dynamicFriction, restitution: restitution)
            } else {
                return .generate(
                    friction: (try? element.attributeValue(Float.self, for: "friction")) ?? 0.8,
                    restitution: (try? element.attributeValue(Float.self, for: "restitution")) ?? 0.8
                )
            }
        default:
            return .default
        }
    }
}

extension PhysicsBodyMode: AttributeDecodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let value = attribute?.value
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        switch value {
        case "dynamic":
            self = .dynamic
        case "kinematic":
            self = .kinematic
        case "static":
            self = .static
        default:
            throw AttributeDecodingError.badValue(Self.self)
        }
    }
}
