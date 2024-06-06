//
//  ComponentRegistry.swift
//
//
//  Created by Carson Katri on 6/6/24.
//

import LiveViewNative
import RealityKit

public protocol ComponentRegistry: ContentBuilder where Content == [any Component] {}

public extension ComponentRegistry {
    static func empty() -> Content {
        []
    }
    
    static func reduce(accumulated: Content, next: Content) -> Content {
        accumulated + next
    }
}

public struct EmptyComponentRegistry: ComponentRegistry {
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
