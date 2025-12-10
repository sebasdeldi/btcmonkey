# Game Anti-Cheat: Refresh/Back Button Protection

## Overview

This document describes the implementation of a security feature to prevent users from exploiting the game by refreshing the page or using the back button to retry game runs with knowledge of the number positions.

## Problem

Previously, users could:
1. Start a game run and memorize number positions
2. Refresh the page or press the back button
3. Retry the same game run with knowledge of where all the numbers are located
4. This defeats the purpose of the memory and reaction-time game

## Solution

We've implemented a multi-layered approach to detect and prevent this loophole:

### 1. Browser Navigation Detection

**Events Monitored:**
- `beforeunload` - Detects browser refresh button, typing URLs, closing tab/window
- `turbo:before-visit` - Detects Turbo Drive navigation (clicking links, form submissions)
- `keydown` - Detects keyboard shortcuts (Ctrl+R, Cmd+R, F5 for refresh)
- `popstate` - Detects back button clicks

**Behavior:**
- **Navigation links (turbo:before-visit)**: Prevented and shows custom black modal
- **Keyboard refresh (Ctrl+R, Cmd+R, F5)**: Prevented and shows custom modal
- **Back button (popstate)**: Prevented using history manipulation, shows custom modal
- **Browser refresh button/typing URLs (beforeunload)**: Browser shows native "Leave site?" dialog (browser security restriction)

### 2. Exit Warning Modal

**Location:** [`app/views/game_runs/show.html.erb`](app/views/game_runs/show.html.erb)

**Features:**
- **Black screen overlay** - Covers the entire game (prevents seeing the grid)
- **Pause timer** - Game timer pauses while modal is shown
- **Clear warning message** - Explains the consequences
- **Two options:**
  - **Cancel button** - Resumes the game with timer continuing from where it paused
  - **Exit button** - Marks the game as forfeited with penalty score

**Warning Text:**
```
⚠️ Warning: Exit Game?

If you close or refresh this window, the game will be marked as
failed with a score of 1,999,999ms and cannot be retried.

Your progress will be lost and the spot will be forfeited.
```

### 3. Forfeit Mechanism

**Controller Action:** [`app/controllers/game_runs_controller.rb#forfeit`](app/controllers/game_runs_controller.rb)

**Penalty:**
- Score: **1,999,999ms** (very poor score but within valid range of 10,000-1,999,999ms)
- Status: Marked as **played** (cannot be retried)
- Metadata: Includes forfeit reason and timestamp for audit trail

**Metadata Example:**
```ruby
{
  forfeited: true,
  reason: "User attempted to refresh or navigate away during game",
  forfeited_at: "2025-12-09T10:30:15Z"
}
```

### 4. Game State Management

**JavaScript States:**
- `gameStarted` - Tracks if game has begun (after 3-second countdown)
- `gameCompleted` - Tracks if all 25 numbers have been clicked
- `timerPaused` - Tracks if timer is currently paused
- `pausedTime` - Stores elapsed time when paused

**Protection Window:**
- Protection is **only active** when `gameStarted = true` AND `gameCompleted = false`
- No warnings during memorization phase (before game starts)
- No warnings after successful completion

## Files Modified

### JavaScript
- [`app/javascript/controllers/number_sequence_game_controller.js`](app/javascript/controllers/number_sequence_game_controller.js)
  - Added `onBeforeUnload()` handler
  - Added `onVisibilityChange()` handler
  - Added `pauseTimer()` and `resumeTimer()` methods
  - Added `showExitWarning()` and `hideExitWarning()` methods
  - Added `cancelExit()` method (resumes game)
  - Added `forfeitGame()` method (submits forfeit)

### View
- [`app/views/game_runs/show.html.erb`](app/views/game_runs/show.html.erb)
  - Added exit warning modal HTML structure
  - Connected modal to Stimulus controller targets
  - Added action buttons for cancel and exit

### Controller
- [`app/controllers/game_runs_controller.rb`](app/controllers/game_runs_controller.rb)
  - Added `forfeit` action
  - Added `forfeit` to `before_action` filters
  - Implements penalty score and audit metadata

### Routes
- [`config/routes.rb`](config/routes.rb)
  - Added `post :forfeit` route to game_runs member routes

### Styles
- [`app/assets/stylesheets/components/number_game.css`](app/assets/stylesheets/components/number_game.css)
  - Added `.exit-warning-modal` styles
  - Added `.exit-warning-content` styles
  - Added `.exit-warning-title`, `.exit-warning-text`, `.exit-warning-subtext` styles
  - Added `.exit-warning-actions` button layout
  - Added responsive mobile styles
  - Added animations (fadeIn, slideUp)

## User Experience Flow

### Scenario 1: User tries to refresh during game (Keyboard shortcut)

1. User starts game run
2. User presses **Ctrl+R** or **Cmd+R** or **F5**
3. **Black modal appears** (prevented by JavaScript)
4. User chooses:
   - **Cancel** → Resume game
   - **Exit** → Forfeit with 1,999,999ms

### Scenario 1b: User tries to refresh via browser button

1. User starts game run
2. User clicks **browser refresh button**
3. **Browser shows native "Leave site?" dialog** ("Changes you made may not be saved")
4. If user clicks **Stay**:
   - Returns to game, can continue playing
5. If user clicks **Leave**:
   - Page refreshes
   - On page load, game is **automatically forfeited** (1,999,999ms)
   - User is redirected to My Games
   - Cannot retry this game run

