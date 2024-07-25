//
//  AnchoringComponent.swift
//
//
//  Created by Carson Katri on 6/6/24.
//

import LiveViewNative
import LiveViewNativeCore
import RealityKit

extension AnchoringComponent {
    init(from element: ElementNode, in context: _ComponentContentBuilder<some ComponentRegistry>.Context<some RootRegistry>) throws {
        let target = try element.attributeValue(AnchoringComponent.Target.self, for: "target")
        if let trackingMode = try? element.attributeValue(AnchoringComponent.TrackingMode.self, for: "trackingMode") {
            self.init(target, trackingMode: trackingMode)
        } else {
            self.init(target)
        }
    }
}

extension AnchoringComponent.TrackingMode: AttributeDecodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let value = attribute?.value
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        switch value {
        case "continuous":
            self = .continuous
        case "once":
            self = .once
        default:
            throw AttributeDecodingError.badValue(Self.self)
        }
    }
}

extension AnchoringComponent.Target: AttributeDecodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let value = attribute?.value
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        switch value {
        case "hand":
            self = .hand(
                try element.attributeValue(Chirality.self, for: "chirality"),
                location: try element.attributeValue(HandLocation.self, for: "location")
            )
        case "head":
            self = .head
        case "image":
            self = .image(
                group: try element.attributeValue(String.self, for: "group"),
                name: try element.attributeValue(String.self, for: "name")
            )
        case "plane":
            self = .plane(
                try element.attributeValue(Alignment.self, for: "alignment"),
                classification: try element.attributeValue(Classification.self, for: "classification"),
                minimumBounds: try element.attributeValue(SIMD2<Float>.self, for: "minimumBounds")
            )
        default:
            throw AttributeDecodingError.badValue(Self.self)
        }
    }
}

extension AnchoringComponent.Target.Chirality: AttributeDecodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let value = attribute?.value
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        switch value {
        case "left":
            self = .left
        case "right":
            self = .right
        default:
            self = .either
        }
    }
}

extension AnchoringComponent.Target.HandLocation: AttributeDecodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let value = attribute?.value
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        switch value {
        case "aboveHand":
            self = .aboveHand
        case "indexFingerTip":
            self = .indexFingerTip
        case "palm":
            self = .palm
        case "thumbTip":
            self = .thumbTip
        case "wrist":
            self = .wrist
        default:
            self = .aboveHand
        }
    }
}

extension AnchoringComponent.Target.Alignment: AttributeDecodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let value = attribute?.value
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        switch value {
        case "horizontal":
            self = .horizontal
        case "vertical":
            self = .vertical
        default:
            self = .any
        }
    }
}

extension AnchoringComponent.Target.Classification: AttributeDecodable {
    public init(from attribute: Attribute?, on element: ElementNode) throws {
        guard let value = attribute?.value
        else { throw AttributeDecodingError.missingAttribute(Self.self) }
        switch value {
        case "ceiling":
            self = .ceiling
        case "floor":
            self = .floor
        case "seat":
            self = .seat
        case "table":
            self = .table
        case "wall":
            self = .wall
        default:
            self = .any
        }
    }
}
