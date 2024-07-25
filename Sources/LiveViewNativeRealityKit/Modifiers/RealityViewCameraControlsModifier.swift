//
//  RealityViewCameraControlsModifier.swift
//  
//
//  Created by Carson.Katri on 7/25/24.
//

#if os(iOS) || os(macOS)
import LiveViewNative
import LiveViewNativeStylesheet
import SwiftUI
import RealityKit

@ParseableExpression
struct _RealityViewCameraControlsModifier: ViewModifier {
    public static var name: String { "realityViewCameraControls" }
    
    let controls: CameraControls
    
    init(_ controls: CameraControls) {
        self.controls = controls
    }
    
    func body(content: Content) -> some View {
        content.realityViewCameraControls(controls)
    }
}

extension CameraControls: ParseableModifierValue {
    public static func parser(in context: ParseableModifierContext) -> some Parser<Substring.UTF8View, Self> {
        ImplicitStaticMember([
            "dolly": .dolly,
            "none": .none,
            "orbit": .orbit,
            "pan": .pan,
            "tilt": .tilt,
        ])
    }
}
#endif
