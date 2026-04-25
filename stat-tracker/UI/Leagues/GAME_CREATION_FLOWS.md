# Game Creation Flow Reference

This document explains the two different ways users can create games in your app.

---

## Flow #1: Global Game Creation (From Tab Bar)

### Entry Point
User taps the **"Add" tab** in the bottom tab bar.

### Behavior
```
TabView
  └─ "Add" Tab
       └─ AddGameView(viewModel: factory.createAddGameViewModel())
            └─ preselectedLeague: nil
```

### UI State
- ✅ All game types available (NHL, FIFA, NBA)
- ✅ League picker shows **all** leagues that support the selected game type
- ✅ User can select "None" (game won't be tied to any league)
- ✅ League picker updates when game type changes

### Example User Flow
1. User taps "Add" tab
2. Selects "NHL" game type
3. League picker shows: "None", "Winter League", "Champions Cup" (all NHL leagues)
4. User selects "Winter League"
5. Fills in opponent, teams, scores
6. Taps "Save game"
7. Game is created with `league: "winter-league-id"`

### Code
```swift
// In TabView
NavigationStack {
    AddGameView(viewModel: appFactory.createAddGameViewModel())
}
.tabItem { Label("Add", systemImage: "plus.circle.fill") }
```

---

## Flow #2: League-Specific Game Creation (From League Detail)

### Entry Point
User navigates to a specific league, then taps the **"Add Game"** button (+ icon in toolbar).

### Behavior
```
LeaguesView
  └─ NavigationLink to League
       └─ LeagueDetailView(league: specificLeague)
            └─ "Add Game" toolbar button
                 └─ Sheet with AddGameView(viewModel: factory.createAddGameViewModel(forLeague: league))
                      └─ preselectedLeague: specificLeague
```

### UI State
- ⚠️ Game type **restricted** to league's supported types
- ⚠️ Game type picker is **disabled** if league only supports one type
- 🔒 League field is **locked** and shows the league name (read-only)
- 🔒 User **cannot** change or remove the league
- ℹ️ Helper text: "This game will be added to the selected league"

### Example User Flow
1. User taps "Leagues" tab
2. Selects "Winter League" (supports only NHL)
3. Taps "+" button in toolbar
4. Sheet opens with AddGameView
5. Game type is pre-set to "NHL" (disabled/locked)
6. League shows "Winter League" (read-only, cannot change)
7. Fills in opponent, teams, scores
8. Taps "Save game"
9. Game is automatically added to "Winter League"
10. Sheet dismisses, league standings update

### Code
```swift
// In LeagueDetailView
.toolbar {
    ToolbarItem(placement: .primaryAction) {
        Button {
            showAddGame = true
        } label: {
            Label("Add Game", systemImage: "plus.circle.fill")
        }
    }
}
.sheet(isPresented: $showAddGame) {
    NavigationStack {
        AddGameView(
            viewModel: appFactory.createAddGameViewModel(forLeague: viewModel.league)
        )
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { showAddGame = false }
            }
        }
    }
}
```

---

## Comparison Table

| Feature | Global Creation | League-Specific Creation |
|---------|----------------|--------------------------|
| **Entry Point** | "Add" tab | League detail "+" button |
| **Game Type Selection** | Free choice | Restricted to league types |
| **League Selection** | Optional picker | Locked to specific league |
| **Can skip league** | ✅ Yes | ❌ No |
| **Game type changeable** | ✅ Yes | ⚠️ Only if league supports multiple |
| **Use Case** | Casual games, practice | Official league matches |
| **Presentation** | Tab content | Sheet/modal |

---

## Implementation Details

### AddGameViewModel Properties

```swift
@MainActor
final class AddGameViewModel: ObservableObject {
    // ... other properties
    
    private let preselectedLeague: League?
    
    var isLeagueLocked: Bool { 
        preselectedLeague != nil 
    }
    
    var shouldShowLeaguePicker: Bool {
        if preselectedLeague != nil { return true }  // Always show (locked)
        return !leaguesForCurrentType.isEmpty         // Show if leagues available
    }
    
    var leaguesForCurrentType: [League] {
        if let locked = preselectedLeague {
            return [locked]  // Only the locked league
        }
        
        let userLeagues = userManager.currentUserProfile?.leagues ?? []
        return userLeagues.filter { $0.gameTypes.contains(gameType.rawValue) }
    }
}
```

### Factory Methods

```swift
protocol ViewModelFactory {
    // For global creation (Tab Bar)
    func createAddGameViewModel() -> AddGameViewModel
    
    // For league-specific creation (League Detail)
    func createAddGameViewModel(forLeague league: League) -> AddGameViewModel
}

// Implementation
func createAddGameViewModel() -> AddGameViewModel {
    AddGameViewModel(
        gameManager: gameManager,
        userManager: userManager,
        teamsManager: teamsManager,
        preselectedLeague: nil  // ← No restriction
    )
}

func createAddGameViewModel(forLeague league: League) -> AddGameViewModel {
    AddGameViewModel(
        gameManager: gameManager,
        userManager: userManager,
        teamsManager: teamsManager,
        preselectedLeague: league  // ← Locked to this league
    )
}
```

---

## UI Behavior Matrix

### Game Type Picker

| Mode | League Supports | Picker State | Initial Value |
|------|----------------|--------------|---------------|
| Global | N/A | Enabled | .NHL |
| Locked | NHL only | Disabled | .NHL |
| Locked | NHL, FIFA | Enabled | .NHL (first type) |

### League Picker

| Mode | User Leagues | UI Element | User Can Change |
|------|-------------|------------|-----------------|
| Global | None | Hidden | N/A |
| Global | 1+ leagues | Picker with "None" option | ✅ Yes |
| Locked | Any | LabeledContent (read-only) | ❌ No |

### Submit Behavior

Both modes use the same `submit()` function:

```swift
func submit() {
    let payload = CreateGamePayload(
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        homePlayer: homeIsMe ? currentUsername : opponentUsername,
        awayPlayer: homeIsMe ? opponentUsername : currentUsername,
        homeScore: homeScore,
        awayScore: awayScore,
        createdAt: date,
        overTime: overtime ? true : nil,
        penalties: penalties ? true : nil,
        league: selectedLeagueId,  // ← Set from locked or picker
        gameType: gameType
    )
    
    // Create game...
}
```

---

## Edge Cases

### What if user is not in any leagues?

**Global Mode:**
- League picker doesn't show at all
- User creates game without league association
- Works perfectly fine

**Locked Mode:**
- N/A - user can't access this flow without being in a league

### What if league supports multiple game types?

**Locked Mode:**
- Game type picker is **enabled**
- User can switch between supported types
- Example: League supports NHL + NBA → user can toggle between them
- League field remains locked

### What if user selects a game type not supported by any league?

**Global Mode:**
- League picker shows "None" only
- User can create game without league
- This is expected behavior

### What happens when game is submitted?

1. `AddGameViewModel.submit()` is called
2. Creates `CreateGamePayload` with `league: selectedLeagueId`
3. Sends POST to `/api/game` with league ID
4. Backend:
   - Creates game with league reference
   - Adds game to league's `matches` array
   - Returns populated game object
5. Frontend:
   - Refreshes user data (includes leagues)
   - Refreshes games list
   - League detail view updates automatically (via observable data)

---

## Testing Scenarios

### Scenario 1: Global Creation with League
```
Given user is in "Winter League" (NHL only)
When user goes to "Add" tab
And selects NHL game type
Then league picker shows ["None", "Winter League"]
When user selects "Winter League"
And fills in game details
And taps "Save game"
Then game is created with league: "winter-league-id"
And appears in both Games list and Winter League matches
```

### Scenario 2: Global Creation without League
```
Given user is in "Winter League"
When user goes to "Add" tab
And selects NHL game type
Then league picker shows ["None", "Winter League"]
When user selects "None"
And fills in game details
And taps "Save game"
Then game is created with league: null
And appears only in Games list (not in any league)
```

### Scenario 3: League-Specific Creation
```
Given user is viewing "Winter League" detail
When user taps "+" button
Then sheet opens with AddGameView
And game type is pre-set to NHL
And game type picker is disabled (league supports NHL only)
And league field shows "Winter League" (read-only)
When user fills in game details
And taps "Save game"
Then game is created with league: "winter-league-id"
And sheet dismisses
And league standings update
And game appears in league matches
```

### Scenario 4: Multi-Type League
```
Given user is viewing "All-Sports League" (supports NHL, FIFA, NBA)
When user taps "+" button
Then sheet opens with AddGameView
And game type defaults to NHL (first type)
And game type picker is enabled
When user switches to FIFA
Then game type updates to FIFA
And league field still shows "All-Sports League"
And user cannot change league
```

---

## Visual Mockup

### Global Mode
```
┌─────────────────────────────────┐
│  Add game                    ✕  │
├─────────────────────────────────┤
│  Game type                      │
│  ┌───────┬────────┬──────────┐  │
│  │  NHL  │  FIFA  │   NBA    │  │ ← Enabled
│  └───────┴────────┴──────────┘  │
│                                 │
│  Players                        │
│  ...                            │
│                                 │
│  League (optional)              │
│  ┌───────────────────────────┐  │
│  │  None                  ▼  │  │ ← Picker
│  └───────────────────────────┘  │
│  Optionally assign this game    │
│  to a league                    │
│                                 │
│  [Save game]                    │
└─────────────────────────────────┘
```

### Locked Mode
```
┌─────────────────────────────────┐
│  Add game                 Cancel │
├─────────────────────────────────┤
│  Game type                      │
│  ┌───────┬────────┬──────────┐  │
│  │  NHL  │  FIFA  │   NBA    │  │ ← Disabled
│  └───────┴────────┴──────────┘  │
│  Game type is limited to this   │
│  league's supported types       │
│                                 │
│  Players                        │
│  ...                            │
│                                 │
│  League                         │
│  ┌───────────────────────────┐  │
│  │  Winter League            │  │ ← Read-only
│  └───────────────────────────┘  │
│  This game will be added to     │
│  the selected league            │
│                                 │
│  [Save game]                    │
└─────────────────────────────────┘
```

---

## Summary

The dual-flow system provides:

✅ **Flexibility** - Users can create casual games without leagues
✅ **Structure** - League games are properly organized
✅ **UX Clarity** - Different contexts have appropriate constraints
✅ **Data Integrity** - League games can't accidentally be created without league association

This design balances freedom (global creation) with structure (league-specific creation).
