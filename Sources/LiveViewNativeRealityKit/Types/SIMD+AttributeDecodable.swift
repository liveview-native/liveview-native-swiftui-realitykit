//
//  SIMD+AttributeDecodable.swift
//
//
//  Created by Carson Katri on 6/6/24.
//

import Foundation
import LiveViewNative
import LiveViewNativeCore
import Spatial

private let decoder = JSONDecoder()

extension SIMD2: AttributeDecodable where Scalar: AttributeDecodable & Decodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let value = attribute?.value
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        self = try decoder.decode(Self.self, from: Data(value.utf8))
    }
}

extension SIMD3: AttributeDecodable where Scalar: AttributeDecodable & Decodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let value = attribute?.value
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        self = try decoder.decode(Self.self, from: Data(value.utf8))
    }
}

extension SIMD4: AttributeDecodable where Scalar: AttributeDecodable & Decodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let value = attribute?.value
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        self = try decoder.decode(Self.self, from: Data(value.utf8))
    }
}
