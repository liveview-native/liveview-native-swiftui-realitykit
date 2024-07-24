//
//  ViewAttachmentEntity.swift
//  
//
//  Created by Carson Katri on 7/24/24.
//

import LiveViewNative
import LiveViewNativeCore
import RealityKit
import SwiftUI

final class _ViewAttachmentEntity: Entity {
    init<R: RootRegistry, E: EntityRegistry, C: ComponentRegistry>(
        from element: ElementNode,
        in context: EntityContentBuilder<E, C>.Context<R>
    ) throws {
        super.init()
        let attachment = element.attributeValue(for: "attachment")
        self.components.set(ViewAttachmentComponent(attachment: attachment))
    }
    
    required init() {
        super.init()
    }
}

struct ViewAttachmentComponent: Component {
    let attachment: String?
    var resolvedAttachment: Entity? = nil
}
