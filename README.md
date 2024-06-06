# liveview-native-swiftui-realitykit

## About

`liveview-native-swiftui-realitykit` is an add-on library for [LiveView Native](https://github.com/liveview-native/live_view_native). It adds [RealityKit](https://developer.apple.com/documentation/realitykit) support for rendering 3D content on visionOS.

## Installation

1. Add this library as a package to your LiveView Native application's Xcode project
    * In Xcode, select *File* → *Add Packages...*
    * Enter the package URL `https://github.com/liveview-native/liveview-native-swiftui-realitykit`
    * Select *Add Package*

## Usage

Import the library, then add the `.realityKit` addons list on your `#LiveView`.

```swift
import SwiftUI
import LiveViewNative
import LiveViewNativeRealityKit // 1. Import the add-on library.

struct ContentView: View {
    var body: some View {
        #LiveView(
            .localhost,
            addons: [.realityKit] // 2. Include the `.realityKit` addon.
        )
    }
}
```

To render 3D content within a SwiftUI HEEx template, use the `RealityView` element.
Include 3D entities within the `RealityView` to display models, fetch hand tracking data, and more:

```heex
<RealityView>
  <ModelEntity
    transform:translation={[0, 0.15, 0]}
  >
    <Box
      template="mesh"
      size={0.3}
    />
    
    <SimpleMaterial
      template="materials"
      color="system-red"
    />
    
    <Group template="components">
      <OpacityComponent opacity={0.75} />
      <GroundingShadowComponent castsShadow />
      <AnchoringComponent
        target="plane"
        alignment="horizontal"
        classification="table"
        minimumBounds:x={0.5}
        minimumBounds:y={0.5}
      />
    </Group>
  </ModelEntity>
</RealityView>
```

This will create a transparent red cube with the `<ModelEntity>` element, and place it on a table in the user's view with the `<AnchoringComponent>`.

![LiveView Native RealityKit screenshot](./docs/example.png)
