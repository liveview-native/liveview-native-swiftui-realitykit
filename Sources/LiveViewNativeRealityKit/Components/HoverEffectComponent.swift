//
//  HoverEffectComponent.swift
//  
//
//  Created by Carson Katri on 6/12/24.
//

import LiveViewNative
import RealityKit
import SwiftUI

extension HoverEffectComponent {
    init(from element: ElementNode, in context: _ComponentContentBuilder<some ComponentRegistry>.Context<some RootRegistry>) throws {
        if #available(visionOS 2, *) {
            switch element.attributeValue(for: "hoverEffect") {
            case "spotlight":
                self.init(
                    .spotlight(.init(
                        color: (try? element.attributeValue(Color.self, for: "color")).flatMap(UIColor.init),
                        strength: (try? element.attributeValue(Float.self, for: "strength")) ?? 1
                    ))
                )
            case "highlight":
                self.init(
                    .highlight(.init(
                        color: (try? element.attributeValue(Color.self, for: "color")).flatMap(UIColor.init),
                        strength: (try? element.attributeValue(Float.self, for: "strength")) ?? 1
                    ))
                )
            default:
                self.init()
            }
        } else {
            self.init()
        }
    }
}
