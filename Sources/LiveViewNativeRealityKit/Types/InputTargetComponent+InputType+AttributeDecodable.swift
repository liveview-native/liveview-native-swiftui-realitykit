//
//  InputTargetComponent+InputType+AttributeDecodable.swift
//
//
//  Created by Carson Katri on 6/6/24.
//

import LiveViewNative
import LiveViewNativeCore
import RealityKit

extension InputTargetComponent.InputType: AttributeDecodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let value = attribute?.value
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        
        switch value {
        case "indirect":
            self = .indirect
        case "direct":
            self = .direct
        case "all":
            self = .all
        default:
            throw AttributeDecodingError.badValue(Self.self)
        }
    }
}
