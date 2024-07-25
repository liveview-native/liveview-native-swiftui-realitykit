//
//  RealityViewCamera+AttributeDecodable.swift
//  
//
//  Created by Carson.Katri on 7/25/24.
//

#if os(iOS) || os(macOS)
import LiveViewNative
import LiveViewNativeCore
import RealityKit
import SwiftUI

extension RealityViewCamera: AttributeDecodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let value = attribute?.value
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        
        switch value {
        case "virtual":
            self = .virtual
        case "worldTracking":
            self = .worldTracking
        default:
            throw AttributeDecodingError.badValue(Self.self)
        }
    }
}
#else
typealias RealityViewCamera = String
#endif
