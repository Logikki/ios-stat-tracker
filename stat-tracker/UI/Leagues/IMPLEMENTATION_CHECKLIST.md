# Implementation Checklist

Use this checklist to track your progress implementing the fixes.

---

## ✅ Frontend (Swift/SwiftUI) - COMPLETED

### Issue #1: Navigation Fix
- [x] Move `.navigationDestination(for: Game.self)` outside lazy containers
- [x] Extract content into separate `@ViewBuilder` property
- [x] Test navigation from Games list → Game detail

### Issue #2: Decoding Fix
- [x] Create `Models.swift` with flexible `Game` model
- [x] Implement custom `init(from decoder:)` for `Game`
- [x] Handle both String IDs and populated LightUser objects
- [x] Add fallback to "Unknown" username
- [x] Test game creation without crashes

### Issue #3: League Integration
- [x] Add `league: String?` field to Game model
- [x] Update `AddGameViewModel` with `preselectedLeague` parameter
- [x] Add `isLeagueLocked` computed property
- [x] Update `leaguesForCurrentType` to handle locked mode
- [x] Update `AddGameView` to show locked league UI
- [x] Disable game type picker when locked
- [x] Add factory method `createAddGameViewModel(forLeague:)`
- [x] Add "Add Game" button to `LeagueDetailView`
- [x] Wire up sheet presentation with league-locked view model
- [x] Test both creation flows (global and league-specific)

---

## ⚠️ Backend (Node.js/Express) - PENDING

### Issue #2: Player Population
- [ ] Update POST `/api/game` endpoint
- [ ] Add `.populate()` for `homePlayer` field
- [ ] Add `.populate()` for `awayPlayer` field
- [ ] Test response includes player objects
- [ ] Update GET `/api/games` to populate players
- [ ] Update GET `/api/user/own` to populate game players in leagues

### Issue #3: League Schema Updates
- [ ] Add `league` field to Game schema (optional)
  ```javascript
  league: { type: mongoose.Schema.Types.ObjectId, ref: 'League', default: null }
  ```
- [ ] Verify League schema has `matches` array
  ```javascript
  matches: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Game' }]
  ```
- [ ] Run migration for existing games (if needed)

### Issue #3: Game Creation Logic
- [ ] Update POST `/api/game` to accept `league` parameter
- [ ] Validate league exists (if provided)
- [ ] Validate user is member of league
- [ ] Validate game type is supported by league
- [ ] Add game to league's `matches` array
- [ ] Return populated game with players

### Issue #3: User Profile Endpoint
- [ ] Update GET `/api/user/own` to populate leagues
- [ ] Populate league matches
- [ ] Populate match players
- [ ] Test response structure matches Swift models

---

## 🧪 Testing - PENDING

### Unit Tests
- [ ] Test `Game.init(from:)` with String IDs
- [ ] Test `Game.init(from:)` with populated objects
- [ ] Test `AddGameViewModel` league locking logic
- [ ] Test factory creates correct view models

### Integration Tests (Frontend)
- [ ] Create game from Tab Bar without league
- [ ] Create game from Tab Bar with league selected
- [ ] Create game from League Detail (league locked)
- [ ] Verify game appears in Games list
- [ ] Verify game appears in League matches
- [ ] Verify league standings update
- [ ] Test navigation Games → Game Detail
- [ ] Test pull-to-refresh updates league data

### Integration Tests (Backend)
- [ ] POST `/api/game` without league → 200 OK
- [ ] POST `/api/game` with valid league → 200 OK
- [ ] POST `/api/game` with invalid league ID → 404
- [ ] POST `/api/game` user not in league → 403
- [ ] POST `/api/game` wrong game type for league → 400
- [ ] Verify game added to league's matches array
- [ ] Verify GET `/api/user/own` returns updated league data

### End-to-End Tests
- [ ] User creates game from Tab Bar
- [ ] Refresh app → game persists
- [ ] Navigate to league → game appears in matches
- [ ] League standings reflect new game
- [ ] Create another game in same league
- [ ] Standings update correctly
- [ ] Delete league → games still accessible (or cascade delete based on requirements)

