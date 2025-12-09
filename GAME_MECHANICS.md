# Number Sequence Memory Game - Game Mechanics

## Overview

The Number Sequence Memory Game is a competitive skill-based mini-game where players race against time to click numbers 1-25 in sequential order on a 5×5 grid.

**Quick Stats:**
- **Grid Size:** 5×5 (25 numbers)
- **Objective:** Click numbers 1→2→3...→25 in order
- **Scoring:** Time in milliseconds (lower is better)
- **Time Limit:** 10 minutes (600,000ms)
- **Valid Range:** 10,000ms - 600,000ms

---

## Game Flow

### 1. Memorization Phase (3 seconds)

When a player starts a game run:

```
┌─────────────────────────────────┐
│         Get Ready!              │
│                                 │
│  Click the numbers in order:    │
│  1 → 2 → 3 → ... → 25          │
│                                 │
│       Starting in               │
│           3                     │
└─────────────────────────────────┘
```

- 3-second countdown displayed
- Instructions shown: "Click the numbers in order: 1 → 2 → 3 → ... → 25"
- Grid is not yet visible
- Purpose: Prepare player for game start

### 2. Active Gameplay

Grid appears with numbers 1-25 randomly positioned:

```
┌─────────────────────────────────┐
│ Time: 5.2s  Progress: 8/25  Next: 9 │
├─────────────────────────────────┤
│  [ 15 ] [ 3  ] [ 22 ] [ 9  ] [ 11 ] │
│  [ 7  ] [ 19 ] [ 1  ] [ 25 ] [ 14 ] │
│  [ 4  ] [ 12 ] [ 18 ] [ 6  ] [ 2  ] │
│  [ 20 ] [ 8  ] [ 5  ] [ 16 ] [ 10 ] │
│  [ 24 ] [ 17 ] [ 21 ] [ 13 ] [ 23 ] │
└─────────────────────────────────┘
```

**Header Information:**
- **Timer:** Real-time elapsed time (updates every 100ms)
- **Progress:** Current completion (e.g., "8/25")
- **Next:** Next number to click (e.g., "9")

**Click Feedback:**

✅ **Correct Click:**
- Green flash animation (0.4s)
- Cell becomes highlighted and disabled
- Number remains visible but grayed out
- Progress increments
- "Next" indicator updates

❌ **Incorrect Click:**
- Red flash animation (0.5s)
- Shake animation (horizontal wobble)
- Cell remains clickable
- No progress change
- Auditory feedback (optional future feature)

### 3. Completion Screen

After clicking the 25th number:

```
┌─────────────────────────────────┐
│      🏆 NEW RECORD!             │
│                                 │
│   Time         Score            │
│   15.2s        15234ms          │
│                                 │
│  You're #1! Amazing performance!│
│                                 │
│     🏆 Top 5 Leaderboard        │
│                                 │
│  🥇 playerA (You)    15234ms   │
│  🥈 playerB          16789ms   │
│  🥉 playerC          18456ms   │
│  #4 playerD          20123ms   │
│  #5 playerE          22567ms   │
│                                 │
│    Submitting score...          │
└─────────────────────────────────┘
```

**Personalized Messages:**
- **Rank #1:** "🏆 NEW RECORD! You're #1! Amazing performance!" (gold color)
- **Rank #2-5:** "🎉 Great Job! You ranked #X in the top 5!"
- **Outside Top 5:** "✅ Complete! Try again to beat the top scores!"

**Leaderboard Features:**
- Shows top 5 scores for current session
- Current player highlighted in blue
- Medal emojis for top 3 (🥇🥈🥉)
- Rank numbers for #4 and #5
- "(You)" indicator next to username
- Real-time ranking based on predicted final placement

**Auto-Submit:**
- 3-second delay before submission
- Allows player to see their results
- Prevents accidental navigation away

---

## Scoring System

### Score Calculation

**Formula:** `score = time_taken_milliseconds`

**Examples:**
```
12.5 seconds  = 12,500ms (excellent)
15.0 seconds  = 15,000ms (very good)
20.3 seconds  = 20,300ms (good)
30.7 seconds  = 30,700ms (average)
45.2 seconds  = 45,200ms (needs practice)
600+ seconds  = 600,000ms (timeout/maximum penalty)
```

### Valid Score Ranges

