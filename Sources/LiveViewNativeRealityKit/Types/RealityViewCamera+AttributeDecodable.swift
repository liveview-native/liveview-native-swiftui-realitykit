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

struct _RealityViewCamera: AttributeDecodable {
    let value: RealityViewCamera
    
    static var virtual: Self { Self(value: .virtual) }
    static var worldTracking: Self { Self(value: .worldTracking) }
    
    init(value: RealityViewCamera) {
        self.value = value
    }
    
    init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let value = attribute?.value
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        
        switch value {
        case "virtual":
            self.value = .virtual
        case "worldTracking":
            self.value = .worldTracking
        default:
            throw AttributeDecodingError.badValue(Self.self)
        }
    }
}
#else
import LiveViewNative
import LiveViewNativeCore

/// A stub for compatibility across platforms.
enum _RealityViewCamera: String, AttributeDecodable {
    case virtual
    case worldTracking
}
#endif
