//
//  AsyncEntity.swift
//
//
//  Created by Carson Katri on 5/30/24.
//

import Foundation
import RealityKit
import LiveViewNative

final class AsyncEntity: Entity {
    var setupTask: Task<(), Error>? = nil
    
    init(
        from element: ElementNode,
        in context: RealityViewContentBuilder.Context<some RootRegistry>
    ) {
        AsyncEntityComponent.registerComponent()
        
        super.init()
        
        if let url = element.attributeValue(for: "url").flatMap({ URL(string: $0, relativeTo: context.url) }) {
            setupTask = Task { [weak self] in
                let (fileURL, _) = try await URLSession.shared.download(from: url)
                let correctedExtensionURL = fileURL.deletingPathExtension().appendingPathExtension(for: .usdz)
                try FileManager.default.moveItem(at: fileURL, to: correctedExtensionURL)
                
                do {
                    let entity = try await Entity(contentsOf: correctedExtensionURL)
                    entity.components.set(AsyncEntityComponent(url: url))
                    self?.addChild(entity)
                    
                    try self?.updateResolvedEntity(with: element, in: context)
                }
                
                try FileManager.default.removeItem(at: correctedExtensionURL)
            }
        }
    }
    
    required init() {
        super.init()
    }
    
    func updateResolvedEntity(with element: ElementNode, in context: RealityViewContentBuilder.Context<some RootRegistry>) throws {
        guard let entity = self.children.first else { return }
        var elementNodeComponent = self.components[ElementNodeComponent.self]
        if let animationName = element.attributeValue(for: "playAnimation") {
            let transitionDuration = try element.attributeValue(Double.self, for: .init(namespace: "playAnimation", name: "transitionDuration"))
            elementNodeComponent?.animation?.controller.stop(blendOutDuration: transitionDuration)
            elementNodeComponent?.animation = (
                name: animationName,
                controller: entity.playAnimation(
                    try AnimationResource.generate(
                        with: AnimationGroup(
                            group: RealityViewContentBuilder.buildChildren(
                                of: element,
                                forTemplate: animationName,
                                with: AnimationContentBuilder.self,
                                in: context
                            )
                            .map({ $0.resolveAnimationResources(with: entity.availableAnimations) })
                        )
                    ),
                    transitionDuration: transitionDuration,
                    startsPaused: element.attributeBoolean(for: .init(namespace: "playAnimation", name: "startsPaused"))
                )
            )
        }
        if let elementNodeComponent {
            self.components.set(elementNodeComponent)
        }
    }
}

struct AsyncEntityComponent: Component {
    let url: URL
}