| Category | Time Range | Milliseconds | Status |
|----------|-----------|--------------|--------|
| **World-Class** | < 12s | < 12,000ms | Elite performance |
| **Excellent** | 12-15s | 12,000-15,000ms | Very fast |
| **Very Good** | 15-20s | 15,000-20,000ms | Above average |
| **Good** | 20-30s | 20,000-30,000ms | Solid performance |
| **Average** | 30-60s | 30,000-60,000ms | Typical completion |
| **Slow** | 60-300s | 60,000-300,000ms | Needs improvement |
| **Very Slow** | 300-600s | 300,000-600,000ms | Near timeout |
| **Timeout** | > 600s | 600,000ms | Maximum penalty |

### Anti-Cheat Validation

**Minimum Time Threshold:** 10 seconds (10,000ms)
- Reasoning: 25 clicks in < 10s = 0.4s per click (superhuman)
- Rejection: "Completion time impossibly fast"

**Maximum Time Limit:** 10 minutes (600,000ms)
- Automatic timeout after 10 minutes
- Score capped at 600,000ms
- Alert shown: "Time limit exceeded (10 minutes). Game will be scored as 0."

**Average Click Speed:** Minimum 0.3s per click
- Total time / 25 clicks >= 0.3s
- Prevents automated bot play
- Rejection: "Click speed impossibly fast"

**Timestamp Validation:**
- Timestamps must be monotonically increasing
- Each click must occur after the previous
- Rejection: "Timestamps must be sequential"

**Pattern Uniformity Detection:**
- Calculates standard deviation of click intervals
- Human players have natural variance (std dev > 50ms)
- Too uniform = likely scripted bot
- Rejection: "Suspicious click pattern detected"

---

## Grid Generation

### Deterministic Randomization

Each GameRun has a unique `seed` (32-character hex string):

```ruby
# Example seed
seed = "a1b2c3d4e5f6789012345678901234ab"

# Seed converted to integer for Random.new
random = Random.new(seed.to_i(16))

# Positions 0-24 shuffled deterministically
positions = (0..24).to_a.shuffle(random: random)

# Map numbers to grid coordinates
grid_layout = {
  1  => [0, 0],  # Number 1 at row 0, col 0
  2  => [1, 3],  # Number 2 at row 1, col 3
  3  => [0, 1],  # Number 3 at row 0, col 1
  # ... 22 more mappings
  25 => [4, 4]   # Number 25 at row 4, col 4
}
```

**Benefits:**
- **Same seed = same layout** (reproducible for verification)
- **Different seed = different layout** (prevents memorization)
- **Server-controlled** (client cannot manipulate grid)
- **Audit trail** (grid layout stored in metadata)

### Grid Representation

**Backend (Ruby):**
```ruby
{
  1 => [0, 0],   # row, col
  2 => [1, 3],
  # ...
  25 => [4, 4]
}
```

**Frontend (JavaScript):**
```javascript
{
  "1": [0, 0],   // Rendered at position (0,0)
  "2": [1, 3],   // Rendered at position (1,3)
  // ...
  "25": [4, 4]
}
```

**CSS Grid Layout:**
```css
.number-grid {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  grid-template-rows: repeat(5, 1fr);
  gap: var(--space-3);
  aspect-ratio: 1;
}
```

---

## Data Storage

### GameRun Fields

```ruby
# app/models/game_run.rb
{
  id: 123,
  user_id: 456,
  game_session_id: 789,
  spot_purchase_id: 321,
  seed: "a1b2c3d4e5f6789012345678901234ab",
  score: 15234,  # milliseconds
  completed_at: "2025-01-15T10:30:15Z",
  result_metadata: {
    time_taken_seconds: 15.234,
    click_sequence: [1, 2, 3, 4, ..., 25],
    click_timestamps: [582.3, 1204.7, 1689.2, ..., 15234.1],
    grid_layout: {
      "1": [0, 0],
      "2": [1, 3],
      # ... all 25 mappings
    },
    started_at: "2025-01-15T10:30:00Z",
    played_at: "2025-01-15T10:30:15Z",
    client_seed: "a1b2c3d4e5f6789012345678901234ab"
  }
}
```

### Metadata Fields Explained

| Field | Type | Purpose | Example |
|-------|------|---------|---------|
| `time_taken_seconds` | Float | Human-readable time | `15.234` |
| `click_sequence` | Array<Integer> | Verify correct order | `[1,2,3,...,25]` |
| `click_timestamps` | Array<Float> | Detect cheating patterns | `[582.3, 1204.7, ...]` |
| `grid_layout` | Hash | Reproduce exact grid | `{"1": [0,0], ...}` |
| `started_at` | ISO8601 | Game start time | `"2025-01-15T10:30:00Z"` |
| `played_at` | ISO8601 | Completion time | `"2025-01-15T10:30:15Z"` |
| `client_seed` | String | Seed used for grid | `"a1b2c3d4..."` |

