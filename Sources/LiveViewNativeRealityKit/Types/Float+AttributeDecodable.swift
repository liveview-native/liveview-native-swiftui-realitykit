//
//  Float+AttributeDecodable.swift
//
//
//  Created by Carson Katri on 6/6/24.
//

import LiveViewNative
import LiveViewNativeCore

extension Float: AttributeDecodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let attributeValue = attribute?.value else { throw AttributeDecodingError.missingAttribute(Self.self) }
        guard let result = Self(attributeValue) else { throw AttributeDecodingError.badValue(Self.self) }
        self = result
    }
}
