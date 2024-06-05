//
//  RealityViewContentBuilder.swift
//
//
//  Created by Carson Katri on 5/23/24.
//

import LiveViewNative
import LiveViewNativeCore
import SwiftUI
import RealityKit

struct RealityViewContentBuilder: ContentBuilder {
    enum TagName: String {
        case group = "Group"
        case entity = "Entity"
        case modelEntity = "ModelEntity"
        case anchorEntity = "AnchorEntity"
        
        case sceneReconstructionEntity = "SceneReconstructionEntity"
        case handTrackingEntity = "HandTrackingEntity"
    }
    
    typealias Content = [Entity]
    
    static func lookup<R: RootRegistry>(_ tag: TagName, element: LiveViewNative.ElementNode, context: Context<R>) -> [Entity] {
        let entity: Entity?
        switch tag {
        case .group:
            guard let children = try? Self.buildChildren(of: element, in: context) else { return [] }
            return children
        case .entity:
            if element.attribute(named: "url") != nil {
                entity = AsyncEntity(from: element, in: context)
            } else {
                entity = Entity()
            }
        case .modelEntity:
            entity = try? ModelEntity(from: element, in: context)
        case .anchorEntity:
            entity = try? AnchorEntity(element.attributeValue(AnchoringComponent.Target.self, for: "target"))
        case .sceneReconstructionEntity:
            entity = SceneReconstructionEntity(
                material: try? element.attributeValue(AnyMaterial.self, for: "material"),
                allowedInputTypes: (try? element.attributeValue(InputTargetComponent.InputType.self, for: "allowedInputTypes")) ?? .all
            )
        case .handTrackingEntity:
            entity = HandTrackingEntity(from: element, in: context)
        }
        guard let entity else { return [] }
        entity.components.set(ElementNodeComponent(element: element))
        try! entity.applyAttributes(from: element, in: context)
        try! entity.applyChildren(from: element, in: context)
        return [entity]
    }
    
    static func empty() -> [Entity] {
        []
    }
    
    static func reduce(accumulated: [Entity], next: [Entity]) -> [Entity] {
        accumulated + next
    }
}

extension Entity {
    func applyAttributes<R: RootRegistry>(
        from element: ElementNode,
        in context: RealityViewContentBuilder.Context<R>
    ) throws {
        var elementNodeComponent = self.components[ElementNodeComponent.self]
        
        if let transform = try? element.transform(for: "transform") {
            elementNodeComponent?.moveAnimation?.stop(
                blendOutDuration: (try? element.attributeValue(Double.self, for: .init(namespace: "transform", name: "blendOutDuration"))) ?? 0
            )
            let duration = try? element.attributeValue(Double.self, for: .init(namespace: "transform", name: "duration"))
            var moveAnimation: AnimationPlaybackController?
            // only update the position if the server changed the value.
            // client-side position updates should persist.
            if let previousTransform = self.components[ElementNodeComponent.self]?.previousTransform {
                if previousTransform != transform {
                    if let duration {
                        moveAnimation = self.move(
                            to: transform,
                            relativeTo: self.parent,
                            duration: duration,
                            timingFunction: (try? element.attributeValue(AnimationTimingFunction.self, for: .init(namespace: "transform", name: "timingFunction"))) ?? .default
                        )
                    } else {
                        self.transform = transform
                    }
                }
            } else {
                self.transform = transform
            }
            elementNodeComponent?.previousTransform = transform
            elementNodeComponent?.moveAnimation = moveAnimation
        }
        
        if let scale = try? element.simd3(for: "scale") {
            self.scale = scale
        }
        
        if let click = element.attributeValue(for: "phx-click") {
            self.components.set(PhoenixClickEventComponent(event: click))
            self.components.set(InputTargetComponent(
                allowedInputTypes: (try? element.attributeValue(InputTargetComponent.InputType.self, for: "allowedInputTypes")) ?? .all
            ))
        } else {
            self.components.remove(PhoenixClickEventComponent.self)
            self.components.remove(InputTargetComponent.self)
        }
        
        if let modelEntity = self as? ModelEntity {
            modelEntity.model?.materials = [try element.attributeValue(AnyMaterial.self, for: "material")]
        }
        
        if let animationName = element.attributeValue(for: "playAnimation"),
           animationName != elementNodeComponent?.animation?.name
        {
            let transitionDuration = try element.attributeValue(Double.self, for: .init(namespace: "playAnimation", name: "transitionDuration"))
            elementNodeComponent?.animation?.controller.stop(blendOutDuration: transitionDuration)
            elementNodeComponent?.animation = (
                name: animationName,
                controller: self.playAnimation(
                    try AnimationResource.generate(
                        with: AnimationGroup(
                            group: RealityViewContentBuilder.buildChildren(
                                of: element,
                                forTemplate: animationName,
                                with: AnimationContentBuilder.self,
                                in: context
                            )
                                .map({ $0.resolveAnimationResources(with: self.availableAnimations) })
                        )
                    ),
                    transitionDuration: transitionDuration,
                    startsPaused: element.attributeBoolean(for: .init(namespace: "playAnimation", name: "startsPaused"))
                )
            )
        }
        
        if let elementNodeComponent {
            self.components.set(elementNodeComponent)
        }
        
        if let asyncEntity = self as? AsyncEntity {
            try asyncEntity.updateResolvedEntity(with: element, in: context)
        }
    }
    
