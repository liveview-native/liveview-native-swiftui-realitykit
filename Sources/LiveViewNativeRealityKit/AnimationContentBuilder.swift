//
//  AnimationContentBuilder.swift
//
//
//  Created by Carson Katri on 5/30/24.
//

import RealityKit
import Foundation
import LiveViewNative
import LiveViewNativeCore

struct AnimationContentBuilder: ContentBuilder {
    enum TagName: String {
        case animationGroup = "AnimationGroup"
        case animationResource = "AnimationResource"
        case fromToByAnimation = "FromToByAnimation"
        case orbitAnimation = "OrbitAnimation"
    }
    
    typealias Content = [any AnimationDefinition]
    
    static func lookup<R: RootRegistry>(_ tag: TagName, element: ElementNode, context: Context<R>) -> Content {
        let definition: any AnimationDefinition = switch tag {
        case .animationGroup:
            try! AnimationGroup(from: element, in: context)
        case .animationResource:
            AnimationResourceReference(from: element, in: context)
        case .fromToByAnimation:
            try! FromToByAnimation<Transform>(from: element, in: context)
        case .orbitAnimation:
            try! OrbitAnimation(from: element, in: context)
        }
        if element.attributeBoolean(for: "repeatingForever") {
            return [definition.repeatingForever()]
        } else if let count = try? element.attributeValue(Double.self, for: .init(namespace: "repeated", name: "count")) {
            return [definition.repeated(count: count)]
        } else {
            return [definition]
        }
    }
    
    static func empty() -> [any AnimationDefinition] {
        []
    }
    
    static func reduce(accumulated: [any AnimationDefinition], next: [any AnimationDefinition]) -> [any AnimationDefinition] {
        accumulated + next
    }
}

extension AnimationGroup {
    init(from element: ElementNode, in context: AnimationContentBuilder.Context<some RootRegistry>) throws {
        self.init(
            group: try AnimationContentBuilder.buildChildren(of: element, in: context),
            name: element.attributeValue(for: "name") ?? "",
            repeatMode: (try? element.attributeValue(AnimationRepeatMode.self, for: "repeatMode")) ?? .none,
            fillMode: (try? element.attributeValue(AnimationFillMode.self, for: "fillMode")) ?? [],
            trimStart: try? element.attributeValue(Double.self, for: "trimStart"),
            trimEnd: try? element.attributeValue(Double.self, for: "trimEnd"),
            trimDuration: try? element.attributeValue(Double.self, for: "trimDuration"),
            offset: (try? element.attributeValue(Double.self, for: "offset")) ?? 0,
            delay: (try? element.attributeValue(Double.self, for: "delay")) ?? 0,
            speed: (try? element.attributeValue(Float.self, for: "speed")) ?? 1
        )
    }
}

extension FromToByAnimation where Value == Transform {
    init(from element: ElementNode, in context: AnimationContentBuilder.Context<some RootRegistry>) throws {
        self.init(
            name: element.attributeValue(for: "name") ?? "",
            from: try? element.transform(for: "from"),
            to: try? element.transform(for: "to"),
            by: try? element.transform(for: "by"),
            duration: (try? element.attributeValue(Double.self, for: "duration")) ?? 1,
            timing: (try? element.attributeValue(AnimationTimingFunction.self, for: "timing")) ?? .linear,
            isAdditive: element.attributeBoolean(for: "isAdditive"),
            bindTarget: try? element.attributeValue(BindTarget.self, for: "bindTarget"),
            blendLayer: Int32((try? element.attributeValue(Int.self, for: "blendLayer")) ?? 0),
            repeatMode: (try? element.attributeValue(AnimationRepeatMode.self, for: "repeatMode")) ?? .none,
            fillMode: (try? element.attributeValue(AnimationFillMode.self, for: "fillMode")) ?? [],
            trimStart: try? element.attributeValue(Double.self, for: "trimStart"),
            trimEnd: try? element.attributeValue(Double.self, for: "trimEnd"),
            trimDuration: try? element.attributeValue(Double.self, for: "trimDuration"),
            offset: (try? element.attributeValue(Double.self, for: "offset")) ?? 0,
            delay: (try? element.attributeValue(Double.self, for: "delay")) ?? 0,
            speed: (try? element.attributeValue(Float.self, for: "speed")) ?? 1
        )
    }
}

