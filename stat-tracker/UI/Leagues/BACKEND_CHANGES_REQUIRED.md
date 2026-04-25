# Backend Changes Required for Full Game-League Integration

## Issue #2 Fix: Populate Player Objects in Game Response

### Current Problem
Your backend is returning player IDs as strings:
```json
{
  "homePlayer": "69ec7cd6a90367258c6178c1",
  "awayPlayer": "69eca64df16b50a59412d6e7"
}
```

But the Swift app expects populated user objects:
```json
{
  "homePlayer": {
    "id": "69ec7cd6a90367258c6178c1",
    "username": "alice",
    "profileVisibility": "Public"
  }
}
```

### Solution: Populate Players on Backend

In your Node.js/Express game creation endpoint, use Mongoose's `.populate()`:

```javascript
// Example: POST /api/game endpoint
router.post('/game', authenticateToken, async (req, res) => {
  try {
    const { 
      gameType, homeTeam, awayTeam, homeScore, awayScore,
      homePlayer, awayPlayer, overTime, penalties, createdAt, league 
    } = req.body;

    // Create the game
    const game = new Game({
      gameType,
      homeTeam,
      awayTeam,
      homeScore,
      awayScore,
      homePlayer,  // These are user IDs from the request
      awayPlayer,
      overTime,
      penalties,
      createdAt,
      league
    });

    await game.save();

    // If league is specified, add game to the league
    if (league) {
      await League.findByIdAndUpdate(
        league,
        { $push: { matches: game._id } }
      );
    }

    // IMPORTANT: Populate player fields before returning
    await game.populate([
      { path: 'homePlayer', select: 'username profileVisibility' },
      { path: 'awayPlayer', select: 'username profileVisibility' }
    ]);

    // Return the populated game
    res.json({
      id: game._id,
      gameType: game.gameType,
      homeTeam: game.homeTeam,
      awayTeam: game.awayTeam,
      homeScore: game.homeScore,
      awayScore: game.awayScore,
      homePlayer: {
        id: game.homePlayer._id,
        username: game.homePlayer.username,
        profileVisibility: game.homePlayer.profileVisibility
      },
      awayPlayer: {
        id: game.awayPlayer._id,
        username: game.awayPlayer.username,
        profileVisibility: game.awayPlayer.profileVisibility
      },
      overTime: game.overTime,
      penalties: game.penalties,
      createdAt: game.createdAt,
      league: game.league
    });
  } catch (error) {
    console.error('Error creating game:', error);
    res.status(500).json({ error: 'Failed to create game' });
  }
});
```

## Issue #3 Fix: Add League Support to Game Schema

### Update Your Mongoose Game Schema

```javascript
// models/Game.js
const gameSchema = new mongoose.Schema({
  gameType: { type: String, required: true, enum: ['NHL', 'FIFA', 'NBA'] },
  homeTeam: { type: String, required: true },
  awayTeam: { type: String, required: true },
  homeScore: { type: Number, required: true },
  awayScore: { type: Number, required: true },
  homePlayer: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  awayPlayer: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  overTime: { type: Boolean, default: false },
  penalties: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now },
  league: { type: mongoose.Schema.Types.ObjectId, ref: 'League', default: null }  // ← ADD THIS
});

module.exports = mongoose.model('Game', gameSchema);
```

### Update League Schema to Track Games

```javascript
// models/League.js
const leagueSchema = new mongoose.Schema({
  name: { type: String, required: true },
  description: String,
  gameTypes: [{ type: String, enum: ['NHL', 'FIFA', 'NBA'] }],
  users: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  admins: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  matches: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Game' }],  // ← Ensure this exists
  duration: { type: Date, required: true }
});

module.exports = mongoose.model('League', leagueSchema);
```

### Update Game Creation Logic

