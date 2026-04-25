//
//  MIGRATION_GUIDE.md
//  stat-tracker
//
//  How to migrate from ViewModeFactoryImpl to DependencyContainer
//

# Migration Guide: Dependency Injection Improvements

## What Changed?

### Before (Old Way)
```swift
// In your view:
@EnvironmentObject var appFactory: ViewModeFactoryImpl
@EnvironmentObject var userManager: UserManagerImpl
@EnvironmentObject var gameManager: GameManagerImpl
// ... and more

// Creating ViewModels:
let vm = appFactory.createGamesViewModel()
```

### After (New Way)
```swift
// In your view:
@EnvironmentObject var dependencies: DependencyContainer

// Creating ViewModels:
let vm = dependencies.getGamesViewModel()  // Cached
// OR
let vm = dependencies.createAddGameViewModel()  // Transient
```

---

## Benefits of the New Approach

### 1. **Single Dependency** ✅
- Only pass ONE `@EnvironmentObject` instead of 6+
- Cleaner view code
- No more missing environment object crashes

### 2. **Explicit State Management** ✅
- `getXViewModel()` = Cached (singleton) - preserves state
- `createXViewModel()` = Transient (new each time) - fresh state
- No more accidental state loss!

### 3. **Better Testing** ✅
```swift
// Easy to mock for tests
class MockDependencyContainer: DependencyContainer {
    // Override specific managers for testing
}
```

### 4. **Clear Dependency Graph** ✅
All dependencies are created in ONE place (`DependencyContainer.init`)

### 5. **Lifecycle Management** ✅
```swift
// Reset all cached ViewModels after logout:
dependencies.resetViewModels()
```

---

## Step-by-Step Migration

### Step 1: Update Your Views

**Old:**
```swift
struct MyView: View {
    @EnvironmentObject var appFactory: ViewModeFactoryImpl
    @EnvironmentObject var userManager: UserManagerImpl
    @StateObject private var viewModel: MyViewModel
    
    init() {
        _viewModel = StateObject(wrappedValue: 
            ViewModeFactoryImpl(...).createMyViewModel()
        )
    }
}
```

**New:**
```swift
struct MyView: View {
    @EnvironmentObject var dependencies: DependencyContainer
    @StateObject private var viewModel: MyViewModel
    
    init() {
        _viewModel = StateObject(wrappedValue: 
            DependencyContainer.shared.getMyViewModel()
        )
    }
}
```

### Step 2: Replace EnvironmentObject References

**Old:**
```swift
@EnvironmentObject var appFactory: ViewModeFactoryImpl
@EnvironmentObject var userManager: UserManagerImpl
@EnvironmentObject var gameManager: GameManagerImpl

// Later in code:
if let user = userManager.currentUserProfile {
    // ...
}
```

**New:**
```swift
@EnvironmentObject var dependencies: DependencyContainer

// Later in code:
if let user = dependencies.userManager.currentUserProfile {
    // ...
}
```

### Step 3: Update Navigation Destinations

**Old:**
```swift
.navigationDestination(for: League.self) { league in
    LeagueDetailView(viewModel: appFactory.createLeagueDetailViewModel(league: league))
}
```

**New:**
```swift
.navigationDestination(for: League.self) { league in
    LeagueDetailView(viewModel: dependencies.createLeagueDetailViewModel(league: league))
}
```

### Step 4: Update Sheets and Full Screen Covers

**Old:**
```swift
.sheet(isPresented: $showSheet) {
    NavigationStack {
        AddGameView(viewModel: appFactory.createAddGameViewModel())
            .environmentObject(appFactory)
            .environmentObject(userManager)
    }
}
```

**New:**
```swift
.sheet(isPresented: $showSheet) {
    NavigationStack {
        AddGameView(viewModel: dependencies.createAddGameViewModel())
            .environmentObject(dependencies)
    }
}
```

---

## Cached vs Transient ViewModels

### Use **Cached** (`getXViewModel()`) when:
- ✅ ViewModel needs to preserve state across navigation (filters, selections, etc.)
- ✅ ViewModel is used in multiple places and should share state
- ✅ Examples: `GamesViewModel`, `ProfileViewModel`, `SettingsViewModel`

### Use **Transient** (`createXViewModel()`) when:
- ✅ ViewModel is context-specific (depends on parameters like a League or Game)
- ✅ You want fresh state each time
- ✅ Examples: `AddGameViewModel`, `LeagueDetailViewModel`

---

## Testing Example

```swift
@testable import stat_tracker
import XCTest

class MyViewModelTests: XCTestCase {
    var dependencies: DependencyContainer!
    var sut: MyViewModel!
    
    override func setUp() {
        super.setUp()
        dependencies = DependencyContainer.shared
        sut = dependencies.getMyViewModel()
    }
    
    func testExample() {
        // Test your ViewModel using the dependency container
    }
}
```

---

## Common Patterns

### Pattern 1: Accessing Services Directly

```swift
struct MyView: View {
    @EnvironmentObject var dependencies: DependencyContainer
    
    var body: some View {
        VStack {
            // Access managers directly when you don't need a ViewModel
            Text(dependencies.userManager.currentUserProfile?.name ?? "Guest")
            
            Button("Refresh") {
                Task {
                    await dependencies.userManager.fetchOwnUser()
                }
            }
        }
    }
}
```

### Pattern 2: Property Wrapper for Cleaner Access

```swift
@propertyWrapper
struct Injected<T> {
    private let keyPath: KeyPath<DependencyContainer, T>
    
    var wrappedValue: T {
        DependencyContainer.shared[keyPath: keyPath]
    }
    
    init(_ keyPath: KeyPath<DependencyContainer, T>) {
        self.keyPath = keyPath
    }
}

// Usage:
struct MyView: View {
    @Injected(\.userManager) var userManager
    @Injected(\.gameManager) var gameManager
    
    var body: some View {
        // Use managers directly without @EnvironmentObject
    }
}
```

### Pattern 3: Conditional ViewModel Creation

```swift
struct GameDetailView: View {
    @EnvironmentObject var dependencies: DependencyContainer
    @StateObject private var viewModel: GameDetailViewModel
    
    let game: Game
    
    init(game: Game) {
        self.game = game
        _viewModel = StateObject(wrappedValue: 
            DependencyContainer.shared.createGameDetailViewModel(game: game)
        )
    }
}
```

---

## Checklist for Each View

- [ ] Replace `@EnvironmentObject var appFactory` with `@EnvironmentObject var dependencies`
- [ ] Remove other `@EnvironmentObject` declarations (userManager, gameManager, etc.)
- [ ] Update ViewModel initialization to use `DependencyContainer.shared`
- [ ] Replace `appFactory.createX()` with `dependencies.getX()` or `dependencies.createX()`
- [ ] Access managers via `dependencies.userManager` instead of `@EnvironmentObject`
- [ ] Update `.environmentObject()` modifiers to only pass `dependencies`

---

## Files to Update

1. All View files (replace `appFactory` with `dependencies`)
2. Remove old `Factory.swift` (after migration is complete)
3. Update previews to use `DependencyContainer.shared`

---

## After Migration

Once all views are migrated, you can:

1. **Delete** `Factory.swift` (old file)
2. **Keep** `DependencyContainer.swift` (new file)
3. Enjoy cleaner, more maintainable code! 🎉
