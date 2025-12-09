# BTC Play

A Rails application that allows users to purchase credits using Bitcoin payments and participate in competitive mini-game sessions via BTCPay Server integration.

## Table of Contents

- [Getting Started](#getting-started)
- [Game Mechanics](#game-mechanics)
- [Architecture](#architecture)
- [Design System](#design-system)
- [Services & Clients](#services--clients)
- [Credits Ledger System](#credits-ledger-system)
- [Rake Tasks](#rake-tasks)
- [Development](#development)
- [Data Flow Examples](#data-flow-examples)

## Getting Started

### Prerequisites

- Ruby 3.1.3
- Rails 8.0
- PostgreSQL
- BTCPay Server instance (for Bitcoin payments)

### Installation

1. Clone the repository
```bash
git clone <repository-url>
cd btc-play
```

2. Install dependencies
```bash
bundle install
```

3. Setup database
```bash
rails db:create
rails db:migrate
rails db:seed
```

4. Configure environment variables
```bash
cp .env.example .env
```

Edit `.env` and set the following:
- `BTCPAY_SERVER_URL` - Your BTCPay Server instance URL
- `BTCPAY_API_KEY` - Your BTCPay Server API key
- `BTCPAY_STORE_ID` - Your BTCPay Server store ID
- `APP_HOST` - Your application host (for callbacks)

5. Start the server
```bash
rails server
```

## Game Mechanics

BTC Play features competitive mini-game sessions where users purchase spots using credits and compete for prize pools.

### Overview

Each game session is a competitive event where:
- Users purchase one or more spots (up to 10 per transaction)
- Each spot represents one playable game run
- Players compete by playing a number sequence memory game (click numbers 1-25 in order)
- The **lowest score (fastest time in milliseconds)** wins the entire prize pool
- Sessions complete 2.5 hours after the last spot is sold

### Core Models

**GameSession**: The competitive event container
- `max_spots`: Total spots available (e.g., 10)
- `price_in_credits`: Cost per spot (e.g., 10 credits)
- `expected_award_in_credits`: Prize pool for winner (e.g., 90 credits)
- `status`: `active` → `full` → `finished`
- `completion_deadline`: Set when session fills (2.5 hours from last spot sold)

**SpotPurchase**: Record of user purchasing spots
- `user_id`: Who bought the spots
- `game_session_id`: Which session
- `quantity`: How many spots purchased (1-10)
- `credits_spent`: Total credits deducted
- `spot_number`: Assigned spot number

**GameRun**: Individual playable instance
- `user_id`: Who plays this run
- `game_session_id`: Which session
- `spot_purchase_id`: Which purchase created this run
- `seed`: Random seed for deterministic grid generation
- `score`: Final score in milliseconds (10,000-600,000, null if unplayed, lower is better)
- `completed_at`: When the game was played
- `result_metadata`: JSONB storing game data (click sequence, timestamps, grid layout)

### User Journey

#### 1. Browse and Purchase
```
User visits /game_sessions
  → Sees available sessions (Win-100, Win-1000, etc.)
  → Clicks on session to view details
  → Selects quantity (1-10 spots)
  → Clicks "Buy Spots"
  → SpotPurchaseService deducts credits
  → Creates 1 SpotPurchase with quantity=3
  → Automatically creates 3 GameRun records (unplayed)
  → Redirects to first game run
```

#### 2. Play Game Runs
```
User redirected to /game_runs/:id
  → Sees "Number Sequence Memory Game" interface
  → 3-second memorization phase countdown
  → Game starts: 5×5 grid with numbers 1-25 in random positions
  → User clicks numbers in sequential order (1→2→3...→25)
  → Visual feedback: green flash for correct, red flash + shake for incorrect
  → Timer tracks completion time in milliseconds
  → After 25th click: completion screen shows time, score, and leaderboard
  → Score auto-submitted after 3 seconds
  → Score saved to GameRun with full audit trail
  → Redirects to next unplayed run OR "My Games" page
```

#### 3. Time Windows
- **Play Window**: 2 hours from last spot purchased to complete all runs
- **Completion Deadline**: 2.5 hours from last spot purchased
- **Forfeit**: Unplayed runs after deadline are scored as 0

#### 4. Winner Selection
```
When completion_deadline is reached:
  → GameCompletionService.call (via rake task or background job)
  → Forfeit unplayed runs (score = 600,000ms maximum penalty)
  → Find LOWEST score across all GameRuns (fastest time wins)
  → Award prize to winner's credit wallet
  → Record prize in credit ledger
  → Mark session as "finished"
```

### Number Sequence Memory Game

The competitive mini-game is a memory and reaction test where players click numbers 1-25 in sequential order as fast as possible.

#### Game Features

**Gameplay:**
- 5×5 grid with numbers 1-25 in randomized positions (deterministic per seed)
- 3-second memorization countdown before game starts
- Click numbers in order: 1 → 2 → 3 → ... → 25
- Real-time timer tracking milliseconds
- Visual feedback for correct (green flash) and incorrect (red flash + shake) clicks
- Progress indicator showing completion status (e.g., "12/25")

**Scoring System:**
- Score = completion time in milliseconds (lower is better)
- Valid range: 10,000ms (10 seconds) to 600,000ms (10 minutes)
- Times under 10 seconds are rejected as impossible
- Times over 10 minutes capped at 600,000ms
- Millisecond precision creates competitive leaderboards with no ties

**Completion Screen:**
- Shows final time and millisecond score
- Displays top 5 leaderboard for current session
- Personalized messages based on rank:
  - **#1:** "🏆 NEW RECORD! You're #1! Amazing performance!"
  - **#2-5:** "🎉 Great Job! You ranked #X in the top 5!"
  - **Outside Top 5:** "✅ Complete! Try again to beat the top scores!"
- Medal emojis for podium (🥇🥈🥉)
- Current user highlighted in blue

**Security & Anti-Cheat:**
- Server-side validation of click sequence
- Timestamp validation (must be sequential)
- Minimum average click interval (0.3s prevents superhuman speeds)
- Pattern uniformity detection (standard deviation check)
- Full audit trail in `result_metadata` JSONB field
- Deterministic grid layout prevents memorization exploits

**Audit Trail (result_metadata):**
```json
{
  "time_taken_seconds": 15.234,
  "click_sequence": [1, 2, 3, ..., 25],
  "click_timestamps": [582.3, 1204.7, ...],
  "grid_layout": {"1": [0, 0], "2": [1, 3], ...},
  "started_at": "2025-01-15T10:30:00Z",
  "played_at": "2025-01-15T10:30:15Z",
  "client_seed": "a1b2c3d4..."
}
```

### Code Examples

#### Purchasing Multiple Spots
```ruby
# Controller
def create
  service = SpotPurchaseService.new(
    user: current_user,
    game_session: @game_session,
    quantity: 3  # Buy 3 spots
  )

  if service.call
    # Success - 3 GameRuns created
    redirect_to game_run_path(service.spot_purchase.game_runs.first)
  else
    # Error handling
    flash[:alert] = service.errors.join(", ")
  end
end
```

#### Playing a Game Run
```ruby
# GameRun model
class GameRun < ApplicationRecord
  def play!(score_value)
    raise "Game already played" if played?

    update!(
      score: score_value,
      completed_at: Time.current,
      result_metadata: {
        played_at: Time.current.iso8601,
        client_seed: seed
      }
    )
  end
end

# Controller
def complete
  score = params[:score].to_i
  @game_run.play!(score)

  redirect_to next_run_or_my_games_path
end
```

#### Completing a Session
```ruby
# GameCompletionService
service = GameCompletionService.new(game_session)

if service.call
  # 1. Forfeited unplayed runs (score = 0)
  # 2. Calculated winner (highest score)
  # 3. Awarded prize to winner
  # 4. Marked session as finished
  puts "Winner: #{game_session.winner.username}"
  puts "Score: #{game_session.winning_score}"
else
  puts "Errors: #{service.errors.join(', ')}"
end
```

### Session Lifecycle

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

### Resume Playing Feature

If a user closes their browser or navigates away, they can resume:

**From Session Show Page:**
```erb
<% if @user_unplayed_runs.any? %>
  <div class="alert alert-success">
    You have <%= @user_unplayed_runs.count %> unplayed runs!
    <%= link_to "Play Now", game_run_path(@user_unplayed_runs.first) %>
  </div>
<% end %>
```

**From My Games Page:**
```erb
<% unplayed_count = user_runs.unplayed.count %>
<% if unplayed_count > 0 %>
  <%= link_to "Play Now", game_run_path(user_runs.unplayed.first),
              class: "btn btn-primary" %>
<% end %>
```

### Transaction Safety

All database operations use pessimistic locking and transactions:

```ruby
ActiveRecord::Base.transaction do
  # Lock session to prevent race conditions
  @game_session = GameSession.lock.find(@game_session.id)

  # Deduct credits
  wallet.update!(total_credits: wallet.total_credits - total_cost)

  # Create spot purchase
  @spot_purchase = @game_session.spot_purchases.create!(...)

  # Record in ledger
  CreditLedgerService.record_entry(...)

  # Update session status if full
  @game_session.update!(status: "full") if @game_session.spots_remaining <= 0
end
```

If any step fails, the entire transaction rolls back - ensuring no partial purchases or credit loss.

### Integration with Credit Ledger

Every game-related credit movement is recorded:

**Spot Purchase (Debit):**
```ruby
CreditLedgerService.record_entry(
  user: user,
  movement_type: :debit_spot,
  amount: -30,  # Negative for debit
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
  movement_type: :purchase,  # Using purchase for credit addition
  amount: 90,  # Positive for credit
  source: game_session,
  description: "Won Win-100 with score 94",
  metadata: {
    game_session_id: session.id,
    winning_score: 94,
    prize_type: "game_winner"
  }
)
```

This provides complete audit trail of all game-related credits.

## Architecture

### Directory Structure


```
app/
├── clients/              # External API clients
│   └── btc_pay_server_client.rb
├── services/             # Business logic services
│   ├── user_registration_service.rb
│   ├── credit_purchase_service.rb
│   ├── credit_wallet_service.rb
│   ├── credit_ledger_service.rb
│   ├── balance_verification_service.rb
│   ├── spot_purchase_service.rb
│   ├── game_completion_service.rb
│   └── btc_pay_webhook_handler_service.rb
├── jobs/                 # Background jobs
│   └── game_completion_job.rb
├── controllers/          # Rails controllers
│   ├── game_sessions_controller.rb
│   ├── game_runs_controller.rb
│   ├── spots_controller.rb
│   └── ...
├── models/               # ActiveRecord models
│   ├── user.rb
│   ├── user_credit_wallet.rb
│   ├── credit_ledger_entry.rb
│   ├── btc_transaction.rb
│   ├── game_session.rb
│   ├── spot_purchase.rb
│   ├── game_run.rb
│   └── ...
├── views/                # ERB templates
│   ├── game_sessions/
│   │   ├── index.html.erb
│   │   ├── show.html.erb
│   │   ├── my_games.html.erb
│   │   ├── _participate_button.html.erb
│   │   └── _progress_bar.html.erb
│   ├── game_runs/
│   │   └── show.html.erb
│   ├── components/       # Reusable UI components
│   └── ...
├── javascript/
│   └── controllers/
│       ├── random_number_game_controller.js
│       └── ...
├── helpers/              # View helpers
│   └── components_helper.rb
└── assets/
    └── stylesheets/      # Modular CSS
        ├── design_tokens.css
        ├── components/
        └── layout/
```

### Architecture Layers

**Clients** (`app/clients/`):
- Handle communication with external services
- Manage API authentication and requests
- Parse and transform API responses
- Example: `BtcPayServerClient`

**Services** (`app/services/`):
- Encapsulate business logic
- Orchestrate complex operations
- Manage database transactions
- Example: `CreditPurchaseService`

**Controllers**:
- Handle HTTP requests
- Call services for business logic
- Render views or redirect

**Models**:
- Represent database tables
- Define validations and associations
- Core domain objects

**Views**:
- Render HTML templates
- Use reusable components
- Follow design system

**Helpers**:
- Extract view logic from templates
- Component rendering logic

## Design System

[DESIGN_SYSTEM_README.md](DESIGN_SYSTEM_README.md)

### Design Tokens

156 CSS custom properties defined in `design_tokens.css`:
- **Colors**: Navy (#1a2332), Blue (#3b82f6), White
- **Spacing**: 4px base unit system
- **Typography**: Font sizes, weights, line heights
- **Shadows**: Multiple shadow levels
- **Borders**: Radius values

### Component CSS

Modular CSS files in `app/assets/stylesheets/components/`:
- `buttons.css` - Button styles
- `cards.css` - Card components
- `forms.css` - Form inputs
- `badges.css` - Badge and status components
- `navigation.css` - Navigation bar
- `alerts.css` - Alert messages
- And more...

### Layout CSS

Layout files in `app/assets/stylesheets/layout/`:
- `base.css` - Reset and typography
- `containers.css` - Container widths
- `grid.css` - Grid systems
- `utilities.css` - Utility classes

### Using Components

Components are reusable partials in `app/views/components/`:

```erb
<%# Button component %>
<%= render 'components/button',
    text: 'Buy Now',
    variant: 'primary',
    url: credit_purchases_path %>

<%# Card component %>
<%= render 'components/card',
    title: 'Package Name',
    variant: 'primary' do %>
  Card content here
<% end %>

<%# Form field component %>
<%= render 'components/form_field',
    form: f,
    field: :email,
    type: 'email' %>

<%# Status badge %>
<%= render 'components/status_badge',
    status: transaction.status %>
```

All view logic is extracted to helpers in `ComponentsHelper`:
- `button_classes()` - Generate button CSS classes
- `badge_classes()` - Generate badge CSS classes
- `available_credits()` - Calculate available credits
- And more...

## Services & Clients

### Clients (`app/clients/`)

Clients handle external API communication.

#### BtcPayServerClient

Integrates with BTCPay Server API for Bitcoin payments.

**Creating an invoice:**
```ruby
client = BtcPayServerClient.new
invoice = client.create_invoice(
  amount_usd: 19.00,
  order_id: 123,
  buyer_email: 'user@example.com'
)
# => { invoice_id: "abc123", btc_address: "bc1q...", expected_btc: 0.0005, checkout_link: "..." }
```

**Retrieving invoice status:**
```ruby
invoice = client.get_invoice("abc123")
# => { status: "Settled", btc_address: "bc1q...", received_btc: 0.0005 }
```

**Error handling:**
- `BtcPayServerClient::Error` - Configuration errors
- `BtcPayServerClient::ApiError` - API errors

### Services (`app/services/`)

Services encapsulate business logic and orchestrate operations.

#### UserRegistrationService

Handles user registration with automatic wallet creation.

```ruby
service = UserRegistrationService.new(
  email: 'user@example.com',
  username: 'player123',
  password: 'secure_password',
  password_confirmation: 'secure_password'
)

if service.call
  user = service.user
  # Registration successful
else
  errors = service.errors
  # Handle errors
end
```

#### CreditPurchaseService

Orchestrates the complete credit purchase flow.

```ruby
service = CreditPurchaseService.new(
  user: current_user,
  credit_package: CreditPackage.find(1)
)

if service.call
  redirect_to service.checkout_link
else
  flash[:alert] = service.errors.join(", ")
end
```

#### CreditWalletService

Manages all credit wallet operations.

```ruby
service = CreditWalletService.new(user)

# Add credits after payment (automatically records in ledger)
service.add_credits(100, source: transaction)
```

#### CreditLedgerService

Central service for recording all credit movements in the ledger.

```ruby
# Records are created automatically by CreditWalletService and SpotPurchaseService
# Manual recording (within a transaction):
CreditLedgerService.record_entry(
  user: user,
  movement_type: :purchase,
  amount: 100,
  source: btc_transaction,
  description: "Bitcoin payment received"
)

# Verify user's balance matches ledger
CreditLedgerService.verify_balance(user) # => true/raises error

# Deep audit by replaying ledger
result = CreditLedgerService.audit_balance(user)
# => { expected: 100, actual: 100, matches: true }
```

#### SpotPurchaseService

Handles purchasing spots in game sessions with full transaction safety.

```ruby
service = SpotPurchaseService.new(
  user: current_user,
  game_session: game_session,
  quantity: 3  # Purchase 3 spots
)

if service.call
  spot_purchase = service.spot_purchase
  # Credits deducted, spot purchased, GameRuns created
  # Ledger entry recorded, session updated if full
else
  errors = service.errors
  # Handle errors (insufficient credits, session full, etc.)
end
```

Features:
- Pessimistic locking to prevent race conditions
- Automatic GameRun creation (one per spot purchased)
- Credit ledger integration
- Session status updates when full
- Sets completion deadline when last spot sold

#### GameCompletionService

Completes game sessions by forfeiting unplayed runs, selecting winner, and awarding prize.

```ruby
# Normal usage (with validations)
service = GameCompletionService.new(game_session)

if service.call
  winner = game_session.winner
  score = game_session.winning_score
  # Unplayed runs forfeited (score = 0)
  # Winner selected (highest score)
  # Prize awarded and recorded in ledger
  # Session marked as finished
else
  errors = service.errors
  # May include: "Session is not full", "No completion deadline set",
  # "Completion deadline not reached"
end

# Force mode (skip validations)
service = GameCompletionService.new(game_session, force: true)
service.call  # Will complete regardless of status or deadline
```

**Validations:**
- Session must be full (all spots sold)
- Completion deadline must be set
- Completion deadline must have been reached

**Force mode:** Pass `force: true` to skip all validations (useful for testing or manual intervention).

This service is typically called by:
- Background job: `GameCompletionJob.perform_later(session.id)`
- Rake task: `rails game_sessions:complete[SESSION_ID]` (with optional `FORCE=true`)
- Scheduled task: `rails game_sessions:complete_expired` (cron)

#### BalanceVerificationService

Verifies credit balance integrity and detects fraud.

```ruby
# Verify single user
service = BalanceVerificationService.new(user)
service.verify # => true/false

# Get transaction summary
summary = service.transaction_summary
# => { total_entries: 5, total_credits_added: 200, total_credits_spent: 50, ... }

# Audit all users (use with caution)
results = BalanceVerificationService.audit_all_users
# => { total: 100, verified: 98, mismatches: 2, errors: 0 }

# Detect anomalies
anomalies = BalanceVerificationService.detect_anomalies(days: 7)
# => [{ user_id: 123, reason: "High transaction volume", count: 52 }, ...]
```

#### BtcPayWebhookHandlerService

Processes webhook notifications from BTCPay Server.

```ruby
service = BtcPayWebhookHandlerService.new(webhook_payload)

if service.call
  # Webhook processed successfully
else
  errors = service.errors
  # Log errors
end
```

Use a tunneling service (Recommended for Development)
- Install ngrok (if not already installed):
```$ brew install ngrok/ngrok/ngrok```
- Start your Rails server:
```$ rails server``` or ```$ bin/dev```
- Start ngrok in another terminal:
```$ ngrok http 3000```

Update your BTCPay webhook URL:
- ngrok will give you a URL like https://abc123.ngrok.io
- Go to your BTCPay Server: https://pay.btcmonkey.io/
- Navigate to Store Settings → Webhooks
- Update the webhook URL to: https://abc123.ngrok.io/webhooks/btcpay
Note: The ngrok URL changes each time you restart it (unless you have a paid plan). You'll need to update the webhook URL in BTCPay Server each time.

### Service Pattern

All services follow a consistent pattern:

```ruby
class MyService
  attr_reader :errors

  def initialize(params)
    @params = params
    @errors = []
  end

  def call
    # Validate inputs
    # Execute business logic
    # Use database transactions if needed
    success?
  end

  def success?
    @errors.empty?
  end

  private
  # Implementation details
end
```

### Adding New Clients

1. Create `app/clients/{service_name}_client.rb`
2. Define custom error classes
3. Handle configuration and authentication
4. Document all public methods
5. Return consistent data structures (hashes)

Example:
```ruby
class ExternalServiceClient
  class Error < StandardError; end
  class ApiError < Error; end

  def initialize
    validate_configuration!
  end

  def fetch_data(params)
    # Make API call
    # Handle response
    # Return data
  rescue => e
    raise ApiError, "Failed: #{e.message}"
  end
end
```

### Adding New Services

1. Create `app/services/{operation}_service.rb`
2. Follow standard pattern (initialize, call, success?)
3. Use `ActiveRecord::Base.transaction` for database operations
4. Collect errors in `@errors` array
5. Document with examples

Example:
```ruby
class MyOperationService
  attr_reader :result, :errors

  def initialize(params)
    @params = params
    @errors = []
  end

  def call
    ActiveRecord::Base.transaction do
      validate_inputs
      perform_operation
    end
    success?
  end

  def success?
    @errors.empty?
  end
end
```

## Credits Ledger System

The application maintains a complete, immutable audit trail of all credit movements through the `credit_ledger_entries` table.

### Overview

Every credit transaction (purchases, spot debits, refunds) is automatically recorded in the ledger, providing:
- **Full Auditability**: Complete transaction history for each user
- **Anti-Fraud Detection**: Identify suspicious patterns and anomalies
- **Debugging Clarity**: Trace any balance issue to specific transactions
- **Immutability**: Entries can never be modified or deleted

### Ledger Structure

Each ledger entry contains:
- **user_id**: User who performed the transaction
- **movement_type**: Type of transaction (purchase, debit_spot, refund, admin_adjustment)
- **amount**: Signed integer (positive for credits added, negative for debits)
- **balance_after**: Snapshot of balance after this transaction
- **source**: Polymorphic link to source record (BtcTransaction, SpotPurchase, etc.)
- **metadata**: JSON field with transaction details
- **description**: Human-readable description
- **ip_address**: For fraud detection
- **admin_user_id**: For admin adjustments

### Movement Types

| Type | Amount Sign | Description | Source |
|------|-------------|-------------|--------|
| `purchase` | Positive | Credits bought via Bitcoin | BtcTransaction |
| `debit_spot` | Negative | Credits spent on game spots | SpotPurchase |
| `refund` | Positive | Credits returned | Varies |
| `admin_adjustment` | Either | Manual correction | None |

### Automatic Recording

Credit movements are automatically recorded by:
- **CreditWalletService**: Records `purchase` entries when credits are added
- **SpotPurchaseService**: Records `debit_spot` entries when spots are purchased

### Rake Tasks

```bash
# Verify all user balances match their ledger
rails credit_ledger:verify_all

# Verify a specific user's balance
rails credit_ledger:verify_user USER_ID=123

# Detect suspicious activity patterns
rails credit_ledger:detect_anomalies DAYS=7

# One-time backfill from existing data (use with caution)
rails credit_ledger:backfill
```

### Balance Verification

```ruby
# Quick verification (O(1))
CreditLedgerService.verify_balance(user)
# => true or raises BalanceMismatchError

# Deep audit (O(n) - replays entire ledger)
result = CreditLedgerService.audit_balance(user)
# => { expected: 100, actual: 100, matches: true }
```

### Fraud Detection

```ruby
# Detect high transaction volume
anomalies = BalanceVerificationService.detect_anomalies(days: 7)
# Returns users with suspicious patterns:
# - High transaction volume (>50 in period)
# - Balance mismatches
```

### Data Flow

1. **Bitcoin Payment**:
   - User pays → BTCPay webhook → BtcPayWebhookHandlerService
   - Calls CreditWalletService.add_credits → Records `purchase` entry
   - Ledger entry links to BtcTransaction as source

2. **Spot Purchase**:
   - User buys spot → SpotPurchaseService.call
   - Deducts credits → Creates SpotPurchase → Records `debit_spot` entry
   - Ledger entry links to SpotPurchase as source

### Key Features

- **Immutable**: Entries use `before_update` and `before_destroy` hooks to prevent modification
- **Balance Snapshots**: Each entry stores `balance_after` for O(1) verification
- **Transaction Safety**: Ledger entries created within same database transaction as wallet updates
- **Rollback Protection**: If ledger recording fails, entire transaction rolls back
- **Metadata Tracking**: Stores rich context (invoice IDs, game session details, etc.)

## Rake Tasks

The application includes several rake tasks for manual operations and scheduled maintenance.

### Game Session Management

#### Complete a Specific Game Session
```bash
rails game_sessions:complete[SESSION_ID]

# Example:
rails game_sessions:complete[42]

# Force completion (skip validations):
rails game_sessions:complete[42] FORCE=true
```

Manually complete a specific game session by ID. This will:
- Forfeit all unplayed game runs (score = 0)
- Calculate winner (highest score)
- Award prize to winner's wallet
- Record prize in credit ledger
- Mark session as finished

Provides detailed output including:
- Session status and details
- Total runs (played vs unplayed)
- Winner information
- Any errors encountered

**Validations (can be bypassed with FORCE=true):**
- Session must be full (all spots sold)
- Completion deadline must be set
- Completion deadline must have been reached

**Use case:** Manually complete a session for testing or when needed.

#### Complete All Eligible Sessions
```bash
rails game_sessions:complete_all

# Force completion (skip validations):
rails game_sessions:complete_all FORCE=true
```

Idempotently complete all game sessions that have reached their completion deadline. This task:
- Finds all "full" sessions past their deadline
- Completes each session using GameCompletionService
- Shows summary of results (successful, already finished, failed)

**Validations (can be bypassed with FORCE=true):**
- Session must be full (all spots sold)
- Completion deadline must be set
- Completion deadline must have been reached

**Use case:** One-time cleanup or manual batch processing.

#### Complete Expired Sessions (For Cron)
```bash
rails game_sessions:complete_expired
```

Enqueue background jobs to complete sessions past their deadline. This is the **recommended approach for scheduled tasks**:
- Finds eligible sessions
- Enqueues GameCompletionJob for each
- Jobs run asynchronously in background

**Use case:** Add to crontab to run every 5-10 minutes:
```bash
*/5 * * * * cd /path/to/app && rails game_sessions:complete_expired RAILS_ENV=production
```

#### Display Session Statistics
```bash
rails game_sessions:stats
```

Show comprehensive statistics about game sessions:
- Total sessions by status (active, full, finished)
- Sessions awaiting completion
- Recent activity (last 24 hours)
- User participation stats

**Use case:** Monitoring and analytics.

### Credit Ledger Management

#### Verify All User Balances
```bash
rails credit_ledger:verify_all
```

Verify that all user credit wallets match their ledger entries. Shows:
- Total users verified
- Number of mismatches found
- Details of any discrepancies

**Use case:** Regular integrity checks, debugging balance issues.

#### Verify Specific User
```bash
rails credit_ledger:verify_user USER_ID=123
```

Verify a specific user's credit balance matches their ledger. Shows:
- Expected balance (from ledger)
- Actual balance (from wallet)
- Whether they match
- All ledger entries if mismatch found

**Use case:** Investigate specific user balance issues.

#### Detect Anomalies
```bash
rails credit_ledger:detect_anomalies DAYS=7
```

Detect suspicious activity patterns in the specified time period:
- High transaction volume (>50 transactions)
- Balance mismatches
- Unusual patterns

**Use case:** Fraud detection, monitoring user behavior.

#### Backfill Ledger Entries
```bash
rails credit_ledger:backfill
```

**⚠️ Use with extreme caution!** One-time operation to create ledger entries from existing transactions.

This task should only be run:
- Once during initial ledger system deployment
- Never in production with real data
- Only after thorough testing

**Use case:** Initial migration to ledger system.

### Recommended Cron Schedule

For production environments, add these to your crontab:

```bash
# Complete expired game sessions every 5 minutes
*/5 * * * * cd /app && rails game_sessions:complete_expired RAILS_ENV=production

# Verify credit balances daily at 3 AM
0 3 * * * cd /app && rails credit_ledger:verify_all RAILS_ENV=production

# Detect anomalies daily at 4 AM
0 4 * * * cd /app && rails credit_ledger:detect_anomalies DAYS=1 RAILS_ENV=production

# Generate stats daily at 5 AM
0 5 * * * cd /app && rails game_sessions:stats RAILS_ENV=production
```

## Development

### Running Tests

```bash
rails test
```

### Code Style

- Follow Rails conventions
- No logic in views (use helpers)
- Services for business logic
- Clients for external APIs
- Transaction safety for multi-step operations
- Consistent error handling

### Database Migrations

```bash
rails generate migration MigrationName
rails db:migrate
```

### Creating Components

1. Create view partial in `app/views/components/_component_name.html.erb`
2. Add matching CSS in `app/assets/stylesheets/components/component_name.css`
3. Add helper methods in `app/helpers/components_helper.rb` if needed
4. Document usage in this README

### Design System Guidelines

1. Use design tokens for all colors, spacing, and typography
2. Create component-specific CSS files
3. Use utility classes for common patterns
4. Follow 4px spacing system
5. Mobile-first responsive design

### Key Principles

1. **Separation of Concerns**: Clients handle APIs, services handle business logic
2. **Transaction Safety**: Wrap database operations in transactions
3. **Error Collection**: Return errors clearly to callers
4. **Documentation**: Document public methods
5. **Testing**: Test all services and clients
6. **Rails Best Practices**: Fat models, skinny controllers, service objects

## Data Flow Examples

### Credit Purchase Flow

1. User selects package → `CreditPurchasesController`
2. Controller calls → `CreditPurchaseService`
3. Service validates package is active
4. Service creates `BtcTransaction` (pending)
5. Service calls → `BtcPayServerClient.create_invoice`
6. Client makes API request → BTCPay Server
7. Client returns invoice details
8. Service updates transaction with invoice data
9. Service returns checkout link
10. Controller redirects user to BTCPay checkout
11. User pays Bitcoin
12. BTCPay sends webhook → `BtcPayWebhooksController`
13. Controller calls → `BtcPayWebhookHandlerService`
14. Service calls → `BtcPayServerClient.get_invoice`
15. Service updates transaction status
16. Service calls → `CreditWalletService.add_credits`
17. **Wallet service records ledger entry** (within same transaction)
18. User receives credits + ledger entry created

### Spot Purchase and Game Run Flow

1. User selects quantity (3 spots) → `SpotsController#create`
2. Controller calls → `SpotPurchaseService.new(user, session, quantity: 3)`
3. Service validates:
   - Session is active and accepting purchases
   - Session has >= 3 spots remaining
   - User has sufficient credits (price × 3)
4. Within transaction:
   - Acquire pessimistic lock on game_session
   - Deduct credits from wallet (price × 3)
   - Create SpotPurchase record (quantity: 3, credits_spent: 30)
   - **After-create callback creates 3 GameRun records** (unplayed)
   - Record ledger entry (debit_spot, amount: -30)
   - Update session status to "full" if last spot sold
   - **Set completion_deadline (2.5 hours from now)** if full
5. Redirect user → `/game_runs/:id` (first unplayed run)
6. User plays random number game:
   - Clicks "Generate Number"
   - JavaScript animates (0-100)
   - Auto-submits score after 1.5 seconds
   - GameRun.play!(score) saves score and completed_at
7. Redirect to next unplayed run OR "My Games" page
8. User plays remaining runs (or resumes later)
9. When completion_deadline reached:
   - Rake task or cron job runs
   - GameCompletionService.call:
     - Forfeit unplayed runs (score = 0)
     - Find highest score
     - Award prize to winner
     - Record ledger entry (purchase, amount: +90)
     - Mark session as finished

### Ledger Recording (Automatic)

All credit movements are automatically recorded:

**On Credit Addition**:
```
CreditWalletService.add_credits
  → Updates wallet.total_credits
  → CreditLedgerService.record_entry (movement_type: purchase)
  → Creates immutable ledger entry with balance snapshot
```

**On Spot Purchase**:
```
SpotPurchaseService.call
  → Updates wallet.total_credits
  → Creates SpotPurchase
  → CreditLedgerService.record_entry (movement_type: debit_spot)
  → Creates immutable ledger entry with balance snapshot
```

