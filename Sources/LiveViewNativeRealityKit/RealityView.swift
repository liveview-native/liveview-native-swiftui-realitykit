//
//  File.swift
//  
//
//  Created by Carson.Katri on 5/22/24.
//

import LiveViewNative
import LiveViewNativeCore
import SwiftUI
import RealityKit
import Combine
import AudioToolbox
import OSLog

final class ElementNodeUpdateSystem<Root: RootRegistry, E: EntityRegistry, C: ComponentRegistry>: System {
    let updateContextQuery = EntityQuery(where: .has(UpdateContextComponent<Root, E, C>.self))
    let elementNodeQuery = EntityQuery(where: .has(ElementNodeComponent.self))
    let viewAttachmentQuery = EntityQuery(where: .has(ViewAttachmentComponent.self))
    let cameraTargetQuery = EntityQuery(where: .has(CameraTargetComponent.self))
    
    init(scene: RealityKit.Scene) {}
    
    func update(context: SceneUpdateContext) {
        var updateContextEntities = context.entities(matching: updateContextQuery, updatingSystemWhen: .rendering).makeIterator()
        guard let updateContextEntity = updateContextEntities.next(),
              var updateContext = updateContextEntity.components[UpdateContextComponent<Root, E, C>.self]
        else { return }

        // apply view attachments
        #if os(visionOS)
        for entity in context.entities(matching: viewAttachmentQuery, updatingSystemWhen: .rendering) {
            var attachment = entity.components[ViewAttachmentComponent.self]!
            guard attachment.resolvedAttachment == nil,
                  let id = attachment.attachment,
                  let resolvedAttachment = updateContext.attachments.entity(for: id)
            else { continue }
            attachment.resolvedAttachment = resolvedAttachment
            entity.addChild(resolvedAttachment)
        }
        #endif
        
        // update cameraTarget entity
        #if os(iOS) || os(macOS)
        var cameraTargetEntities = context.entities(matching: cameraTargetQuery, updatingSystemWhen: .rendering).makeIterator()
        let newCameraTarget = cameraTargetEntities.next()
        if newCameraTarget != updateContext.storage.cameraTarget {
            updateContext.storage.cameraTarget = newCameraTarget
        }
        #endif
        
        guard !updateContext.updates.isEmpty,
              let document = updateContext.document
        else { return }
        
        let elementNodes = context.entities(matching: elementNodeQuery, updatingSystemWhen: .rendering)
        // apply updates
        for updateId in updateContext.updates {
            guard let updatedEntity = elementNodes.first(where: { $0.components[ElementNodeComponent.self]?.element.id == updateId }),
                  let element = document[updateId].asElement()
            else { continue }
            
            do {
                try updatedEntity.applyAttributes(from: element, in: updateContext.context)
                try updatedEntity.applyChildren(from: element, in: updateContext.context)
            } catch {
                logger.error("Entity \(element.tag) failed to update with: \(error)")
            }
        }
        
        // clear pending updates
        updateContext.updates = []
        updateContextEntity.components.set(updateContext)
    }
}

struct UpdateContextComponent<Root: RootRegistry, E: EntityRegistry, C: ComponentRegistry>: Component {
    var storage: Storage
    var updates: Set<NodeRef> {
        get { storage.updates }
        set { storage.updates = newValue }
    }
    let document: Document?
    let context: EntityContentBuilder<E, C>.Context<Root>
    #if os(visionOS)
    let attachments: RealityViewAttachments
    #endif
    
    @Observable
    final class Storage {
        var updates: Set<NodeRef> = []
        var cameraTarget: Entity?
    }
}

private let logger = Logger(subsystem: "LiveViewNativeRealityKit", category: "RealityView")

@LiveElement
struct _RealityView<Root: RootRegistry, Entities: EntityRegistry, Components: ComponentRegistry>: View {
    @LiveElementIgnored
    @ObservedElement(observeChildren: true)
    private var element
    
    @LiveElementIgnored
    @LiveContext<Root>
    private var liveContext
    
    @LiveElementIgnored
    @ContentBuilderContext<Root, EntityContentBuilder<Entities, Components>>
    private var context
    
    private var audibleClicks: Bool = false
    
    private var camera: _RealityViewCamera = .worldTracking
    
    @LiveElementIgnored
    @State
    private var updateStorage = UpdateContextComponent<Root, Entities, Components>.Storage()
    