### Scenario 2: User presses back button

1. User starts game run
2. User presses **browser back button**
3. **Black modal appears** (navigation prevented)
4. User chooses:
   - **Cancel** → Resume game
   - **Exit** → Forfeit with 1,999,999ms

### Scenario 3a: User clicks navigation links (in-app)

1. User starts game run
2. User clicks navigation link (e.g., "Buy Credits", "Sign Out", "My Games")
3. **Custom black modal appears** (navigation prevented)
4. User chooses:
   - **Cancel** → Resume game
   - **Exit** → Forfeit with 1,999,999ms

### Scenario 3b: User types URL in address bar

1. User starts game run
2. User types new URL in address bar and presses Enter
3. **Browser shows native "Leave site?" dialog** (cannot be customized - browser security)
4. If user clicks **Stay**:
   - Stays on game page, can continue playing
5. If user clicks **Leave**:
   - Navigates to new page
   - When/if they return to game, **auto-forfeit** triggers
   - Redirected to My Games with 1,999,999ms score

### Scenario 4: User completes game normally

1. User starts game run
2. User clicks all 25 numbers
3. Completion screen shows
4. **No warnings or restrictions** - user can freely navigate anywhere

## Design Decisions

### Why 1,999,999ms instead of 1,999,999ms (maximum)?

**Answer:** While 1,999,999ms is the maximum valid score, we chose 1,999,999ms because:
- It's still a very poor score that won't win
- It's clearly distinguishable in the leaderboard
- It signals "forfeit" rather than "timeout"
- Leaves room for actual 10-minute timeouts to use 1,999,999ms

### Why pause on tab switch?

**Answer:** Tab switching may be accidental or legitimate:
- User might need to check something quickly
- User might get an urgent notification
- Timer pause prevents unfair time penalties
- Modal reminds them of consequences before deciding

### Why use both beforeunload and visibilitychange?

**Answer:** Different browsers handle navigation differently:
- `beforeunload` - Catches refresh, back button, close window
- `visibilitychange` - Catches tab switches, window minimize
- Together they provide comprehensive coverage

## Technical Implementation Details

### How Auto-Forfeit on Refresh Works

1. **Before leaving:** When `beforeunload` fires, we set a flag in `localStorage`:
   ```javascript
   localStorage.setItem(`game_run_${gameRunId}_in_progress`, 'true')
   ```

2. **On return:** When page loads again, we check for this flag:
   ```javascript
   if (localStorage.getItem(abandonmentKey) === 'true') {
     // Auto-forfeit and redirect
     this.autoForfeitAbandoned()
   }
   ```

3. **Clean up:** The flag is removed when:
   - Game completes successfully
   - User explicitly forfeits
   - Auto-forfeit executes

### Why localStorage?

- Persists across page refreshes
- Specific to this game run ID
- Survives browser close/reopen
- Automatically cleaned up

## Security Considerations

### Can users bypass this?

**Possible bypass attempts:**
1. **Disable JavaScript** - Game won't load at all (requires JS)
2. **Clear localStorage before refresh** - Still shows native dialog, user knows consequences
3. **Browser DevTools** - Could potentially manipulate state, but:
   - Server validates all submissions
   - Grid layout is server-generated (deterministic seed)
   - Click sequence and timestamps are validated
   - Anti-cheat detects impossible patterns
4. **Multiple browser tabs** - Each tab has independent localStorage, works correctly

### Additional protections already in place

From [`GAME_MECHANICS.md`](GAME_MECHANICS.md):
- Server-side validation of click sequence
- Timestamp validation (must be sequential)
- Minimum average click interval (0.3s prevents bots)
- Pattern uniformity detection (standard deviation check)
- Deterministic grid layout (seed-based, not predictable)

## Testing Checklist

- [ ] Refresh page during game → Browser warning appears
- [ ] Click "Stay" on warning → Game continues normally
- [ ] Click "Leave" on warning → Game is forfeited (1,999,999ms score)
- [ ] Switch tabs during game → Modal appears when returning
- [ ] Click "Cancel" on modal → Timer resumes, game continues
- [ ] Click "Exit" on modal → Game forfeited (1,999,999ms score)
- [ ] Complete game normally → No warnings, can navigate freely
- [ ] Back button during game → Browser warning appears
- [ ] Close window during game → Browser warning appears
- [ ] Score shows 1,999,999ms in leaderboard for forfeited games
- [ ] Cannot replay forfeited game runs
- [ ] Mobile: Modal displays correctly
- [ ] Mobile: Buttons are large enough to tap

## Future Enhancements

### Optional improvements:
1. **Grace period** - Allow 1-2 tab switches before showing modal
2. **Warning countdown** - Show 5-second countdown before auto-forfeit
3. **Analytics** - Track forfeit rate to identify UX issues
4. **Customizable penalties** - Different scores for different quit methods

## Compliance with Requirements

✅ **Requirement:** If user refreshes or goes back, pause timer and show warning
✅ **Requirement:** Black screen overlay that obscures the game
✅ **Requirement:** Warning message about forfeit consequences
✅ **Requirement:** Cannot retry the game run
✅ **Requirement:** Cancel button resumes game
✅ **Requirement:** Exit button marks as played with score of 1,999,999ms

---

**Implementation Date:** December 9, 2025
**Status:** ✅ Complete
**Tested:** Pending user testing
