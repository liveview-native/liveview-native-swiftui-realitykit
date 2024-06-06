//
//  EntityContentBuilder.swift
//
//
//  Created by Carson Katri on 5/23/24.
//

import LiveViewNative
import LiveViewNativeCore
import SwiftUI
import RealityKit
import OSLog

private let logger = Logger(subsystem: "LiveViewNativeRealityKit", category: "EntityContentBuilder")

struct EntityContentBuilder: ContentBuilder {
    enum TagName: String {
        case group = "Group"
        case entity = "Entity"
        case modelEntity = "ModelEntity"
        case anchorEntity = "AnchorEntity"
        
        case sceneReconstructionProvider = "SceneReconstructionProvider"
        case handTrackingProvider = "HandTrackingProvider"
    }
    
    typealias Content = [Entity]
    
    static func lookup<R: RootRegistry>(_ tag: TagName, element: LiveViewNative.ElementNode, context: Context<R>) -> [Entity] {
        let entity: Entity
        do {
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
                entity = try ModelEntity(from: element, in: context)
            case .anchorEntity:
                entity = try AnchorEntity(from: element, in: context)
            case .sceneReconstructionProvider:
                entity = try SceneReconstructionEntity(from: element, in: context)
            case .handTrackingProvider:
                entity = HandTrackingEntity(from: element, in: context)
            }
        } catch {
            logger.log(level: .error, "Entity \(tag.rawValue) failed to build with: \(error.localizedDescription)")
            return []
        }
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
        in context: EntityContentBuilder.Context<R>
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
        
        if let scale = try? element.attributeValue(SIMD3<Float>.self, for: "scale") {
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
                            group: EntityContentBuilder.buildChildren(
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
        in context: EntityContentBuilder.Context<R>
    ) throws {
        var elementNodeComponent = self.components[ElementNodeComponent.self]
        var componentTypes = elementNodeComponent?.componentTypes ?? []
        var newComponentTypes = [any Component.Type]()
        for component in try EntityContentBuilder.buildChildren(of: element, forTemplate: "components", with: ComponentContentBuilder.self, in: context) {
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
                for child in try! EntityContentBuilder.build([childNode], in: context) {
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
