# AudioManager

A simple package for programmatically getting and setting volume and muted/unmuted properties on the default macOS audio device.

```swift
let audioManager = AudioManager()
let state = try audioManager.getAudioState()
state.volume // 0.80575358867645264
state.muted  // false
let newState = AudioState(volume: 0.5, muted: false)
let updatedState = try audioManager.setAudioState(newState)
```

### Swift Package Manager.
```swift
.package(url: "https://github.com/Antman261/AudioManager.git", from: "0.1.5"),
```
