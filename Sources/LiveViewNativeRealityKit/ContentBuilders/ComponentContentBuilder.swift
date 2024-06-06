//
//  ComponentContentBuilder.swift
//
//
//  Created by Carson Katri on 5/23/24.
//

import LiveViewNative
import LiveViewNativeCore
import RealityKit
import OSLog

private let logger = Logger(subsystem: "LiveViewNativeRealityKit", category: "ComponentContentBuilder")

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
        do {
            switch tag {
            case .group:
                return try Self.buildChildren(of: element, in: context)
            case .anchoringComponent:
                return [try AnchoringComponent(from: element, in: context)]
            case .opacityComponent:
                return [try OpacityComponent(from: element, in: context)]
            case .groundingShadowComponent:
                return [try GroundingShadowComponent(from: element, in: context)]
            case .physicsBodyComponent:
                let physicsBody = try PhysicsBodyComponent(from: element, in: context)
                if let changeEvent = element.attributeValue(for: "phx-change") {
                    return [physicsBody, PhysicsBodyChangeEventComponent(event: changeEvent)]
                } else {
                    return [physicsBody]
                }
            case .collisionComponent:
                return [try CollisionComponent(from: element, in: context)]
            case .hoverEffectComponent:
                return [HoverEffectComponent()]
            }
        } catch {
            logger.log(level: .error, "Component \(tag.rawValue) failed to build with: \(error.localizedDescription)")
            return []
        }
    }
    
    static func empty() -> [any Component] {
        []
    }
    
    static func reduce(accumulated: [any Component], next: [any Component]) -> [any Component] {
        accumulated + next
    }
}
