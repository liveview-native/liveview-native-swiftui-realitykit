//
//  File.swift
//  
//
//  Created by Carson.Katri on 6/6/24.
//

import LiveViewNative
import LiveViewNativeCore
import SwiftUI
import RealityKit

extension PhysicallyBasedMaterial {
    public init(from element: ElementNode) throws {
        self.init()
        if let baseColor = try? element.attributeValue(SwiftUI.Color.self, for: "baseColor") {
            self.baseColor = .init(
                tint: UIColor(baseColor),
                texture: nil
            )
        }
        if let roughness = try? element.attributeValue(Float.self, for: "roughness") {
            self.roughness = .init(floatLiteral: roughness)
        }
        if let metallic = try? element.attributeValue(Float.self, for: "metallic") {
            self.metallic = .init(floatLiteral: metallic)
        }
        if let blending = try? element.attributeValue(Float.self, for: "blending") {
            self.blending = .transparent(opacity: .init(floatLiteral: blending))
        }
        if let specular = try? element.attributeValue(Float.self, for: "specular") {
            self.specular = .init(floatLiteral: specular)
        }
        if let sheen = try? element.attributeValue(SwiftUI.Color.self, for: "sheen") {
            self.sheen = .init(tint: UIColor(sheen), texture: nil)
        }
        if let clearcoat = try? element.attributeValue(Float.self, for: "clearcoat") {
            self.clearcoat = .init(floatLiteral: clearcoat)
        }
        if let clearcoatRoughness = try? element.attributeValue(Float.self, for: "clearcoatRoughness") {
            self.clearcoatRoughness = .init(floatLiteral: clearcoatRoughness)
        }
        if let anisotropyLevel = try? element.attributeValue(Float.self, for: "anisotropyLevel") {
            self.anisotropyLevel = .init(floatLiteral: anisotropyLevel)
        }
        if let anisotropyAngle = try? element.attributeValue(Float.self, for: "anisotropyAngle") {
            self.anisotropyAngle = .init(floatLiteral: anisotropyAngle)
        }
        if let emissiveIntensity = try? element.attributeValue(Float.self, for: "emissiveIntensity") {
            self.emissiveIntensity = emissiveIntensity
        }
        if let emissiveColor = try? element.attributeValue(SwiftUI.Color.self, for: "emissiveColor") {
            self.emissiveColor = .init(color: UIColor(emissiveColor))
        }
        if let faceCulling = try? element.attributeValue(MaterialParameterTypes.FaceCulling.self, for: "faceCulling") {
            self.faceCulling = faceCulling
        }
        if let triangleFillMode = try? element.attributeValue(MaterialParameterTypes.TriangleFillMode.self, for: "triangleFillMode") {
            self.triangleFillMode = triangleFillMode
        }
    }
}

extension MaterialParameterTypes.FaceCulling: AttributeDecodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let value = attribute?.value
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        switch value {
        case "back":
            self = .back
        case "front":
            self = .front
        case "none":
            self = .none
        default:
            throw AttributeDecodingError.badValue(Self.self)
        }
    }
}

extension MaterialParameterTypes.TriangleFillMode: AttributeDecodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let value = attribute?.value
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        switch value {
        case "fill":
            self = .fill
        case "lines":
            self = .lines
        default:
            throw AttributeDecodingError.badValue(Self.self)
        }
    }
}
