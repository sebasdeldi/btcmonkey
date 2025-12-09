# Game Mechanics Implementation Changelog

## Overview

This document tracks all changes made to implement the game run mechanics system in BTC Play.

## Features Implemented

### 1. Multiple Spot Purchases Per User
**Previous Behavior:** Users could only purchase 1 spot per game session.

**New Behavior:** Users can purchase multiple spots (1-10 per transaction) in the same game session.

**Changes:**
- Removed unique index on `spot_purchases(game_session_id, user_id)`
- Added `quantity` field to `SpotPurchase` model
- Updated `SpotPurchaseService` to support quantity parameter
- Added quantity selector UI in participate button partial
- Added dynamic cost calculator (JavaScript) in the UI

**Files Modified:**
- `db/migrate/20251208000002_remove_user_uniqueness_from_spot_purchases.rb`
- `app/models/spot_purchase.rb`
- `app/services/spot_purchase_service.rb`
- `app/views/game_sessions/_participate_button.html.erb`

---

### 2. Game Runs System
**Description:** Each purchased spot creates a playable GameRun instance with a random number mini-game.

**New Components:**
- **GameRun Model:** Tracks individual playable instances
  - `seed`: Random seed for determinism
  - `score`: Final score (0-100, null if unplayed)
  - `completed_at`: When the game was played
  - `result_metadata`: JSONB field for game-specific data

**Database Schema:**
```ruby
create_table :game_runs do |t|
  t.string :seed, null: false
  t.references :user, null: false, foreign_key: true
  t.references :game_session, null: false, foreign_key: true
  t.references :spot_purchase, null: false, foreign_key: true
  t.jsonb :result_metadata, default: {}
  t.integer :score
  t.datetime :completed_at
  t.timestamps
end
```

**Automatic GameRun Creation:**
- `SpotPurchase` has `after_create :create_game_runs` callback
- Creates N GameRuns for quantity=N

**Files Created:**
- `db/migrate/20251208000003_create_game_runs.rb`
- `app/models/game_run.rb`
- `app/controllers/game_runs_controller.rb`
- `app/views/game_runs/show.html.erb`
- `app/javascript/controllers/random_number_game_controller.js`

---

### 3. Number Sequence Memory Game ⭐ (v2.0.0 Update)
**Description:** Competitive skill-based game where users click numbers 1-25 in sequential order on a 5×5 grid as fast as possible.

**Game Features:**
- 5×5 grid with deterministic random positioning (seeded)
- 3-second memorization countdown phase
- Sequential clicking: 1 → 2 → 3 → ... → 25
- Real-time timer (millisecond precision)
- Visual feedback:
  - ✅ Correct: Green flash animation
  - ❌ Incorrect: Red flash + shake animation
- Progress indicator (e.g., "12/25")
- "Next" number display
- Completion screen with:
  - Final time and score (milliseconds)
  - Top 5 leaderboard
  - Personalized rank messages
  - Medal emojis (🥇🥈🥉)

**Scoring System:**
- Score = completion time in milliseconds
- Lower score = better (fastest time wins)
- Valid range: 10,000ms - 600,000ms
- Times under 10s rejected as impossible
- Times over 600s capped at maximum penalty

**Anti-Cheat Security:**
- Server-side click sequence validation
- Timestamp sequence validation
- Minimum average click interval (0.3s)
- Pattern uniformity detection (standard deviation check)
- Complete audit trail stored in result_metadata

**User Flow:**
1. 3-second memorization countdown
2. Grid appears with numbers 1-25 randomized
3. User clicks numbers in order
4. Timer tracks milliseconds
5. Completion screen shows time, score, leaderboard
6. Score auto-submitted after 3 seconds
7. Redirect to next run or "My Games" page

**Files Created:**
- `app/services/number_sequence_game_service.rb`
- `app/javascript/controllers/number_sequence_game_controller.js`
- `app/assets/stylesheets/components/number_game.css`
- `GAME_MECHANICS.md` (comprehensive documentation)