    @LiveElementIgnored
    @State
    private var subscriptions: [EventSubscription] = []
    
    init() {
        ElementNodeComponent.registerComponent()
        PhoenixClickEventComponent.registerComponent()
        PhysicsBodyChangeEventComponent.registerComponent()
        ViewAttachmentComponent.registerComponent()
        CameraTargetComponent.registerComponent()
        ElementNodeUpdateSystem<Root, Entities, Components>.registerSystem()
    }
    
    private func playClickSound() {
        guard audibleClicks
        else { return }
        let clickSoundURL = URL(filePath: "/System/Library/Audio/UISounds/key_press_click_visionOS.caf")
        var clickSoundID: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(clickSoundURL as CFURL, &clickSoundID)
        AudioServicesPlaySystemSound(clickSoundID)
    }
    
    #if os(visionOS)
    @AttachmentContentBuilder
    var attachments: some AttachmentContent {
        let attachments = $liveElement.childNodes
            .compactMap({ $0.asElement() })
            .filter({ $0.tag == "Attachment" && $0.attributes.contains(where: { $0.name == "template" && $0.value == "attachments" }) })
            .compactMap({ (attachment) -> (id: String, element: ElementNode)? in
                guard let id = attachment.attributeValue(for: "id") else { return nil }
                return (id: id, element: attachment)
            })
        switch attachments.count {
        case 1:
            Attachment(id: attachments[0].id) { $liveElement.context.buildChildren(of: attachments[0].element) }
        case 2:
            Attachment(id: attachments[0].id) { $liveElement.context.buildChildren(of: attachments[0].element) }
            Attachment(id: attachments[1].id) { $liveElement.context.buildChildren(of: attachments[1].element) }
        case 3:
            Attachment(id: attachments[0].id) { $liveElement.context.buildChildren(of: attachments[0].element) }
            Attachment(id: attachments[1].id) { $liveElement.context.buildChildren(of: attachments[1].element) }
            Attachment(id: attachments[2].id) { $liveElement.context.buildChildren(of: attachments[2].element) }
        default:
            EmptyAttachmentContent()
        }
    }
    #endif
    
    var body: some View {
        Group {
            #if os(visionOS)
            RealityView { content, attachments in
                make(content: &content, attachments: attachments)
            } update: { content, attachments in
                update(content: &content)
            } attachments: {
                attachments
            }
            #else
            RealityView { content in
                make(content: &content, attachments: Optional<Never>.none)
            } update: { content in
                update(content: &content)
            }
            #endif
        }
        .onReceive($element) { id in
            self.updateStorage.updates.insert(id)
        }
        .gesture(
            SpatialTapGesture()
                .targetedToEntity(where: .has(PhoenixClickEventComponent.self))
                .onEnded { value in
                    let event = value.entity.components[PhoenixClickEventComponent.self]!.event
                    let element = value.entity.components[ElementNodeComponent.self]!.element
                    
                    let prefix = "phx-value-"
                    var payload: [String:Any] = element.attributes
                        .filter { $0.name.namespace == nil && $0.name.name.starts(with: prefix) }
                        .reduce(into: [:]) { partialResult, attr in
                            // TODO: for nil attribute values, what value should this use?
                            partialResult[String(attr.name.name.dropFirst(prefix.count))] = attr.value
                        }
                    
                    #if os(visionOS)
                    let tapLocation = value.convert(value.location3D, from: .local, to: .scene)
                    #else
                    let tapLocation = value.hitTest(point: value.location, in: .local).first?.position ?? value.entity.position
                    #endif
                    
                    payload["_location"] = [tapLocation.x, tapLocation.y, tapLocation.z]
                    
                    playClickSound()
                    
                    Task {
                        try await liveContext.coordinator.pushEvent(
                            type: "click",
                            event: event,
                            value: payload
                        )
                    }
                }
        )
    }
    
    #if os(visionOS)
    typealias _RealityViewContent = RealityViewContent
    #else
    typealias _RealityViewContent = RealityViewCameraContent
    #endif
    
