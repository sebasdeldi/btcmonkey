# BTC Play

A Rails application that allows users to purchase credits using Bitcoin payments via BTCPay Server integration.

## Table of Contents

- [Getting Started](#getting-started)
- [Architecture](#architecture)
- [Design System](#design-system)
- [Services & Clients](#services--clients)
- [Credits Ledger System](#credits-ledger-system)
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
│   └── btc_pay_webhook_handler_service.rb
├── controllers/          # Rails controllers
├── models/               # ActiveRecord models
│   ├── user.rb
│   ├── user_credit_wallet.rb
│   ├── credit_ledger_entry.rb
│   ├── btc_transaction.rb
│   ├── spot_purchase.rb
│   └── ...
├── views/                # ERB templates
│   ├── components/       # Reusable UI components
│   └── ...
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

### Spot Purchase Flow

1. User clicks "Participate" → `SpotsController`
2. Controller calls → `SpotPurchaseService.call`
3. Service validates session availability and user credits
4. Service locks game session (pessimistic lock)
5. Service deducts credits from wallet
6. Service creates `SpotPurchase` record
7. **Service records ledger entry** (within same transaction)
8. Service updates session status if full
9. Service broadcasts real-time updates
10. User receives spot + ledger entry created

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

