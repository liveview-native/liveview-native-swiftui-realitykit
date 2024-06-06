//
//  MeshResourceContentBuilder.swift
//
//
//  Created by Carson Katri on 6/6/24.
//

import LiveViewNative
import LiveViewNativeCore
import RealityKit
import OSLog

private let logger = Logger(subsystem: "LiveViewNativeRealityKit", category: "MeshResourceContentBuilder")

struct MeshResourceContentBuilder: ContentBuilder {
    enum TagName: String {
        case group = "Group"
        
        case box = "Box"
        case sphere = "Sphere"
        case cone = "Cone"
        case cylinder = "Cylinder"
        case plane = "Plane"
    }
    
    typealias Content = [MeshResource]
    
    static func lookup<R>(_ tag: TagName, element: ElementNode, context: Context<R>) -> Content where R : RootRegistry {
        do {
            switch tag {
            case .group:
                return try Self.buildChildren(of: element, in: context)
            case .box:
                return [try MeshResource.generateBox(from: element)]
            case .sphere:
                return [try MeshResource.generateSphere(from: element)]
            case .cone:
                return [try MeshResource.generateCone(from: element)]
            case .cylinder:
                return [try MeshResource.generateCylinder(from: element)]
            case .plane:
                return [try MeshResource.generatePlane(from: element)]
            }
        } catch {
            logger.error("MeshResource \(element.tag) failed to build with: \(error)")
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

extension MeshResource {
    static func generate(from children: [MeshResource]) throws -> MeshResource {
        guard children.count != 1 else {
            return children[0]
        }
        
        var contents = Contents()
        for (id, child) in children.enumerated() {
            let id = String(id)
            for var instance in child.contents.instances {
                instance.id = id
                instance.model = id
                contents.instances.insert(instance)
            }
            for var model in child.contents.models {
                model.id = id
                contents.models.insert(model)
            }
        }
        return try .generate(from: contents)
    }
    
    static func generateBox(from element: ElementNode) throws -> MeshResource {
        let cornerRadius = try? element.attributeValue(Float.self, for: "cornerRadius")
        if let size = try? element.attributeValue(Float.self, for: "size") {
            return .generateBox(size: size, cornerRadius: cornerRadius ?? 0)
        } else if let size = try? element.attributeValue(SIMD3<Float>.self, for: "size") {
            if let cornerRadius {
                return .generateBox(size: size, cornerRadius: cornerRadius)
            } else {
                let majorCornerRadius = try? element.attributeValue(Float.self, for: "majorCornerRadius")
                let minorCornerRadius = try? element.attributeValue(Float.self, for: "minorCornerRadius")
                if majorCornerRadius != nil || minorCornerRadius != nil {
                    return .generateBox(size: size, majorCornerRadius: majorCornerRadius ?? 0.2, minorCornerRadius: minorCornerRadius ?? 0.05)
                } else {
                    return .generateBox(size: size)
                }
            }
        } else {
            return .generateBox(
                width: try element.attributeValue(Float.self, for: "width"),
                height: try element.attributeValue(Float.self, for: "height"),
                depth: try element.attributeValue(Float.self, for: "depth"),
                cornerRadius: cornerRadius ?? 0,
                splitFaces: element.attributeBoolean(for: "splitFaces")
            )
        }
    }
    
    static func generateSphere(from element: ElementNode) throws -> MeshResource {
        return .generateSphere(radius: try element.attributeValue(Float.self, for: "radius"))
    }
    
    static func generateCone(from element: ElementNode) throws -> MeshResource {
        return .generateCone(
            height: try element.attributeValue(Float.self, for: "height"),
            radius: try element.attributeValue(Float.self, for: "radius")
        )
    }
    
    static func generateCylinder(from element: ElementNode) throws -> MeshResource {
        return .generateCylinder(
            height: try element.attributeValue(Float.self, for: "height"),
            radius: try element.attributeValue(Float.self, for: "radius")
        )
    }
    
    static func generatePlane(from element: ElementNode) throws -> MeshResource {
        let cornerRadius = (try? element.attributeValue(Float.self, for: "cornerRadius")) ?? 0
        let width = try element.attributeValue(Float.self, for: "width")
        
        if let depth = try? element.attributeValue(Float.self, for: "depth") {
            return .generatePlane(width: width, depth: depth, cornerRadius: cornerRadius)
        } else {
            return .generatePlane(
                width: width,
                height: try element.attributeValue(Float.self, for: "height"),
                cornerRadius: cornerRadius
            )
        }
    }
}
