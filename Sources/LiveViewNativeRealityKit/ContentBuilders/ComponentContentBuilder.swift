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

struct ComponentContentBuilder<Components: ComponentRegistry>: ComponentRegistry {
    enum TagName: RawRepresentable {
        case builtin(Builtin)
        case custom(Components.TagName)
        
        enum Builtin: String {
            case group = "Group"
            
            case anchoringComponent = "AnchoringComponent"
            case opacityComponent = "OpacityComponent"
            case groundingShadowComponent = "GroundingShadowComponent"
            
            case physicsBodyComponent = "PhysicsBodyComponent"
            case collisionComponent = "CollisionComponent"
            
            case hoverEffectComponent = "HoverEffectComponent"
        }
        
        typealias RawValue = String
        
        init?(rawValue: String) {
            if let builtin = Builtin.init(rawValue: rawValue) {
                self = .builtin(builtin)
            } else if let custom = Components.TagName.init(rawValue: rawValue) {
                self = .custom(custom)
            } else {
                return nil
            }
        }
        
        var rawValue: RawValue {
            switch self {
            case .builtin(let builtin):
                builtin.rawValue
            case .custom(let tagName):
                tagName.rawValue
            }
        }
    }
    
    static func lookup<R: RootRegistry>(_ tag: TagName, element: LiveViewNative.ElementNode, context: Context<R>) -> [any Component] {
        do {
            switch tag {
            case let .builtin(builtin):
                switch builtin {
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
            case .custom:
                return try Self.build([element.node], with: Components.self, in: context)
            }
        } catch {
            logger.log(level: .error, "Component \(tag.rawValue) failed to build with: \(error)")
            return []
        }
    }
}
