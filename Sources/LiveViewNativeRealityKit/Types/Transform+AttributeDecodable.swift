//
//  Transform+AttributeDecodable.swift
//
//
//  Created by Carson Katri on 6/6/24.
//

import LiveViewNative
import RealityKit

extension ElementNode {
    func transform(for namespace: String) throws -> Transform {
        .init(
            scale: (try? attributeValue(SIMD3<Float>.self, for: .init(namespace: namespace, name: "scale"))) ?? SIMD3<Float>(x: 1, y: 1, z: 1),
            rotation: simd_quaternion((try? attributeValue(SIMD4<Float>.self, for: .init(namespace: namespace, name: "rotation"))) ?? SIMD4<Float>(0, 0, 0, 1)),
            translation: (try? attributeValue(SIMD3<Float>.self, for: .init(namespace: namespace, name: "translation"))) ?? SIMD3<Float>(x: 0, y: 0, z: 0)
        )
    }
}