---

## Winner Determination

### Finding the Winner

When a game session completes:

```ruby
# app/services/game_completion_service.rb

# 1. Forfeit unplayed runs
unplayed_runs.update_all(
  score: 600_000,  # Maximum penalty
  completed_at: Time.current,
  result_metadata: { forfeited: true, reason: "Unplayed within time window" }
)

# 2. Find winner (LOWEST score)
winning_run = @game_session.game_runs
  .order(score: :asc)  # Ascending - lowest first
  .first

# 3. Award prize
CreditLedgerService.new(
  user: winning_run.user,
  amount: @game_session.expected_award_in_credits,
  description: "Prize for #{@game_session.name}",
  category: "game_prize"
).call
```

**Key Points:**
- **Lowest score wins** (fastest time)
- Forfeited runs get maximum penalty (600,000ms)
- Ties are impossible due to millisecond precision
- Winner receives full prize pool
- Transaction recorded in credit ledger

---

## Leaderboard System

### Top 5 Display

**Backend Query:**
```ruby
# app/controllers/game_runs_controller.rb
@leaderboard = @game_session.game_runs
  .played
  .where.not(score: nil)
  .order(score: :asc)  # Lower is better
  .limit(5)
  .includes(:user)
  .map { |run| { username: run.user.username, score: run.score } }
```

**Frontend Rendering:**
```javascript
// app/javascript/controllers/number_sequence_game_controller.js
renderLeaderboard(top5, currentUser, currentScore) {
  top5.forEach((entry, index) => {
    const rank = index + 1
    const isCurrentUser = (entry.username === currentUser && entry.score === currentScore)

    // Render with medal emojis, highlighting, etc.
  })
}
```

### Rank Messages

```javascript
if (userRank === 1) {
  title = "🏆 NEW RECORD!"
  message = "You're #1! Amazing performance!"
  color = "gold"
} else if (userRank > 0 && userRank <= 5) {
  title = "🎉 Great Job!"
  message = `You ranked #${userRank} in the top 5!`
} else {
  title = "✅ Complete!"
  message = "Try again to beat the top scores!"
}
```

---

## Security Measures

### Validation Pipeline

```ruby
# app/services/number_sequence_game_service.rb

def detect_cheating(time_seconds, click_count, timestamps)
  # Check 1: Too fast (< 10 seconds)
  return "Completion time impossibly fast" if time_seconds < 10.0

  # Check 2: Wrong click count
  return "Invalid click count (expected 25)" unless click_count == 25

  # Check 3: Timestamps sequential
  return "Timestamps must be sequential" unless sequential?(timestamps)

  # Check 4: Average click speed
  avg_interval = time_seconds / 25.0
  return "Click speed impossibly fast" if avg_interval < 0.3

  # Check 5: Pattern uniformity
  intervals = timestamps.each_cons(2).map { |a, b| b - a }
  std_dev = calculate_std_dev(intervals)
  return "Suspicious click pattern detected" if std_dev < 50

  nil  # No cheating detected
end
```

### Standard Deviation Analysis

**Purpose:** Detect bots with uniform click intervals

**Human Behavior:**
- Natural variance in reaction time
- Some clicks faster, some slower
- Standard deviation typically > 100ms

**Bot Behavior:**
- Perfectly uniform intervals (e.g., exactly 500ms each)
- Very low standard deviation (< 50ms)
- Suspicious and rejected

**Example:**
```ruby
# Human player (natural variance)
intervals = [623, 489, 701, 534, 612, 578, ...]
std_dev = 87.3  # PASS (> 50)

# Bot (too uniform)
intervals = [500, 500, 500, 500, 500, ...]
std_dev = 0.0  # FAIL (< 50) - rejected
```

---

## Technical Stack

### Backend

- **Language:** Ruby 3.1.3
- **Framework:** Rails 8.0
- **Database:** PostgreSQL (JSONB for metadata)
- **Service:** `NumberSequenceGameService` (game logic & validation)
- **Controller:** `GameRunsController#show` & `#complete`
- **Model:** `GameRun` (with `play!` method)

### Frontend

