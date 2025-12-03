# Service object for managing user credit wallet operations.
#
# This service provides safe, transactional operations for manipulating user credits:
# - Adding credits (e.g., after successful Bitcoin payment)
# - Locking credits (e.g., when starting a game or activity)
# - Unlocking credits (e.g., when canceling an activity)
# - Deducting credits (e.g., when consuming credits for gameplay)
#
# All operations are wrapped in database transactions to ensure atomicity.
# The service maintains a distinction between total credits and locked credits:
# - Total credits: All credits owned by the user
# - Locked credits: Credits temporarily reserved (cannot be spent elsewhere)
# - Available credits: total_credits - locked_credits (can be spent or locked)
#
# Typical credit lifecycle:
# 1. User pays for credits → add_credits (increases total_credits)
# 2. User starts game → lock_credits (increases locked_credits)
# 3. Game ends → deduct_credits (decreases both locked and total)
# 4. Game canceled → unlock_credits (decreases locked_credits only)
#
# @example Adding credits after payment
#   service = CreditWalletService.new(user)
#   service.add_credits(100, source: btc_transaction)
#   # User's total_credits increases by 100
#
# @example Locking credits for gameplay
#   service = CreditWalletService.new(user)
#   service.lock_credits(10)
#   # User's locked_credits increases by 10, available credits decreases by 10
#
# @example Deducting credits after game completion
#   service = CreditWalletService.new(user)
#   service.deduct_credits(10)
#   # User's locked_credits and total_credits both decrease by 10
#
# @example Handling insufficient credits
#   service = CreditWalletService.new(user)
#   service.lock_credits(1000) # => false
#   service.errors # => ["Insufficient available credits"]
#
class CreditWalletService
  # Raised when attempting operations with insufficient credits.
  class InsufficientCreditsError < StandardError; end

  # @return [UserCreditWallet] the user's credit wallet
  attr_reader :wallet

  # @return [Array<String>] array of error messages if operations fail
  attr_reader :errors

  # Initialize the credit wallet service for a user.
  #
  # @param user [User] the user whose wallet to manage
  def initialize(user)
    @user = user
    @wallet = user.user_credit_wallet || user.build_user_credit_wallet
    @errors = []
  end

  # Add credits to the user's wallet.
  #
  # Increases the total_credits balance. This is typically called after
  # a successful Bitcoin payment or as an admin action.
  #
  # @param amount [Integer] the number of credits to add (must be > 0)
  # @param source [Object, nil] optional source reference (e.g., BtcTransaction)
  # @return [Boolean] true if credits were added successfully, false otherwise
  #
  # @example After successful payment
  #   service.add_credits(100, source: transaction)
  #   # wallet.total_credits increases by 100
  def add_credits(amount, source: nil)
    return false unless valid_amount?(amount)

    ActiveRecord::Base.transaction do
      @wallet.total_credits += amount

      unless @wallet.save
        @errors.concat(@wallet.errors.full_messages)
        raise ActiveRecord::Rollback
      end
    end

    # Broadcast wallet update after successful commit
    broadcast_wallet_update if success?

    success?
  end

  # Lock credits for temporary use.
  #
  # Increases locked_credits, making them unavailable for other activities.
  # Fails if the user doesn't have enough available (unlocked) credits.
  #
  # @param amount [Integer] the number of credits to lock (must be > 0)
  # @return [Boolean] true if credits were locked successfully, false otherwise
  #
  # @example Starting a game that costs 10 credits
  #   service.lock_credits(10)
  #   # wallet.locked_credits increases by 10
  def lock_credits(amount)
    return false unless valid_amount?(amount)

    ActiveRecord::Base.transaction do
      available_credits = @wallet.total_credits - @wallet.locked_credits

      if available_credits < amount
        @errors << "Insufficient available credits"
        raise ActiveRecord::Rollback
      end

      @wallet.locked_credits += amount

      unless @wallet.save
        @errors.concat(@wallet.errors.full_messages)
        raise ActiveRecord::Rollback
      end
    end

    success?
  end

  # Unlock previously locked credits.
  #
  # Decreases locked_credits, making them available again.
  # This is typically used when canceling an activity or refunding credits.
  # Fails if trying to unlock more credits than are currently locked.
  #
  # @param amount [Integer] the number of credits to unlock (must be > 0)
  # @return [Boolean] true if credits were unlocked successfully, false otherwise
  #
  # @example Canceling a game
  #   service.unlock_credits(10)
  #   # wallet.locked_credits decreases by 10
  def unlock_credits(amount)
    return false unless valid_amount?(amount)

    ActiveRecord::Base.transaction do
      if @wallet.locked_credits < amount
        @errors << "Cannot unlock more credits than currently locked"
        raise ActiveRecord::Rollback
      end

      @wallet.locked_credits -= amount

      unless @wallet.save
        @errors.concat(@wallet.errors.full_messages)
        raise ActiveRecord::Rollback
      end
    end

    success?
  end

  # Deduct credits from the wallet after consumption.
  #
  # Decreases both locked_credits and total_credits by the specified amount.
  # This represents actual consumption of credits (e.g., completing a game).
  # The credits must already be locked before deduction.
  #
  # @param amount [Integer] the number of credits to deduct (must be > 0)
  # @return [Boolean] true if credits were deducted successfully, false otherwise
  #
  # @example Completing a game that consumed 10 locked credits
  #   service.deduct_credits(10)
  #   # wallet.locked_credits decreases by 10
  #   # wallet.total_credits decreases by 10
  def deduct_credits(amount)
    return false unless valid_amount?(amount)

    ActiveRecord::Base.transaction do
      if @wallet.locked_credits < amount
        @errors << "Cannot deduct more than locked credits"
        raise ActiveRecord::Rollback
      end

      @wallet.locked_credits -= amount
      @wallet.total_credits -= amount

      unless @wallet.save
        @errors.concat(@wallet.errors.full_messages)
        raise ActiveRecord::Rollback
      end
    end

    success?
  end

  # Calculate the number of available (unlocked) credits.
  #
  # @return [Integer] the number of credits available for use
  #
  # @example
  #   # If total_credits = 100 and locked_credits = 25
  #   service.available_credits # => 75
  def available_credits
    @wallet.total_credits - @wallet.locked_credits
  end

  # Check if the last operation was successful.
  #
  # @return [Boolean] true if no errors, false otherwise
  def success?
    @errors.empty?
  end

  private

  # Validate that the amount is valid (positive and non-nil).
  #
  # @param amount [Integer, nil] the amount to validate
  # @return [Boolean] true if valid, false otherwise
  def valid_amount?(amount)
    if amount.nil? || amount <= 0
      @errors << "Amount must be greater than zero"
      return false
    end
    true
  end

  # Broadcast wallet balance update
  # Uses Turbo::StreamsChannel for compatibility with turbo_stream_from helper
  def broadcast_wallet_update
    # Eager load wallet to prevent N+1
    @user.reload # Ensure we have fresh data
    wallet = @user.user_credit_wallet
    user_id = @user.id

    # Calculate available credits (helper logic inline to avoid context issues)
    available_credits = wallet.total_credits - wallet.locked_credits
    has_locked = wallet.locked_credits > 0

    Turbo::StreamsChannel.broadcast_render_to(
      @user,
      inline: <<~ERB,
        <%= turbo_stream.replace "navbar-wallet-#{user_id}" do %>
          <div id="navbar-wallet-#{user_id}" class="credit-badge">
            <strong><%= available_credits %></strong>
            <span>credits</span>
          </div>
        <% end %>
        <%= turbo_stream.replace "wallet-card-#{user_id}" do %>
          <div id="wallet-card-#{user_id}" class="wallet-card">
            <p class="wallet-header">Your Current Balance</p>
            <p class="wallet-amount">
              <%= available_credits %>
              <span class="wallet-amount-label">available credits</span>
            </p>
            <% if has_locked %>
              <p class="wallet-locked">
                (<%= locked_credits %> credits locked)
              </p>
            <% end %>
          </div>
        <% end %>
        <%= turbo_stream.replace "user-wallet-#{user_id}" do %>
          <div id="user-wallet-#{user_id}" class="wallet-card flex items-center justify-between">
            <div>
              <p class="wallet-header">Available Credits</p>
              <p class="wallet-amount">
                <%= available_credits %>
              </p>
            </div>
            <%= link_to "Buy More", credit_purchases_path, class: "btn btn-primary" %>
          </div>
        <% end %>
      ERB
      locals: { user_id: user_id, available_credits: available_credits, has_locked: has_locked, locked_credits: wallet.locked_credits }
    )

    Rails.logger.info "Broadcasted wallet update to user #{@user.id}"
  end
end
