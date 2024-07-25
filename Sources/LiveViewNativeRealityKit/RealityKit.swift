import LiveViewNative
import LiveViewNativeStylesheet
import SwiftUI
import RealityKit

public struct CustomizableRealityKitRegistry<
    Entities: EntityRegistry,
    Components: ComponentRegistry
> {
    public struct Registry<Root: RootRegistry>: CustomRegistry {
        public enum TagName: String {
            case realityView = "RealityView"
        }
        
        public static func lookup(_ name: TagName, element: ElementNode) -> some View {
            switch name {
            case .realityView:
                _RealityView<Root, Entities, _ComponentContentBuilder<Components>>()
            }
        }
        
        #if os(iOS) || os(macOS)
        public static func parseModifier(
            _ input: inout Substring.UTF8View,
            in context: ParseableModifierContext
        ) throws -> CustomModifier {
            try CustomModifier.parser(in: context).parse(&input)
        }
        
        public struct CustomModifier: ViewModifier, ParseableModifierValue {
            enum Storage {
                case realityViewCameraControls(_RealityViewCameraControlsModifier)
            }
            
            let storage: Storage
            
            public static func parser(in context: ParseableModifierContext) -> some Parser<Substring.UTF8View, Self> {
                CustomModifierGroupParser(output: Self.self) {
                    _RealityViewCameraControlsModifier.parser(in: context).map({ Self(storage: .realityViewCameraControls($0)) })
                }
            }
            
            public func body(content: Content) -> some View {
                switch storage {
                case .realityViewCameraControls(let modifier):
                    content.modifier(modifier)
                }
            }
        }
        #endif
    }
}

public extension Addons {
    typealias RealityKit<Root: RootRegistry> = CustomizableRealityKitRegistry<
        EmptyEntityRegistry,
        EmptyComponentRegistry
    >.Registry<Root>
    
    static var realityKit: LiveViewNative.Addons {
        fatalError("Registered addons cannot be accessed outside of the #LiveView macro.")
    }
}
