import LiveViewNative
import LiveViewNativeStylesheet
import SwiftUI

public extension Addons {
    @Addon
    struct RealityKit<Root: RootRegistry> {
        public enum TagName: String {
            case realityView = "RealityView"
        }
        
        public static func lookup(_ name: TagName, element: ElementNode) -> some View {
            switch name {
            case .realityView:
                _RealityView<Root>()
            }
        }
    }
}
