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

struct AnyMaterial: RealityKit.Material, AttributeDecodable {
    var __resource: __MaterialResource
    var __parameterBlock: __RKMaterialParameterBlock
    
    init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let value = attribute?.value,
              let name = attribute?.name.name
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        let material: any RealityKit.Material = switch value {
        case "pbr":
            try PhysicallyBasedMaterial(from: attribute, on: element)
        case "unlit":
            UnlitMaterial(
                color: UIColor(try element.attributeValue(SwiftUI.Color.self, for: .init(namespace: name, name: "color")))
            )
        case "simple":
            try SimpleMaterial(from: attribute, on: element)
        case "occlusion":
            OcclusionMaterial()
        default:
            throw AttributeDecodingError.badValue(Self.self)
        }
        self.__resource = material.__resource
        self.__parameterBlock = material.__parameterBlock
    }
}

extension PhysicallyBasedMaterial: AttributeDecodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let name = attribute?.name.name
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        self.init()
        self.baseColor = .init(
            tint: UIColor(try element.attributeValue(SwiftUI.Color.self, for: .init(namespace: name, name: "baseColor"))),
            texture: nil
        )
        if let metallic = try? element.attributeValue(Float.self, for: .init(namespace: name, name: "metallic")) {
            self.metallic = .init(floatLiteral: metallic)
        }
        if let roughness = try? element.attributeValue(Float.self, for: .init(namespace: name, name: "roughness")) {
            self.roughness = .init(floatLiteral: roughness)
        }
    }
}

extension SimpleMaterial: AttributeDecodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let name = attribute?.name.name
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        self.init(
            color: UIColor(try element.attributeValue(SwiftUI.Color.self, for: .init(namespace: name, name: "color"))),
            roughness: .float((try? element.attributeValue(Float.self, for: .init(namespace: name, name: "roughness"))) ?? 0),
            isMetallic: element.attributeBoolean(for: .init(namespace: name, name: "isMetallic"))
        )
    }
}
