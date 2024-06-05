//
//  HandTracking.swift
//
//
//  Created by Carson Katri on 5/23/24.
//

import LiveViewNative
import LiveViewNativeCore
import ARKit
import RealityKit
import OSLog
import Combine

private let logger = Logger(subsystem: "LiveViewNativeRealityKit", category: "HandTrackingEntity")

class HandTrackingEntity: Entity {
    let session = ARKitSession()
    let provider = HandTrackingProvider()
    
    var fingerEntities: [HandAnchor.Chirality:[HandSkeleton.JointName:[Entity]]] = [
        .left: [:],
        .right: [:]
    ]
    
    let changePublisher: PassthroughSubject<HandAnchor, Never> = .init()
    var cancellable: AnyCancellable?
    
    required init() {
        super.init()
        self.start()
    }
    
    init<R: RootRegistry>(
        from element: ElementNode,
        in context: RealityViewContentBuilder.Context<R>
    ) {
        if let changeEvent = element.attributeValue(for: "phx-change") {
            let chiralityFilter: HandAnchor.Chirality? = switch element.attributeValue(for: "chirality") {
            case "left":
                .left
            case "right":
                .right
            default:
                nil
            }
            let jointFilter = element.attributeValue(for: "joint")
            
            self.cancellable = self.changePublisher
                .filter({ chiralityFilter == nil || $0.chirality == chiralityFilter })
                .throttle(
                    for: .milliseconds(Int(
                        (try? element.attributeValue(Double.self, for: "phx-throttle"))
                        ?? (try? element.attributeValue(Double.self, for: "phx-debounce"))
                        ?? 0
                    )),
                    scheduler: RunLoop.current,
                    latest: true
                )
                .sink { handAnchor in
                    guard let jointTransforms = handAnchor.handSkeleton?.allJoints
                        .reduce(into: [String:[[Float]]](), { (result, joint) in
                            if let jointFilter {
                                guard joint.name.description == jointFilter else { return }
                            }
                            guard joint.isTracked else { return }
                            let origin = handAnchor.originFromAnchorTransform * joint.anchorFromJointTransform
                            result[joint.name.description] = [
                                origin.columns.0,
                                origin.columns.1,
                                origin.columns.2,
                                origin.columns.3
                            ].map({ [$0.x, $0.y, $0.z, $0.w] })
                        })
                    else { return }
                    Task {
                        try await context.coordinator.pushEvent(type: "click", event: changeEvent, value: [
                            "chirality": handAnchor.chirality.description,
                            "id": handAnchor.id.uuidString,
                            "allJoints": jointTransforms,
                            "originFromAnchorTransform": [
                                handAnchor.originFromAnchorTransform.columns.0,
                                handAnchor.originFromAnchorTransform.columns.1,
                                handAnchor.originFromAnchorTransform.columns.2,
                                handAnchor.originFromAnchorTransform.columns.3
                            ].map({ [$0.x, $0.y, $0.z, $0.w] })
                        ])
                    }
                }
        }
        
        super.init()
        
        for child in element.children() {
            guard let template = child.attributes.first(where: { $0.name == "template" })?.value
            else { continue }
            let fingerReference = template.split(separator: "." as Character)
            guard fingerReference.count == 2 else { continue }
            let chirality: HandAnchor.Chirality
            switch fingerReference.first {
            case "left":
                chirality = .left
            case "right":
                chirality = .right
            default:
                continue
            }
            guard let jointName = HandSkeleton.JointName.allCases.first(where: { $0.description == String(fingerReference.last!) })
            else { continue }
            
            let entities = try! RealityViewContentBuilder.build([child], in: context)
            fingerEntities[chirality]![jointName] = entities
            for entity in entities {
                addChild(entity)
            }
        }
        self.start()
    }
    
    func start() {
        Task { [weak self] in
            guard let self else { return }
            if HandTrackingProvider.isSupported {
                try await session.run([provider])
            } else {
                logger.warning("Hand tracking is not available on this device")
            }
        }
        Task { [weak self] in
            guard let self else { return }
            for await update in provider.anchorUpdates {
                let handAnchor = update.anchor

                guard handAnchor.isTracked else { continue }
                
                changePublisher.send(handAnchor)
                
                for (name, entities) in (fingerEntities[handAnchor.chirality] ?? [:]) {
                    guard let joint = handAnchor.handSkeleton?.joint(name),
                          joint.isTracked
                    else { continue }
                    let origin = handAnchor.originFromAnchorTransform * joint.anchorFromJointTransform
                    for entity in entities {
                        entity.setTransformMatrix(origin, relativeTo: nil)
                    }
                }
            }
        }
    }
    
    deinit {
        session.stop()
    }
}
