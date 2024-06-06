//
//  UnlitMaterial.swift
//
//
//  Created by Carson Katri on 6/6/24.
//

import LiveViewNative
import SwiftUI
import RealityKit

extension UnlitMaterial {
    init(from element: ElementNode) throws {
        if let color = try? element.attributeValue(SwiftUI.Color.self, for: "color") {
            self.init(
                color: UIColor(color),
                applyPostProcessToneMap: element.attributeBoolean(for: "applyPostProcessToneMap")
            )
        } else {
            self.init(applyPostProcessToneMap: element.attributeBoolean(for: "applyPostProcessToneMap"))
        }
    }
}