**Files Modified:**
- `app/models/game_run.rb` (updated score validation: 1-600,000)
- `app/controllers/game_runs_controller.rb` (added leaderboard, validation)
- `app/views/game_runs/show.html.erb` (new game interface)
- `app/javascript/controllers/index.js` (registered new controller)
- `README.md` (updated game mechanics section)

---

### 4. Game Completion System
**Description:** Automated system to complete game sessions, forfeit unplayed runs, select winners, and award prizes.

**New Components:**
- **GameCompletionService:** Orchestrates session completion
  - Forfeits unplayed runs (score = 600,000ms maximum penalty)
  - Selects winner (LOWEST score - fastest time)
  - Awards prize to winner's wallet
  - Records prize in credit ledger
  - Marks session as finished

**Validations (can be bypassed with `force: true`):**
- Session must be full (all spots sold)
- Completion deadline must be set
- Completion deadline must have been reached

**Force Mode:**
```ruby
# Normal mode (with validations)
service = GameCompletionService.new(game_session)

# Force mode (skip validations)
service = GameCompletionService.new(game_session, force: true)
```

**Files Created:**
- `app/services/game_completion_service.rb`
- `app/jobs/game_completion_job.rb`

---

### 5. Session Deadlines & Time Windows
**Description:** Automatic deadline management to ensure sessions complete in a timely manner.

**Time Windows:**
- **Play Window:** 2 hours from last spot purchased
- **Completion Deadline:** 2.5 hours from last spot purchased
- **Forfeit:** Unplayed runs after deadline are scored as 0

**Database Fields Added:**
- `game_sessions.completion_deadline` (datetime)
- `game_sessions.last_spot_purchased_at` (datetime)
- `game_sessions.winner_id` (foreign key to users)
- `game_sessions.winning_score` (integer)

**Files Modified:**
- `db/migrate/20251208000004_add_winner_to_game_sessions.rb`
- `app/models/game_session.rb` (added `set_completion_deadline!` method)
- `app/services/spot_purchase_service.rb` (calls deadline setter when full)

---

### 6. Resume Playing Feature
**Description:** Users can resume unplayed runs from multiple entry points.

**Entry Points:**
1. **Session Show Page:** Green banner with "Play Now" button if user has unplayed runs
2. **My Games Page:** Shows run counts and "Play Now" button
3. **After completing a run:** Auto-redirects to next unplayed run

**UI Indicators:**
- Unplayed run count badge
- Time remaining display
- Play window expiration warning

**Files Modified:**
- `app/controllers/game_sessions_controller.rb` (loads `@user_unplayed_runs`)
- `app/views/game_sessions/show.html.erb` (displays unplayed runs banner)
- `app/views/game_sessions/my_games.html.erb` (shows run status)

---

### 7. Rake Tasks for Manual Game Management
**Description:** Command-line tools for manually completing game sessions.

**Tasks Created:**

#### `game_sessions:complete[SESSION_ID]`
Complete a specific game session by ID.

```bash
# Normal mode
rails game_sessions:complete[42]

# Force mode (skip validations)
rails game_sessions:complete[42] FORCE=true
```

#### `game_sessions:complete_all`
Complete all eligible game sessions idempotently.

```bash
# Normal mode
rails game_sessions:complete_all

# Force mode
rails game_sessions:complete_all FORCE=true
```

#### `game_sessions:complete_expired`
Enqueue background jobs for expired sessions (for cron).

```bash
rails game_sessions:complete_expired
```

#### `game_sessions:stats`
Display comprehensive statistics about game sessions.

```bash
rails game_sessions:stats
```

**Files Created:**
- `lib/tasks/game_sessions.rake`

---

### 8. Transaction Safety & Error Handling
**Description:** All database operations are wrapped in transactions with proper error handling.

**Features:**
- Pessimistic locking on `GameSession` during spot purchase
- `begin/rescue` blocks around transactions
- Specific error handling for `ActiveRecord::RecordInvalid`
- Comprehensive logging of errors with backtraces
- Automatic rollback on any failure