    func applyChildren<R: RootRegistry>(
        from element: ElementNode,
        in context: RealityViewContentBuilder.Context<R>
    ) throws {
        var elementNodeComponent = self.components[ElementNodeComponent.self]
        var componentTypes = elementNodeComponent?.componentTypes ?? []
        var newComponentTypes = [any Component.Type]()
        for component in try RealityViewContentBuilder.buildChildren(of: element, forTemplate: "components", with: ComponentContentBuilder.self, in: context) {
            self.components.set(component)
            componentTypes.removeAll(where: { $0 == type(of: component) })
            newComponentTypes.append(type(of: component))
        }
        for type in componentTypes {
            self.components.remove(type)
        }
        elementNodeComponent?.componentTypes = newComponentTypes
        if let elementNodeComponent {
            self.components.set(elementNodeComponent)
        }
        
        guard !(self is SceneReconstructionEntity) else { return } // scene reconstruction creates its own child meshes
        
        /// The list of children previously part of this element.
        ///
        /// We remove children from this list that are still present in the new element.
        /// Any remaining children are no longer present in the document and should be removed from the entity.
        var previousChildren = Array(self.children)
        for childNode in element.children() {
            guard let childElement = childNode.asElement()
            else { continue }
            if let existingChildIndex = self.children.firstIndex(where: { $0.components[ElementNodeComponent.self]?.element.id == childElement.id }) {
                // update children that existed previously
                let existingChild = self.children[existingChildIndex]
                try! existingChild.applyAttributes(from: childElement, in: context)
                try! existingChild.applyChildren(from: childElement, in: context)
                previousChildren.removeAll(where: { $0.components[ElementNodeComponent.self]?.element.id == childElement.id })
            } else if !childElement.attributes.contains(where: { $0.name.namespace == nil && $0.name.name == "template" }) {
                // add new children
                for child in try! RealityViewContentBuilder.build([childNode], in: context) {
                    self.addChild(child)
                }
            }
        }
        // remove children that are no longer in the document
        for child in previousChildren where !child.components.has(AsyncEntityComponent.self) {
            self.removeChild(child)
        }
    }
}

extension ModelEntity {
    convenience init<R: RootRegistry>(
        from element: ElementNode,
        in context: RealityViewContentBuilder.Context<R>
    ) throws {
        self.init(
            mesh: try MeshResource.generate(from: element.attribute(named: "mesh"), on: element),
            materials: [try element.attributeValue(AnyMaterial.self, for: "material")]
        )
        if element.attributeBoolean(for: "generateCollisionShapes") {
            self.generateCollisionShapes(recursive: true, static: element.attributeBoolean(for: .init(namespace: "generateCollisionShapes", name: "static")))
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

struct AnyMaterial: RealityKit.Material, AttributeDecodable {
    var __resource: __MaterialResource
    var __parameterBlock: __RKMaterialParameterBlock
    
    init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let value = attribute?.value,
              let name = attribute?.name.name
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        let material: any RealityKit.Material = switch value {
        case "pbr":
            try PhysicallyBasedMaterial(from: attribute, on: element)
        case "unlit":
            UnlitMaterial(
                color: UIColor(try element.attributeValue(SwiftUI.Color.self, for: .init(namespace: name, name: "color")))
            )
        case "simple":
            try SimpleMaterial(from: attribute, on: element)
        case "occlusion":
            OcclusionMaterial()
        default:
            throw AttributeDecodingError.badValue(Self.self)
        }
        self.__resource = material.__resource
        self.__parameterBlock = material.__parameterBlock
    }
}

extension PhysicallyBasedMaterial: AttributeDecodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let name = attribute?.name.name
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        self.init()
        self.baseColor = .init(
            tint: UIColor(try element.attributeValue(SwiftUI.Color.self, for: .init(namespace: name, name: "baseColor"))),
            texture: nil
        )
        if let metallic = try? element.attributeValue(Float.self, for: .init(namespace: name, name: "metallic")) {
            self.metallic = .init(floatLiteral: metallic)
        }
        if let roughness = try? element.attributeValue(Float.self, for: .init(namespace: name, name: "roughness")) {
            self.roughness = .init(floatLiteral: roughness)
        }
    }
}

