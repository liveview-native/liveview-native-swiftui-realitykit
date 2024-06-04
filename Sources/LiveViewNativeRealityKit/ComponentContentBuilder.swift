//
//  ComponentContentBuilder.swift
//
//
//  Created by Carson Katri on 5/23/24.
//

import LiveViewNative
import LiveViewNativeCore
import RealityKit

struct ComponentContentBuilder: ContentBuilder {
    enum TagName: String {
        case group = "Group"
        
        case anchoringComponent = "AnchoringComponent"
        case opacityComponent = "OpacityComponent"
        case groundingShadowComponent = "GroundingShadowComponent"
        
        case physicsBodyComponent = "PhysicsBodyComponent"
        case collisionComponent = "CollisionComponent"
        
        case hoverEffectComponent = "HoverEffectComponent"
    }
    
    typealias Content = [any Component]
    
    static func lookup<R: RootRegistry>(_ tag: TagName, element: LiveViewNative.ElementNode, context: Context<R>) -> [any Component] {
        switch tag {
        case .group:
            return try! Self.buildChildren(of: element, in: context)
        case .anchoringComponent:
            return [AnchoringComponent(try! element.attributeValue(AnchoringComponent.Target.self, for: "target"))]
        case .opacityComponent:
            return [OpacityComponent(opacity: (try? element.attributeValue(Float.self, for: "opacity")) ?? 1)]
        case .groundingShadowComponent:
            return [GroundingShadowComponent(castsShadow: element.attributeBoolean(for: "castsShadow"))]
        case .physicsBodyComponent:
            return [try! PhysicsBodyComponent(from: element, in: context)]
        case .collisionComponent:
            return [CollisionComponent(
                shapes: try! Self.buildChildren(of: element, with: ShapeResourceBuilder.self, in: context),
                isStatic: element.attributeBoolean(for: "isStatic")
            )]
        case .hoverEffectComponent:
            return [HoverEffectComponent()]
        }
    }
    
    static func empty() -> [any Component] {
        []
    }
    
    static func reduce(accumulated: [any Component], next: [any Component]) -> [any Component] {
        accumulated + next
    }
}

struct ShapeResourceBuilder: ContentBuilder {
    enum TagName: String {
        case group = "Group"
        case box = "Box"
        case sphere = "Sphere"
        case capsule = "Capsule"
    }
    
    typealias Content = [ShapeResource]
    
    static func lookup<R: RootRegistry>(_ tag: TagName, element: ElementNode, context: Context<R>) -> [ShapeResource] {
        switch tag {
        case .group:
            return try! Self.buildChildren(of: element, in: context)
        case .box:
            return [ShapeResource.generateBox(
                width: try! element.attributeValue(Float.self, for: "width"),
                height: try! element.attributeValue(Float.self, for: "height"),
                depth: try! element.attributeValue(Float.self, for: "depth")
            )]
        case .sphere:
            return [ShapeResource.generateSphere(
                radius: try! element.attributeValue(Float.self, for: "radius")
            )]
        case .capsule:
            return [ShapeResource.generateCapsule(
                height: try! element.attributeValue(Float.self, for: "height"),
                radius: try! element.attributeValue(Float.self, for: "radius")
            )]
        }
    }
    
    static func empty() -> [ShapeResource] {
        []
    }
    
    static func reduce(accumulated: [ShapeResource], next: [ShapeResource]) -> [ShapeResource] {
        accumulated + next
    }
}

extension AnchoringComponent.Target: AttributeDecodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let value = attribute?.value
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        switch value {
        case "hand":
            self = .hand(
                try element.attributeValue(Chirality.self, for: "chirality"),
                location: try element.attributeValue(HandLocation.self, for: "location")
            )
        case "head":
            self = .head
        case "image":
            self = .image(
                group: try element.attributeValue(String.self, for: "group"),
                name: try element.attributeValue(String.self, for: "name")
            )
        case "plane":
            self = .plane(
                try element.attributeValue(Alignment.self, for: "alignment"),
                classification: try element.attributeValue(Classification.self, for: "classification"),
                minimumBounds: try element.simd2(for: "minimumBounds")
            )
        default:
            throw AttributeDecodingError.badValue(Self.self)
        }
    }
}

extension AnchoringComponent.Target.Chirality: AttributeDecodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let value = attribute?.value
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        switch value {
        case "left":
            self = .left
        case "right":
            self = .right
        default:
            self = .either
        }
    }
}

extension AnchoringComponent.Target.HandLocation: AttributeDecodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let value = attribute?.value
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        switch value {
        case "aboveHand":
            self = .aboveHand
        case "indexFingerTip":
            self = .indexFingerTip
        case "palm":
            self = .palm
        case "thumbTip":
            self = .thumbTip
        case "wrist":
            self = .wrist
        default:
            self = .aboveHand
        }
    }
}

extension AnchoringComponent.Target.Alignment: AttributeDecodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let value = attribute?.value
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        switch value {
        case "horizontal":
            self = .horizontal
        case "vertical":
            self = .vertical
        default:
            self = .any
        }
    }
}

extension AnchoringComponent.Target.Classification: AttributeDecodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let value = attribute?.value
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        switch value {
        case "ceiling":
            self = .ceiling
        case "floor":
            self = .floor
        case "seat":
            self = .seat
        case "table":
            self = .table
        case "wall":
            self = .wall
        default:
            self = .any
        }
    }
}

extension PhysicsBodyComponent {
    init<R: RootRegistry>(
        from element: ElementNode,
        in context: ComponentContentBuilder.Context<R>
    ) throws {
        if let mass = try? element.attributeValue(Float.self, for: "mass") {
            self.init(
                shapes: try! ComponentContentBuilder.buildChildren(of: element, with: ShapeResourceBuilder.self, in: context),
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
                    friction: (try? element.attributeValue(Float.self, for: "staticFriction")) ?? 0.8,
                    restitution: (try? element.attributeValue(Float.self, for: "staticFriction")) ?? 0.8
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