### Edge Cases
- [ ] User in no leagues → can still create games
- [ ] League supports multiple game types → user can switch
- [ ] League supports one game type → picker disabled
- [ ] Cancel game creation → no game created
- [ ] Network error during creation → error message shown
- [ ] Duplicate game prevention (if applicable)
- [ ] Offline creation handling (if applicable)

---

## 📱 UI/UX Verification

### Global Game Creation (Tab Bar)
- [ ] Game type picker shows all types
- [ ] Game type picker is enabled
- [ ] League picker shows when user has leagues
- [ ] League picker filters by game type
- [ ] "None" option available in league picker
- [ ] Selecting different game type updates league list
- [ ] Submit button disabled until valid
- [ ] Success message shown after creation
- [ ] Form resets after successful submission

### League-Specific Game Creation
- [ ] "Add Game" button visible in league detail
- [ ] Tapping button opens sheet with form
- [ ] Game type pre-selected from league types
- [ ] Game type picker disabled if one type
- [ ] Game type picker enabled if multiple types
- [ ] League field shows league name (read-only)
- [ ] Helper text explains game will be added to league
- [ ] Cancel button dismisses sheet
- [ ] Submit creates game and dismisses sheet
- [ ] League standings update immediately

### Navigation
- [ ] No console warnings about lazy containers
- [ ] Games list → Game detail works
- [ ] League detail → Game detail works (from matches section)
- [ ] Back navigation works correctly
- [ ] Tab switching preserves navigation state

### Error Handling
- [ ] Network errors show alert
- [ ] Decoding errors show meaningful message
- [ ] Validation errors show inline
- [ ] Loading states show spinner
- [ ] Pull-to-refresh shows indicator

---

## 📝 Documentation

- [x] Create `BACKEND_CHANGES_REQUIRED.md`
- [x] Create `FIX_SUMMARY.md`
- [x] Create `GAME_CREATION_FLOWS.md`
- [x] Create this checklist
- [ ] Update API documentation with new endpoints
- [ ] Update README with feature description
- [ ] Create migration guide for existing data
- [ ] Document environment setup

---

## 🚀 Deployment

### Pre-Deployment
- [ ] All tests passing
- [ ] No console errors/warnings
- [ ] Code review completed
- [ ] Database migration script ready
- [ ] Backup current database

### Backend Deployment
- [ ] Deploy schema changes
- [ ] Run migration script
- [ ] Verify migrations succeeded
- [ ] Deploy API changes
- [ ] Test API endpoints manually
- [ ] Monitor error logs

### Frontend Deployment
- [ ] Archive app for distribution
- [ ] Test on physical devices
- [ ] Verify network calls work
- [ ] Submit to TestFlight (if applicable)
- [ ] Release to production

### Post-Deployment
- [ ] Monitor crash reports
- [ ] Monitor error logs
- [ ] Verify features work in production
- [ ] Gather user feedback
- [ ] Plan iterations based on feedback

---

## 🐛 Known Issues / Future Improvements

### Current Limitations
- [ ] Games can only be in one league (not multiple)
- [ ] No way to move game from one league to another
- [ ] No way to remove game from league after creation
- [ ] League deletion doesn't cascade to games

### Future Enhancements
- [ ] Add game editing functionality
- [ ] Add bulk game import
- [ ] Add game filtering by league
- [ ] Add league statistics dashboard
- [ ] Add push notifications for new games
- [ ] Add real-time updates via WebSocket
- [ ] Add game comments/reactions
- [ ] Add photo upload for games

---

## ✅ Sign-Off

### Frontend Lead
- [ ] Code reviewed
- [ ] Tests pass locally
- [ ] UI matches designs
- [ ] Performance acceptable
- [ ] Approved for deployment

**Signature:** _________________ **Date:** _______

### Backend Lead
- [ ] Code reviewed
- [ ] Tests pass locally
- [ ] API documentation updated
- [ ] Performance acceptable
- [ ] Approved for deployment

**Signature:** _________________ **Date:** _______

### QA Lead
- [ ] Test plan executed
- [ ] No critical bugs
- [ ] Edge cases tested
- [ ] Approved for deployment

**Signature:** _________________ **Date:** _______

---

## Notes

Add any additional notes, blockers, or decisions here:

```
[Your notes here]
```

---

Last updated: April 25, 2026
