# Fusion

[![Fusion](logo.png)]()

![Swift](https://img.shields.io/badge/Swift-5-red.svg)
[![Platforms](https://img.shields.io/endpoint?url=https://swiftpackageindex.com/api/packages/db-in/Fusion/badge?type=platforms)](https://github.com/db-in/fusion)
[![CocoaPods](https://img.shields.io/cocoapods/v/Fusion.svg)](https://cocoapods.org/pods/Fusion)
[![iOS Pipeline](https://github.com/db-in/fusion/actions/workflows/ios.yml/badge.svg)](https://github.com/db-in/fusion/actions/workflows/ios.yml)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**The production toolkit Apple apps actually ship with.**

Fusion is a single Swift framework for iOS, macOS, tvOS, and watchOS. It gives you typed storage with live bindings, an image pipeline that respects memory, REST that stays Codable end-to-end, tween animations that survive backgrounding, and UI helpers that remove the glue code every app rewrites.

It is not a kitchen-sink SDK. Every API exists because a real product needed it, and the hot paths are measured in nanoseconds.

---

## Why it exists

Building an Apple app means solving the same problems again: persist state safely, refresh the UI when it changes, load images without melting the heap, animate without dropping frames, talk to an API without boilerplate.

Fusion is that layer, already battle-tested:

| What you need | What Fusion gives you |
|---|---|
| Persist app state across launches, widgets, and processes | Typed `DataManageable` over memory, files, UserDefaults, or Keychain — with optional async writes and `flushPendingWrites()` when another process must read |
| React when a value changes | Bindings via closure, Combine, or `AsyncStream` — same key, same semantics |
| Show remote images without thrashing memory | `ImagePipeline` with coalesced downloads, URL cache, and thumbnail decode |
| Animate UIKit properties | `Tween` with easing, repetition, and background-safe timing |
| Call a JSON API | `RESTBuilder` + standard date codecs + optional authenticator |
| Ship across Apple platforms | One library: iOS 17 · macOS 14 · tvOS 17 · watchOS 10 |

---

## Performance that is proven, not claimed

Fusion ships a one-tap benchmark suite. Numbers below are from the committed baseline on Apple M4 Pro (Release).

| Hot path | Cost |
|---|---:|
| `ThreadSafe` read / mutate | **6–7 ns** |
| Silent logger call | **5 ns** |
| Image memory-cache hit | **~100 ns** |
| Idle `flushPendingWrites()` | **~134 ns** |
| `InMemoryCache.getOrSet` | **~74 ns** |
| Number → localized string | **~670 ns** |
| File storage write | **~3 µs** |
| Present-key cold read from disk | **~17 µs** |
| Downsampled 1024→128 image decode | **~2.8 ms**, ~⅓ the peak memory of a full decode |

Run it yourself:

- Double-click **`Run Benchmarks.command`**, or
- In Xcode: scheme **Benchmarks** → **⌘B**

Results open in [`Benchmarks/report.html`](Benchmarks/report.html) (**Baseline · Best · Worst · Current**). History: [`Benchmarks/HISTORY.md`](Benchmarks/HISTORY.md). How to run: [Benchmarks/README.md](Benchmarks/README.md).

---

## What’s inside

### Storage & reactivity

Define a store once. Read and write with types. Bind anywhere.

```swift
import Fusion

enum AppStorage: DataManageable {
    typealias Storage = FileManager   // or StateStorage, UserDefaults, Keychain

    enum Key: String, CaseIterable {
        case session
        case profile
    }

    @Stored(AppStorage.self, key: .session)
    static var session: Session?
}

AppStorage.session = Session(token: "…")
let token = AppStorage.session?.token

let observer = NSObject()
AppStorage.bind(key: .session, cancellable: observer) { (session: Session?) in
    // fired on every write and removal
}

for await session in AppStorage.stream(key: .session) as AsyncStream<Session?> {
    // same source of truth, async form
}

AppStorage.flushPendingWrites()   // before a widget / extension reads the same files
```

Keychain stays a one-liner for secrets:

```swift
let keychain = Keychain()
keychain["refreshToken"] = Data("…".utf8)
let data = keychain["refreshToken"]
```

### Image loading

Coalesced network requests, memory cache, disk via `URLCache.appGroup`, and downsampling so a 4K asset never becomes a 4K bitmap in RAM.

```swift
// UIKit
UIImage.loadOrDownload(url: url) { image, fromCache in
    imageView.image = image
}

// SwiftUI — cache-aware async image
AsyncImageCached(url) { image in
    image.resizable().scaledToFill()
} placeholder: {
    ProgressView()
}

UIImage.flushCache()   // memory + URL cache, cleanly
```

### Networking

Typed requests, shared JSON date strategy, async or completion-based.

```swift
let users = RESTBuilder<[User]>(url: "https://api.example.com/users")
let (list, _) = try await users.execute()

let create = RESTBuilder<User>(url: "https://api.example.com/users", method: .post)
create.execute(body: NewUser(name: "Ada")) { result in
    // Result<User, Error>
}
```

### Animation

Property tweens with real easing curves, mirrors, and background-safe clocks.

```swift
Tween(
    card,
    duration: 0.45,
    options: .init(ease: .smoothOut),
    toValues: [
        \.alpha: 1,
        \.center.y: 240
    ]
)
```

### UI & flow

Navigation without the ceremony: storyboard or factory-based flows, push/modal, hooks for login and deep links.

```swift
let login = UserFlow("Login", bundle: .main)
login.startAsModal(withNavigation: true)

let profile = UserFlow { _ in ProfileViewController() }
profile.startAsPush()
```

Also included: color/font utilities, text styling, haptics, scroll helpers, SwiftUI↔UIKit bridges, localization with preferred-locale caches, encryption helpers, and a structured logger.

---

## Install

**Swift Package Manager** (recommended)

```swift
.package(url: "https://github.com/db-in/fusion.git", from: "2.1.1")
```

In Xcode: *File → Add Package Dependencies…* → `https://github.com/db-in/fusion.git`

```swift
import Fusion
```

**CocoaPods**

```ruby
pod 'Fusion'           # everything
pod 'Fusion/Core'      # storage, networking, utilities
pod 'Fusion/UI'        # UI + Core
```

**Carthage**

```
github "db-in/fusion" ~> 2.1.1
```

### Requirements

| | |
|---|---|
| iOS | 17.0+ |
| macOS | 14.0+ |
| tvOS | 17.0+ |
| watchOS | 10.0+ |
| Swift | 5.0+ |
| Xcode | 15.0+ |

---

## Documentation & samples

- [API documentation](https://db-in.github.io/fusion/)
- Sample apps in this repo for iOS, macOS, tvOS, watchOS, and visionOS
- [Benchmarks](Benchmarks/README.md) — methodology, history, and live HTML report

---

## Contributing

Issues and pull requests are welcome. If you touch a hot path, run the **Benchmarks** scheme and keep `Benchmarks/report.html` honest.

## License

MIT. See [LICENSE](LICENSE).

## Author

**Diney Bomfim** — [@dineybomfim](https://github.com/dineybomfim)
