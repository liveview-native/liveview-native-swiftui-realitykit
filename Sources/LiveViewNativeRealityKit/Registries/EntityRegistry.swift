//
//  EntityRegistry.swift
//
//
//  Created by Carson Katri on 6/6/24.
//

import LiveViewNative
import RealityKit

public protocol EntityRegistry: ContentBuilder where Content == [Entity] {}

public extension EntityRegistry {
    static func empty() -> Content {
        []
    }
    
    static func reduce(accumulated: Content, next: Content) -> Content {
        accumulated + next
    }
}

public struct EmptyEntityRegistry: EntityRegistry {
    public struct TagName: RawRepresentable {
        public init?(rawValue: String) {
            return nil
        }
        
        public var rawValue: String {
            fatalError()
        }
    }
    
    public static func lookup<R: RootRegistry>(_ tag: TagName, element: ElementNode, context: Context<R>) -> Content {
        []
    }
}
