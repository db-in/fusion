# Fusion

[![Fusion](logo.png)]()

![Version](https://img.shields.io/badge/swift-5-red.svg)
[![Swift Package Manager Compatible](https://img.shields.io/endpoint?url=https://swiftpackageindex.com/api/packages/db-in/Fusion/badge?type=platforms)](https://github.com/apple/swift-package-manager)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/Fusion.svg)](https://img.shields.io/cocoapods/v/Fusion.svg)
[![Platform](https://img.shields.io/cocoapods/p/Fusion.svg)](https://github.com/db-in/fusion)
[![iOS Pipeline](https://github.com/db-in/fusion/actions/workflows/ios.yml/badge.svg)](https://github.com/db-in/fusion/actions/workflows/ios.yml)
[![codebeat badge](https://codebeat.co/badges/36b686b3-92d6-4b93-ac7c-37f959ed8f3b)](https://codebeat.co/projects/github-com-db-in-fusion-master)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

## Description

**Fusion** is a comprehensive Swift framework that provides essential utilities and tools for iOS, macOS, tvOS, and watchOS development. It offers a modular architecture with two main components: **FusionCore** for fundamental functionality and **FusionUI** for user interface enhancements.

## Features

### ⚙️ Core Module (FusionCore)

**Storage & Data Management**
- [x] **Keychain Integration** - Secure storage for sensitive data
- [x] **Multiple Storage Backends** - UserDefaults, FileManager, and in-memory storage
- [x] **Data Binding** - Reactive data management with automatic updates
- [x] **In-Memory Caching** - High-performance temporary data storage
- [x] **Thread-Safe Operations** - Concurrent access protection

**Networking & Communication**
- [x] **REST API Client** - Complete HTTP client with authentication
- [x] **Request/Response Handling** - Type-safe networking with Codable support
- [x] **Cookie Management** - HTTP cookie handling and persistence
- [x] **Encryption Utilities** - Data encryption and security helpers
- [x] **Request Logging** - Comprehensive network request logging

**Utilities & Helpers**
- [x] **Timer Control** - High-performance timer management with background handling
- [x] **Async Operations** - Advanced asynchronous operation management
- [x] **Text Processing** - Rich text manipulation and styling
- [x] **Mathematical Functions** - Extended math utilities and trigonometry
- [x] **Localization Support** - Multi-language text handling
- [x] **Local Notifications** - User notification management

### 📱 UI Module (FusionUI)

**Animation & Effects**
- [x] **Tween Animations** - Smooth property animations with easing functions
- [x] **Easing Functions** - Multiple animation curves (linear, ease-in, ease-out, etc.)
- [x] **View Transitions** - Custom view transition effects

**User Interface Controls**
- [x] **User Flow Management** - Navigation and presentation flow control
- [x] **Control Actions** - Unified action handling for UI controls
- [x] **View Hierarchy Utilities** - Advanced view manipulation and traversal
- [x] **Haptic Feedback** - Tactile feedback integration
- [x] **Scroll View Extensions** - Enhanced scroll view functionality

**Styling & Theming**
- [x] **Color Management** - Advanced color utilities and theming
- [x] **Font Handling** - Dynamic font management and styling
- [x] **Gradient Views** - Custom gradient view components
- [x] **Image Processing** - Image loading, caching, and manipulation
- [x] **SwiftUI Integration** - SwiftUI modifiers and style extensions
- [x] **Geometric Shapes** - Custom shape drawing utilities

## Requirements

- iOS 15.0+
- macOS 12.0+
- tvOS 15.0+
- watchOS 9.0+
- Swift 5.0+
- Xcode 13.0+

## Usage Examples

### Storage & Keychain

```swift
import Fusion

// Secure keychain storage
let keychain = Keychain()
keychain["userToken"] = "abc123".data(using: .utf8)
let token = keychain["userToken"]

// Multiple storage backends
UserDefaults.shared.set("value", forKey: "key")
FileManager.shared.set(model, forKey: "model.json")
StateStorage.shared.set(temporaryData, forKey: "temp")
```

### Networking

```swift
import Fusion

// REST API requests
let request = RESTBuilder<UserModel>(url: "https://api.example.com/users", method: .get)
request.execute { result, response in
    switch result {
    case .success(let user):
        print("User: \(user)")
    case .failure(let error):
        print("Error: \(error)")
    }
}

// With authentication
let authRequest = RESTBuilder<UserModel>(url: "https://api.example.com/profile", method: .get)
    .authenticated()
    .headers(["Custom-Header": "value"])
```

### Animations

```swift
import Fusion

// Tween animations
let view = UIView()
let tween = Tween(view, duration: 1.0)
    .to(\.alpha, 0.0)
    .to(\.transform, CGAffineTransform(scaleX: 0.5, y: 0.5))
    .ease(.easeInOut)
    .onComplete { print("Animation finished") }
    .start()
```

### User Flow Management

```swift
import Fusion

// Define user flows
let loginFlow = UserFlow("Login", bundle: .main)
let profileFlow = UserFlow { _ in ProfileViewController() }

// Present flows
loginFlow.startAsModal(withNavigation: true)
profileFlow.startAsPush()

// With hooks
let flow = UserFlow("Main", bundle: .main, hooks: [
    UserFlowHook(.userDidLogin, style: .push)
])
```

### Text Styling

```swift
import Fusion

// Rich text styling
let text = "Hello World"
    .styled([.foregroundColor: UIColor.blue])
    .styled([.font: UIFont.boldSystemFont(ofSize: 18)], onText: "World")

// HTML styling
let htmlText = "This is <b>bold</b> and <i>italic</i>"
    .styledHTML([
        "b": [.font: UIFont.boldSystemFont(ofSize: 16)],
        "i": [.obliqueness: 0.3]
    ])
```

## Installation

### Using [Swift Package Manager](https://swift.org/package-manager) (Recommended)

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/db-in/fusion.git", from: "1.3.5")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/db-in/fusion.git`
3. Select version 1.3.5 or later

### Using [CocoaPods](https://cocoapods.org)

Add to your `Podfile`:

```ruby
# Full framework
pod 'Fusion'

# Or install specific modules
pod 'Fusion/Core'  # Core functionality only
pod 'Fusion/UI'    # UI components (includes Core)
```

Then run:
```bash
pod install
```

### Using [Carthage](https://github.com/Carthage/Carthage)

Add to your `Cartfile`:

```
github "db-in/fusion" ~> 1.3.5
```

Then run:
```bash
carthage update
```

## Module Structure

Fusion is organized into modular components:

- **FusionCore**: Essential utilities, networking, storage, and data management
- **FusionUI**: User interface components, animations, and styling utilities
- **Fusion**: Complete framework (includes both Core and UI)

You can import specific modules based on your needs:

```swift
import FusionCore  // Core functionality only
import FusionUI    // UI components (automatically includes Core)
import Fusion      // Complete framework
```

## Documentation

- [API Documentation](https://db-in.github.io/fusion/)
- [GitHub Repository](https://github.com/db-in/fusion)
- [Issues & Bug Reports](https://github.com/db-in/fusion/issues)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

Fusion is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

## Author

**Diney Bomfim**
- GitHub: [@dineybomfim](https://github.com/dineybomfim)