- **JavaScript Framework:** Stimulus (Hotwire)
- **Controller:** `NumberSequenceGameController`
- **Styling:** CSS custom properties (design tokens)
- **Animation:** CSS keyframes (flash-correct, flash-incorrect, shake)
- **Timer:** `performance.now()` for high-precision timing

### Data Flow

```
1. User clicks "Play Now"
   ↓
2. GameRunsController#show
   ↓
3. Generate grid layout (deterministic seed)
   ↓
4. Render view with Stimulus controller
   ↓
5. JavaScript: Memorization countdown
   ↓
6. JavaScript: Render grid, start timer
   ↓
7. User clicks cells (validation client-side)
   ↓
8. Completion: Show leaderboard
   ↓
9. Submit to GameRunsController#complete
   ↓
10. Server validation (sequence, timestamps, cheating)
    ↓
11. Save score + metadata
    ↓
12. Redirect to next run or "My Games"
```

---

## Future Enhancements

### Potential Features

1. **Difficulty Levels**
   - 3×3 grid (9 numbers) - Easy
   - 4×4 grid (16 numbers) - Medium
   - 5×5 grid (25 numbers) - Hard
   - 6×6 grid (36 numbers) - Expert

2. **Power-Ups**
   - Time freeze (pause timer for 3 seconds)
   - Hint button (highlight next number location)
   - Remove half (hide 12-13 random numbers)

3. **Sound Effects**
   - Click sound for correct answers
   - Error sound for incorrect clicks
   - Victory fanfare on completion

4. **Practice Mode**
   - Free play without using credits
   - Track personal best times
   - No leaderboard or prizes

5. **Global Leaderboards**
   - All-time fastest times
   - Daily/weekly/monthly rankings
   - User profiles with statistics

6. **Accessibility**
   - Keyboard navigation (arrow keys + space/enter)
   - Screen reader support
   - High contrast mode
   - Colorblind-friendly themes

7. **Mobile Optimization**
   - Larger tap targets (60px+)
   - Swipe gestures
   - Haptic feedback

---

## Testing Checklist

### Functional Tests

- [ ] Memorization countdown displays correctly
- [ ] Grid renders with correct numbers
- [ ] Same seed produces identical grid
- [ ] Timer starts on game begin
- [ ] Correct click shows green flash
- [ ] Incorrect click shows red shake
- [ ] Progress indicator updates
- [ ] Completion screen appears after 25th click
- [ ] Leaderboard shows top 5 correctly
- [ ] Current user highlighted in leaderboard
- [ ] Personalized message based on rank
- [ ] Score submits after 3 seconds
- [ ] Redirects to next run or "My Games"

### Security Tests

- [ ] Server rejects time < 10 seconds
- [ ] Server rejects time > 600 seconds
- [ ] Server rejects invalid click sequence
- [ ] Server rejects non-sequential timestamps
- [ ] Server rejects too-uniform patterns
- [ ] Cannot replay completed GameRun
- [ ] Grid layout matches server-provided seed

### Edge Cases

- [ ] Browser refresh during game
- [ ] Network failure during submission
- [ ] Multiple tabs open simultaneously
- [ ] Mobile device orientation change
- [ ] Slow internet connection
- [ ] Timeout at exactly 600 seconds

---

## Performance Targets

### Expected Performance

| Metric | Target | Rationale |
|--------|--------|-----------|
| **Page Load** | < 1s | Fast game start |
| **Grid Render** | < 100ms | Instant visual feedback |
| **Click Response** | < 50ms | Smooth animations |
| **Timer Update** | 100ms | Precise time tracking |
| **Score Submit** | < 2s | Quick transition |

### Optimization Strategies

1. **Client-side score calculation** (mirrors server)
2. **Minimal DOM manipulation** (grid rendered once)
3. **CSS animations** (hardware-accelerated)
4. **Debounced click handlers** (prevent double-clicks)
5. **Efficient leaderboard rendering** (virtual scrolling if > 5)

---

## Conclusion

The Number Sequence Memory Game combines skill, speed, and memory in a fair and engaging competitive format. With millisecond-precision scoring, robust anti-cheat measures, and real-time leaderboards, it creates an exciting and equitable gaming experience for all players.

**Key Strengths:**
- ✅ Skill-based (no luck involved)
- ✅ Fair (deterministic grid prevents exploits)
- ✅ Competitive (millisecond precision, no ties)
- ✅ Secure (multi-layer validation)
- ✅ Engaging (instant feedback, leaderboards)
- ✅ Auditable (full metadata trail)
