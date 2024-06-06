//
//  SceneReconstruction.swift
//
//
//  Created by Carson Katri on 5/23/24.
//

import LiveViewNative
import ARKit
import RealityKit
import OSLog

private let logger = Logger(subsystem: "LiveViewNativeRealityKit", category: "SceneReconstructionEntity")

class SceneReconstructionEntity: Entity {
    let session = ARKitSession()
    let provider = SceneReconstructionProvider()
    
    var meshEntities: [UUID:ModelEntity] = [:]
    let materials: [any Material]
    let allowedInputTypes: InputTargetComponent.InputType
    
    required init() {
        self.materials = []
        self.allowedInputTypes = .all
        super.init()
        self.start()
    }
    
    init<E: EntityRegistry, C: ComponentRegistry>(
        from element: ElementNode,
        in context: EntityContentBuilder<E, C>.Context<some RootRegistry>
    ) throws {
        self.materials = try EntityContentBuilder<E, C>.buildChildren(of: element, forTemplate: "materials", with: MaterialContentBuilder.self, in: context)
        self.allowedInputTypes = (try? element.attributeValue(InputTargetComponent.InputType.self, for: "allowedInputTypes")) ?? .all
        super.init()
        self.start()
    }
    
    func start() {
        Task { [weak self] in
            guard let self else { return }
            if SceneReconstructionProvider.isSupported {
                try await session.run([provider])
            } else {
                logger.warning("Scene reconstruction is not available on this device")
            }
        }
        Task { [weak self] in
            guard let self else { return }
            for await update in provider.anchorUpdates {
                let meshAnchor = update.anchor
                
                guard let shape = try? await ShapeResource.generateStaticMesh(from: meshAnchor) else { continue }
                let mesh: MeshResource?
                
                if let material = self.materials.first {
                    var descriptor = MeshDescriptor()
                    let posValues = meshAnchor.geometry.vertices.asSIMD3(ofType: Float.self)
                    descriptor.positions = .init(posValues)
                    let normalValues = meshAnchor.geometry.normals.asSIMD3(ofType: Float.self)
                    descriptor.normals = .init(normalValues)
                    descriptor.primitives = .polygons(
                        (0..<meshAnchor.geometry.faces.count).map { _ in UInt8(3) },
                        (0..<meshAnchor.geometry.faces.count * 3).map {
                            meshAnchor.geometry.faces.buffer.contents()
                                .advanced(by: $0 * meshAnchor.geometry.faces.bytesPerIndex)
                                .assumingMemoryBound(to: UInt32.self).pointee
                        }
                    )
                    mesh = try? await MeshResource(from: [descriptor])
                } else {
                    mesh = nil
                }
                
                switch update.event {
                case .added:
                    let entity: ModelEntity
                    if let material = self.materials.first,
                       let mesh
                    {
                        entity = ModelEntity(mesh: mesh, materials: [material])
                    } else {
                        entity = ModelEntity()
                    }
                    entity.transform = Transform(matrix: meshAnchor.originFromAnchorTransform)
                    entity.collision = CollisionComponent(shapes: [shape], isStatic: true)
                    entity.components.set(InputTargetComponent(allowedInputTypes: allowedInputTypes))
                    if self.components.has(PhoenixClickEventComponent.self) {
                        entity.components.set(self.components[PhoenixClickEventComponent.self]!)
                        entity.components.set(self.components[ElementNodeComponent.self]!)
                    }
                    
                    entity.physicsBody = PhysicsBodyComponent(mode: .static)
                    
                    meshEntities[meshAnchor.id] = entity
                    addChild(entity)
                case .updated:
                    guard let entity = meshEntities[meshAnchor.id] else { continue }
                    entity.transform = Transform(matrix: meshAnchor.originFromAnchorTransform)
                    entity.collision?.shapes = [shape]
                    if let mesh {
                        entity.model?.mesh = mesh
                    }
                    entity.components.set(InputTargetComponent(allowedInputTypes: allowedInputTypes))
                case .removed:
                    meshEntities[meshAnchor.id]?.removeFromParent()
                    meshEntities.removeValue(forKey: meshAnchor.id)
                }
            }
        }
    }
    
    deinit {
        session.stop()
    }
}

extension GeometrySource {
    @MainActor func asArray<T>(ofType: T.Type) -> [T] {
        assert(MemoryLayout<T>.stride == stride, "Invalid stride \(MemoryLayout<T>.stride); expected \(stride)")
        return (0..<self.count).map {
            buffer.contents().advanced(by: offset + stride * Int($0)).assumingMemoryBound(to: T.self).pointee
        }
    }

    @MainActor func asSIMD3<T>(ofType: T.Type) -> [SIMD3<T>] {
        return asArray(ofType: (T, T, T).self).map { .init($0.0, $0.1, $0.2) }
    }
}
