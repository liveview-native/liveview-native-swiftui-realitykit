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
import AudioToolbox

final class ElementNodeUpdateSystem<Root: RootRegistry>: System {
    let updateContextQuery = EntityQuery(where: .has(UpdateContextComponent<Root>.self))
    let elementNodeQuery = EntityQuery(where: .has(ElementNodeComponent.self))
    
    init(scene: RealityKit.Scene) {}
    
    func update(context: SceneUpdateContext) {
        var updateContextEntities = context.entities(matching: updateContextQuery, updatingSystemWhen: .rendering).makeIterator()
        guard let updateContextEntity = updateContextEntities.next(),
              var updateContext = updateContextEntity.components[UpdateContextComponent<Root>.self],
              !updateContext.updates.isEmpty,
              let document = updateContext.document
        else { return }
        
        let elementNodes = context.entities(matching: elementNodeQuery, updatingSystemWhen: .rendering)
        // apply updates
        for updateId in updateContext.updates {
            guard let updatedEntity = elementNodes.first(where: { $0.components[ElementNodeComponent.self]?.element.id == updateId }),
                  let element = document[updateId].asElement()
            else { continue }
            print("Updating \(updateId) (\(element.tag))")
            
            try! updatedEntity.applyAttributes(from: element, in: updateContext.context)
            try! updatedEntity.applyChildren(from: element, in: updateContext.context)
        }
        
        // clear pending updates
        updateContext.updates = []
        updateContextEntity.components.set(updateContext)
    }
}

struct UpdateContextComponent<Root: RootRegistry>: Component {
    var storage: Storage
    var updates: Set<NodeRef> {
        get { storage.updates }
        set { storage.updates = newValue }
    }
    let document: Document?
    let context: RealityViewContentBuilder.Context<Root>
    
    final class Storage {
        var updates: Set<NodeRef> = []
    }
}

@LiveElement
struct _RealityView<Root: RootRegistry>: View {
    @LiveElementIgnored
    @ObservedElement(observeChildren: true)
    private var element
    
    @LiveElementIgnored
    @LiveContext<Root>
    private var liveContext
    
    @LiveElementIgnored
    @ContentBuilderContext<Root, RealityViewContentBuilder>
    private var context
    
    private var audibleClicks: Bool = false
    
    @LiveElementIgnored
    @State
    private var updateStorage = UpdateContextComponent<Root>.Storage()
    
    init() {
        ElementNodeComponent.registerComponent()
        PhoenixClickEventComponent.registerComponent()
        ElementNodeUpdateSystem<Root>.registerSystem()
    }
    
    private func playClickSound() {
        guard audibleClicks
        else { return }
        let clickSoundURL = URL(filePath: "/System/Library/Audio/UISounds/key_press_click_visionOS.caf")
        var clickSoundID: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(clickSoundURL as CFURL, &clickSoundID)
        AudioServicesPlaySystemSound(clickSoundID)
    }
    
    var body: some View {
        RealityView { content in
            let updateContext = Entity()
            updateContext.components.set(UpdateContextComponent<Root>(storage: self.updateStorage, document: context.document, context: context))
            content.add(updateContext)
            for entity in try! RealityViewContentBuilder.buildChildren(of: element, in: context) {
                content.add(entity)
            }
        }/* update: {
            let query = EntityQuery(where: .has(ElementNodeComponent.self))
            var elementEntities = content.entities.filter({ $0.components.has(ElementNodeComponent.self) })
            for child in element.children().filter({ !$0.attributes.contains(where: { $0.name.name == "template" }) }) {
                guard let elementNode = child.asElement()
                else { continue }
                if let existingEntityIndex = elementEntities.firstIndex(where: { $0.components[ElementNodeComponent.self]!.element.id == child.id }) {
                    // update entity
                    let existingEntity = elementEntities.remove(at: existingEntityIndex)
                    try? existingEntity.applyAttributes(from: elementNode, in: context)
                    try? existingEntity.applyChildren(from: elementNode, in: context)
                } else {
                    // new entity
                    let newEntities = try! RealityViewContentBuilder.build([child], in: context)
                    for entity in newEntities {
                        content.add(entity)
                    }
                }
            }
            for removedEntity in elementEntities {
                content.remove(removedEntity)
            }
        }*/
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
                    
                    let tapLocation = value.convert(value.location3D, from: .local, to: .scene)
                    
                    payload["_location"] = [
                        "x": tapLocation.x,
                        "y": tapLocation.y,
                        "z": tapLocation.z
                    ]
                    
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