```javascript
router.post('/game', authenticateToken, async (req, res) => {
  try {
    const { league, ...gameData } = req.body;

    // Validate league if provided
    if (league) {
      const leagueDoc = await League.findById(league);
      if (!leagueDoc) {
        return res.status(404).json({ error: 'League not found' });
      }
      
      // Verify user is a member of the league
      const isMember = leagueDoc.users.some(
        userId => userId.toString() === req.user.id
      );
      if (!isMember) {
        return res.status(403).json({ error: 'Not a member of this league' });
      }
      
      // Verify game type is supported by league
      if (!leagueDoc.gameTypes.includes(gameData.gameType)) {
        return res.status(400).json({ 
          error: `This league doesn't support ${gameData.gameType} games` 
        });
      }
    }

    // Create game
    const game = await Game.create({
      ...gameData,
      league: league || null
    });

    // Add game to league's matches array
    if (league) {
      await League.findByIdAndUpdate(
        league,
        { $push: { matches: game._id } }
      );
    }

    // Populate and return
    await game.populate([
      { path: 'homePlayer', select: 'username profileVisibility' },
      { path: 'awayPlayer', select: 'username profileVisibility' }
    ]);

    res.json(transformGame(game));
  } catch (error) {
    console.error('Error creating game:', error);
    res.status(500).json({ error: 'Failed to create game' });
  }
});
```

### Update GET /api/user/own to Populate League Matches

```javascript
router.get('/user/own', authenticateToken, async (req, res) => {
  try {
    const user = await User.findById(req.user.id)
      .populate('friends', 'username profileVisibility')
      .populate('friendRequests', 'username profileVisibility')
      .populate({
        path: 'matches',
        populate: [
          { path: 'homePlayer', select: 'username profileVisibility' },
          { path: 'awayPlayer', select: 'username profileVisibility' }
        ]
      })
      .populate({
        path: 'leagues',
        populate: [
          { path: 'users', select: 'username profileVisibility' },
          { path: 'admins', select: 'username profileVisibility' },
          {
            path: 'matches',
            populate: [
              { path: 'homePlayer', select: 'username profileVisibility' },
              { path: 'awayPlayer', select: 'username profileVisibility' }
            ]
          }
        ]
      });

    res.json(transformUser(user));
  } catch (error) {
    console.error('Error fetching user:', error);
    res.status(500).json({ error: 'Failed to fetch user' });
  }
});
```

## Testing Checklist

After implementing these changes:

### Backend Tests
- [ ] Creating a game without a league works
- [ ] Creating a game with a league ID works
- [ ] Game response includes populated `homePlayer` and `awayPlayer` objects
- [ ] League's `matches` array updates when game is created
- [ ] GET `/api/user/own` returns leagues with populated matches
- [ ] Non-league-members can't add games to a league
- [ ] Game type validation works (can't add NBA game to NHL-only league)

### Frontend Tests
- [ ] Creating a game from Tab Bar works (league picker shows)
- [ ] Creating a game from League Detail works (league is locked)
- [ ] Game decoding no longer fails
- [ ] No more "type mismatch" errors
- [ ] League standings update after adding a game
- [ ] League matches section shows new games

## Database Migration (if needed)

If you already have games in your database without the `league` field:

```javascript
// migration.js
const mongoose = require('mongoose');
const Game = require('./models/Game');

async function migrateGames() {
  // Add league field to existing games (set to null)
  await Game.updateMany(
    { league: { $exists: false } },
    { $set: { league: null } }
  );
  
  console.log('Migration complete');
}

migrateGames();
```

## API Documentation Updates

### POST /api/game

**Request Body:**
```json
{
  "gameType": "NHL",
  "homeTeam": "Buffalo Sabres",
  "awayTeam": "Washington Capitals",
  "homeScore": 1,
  "awayScore": 2,
  "homePlayer": "user-id-1",
  "awayPlayer": "user-id-2",
  "overTime": true,
  "penalties": false,
  "createdAt": "2026-04-25T13:27:15.000Z",
  "league": "league-id-optional"
}
```

**Response:**
```json
{
  "id": "game-id",
  "gameType": "NHL",
  "homeTeam": "Buffalo Sabres",
  "awayTeam": "Washington Capitals",
  "homeScore": 1,
  "awayScore": 2,
  "homePlayer": {
    "id": "user-id-1",
    "username": "alice",
    "profileVisibility": "Public"
  },
  "awayPlayer": {
    "id": "user-id-2",
    "username": "bob",
    "profileVisibility": "Public"
  },
  "overTime": true,
  "penalties": false,
  "createdAt": "2026-04-25T13:27:15.000Z",
  "league": "league-id-optional"
}
```

## Summary

The key backend changes are:

1. **Always populate `homePlayer` and `awayPlayer`** when returning Game objects
2. **Add `league` field** to Game schema (optional, nullable)
3. **Update League's `matches` array** when games are created with a league
4. **Validate league membership and game type** when creating league games
5. **Populate league matches** when returning user profile

The Swift app is now ready to handle both populated objects AND string IDs (for backwards compatibility), but the backend should always return populated objects going forward.
