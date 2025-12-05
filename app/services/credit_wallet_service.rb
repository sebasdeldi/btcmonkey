# Service object for managing user credit wallet operations.
#
# This service provides safe, transactional operations for manipulating user credits:
# - Adding credits (e.g., after successful Bitcoin payment)
#
# NOTE: The credit locking mechanism (lock_credits, unlock_credits, deduct_credits)
# has been deprecated and removed. Spot purchases now use direct credit deduction
# since they are instant, non-refundable transactions.
#
# All operations are wrapped in database transactions to ensure atomicity.
#
# Typical credit lifecycle:
# 1. User pays for credits → add_credits (increases total_credits)
# 2. User purchases spot → Direct deduction via SpotPurchaseService
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

  # DEPRECATED: Lock credits mechanism has been removed.
  # Spot purchases now use direct deduction since they are instant transactions.
  #
  # @deprecated Use direct wallet manipulation in SpotPurchaseService instead
  def lock_credits(amount)
    @errors << "DEPRECATED: lock_credits is no longer supported. Use direct deduction instead."
    false
  end

  # DEPRECATED: Unlock credits mechanism has been removed.
  # Spot purchases now use direct deduction since they are instant transactions.
  #
  # @deprecated Use direct wallet manipulation in SpotPurchaseService instead
  def unlock_credits(amount)
    @errors << "DEPRECATED: unlock_credits is no longer supported. Use direct deduction instead."
    false
  end

  # DEPRECATED: Deduct credits mechanism has been removed.
  # Spot purchases now use direct deduction since they are instant transactions.
  #
  # @deprecated Use direct wallet manipulation in SpotPurchaseService instead
  def deduct_credits(amount)
    @errors << "DEPRECATED: deduct_credits is no longer supported. Use direct deduction instead."
    false
  end

  # Calculate the number of available credits (now simply returns total_credits).
  #
  # @return [Integer] the number of credits available for use
  #
  # @example
  #   service.available_credits # => 100
  def available_credits
    @wallet.total_credits
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
    @user.reload # Ensure we have fresh data
    wallet = @user.user_credit_wallet

    Turbo::StreamsChannel.broadcast_render_to(
      @user,
      partial: 'credit_wallets/wallet_update',
      formats: [:turbo_stream],
      locals: {
        user_id: @user.id,
        wallet: wallet,
        available_credits: wallet.total_credits
      }
    )

    Rails.logger.info "Broadcasted wallet update to user #{@user.id}"
  end
end
