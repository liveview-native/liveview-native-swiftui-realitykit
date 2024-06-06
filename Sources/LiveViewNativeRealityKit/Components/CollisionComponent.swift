//
//  CollisionComponent.swift
//
//
//  Created by Carson Katri on 6/6/24.
//

import Foundation
import LiveViewNative
import LiveViewNativeCore
import RealityKit

extension CollisionComponent {
    init(from element: ElementNode, in context: ComponentContentBuilder.Context<some RootRegistry>) throws {
        let shapes = try ComponentContentBuilder.buildChildren(of: element, with: ShapeResourceContentBuilder.self, in: context)
        let isStatic = element.attributeBoolean(for: "isStatic")
        let filter = try? element.attributeValue(CollisionFilter.self, for: "filter")
        let mode = try? element.attributeValue(Mode.self, for: "mode")
        
        if let collisionOptions = try? element.attributeValue(CollisionOptions.self, for: "collisionOptions") {
            self.init(
                shapes: shapes,
                mode: mode ?? .default,
                collisionOptions: collisionOptions,
                filter: filter ?? .default
            )
        } else if let mode {
            self.init(
                shapes: shapes,
                mode: mode,
                filter: filter ?? .default
            )
        } else {
            self.init(
                shapes: shapes,
                isStatic: isStatic,
                filter: filter ?? .default
            )
        }
    }
}

extension CollisionComponent.Mode: AttributeDecodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let value = attribute?.value
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        
        switch value {
        case "colliding":
            self = .colliding
        case "default":
            self = .default
        case "trigger":
            self = .trigger
        default:
            throw AttributeDecodingError.badValue(Self.self)
        }
    }
}

extension CollisionComponent.CollisionOptions: AttributeDecodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let value = attribute?.value
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        
        switch value {
        case "none":
            self = .none
        case "static":
            self = .static
        default:
            throw AttributeDecodingError.badValue(Self.self)
        }
    }
}

extension CollisionFilter: AttributeDecodable, Decodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let value = attribute?.value
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        
        switch value {
        case "default":
            self = .default
        case "sensor":
            self = .sensor
        default:
            self = try JSONDecoder().decode(Self.self, from: Data(value.utf8))
        }
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            group: try container.decode(CollisionGroup.self, forKey: .group),
            mask: try container.decode(CollisionGroup.self, forKey: .mask)
        )
    }
    
    enum CodingKeys: String, CodingKey {
        case group
        case mask
    }
}

extension CollisionGroup: Decodable {
    public init(from decoder: any Decoder) throws {
        if let container = try? decoder.singleValueContainer() {
            if let named = try? container.decode(DecodableNamedGroup.self) {
                switch named {
                case .all:
                    self = .all
                case .default:
                    self = .default
                case .sceneUnderstanding:
                    self = .sceneUnderstanding
                }
            } else {
                self = .init(rawValue: try container.decode(UInt32.self))
            }
        } else {
            var container = try decoder.unkeyedContainer()
            self = []
            while !container.isAtEnd {
                self.insert(try container.decode(Self.self))
            }
        }
    }
    
    private enum DecodableNamedGroup: String, Decodable {
        case all
        case `default`
        case sceneUnderstanding
    }
}