**Example:**
```ruby
begin
  ActiveRecord::Base.transaction do
    @game_session = GameSession.lock.find(@game_session.id)
    deduct_credits
    create_spot_purchase
    record_in_ledger
    update_session_status
  end
rescue ActiveRecord::RecordInvalid => e
  @errors << "Failed to create game runs: #{e.message}"
  Rails.logger.error(...)
  return false
rescue StandardError => e
  @errors << "Purchase failed: #{e.message}"
  return false
end
```

**Files Modified:**
- `app/services/spot_purchase_service.rb`
- `app/services/game_completion_service.rb`

---

### 9. Credit Ledger Integration
**Description:** All game-related credit movements are automatically recorded in the ledger.

**Ledger Entries Created:**

**Spot Purchase (Debit):**
```ruby
CreditLedgerService.record_entry(
  user: user,
  movement_type: :debit_spot,
  amount: -30,
  source: spot_purchase,
  description: "Purchased 3 spot(s) in Win-100",
  metadata: {
    game_session_id: session.id,
    quantity: 3,
    price_per_spot: 10
  }
)
```

**Prize Award (Credit):**
```ruby
CreditLedgerService.record_entry(
  user: winner,
  movement_type: :prize,
  amount: 90,
  source: game_session,
  description: "Won Win-100 with score 94",
  metadata: {
    game_session_id: session.id,
    winning_score: 94,
    prize_type: "game_winner"
  }
)
```

**Files Modified:**
- `app/services/spot_purchase_service.rb` (records debit entries)
- `app/services/game_completion_service.rb` (records prize entries)

---

## Database Migrations

### Migration 1: Add max_users and completion_deadline
```ruby
add_column :game_sessions, :max_users, :integer, default: 10, null: false
add_column :game_sessions, :completion_deadline, :datetime
```

### Migration 2: Remove unique user constraint
```ruby
remove_index :spot_purchases, [:game_session_id, :user_id]
add_column :spot_purchases, :quantity, :integer, default: 1, null: false
```

### Migration 3: Create game_runs
```ruby
create_table :game_runs do |t|
  t.string :seed, null: false
  t.references :user, null: false
  t.references :game_session, null: false
  t.references :spot_purchase, null: false
  t.jsonb :result_metadata, default: {}
  t.integer :score
  t.datetime :completed_at
  t.timestamps
end
```

### Migration 4: Add winner tracking
```ruby
add_reference :game_sessions, :winner, foreign_key: { to_table: :users }
add_column :game_sessions, :winning_score, :integer
add_column :game_sessions, :last_spot_purchased_at, :datetime
```

---

## Session Lifecycle

```
┌─────────────┐
│   draft     │  Admin creates session
└──────┬──────┘
       │
       ↓
┌─────────────┐
│   active    │  Accepting spot purchases
└──────┬──────┘
       │ (last spot sold)
       ↓
┌─────────────┐
│    full     │  Set completion_deadline (2.5 hours)
└──────┬──────┘  Users have 2 hours to play
       │ (deadline reached)
       ↓
┌─────────────┐
│  finished   │  Winner selected, prize awarded
└─────────────┘
```

---

## Testing Recommendations

### Manual Testing Checklist

1. **Multiple Spot Purchases:**
   - [ ] Purchase 1 spot in a session
   - [ ] Purchase multiple spots (3) in the same session
   - [ ] Verify correct number of GameRuns created
   - [ ] Verify credits deducted correctly (quantity × price)

2. **Game Playing:**
   - [ ] Play a game run and verify score saved
   - [ ] Verify redirect to next unplayed run
   - [ ] Verify cannot replay a completed run
   - [ ] Verify time window display is accurate

3. **Resume Playing:**
   - [ ] Purchase spots and close browser
   - [ ] Return to session show page - verify "Play Now" banner
   - [ ] Navigate to My Games - verify unplayed runs shown
   - [ ] Complete all runs - verify banner disappears

