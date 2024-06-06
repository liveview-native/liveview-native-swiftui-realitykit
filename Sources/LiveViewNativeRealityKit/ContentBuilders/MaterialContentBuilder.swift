//
//  MaterialContentBuilder.swift
//
//
//  Created by Carson Katri on 6/6/24.
//

import LiveViewNative
import SwiftUI
import RealityKit
import OSLog

private let logger = Logger(subsystem: "LiveViewNativeRealityKit", category: "MaterialContentBuilder")

struct MaterialContentBuilder: ContentBuilder {
    enum TagName: String {
        case group = "Group"
        
        case simpleMaterial = "SimpleMaterial"
        case physicallyBasedMaterial = "PhysicallyBasedMaterial"
        case unlitMaterial = "UnlitMaterial"
        case occlusionMaterial = "OcclusionMaterial"
        case portalMaterial = "PortalMaterial"
    }
    
    typealias Content = [any RealityKit.Material]
    
    static func lookup<R>(_ tag: TagName, element: ElementNode, context: Context<R>) -> Content where R : RootRegistry {
        do {
            switch tag {
            case .group:
                return try Self.buildChildren(of: element, in: context)
            case .simpleMaterial:
                return [try SimpleMaterial(from: element)]
            case .physicallyBasedMaterial:
                return [try PhysicallyBasedMaterial(from: element)]
            case .unlitMaterial:
                return [try UnlitMaterial(from: element)]
            case .occlusionMaterial:
                return [OcclusionMaterial()]
            case .portalMaterial:
                return [PortalMaterial()]
            }
        } catch {
            logger.error("Material \(element.tag) failed to build with: \(error)")
            return []
        }
    }
    
    static func empty() -> Content {
        []
    }
    
    static func reduce(accumulated: Content, next: Content) -> Content {
        accumulated + next
    }
}