    func make(content: inout _RealityViewContent, attachments: Any) {
        #if os(iOS) || os(macOS)
        content.camera = self.camera.value
        #endif

        self.subscriptions = [
            content.subscribe(to: CollisionEvents.Began.self, componentType: PhysicsBodyChangeEventComponent.self) { collision in
                for entity in [collision.entityA, collision.entityB] {
                    guard let event = entity.components[PhysicsBodyChangeEventComponent.self]?.event
                    else { continue }
                    
                    let payload: [String:Any] = [
                        "event": "began",
                        "position": [collision.position.x, collision.position.y, collision.position.z],
                        "impulse": collision.impulse,
                        "impulseDirection": [collision.impulseDirection.x, collision.impulseDirection.y, collision.impulseDirection.z],
                        "penetrationDistance": collision.penetrationDistance,
                        "entityA": collision.entityA.components[ElementNodeComponent.self]?.element.attributeValue(for: "id") as Any,
                        "entityB": collision.entityB.components[ElementNodeComponent.self]?.element.attributeValue(for: "id") as Any
                    ]
                    
                    Task {
                        try await liveContext.coordinator.pushEvent(
                            type: "click",
                            event: event,
                            value: payload
                        )
                    }
                }
            },
            content.subscribe(to: CollisionEvents.Ended.self, componentType: PhysicsBodyChangeEventComponent.self) { collision in
                for entity in [collision.entityA, collision.entityB] {
                    guard let event = entity.components[PhysicsBodyChangeEventComponent.self]?.event
                    else { continue }
                    
                    let payload: [String:Any] = [
                        "event": "ended",
                        "entityA": collision.entityA.components[ElementNodeComponent.self]?.element.attributeValue(for: "id") as Any,
                        "entityB": collision.entityB.components[ElementNodeComponent.self]?.element.attributeValue(for: "id") as Any
                    ]
                    
                    Task {
                        try await liveContext.coordinator.pushEvent(
                            type: "click",
                            event: event,
                            value: payload
                        )
                    }
                }
            }
        ]

        let updateContext = Entity()
        #if os(visionOS)
        updateContext.components.set(UpdateContextComponent<Root, Entities, Components>(storage: self.updateStorage, document: context.document, context: context, attachments: attachments as! RealityViewAttachments))
        #else
        updateContext.components.set(UpdateContextComponent<Root, Entities, Components>(storage: self.updateStorage, document: context.document, context: context))
        #endif
        content.add(updateContext)
        do {
            for entity in try EntityContentBuilder<Entities, Components>.buildChildren(of: element, in: context) {
                content.add(entity)
            }
        } catch {
            logger.error("Entities failed to build with: \(error)")
        }
    }
    
    func update(content: inout _RealityViewContent) {
        if self.updateStorage.updates.contains(self.$liveElement.element.id) {
            guard let element: ElementNode = self.context.document?[self.$liveElement.element.id].asElement()
            else { return }
            
            var previousChildren = Array(content.entities.filter({ !$0.components.has(UpdateContextComponent<Root, Entities, Components>.self) }))
            for childNode in element.children() {
                guard let childElement = childNode.asElement()
                else { continue }
                if let existingChildIndex = content.entities.firstIndex(where: { $0.components[ElementNodeComponent.self]?.element.id == childElement.id }) {
                    // update children that existed previously
                    do {
                        let existingChild = content.entities[existingChildIndex]
                        try existingChild.applyAttributes(from: childElement, in: context)
                        try existingChild.applyChildren(from: childElement, in: context)
                        previousChildren.removeAll(where: { $0.components[ElementNodeComponent.self]?.element.id == childElement.id })
                    } catch {
                        logger.error("Entity \(childElement.tag) failed to update with: \(error)")
                    }
                } else if !childElement.attributes.contains(where: { $0.name.namespace == nil && $0.name.name == "template" }) {
                    // add new children
                    do {
                        for child in try EntityContentBuilder<Entities, Components>.build([childNode], in: context) {
                            content.add(child)
                        }
                    } catch {
                        logger.error("Entities failed to build with: \(error)")
                    }
                }
            }
            // remove children that are no longer in the document
            for child in previousChildren where !child.components.has(AsyncEntityComponent.self) {
                content.remove(child)
            }
        }
        content.cameraTarget = self.updateStorage.cameraTarget
    }
}

struct ElementNodeComponent: Component {
    var element: ElementNode
    var previousTransform: Transform?
    var moveAnimation: AnimationPlaybackController?
    var animation: (name: String, controller: AnimationPlaybackController)?
    var componentTypes: [any Component.Type] = []
}

struct PhoenixClickEventComponent: Component {
    let event: String
}

struct PhysicsBodyChangeEventComponent: Component {
    let event: String
}

struct CameraTargetComponent: Component {}