4. **Game Completion:**
   - [ ] Complete session manually with `FORCE=true`
   - [ ] Verify unplayed runs forfeited (score = 0)
   - [ ] Verify winner selected correctly
   - [ ] Verify prize awarded and ledger entry created
   - [ ] Verify session marked as finished

5. **Validations:**
   - [ ] Try completing session before deadline - verify error
   - [ ] Try completing session that's not full - verify error
   - [ ] Use `FORCE=true` - verify validations bypassed

6. **Rake Tasks:**
   - [ ] Run `game_sessions:stats` - verify output
   - [ ] Run `game_sessions:complete[ID]` - verify completion
   - [ ] Run `game_sessions:complete_all` - verify batch processing

---

## Production Deployment Checklist

1. **Database Migrations:**
   - [ ] Run all migrations in staging environment
   - [ ] Verify no errors or data corruption
   - [ ] Run migrations in production

2. **Background Jobs:**
   - [ ] Ensure Sidekiq (or job processor) is running
   - [ ] Test `GameCompletionJob` in staging

3. **Cron Jobs:**
   - [ ] Set up cron job for `game_sessions:complete_expired`
   - [ ] Recommended: Every 5 minutes
   - [ ] Verify cron job runs and completes sessions

4. **Monitoring:**
   - [ ] Monitor `game_sessions.rake` output logs
   - [ ] Monitor error logs for transaction failures
   - [ ] Set up alerts for failed game completions

5. **Rollback Plan:**
   - [ ] Document rollback procedure
   - [ ] Test rollback in staging
   - [ ] Ensure database backups are current

---

## Known Issues & Future Enhancements

### Current Limitations
1. Only one game type implemented (random number generator)
2. No real-time leaderboard during active sessions
3. No notifications when sessions complete
4. No refund mechanism for unplayed runs

### Future Enhancements
1. Multiple game types (memory, reaction time, trivia)
2. Live leaderboards with WebSocket updates
3. Email/SMS notifications for session completion
4. Configurable time windows per game type
5. Tournament brackets for multi-round competitions
6. Team-based gameplay
7. Achievement system
8. Replay functionality with seed replay

---

## Documentation Updates

All documentation has been updated in:
- `README.md` - Comprehensive game mechanics section
- `README.md` - Updated rake tasks documentation
- `README.md` - Updated service documentation
- This file (`GAME_MECHANICS_CHANGELOG.md`)

---

## Contributors

Implementation completed with AI assistance from Claude (Anthropic).

---

## Version History

**v2.0.0** (2025-01-15)
- **BREAKING:** Replaced random number game with number sequence memory game
- Millisecond-based scoring system (10,000ms - 600,000ms)
- Interactive 5×5 grid with deterministic randomization
- 3-second memorization phase
- Real-time timer and progress tracking
- Visual feedback (green flash, red shake animations)
- Completion screen with leaderboard
- Top 5 leaderboard display per session
- Personalized rank messages (#1: "NEW RECORD!", #2-5: "Great Job!", Outside: "Try again!")
- Medal emojis for podium positions (🥇🥈🥉)
- Multi-layer anti-cheat validation:
  - Minimum time threshold (10s)
  - Maximum time limit (600s)
  - Sequential timestamp validation
  - Average click speed validation
  - Pattern uniformity detection (standard deviation)
- Complete audit trail in result_metadata:
  - click_sequence
  - click_timestamps
  - grid_layout
  - started_at
  - played_at
  - client_seed
- Service: NumberSequenceGameService (deterministic grid, validation, scoring)
- Controller: number_sequence_game_controller.js (Stimulus)
- Styling: number_game.css (responsive design)
- Updated winner selection: LOWEST score wins (fastest time)

**v1.0.0** (2024-12-08)
- Initial game mechanics implementation
- Multiple spot purchases
- GameRun system with random number game
- Session completion automation
- Resume playing feature
- Comprehensive rake tasks
- Full credit ledger integration
