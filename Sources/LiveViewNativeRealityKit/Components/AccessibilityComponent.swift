//
//  AccessibilityComponent.swift
//
//
//  Created by Carson Katri on 6/6/24.
//

import LiveViewNative
import LiveViewNativeCore
import Foundation
import RealityKit

extension AccessibilityComponent {
    init(from element: ElementNode, in context: _ComponentContentBuilder<some ComponentRegistry>.Context<some RootRegistry>) throws {
        self.init()
        
        self.label = element.attributeValue(for: "label").flatMap(LocalizedStringResource.init(stringLiteral:))
        self.value = element.attributeValue(for: "label").flatMap(LocalizedStringResource.init(stringLiteral:))
        self.systemActions = (try? element.attributeValue(SupportedActions.self, for: "systemActions")) ?? []
        self.customActions = (
            try? element.attributeValue([String].self, for: "customActions")
        )
            .flatMap({ $0.map(LocalizedStringResource.init(stringLiteral:)) })
            ?? []
    }
}

extension AccessibilityComponent.SupportedActions: AttributeDecodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let value = attribute?.value
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        switch value {
        case "activate":
            self = .activate
        case "decrement":
            self = .decrement
        case "increment":
            self = .increment
        default:
            throw AttributeDecodingError.badValue(Self.self)
        }
    }
}