extension SimpleMaterial: AttributeDecodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let name = attribute?.name.name
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        self.init(
            color: UIColor(try element.attributeValue(SwiftUI.Color.self, for: .init(namespace: name, name: "color"))),
            roughness: .float((try? element.attributeValue(Float.self, for: .init(namespace: name, name: "roughness"))) ?? 0),
            isMetallic: element.attributeBoolean(for: .init(namespace: name, name: "isMetallic"))
        )
    }
}

extension Float: AttributeDecodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let attributeValue = attribute?.value else { throw AttributeDecodingError.missingAttribute(Self.self) }
        guard let result = Self(attributeValue) else { throw AttributeDecodingError.badValue(Self.self) }
        self = result
    }
}

private let decoder = JSONDecoder()

extension SIMD3: AttributeDecodable where Scalar: AttributeDecodable & Decodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let value = attribute?.value
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        self = try decoder.decode(Self.self, from: Data(value.utf8))
    }
}

extension SIMD4: AttributeDecodable where Scalar: AttributeDecodable & Decodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let value = attribute?.value
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        self = try decoder.decode(Self.self, from: Data(value.utf8))
    }
}

extension ElementNode {
    func simd2(for namespace: String) throws -> SIMD2<Float> {
        try .init(
            x: attributeValue(Float.self, for: .init(namespace: namespace, name: "x")),
            y: attributeValue(Float.self, for: .init(namespace: namespace, name: "y"))
        )
    }
    
    func simd3(for namespace: String) throws -> SIMD3<Float> {
        if let scalar = try? attributeValue(Float.self, for: .init(name: namespace)) {
            return .init(repeating: scalar)
        } else {
            return try .init(
                x: attributeValue(Float.self, for: .init(namespace: namespace, name: "x")),
                y: attributeValue(Float.self, for: .init(namespace: namespace, name: "y")),
                z: attributeValue(Float.self, for: .init(namespace: namespace, name: "z"))
            )
        }
    }
    
    func simd4(for namespace: String) throws -> SIMD4<Float> {
        try .init(
            x: attributeValue(Float.self, for: .init(namespace: namespace, name: "x")),
            y: attributeValue(Float.self, for: .init(namespace: namespace, name: "y")),
            z: attributeValue(Float.self, for: .init(namespace: namespace, name: "z")),
            w: attributeValue(Float.self, for: .init(namespace: namespace, name: "w"))
        )
    }
    
    func transform(for namespace: String) throws -> Transform {
        .init(
            scale: (try? attributeValue(SIMD3<Float>.self, for: .init(namespace: namespace, name: "scale"))) ?? SIMD3<Float>(x: 1, y: 1, z: 1),
            rotation: simd_quaternion((try? attributeValue(SIMD4<Float>.self, for: .init(namespace: namespace, name: "rotation"))) ?? SIMD4<Float>(0, 0, 0, 1)),
            translation: (try? attributeValue(SIMD3<Float>.self, for: .init(namespace: namespace, name: "translation"))) ?? SIMD3<Float>(x: 0, y: 0, z: 0)
        )
    }
}

extension InputTargetComponent.InputType: AttributeDecodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let value = attribute?.value
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        
        switch value {
        case "indirect":
            self = .indirect
        case "direct":
            self = .direct
        case "all":
            self = .all
        default:
            throw AttributeDecodingError.badValue(Self.self)
        }
    }
}
