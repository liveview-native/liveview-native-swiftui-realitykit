import LiveViewNative
import LiveViewNativeStylesheet
import SwiftUI

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