extension OrbitAnimation {
    init(from element: ElementNode, in context: AnimationContentBuilder.Context<some RootRegistry>) throws {
        self.init(
            name: element.attributeValue(for: "name") ?? "",
            duration: (try? element.attributeValue(Double.self, for: "duration")) ?? 1,
            axis: (try? element.simd3(for: "exis")) ?? .init(x: 0.0, y: 1.0, z: 0.0),
            startTransform: (try? element.transform(for: "startTransform")) ?? .identity,
            spinClockwise: element.attributeBoolean(for: "spinClockwise"),
            orientToPath: element.attributeBoolean(for: "orientToPath"),
            rotationCount: (try? element.attributeValue(Float.self, for: "rotationCount")) ?? 1,
            bindTarget: try? element.attributeValue(BindTarget.self, for: "bindTarget"),
            blendLayer: Int32((try? element.attributeValue(Int.self, for: "blendLayer")) ?? 0),
            repeatMode: (try? element.attributeValue(AnimationRepeatMode.self, for: "repeatMode")) ?? .none,
            fillMode: (try? element.attributeValue(AnimationFillMode.self, for: "fillMode")) ?? [],
            isAdditive: element.attributeBoolean(for: "isAdditive"),
            trimStart: try? element.attributeValue(Double.self, for: "trimStart"),
            trimEnd: try? element.attributeValue(Double.self, for: "trimEnd"),
            trimDuration: try? element.attributeValue(Double.self, for: "trimDuration"),
            offset: (try? element.attributeValue(Double.self, for: "offset")) ?? 0,
            delay: (try? element.attributeValue(Double.self, for: "delay")) ?? 0,
            speed: (try? element.attributeValue(Float.self, for: "speed")) ?? 1
        )
    }
}

extension AnimationRepeatMode: AttributeDecodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let value = attribute?.value
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        switch value {
        case "repeat":
            self = .`repeat`
        case "cumulative":
            self = .cumulative
        case "autoReverse":
            self = .autoReverse
        case "none":
            self = .none
        default:
            throw AttributeDecodingError.badValue(Self.self)
        }
    }
}

extension AnimationFillMode: AttributeDecodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let value = attribute?.value
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        switch value {
        case "backwards":
            self = .backwards
        case "forwards":
            self = .forwards
        case "both":
            self = .both
        case "none":
            self = .none
        default:
            throw AttributeDecodingError.badValue(Self.self)
        }
    }
}

extension AnimationTimingFunction: AttributeDecodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let value = attribute?.value
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        switch value {
        case "default":
            self = .default
        case "easeIn":
            self = .easeIn
        case "easeOut":
            self = .easeOut
        case "easeInOut":
            self = .easeInOut
        case "linear":
            self = .linear
        default:
            throw AttributeDecodingError.badValue(Self.self)
        }
    }
}

extension BindTarget: AttributeDecodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let value = attribute?.value
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        switch value {
        case "jointTransforms":
            self = .jointTransforms
        case "opacity":
            self = .opacity
        case "transform":
            self = .transform
        default:
            throw AttributeDecodingError.badValue(Self.self)
        }
    }
}

struct AnimationResourceReference: AnimationDefinition {
    var name: String
    
    // only `name` is used
    var blendLayer: Int32 = 0
    
    var fillMode: AnimationFillMode = .none
    
    var bindTarget: BindTarget = .transform
    
    var trimStart: TimeInterval?
    
    var trimEnd: TimeInterval?
    
    var trimDuration: TimeInterval?
    
    var offset: TimeInterval = 0
    
    var delay: TimeInterval = 0
    
    var speed: Float = 1
    
    var repeatMode: AnimationRepeatMode = .none
    
    var duration: TimeInterval = 0
    
    init(from element: ElementNode, in context: AnimationContentBuilder.Context<some RootRegistry>) {
        self.name = element.attributeValue(for: "name")!
        self.repeatMode = (try? element.attributeValue(AnimationRepeatMode.self, for: "repeatMode")) ?? .none
        self.fillMode = (try? element.attributeValue(AnimationFillMode.self, for: "fillMode")) ?? []
        self.trimStart = try? element.attributeValue(Double.self, for: "trimStart")
        self.trimEnd = try? element.attributeValue(Double.self, for: "trimEnd")
        self.trimDuration = try? element.attributeValue(Double.self, for: "trimDuration")
        self.offset = (try? element.attributeValue(Double.self, for: "offset")) ?? 0
        self.delay = (try? element.attributeValue(Double.self, for: "delay")) ?? 0
        self.speed = (try? element.attributeValue(Float.self, for: "speed")) ?? 1
    }
}

extension AnimationDefinition {
    func resolveAnimationResources(with availableAnimations: [AnimationResource]) -> any AnimationDefinition {
        if let reference = self as? AnimationResourceReference {
            if let animation = availableAnimations.first(where: { $0.name == reference.name }) {
                return AnimationGroup(
                    group: [animation.definition],
                    name: reference.name,
                    repeatMode: reference.repeatMode,
                    fillMode: reference.fillMode,
                    trimStart: reference.trimStart,
                    trimEnd: reference.trimEnd,
                    trimDuration: reference.trimDuration,
                    offset: reference.offset,
                    delay: reference.delay,
                    speed: reference.speed
                )
            } else {
                return AnimationGroup(group: [])
            }
        } else if var group = self as? AnimationGroup {
            group.group = group.group.map({ $0.resolveAnimationResources(with: availableAnimations) })
            return group
        } else {
            return self
        }
    }
}
