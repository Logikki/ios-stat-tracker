# Async/Await Refactoring - Implementation Guide

## Changes Made

### Core Managers
1. **UserManager** - Proper async/await with task cancellation
2. **GameManager** - Consistent pattern applied
3. **LeagueManager** - Already using async/await correctly
4. **AppState** - Debounced publishers to prevent rapid updates

### ViewModels
1. **LeaguesViewModel** - Task cancellation + deduplication

### Views
1. **LeaguesView** - Removed duplicate `.task` modifier

## Best Practices Applied

### 1. Task Cancellation Pattern
```swift
private var fetchTask: Task<Void, Never>?

func fetch() async {
    // Cancel previous task
    fetchTask?.cancel()
    
    // Prevent duplicate calls
    guard !isLoading else { return }
    
    fetchTask = Task { @MainActor in
        isLoading = true
        defer { isLoading = false }
        
        // ... network call ...
        
        // Check cancellation before updating state
        guard !Task.isCancelled else { return }
        
        // Update state
    }
    
    await fetchTask?.value
}
```

### 2. Error Handling for Cancellation
```swift
catch is CancellationError {
    // Don't log as error - this is expected
}
catch {
    // Filter out URLError -999 (cancelled)
    if (error as NSError).code != NSURLErrorCancelled {
        errorMessage = error.localizedDescription
    }
}
```

### 3. Debouncing Publishers
```swift
authManager.$isAuthenticated
    .removeDuplicates()
    .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
    .sink { ... }
```

### 4. Deduplication
```swift
userManager.$currentUserProfile
    .map { $0?.leagues ?? [] }
    .removeDuplicates(by: { oldLeagues, newLeagues in
        // Only update if actually changed
        oldLeagues.count == newLeagues.count && 
        oldLeagues.map { $0.id }.sorted() == newLeagues.map { $0.id }.sorted()
    })
```

### 5. Avoid Redundant Data Fetching
- Remove `.task` modifiers when data is already loaded via other means
- User data is loaded automatically when authentication state changes
- Use `.refreshable` for manual refresh only

## What to Check in Other Views

Apply similar patterns to:

### GamesView (if it exists)
- Remove `.task` if it also calls `gameManager.fetchGames()`
- Games should be fetched once on app launch or when explicitly refreshed

### FriendsView / ProfileView
- Check for duplicate `.task` + `.refreshable` + automatic loading
- Apply task cancellation pattern

### Detail Views
- Should NOT auto-refresh on appear
- Should only refresh when user explicitly pulls to refresh
- Use `.refreshable` sparingly

## Performance Improvements

### Before:
- 10+ simultaneous network calls on app launch
- Screen flickering from rapid state changes
- Multiple request cancellations
- Error logs flooding console

### After:
- Single network call per resource
- Smooth state transitions
- Graceful cancellation handling
- Clean console output

## Testing Checklist

- [ ] App launches without multiple `/api/user/own` calls
- [ ] No "Publishing changes from within view updates" warnings
- [ ] No screen flickering/blinking
- [ ] Pull-to-refresh works correctly
- [ ] League creation/joining refreshes data properly
- [ ] Game creation refreshes list
- [ ] Authentication flow smooth (login/logout)
- [ ] No URLError -999 spam in logs

## Future Improvements

1. **Consider adding a shared request cache** to prevent duplicate API calls across managers
2. **Implement exponential backoff** for failed network requests
3. **Add connection state monitoring** to prevent requests when offline
4. **Use `AsyncStream`** for real-time updates instead of polling
5. **Consider migrating more Combine code to async/await** for consistency

## Common Pitfalls to Avoid

❌ **Don't do this:**
```swift
.task { await viewModel.refresh() }
.refreshable { await viewModel.refresh() }
```
This creates duplicate calls!

❌ **Don't do this:**
```swift
authManager.$isAuthenticated
    .sink { isAuthenticated in
        if isAuthenticated {
            Task { await fetchData() }  // Can cause race conditions
        }
    }
```

✅ **Do this instead:**
```swift
authManager.$isAuthenticated
    .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
    .sink { isAuthenticated in
        Task { @MainActor in
            if isAuthenticated {
                await fetchData()
            }
        }
    }
```

## MainActor Best Practices

1. Mark manager classes with `@MainActor` if they primarily update UI state
2. Remove redundant `@MainActor` from methods in `@MainActor` classes
3. Use `@MainActor` closures when updating state from background tasks:
```swift
Task { @MainActor in
    self.isLoading = false
}
```

## Questions to Consider

1. **Do I need to fetch this data automatically?** 
   - Yes: Use publisher observation
   - No: Only fetch on explicit user action

2. **Can this request be cancelled?**
   - Yes: Implement task cancellation
   - No: Let it complete but ignore results if needed

3. **Could this cause duplicate requests?**
   - Check for `.task` + `.refreshable` + publisher triggers
   - Add `isLoading` guards

4. **Is this state change happening during view update?**
   - Use debouncing
   - Wrap in `Task { @MainActor in ... }`
