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
    
    static var entityCache = [URL:Entity]()
    
    init<E: EntityRegistry, C: ComponentRegistry>(
        from element: ElementNode,
        in context: EntityContentBuilder<E, C>.Context<some RootRegistry>
    ) throws {
        AsyncEntityComponent.registerComponent()
        
        super.init()
        
        let loadSync = element.attributeBoolean(for: "loadSync")
        
        if let url = element.attributeValue(for: "url").flatMap({ URL(string: $0, relativeTo: context.url) }) {
            if let cached = Self.entityCache[url] {
                let entity = cached.clone(recursive: true)
                entity.components.set(AsyncEntityComponent.remote(url))
                self.addChild(entity)
            } else if loadSync {
                let group = DispatchGroup()
                group.enter()
                
                var fileURL: Result<URL, Error>!
                
                let downloadTask = URLSession.shared.downloadTask(with: url) { result, _, error in
                    if let result {
                        fileURL = .success(result)
                    } else {
                        fileURL = .failure(error!)
                    }
                    group.leave()
                }
                downloadTask.resume()
                
                group.wait()
                
                switch fileURL! {
                case .success(let fileURL):
                    let correctedExtensionURL = fileURL.deletingPathExtension().appendingPathExtension(for: .usdz)
                    try FileManager.default.moveItem(at: fileURL, to: correctedExtensionURL)
                    
                    do {
                        let entity = try Entity.load(contentsOf: correctedExtensionURL)
                        Self.entityCache[url] = entity.clone(recursive: true)
                        entity.components.set(AsyncEntityComponent.remote(url))
                        self.addChild(entity)
                        
                        try self.updateResolvedEntity(with: element, in: context)
                    } catch {
                        try FileManager.default.removeItem(at: correctedExtensionURL)
                        throw error
                    }
                    
                    try FileManager.default.removeItem(at: correctedExtensionURL)
                case .failure(let error):
                    throw error
                }
            } else {
                setupTask = Task { [weak self] in
                    let (fileURL, _) = try await URLSession.shared.download(from: url)
                    let correctedExtensionURL = fileURL.deletingPathExtension().appendingPathExtension(for: .usdz)
                    try FileManager.default.moveItem(at: fileURL, to: correctedExtensionURL)
                    
                    do {
                        let entity = try await Entity(contentsOf: correctedExtensionURL)
                        Self.entityCache[url] = entity.clone(recursive: true)
                        entity.components.set(AsyncEntityComponent.remote(url))
                        self?.addChild(entity)
                        
                        try self?.updateResolvedEntity(with: element, in: context)
                    } catch {
                        try FileManager.default.removeItem(at: correctedExtensionURL)
                        throw error
                    }
                    try FileManager.default.removeItem(at: correctedExtensionURL)
                }
            }
        } else if let named = element.attributeValue(for: "named") {
            if loadSync {
                let entity = try Entity.load(named: named)
                entity.components.set(AsyncEntityComponent.named(named))
                self.addChild(entity)
                
                try self.updateResolvedEntity(with: element, in: context)
            } else {
                setupTask = Task { [weak self] in
                    let entity = try await Entity(named: named)
                    entity.components.set(AsyncEntityComponent.named(named))
                    self?.addChild(entity)
                    
                    try self?.updateResolvedEntity(with: element, in: context)
                }
            }
        }
    }
    
    required init() {
        super.init()
    }
    
    func updateResolvedEntity<E: EntityRegistry, C: ComponentRegistry>(
        with element: ElementNode,
        in context: EntityContentBuilder<E, C>.Context<some RootRegistry>
    ) throws {
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
                            group: EntityContentBuilder<E, C>.buildChildren(
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

enum AsyncEntityComponent: Component {
    case remote(URL)
    case named(String)
}
