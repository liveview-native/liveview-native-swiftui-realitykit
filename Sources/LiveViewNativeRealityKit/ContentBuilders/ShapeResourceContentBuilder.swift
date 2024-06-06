//
//  ShapeResourceContentBuilder.swift
//
//
//  Created by Carson Katri on 6/6/24.
//

import LiveViewNative
import RealityKit

struct ShapeResourceContentBuilder: ContentBuilder {
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
