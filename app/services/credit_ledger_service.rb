# Central service for recording all credit movements in the ledger.
#
# This service provides the ONLY way to create ledger entries, ensuring:
# - Consistency: All entries follow the same patterns
# - Auditability: Complete tracking of all credit changes
# - Atomicity: Ledger entries created within same transaction as wallet updates
# - Balance integrity: Running balance is always accurate
#
# IMPORTANT: This service should ONLY be called from within an existing
# ActiveRecord::Base.transaction block that also updates the wallet.
#
# @example Recording a credit purchase
#   ActiveRecord::Base.transaction do
#     wallet.total_credits += amount
#     wallet.save!
#
#     CreditLedgerService.record_entry(
#       user: user,
#       movement_type: :purchase,
#       amount: amount,
#       source: btc_transaction,
#       description: "Bitcoin payment received",
#       ip_address: request.remote_ip
#     )
#   end
#
# @example Recording a spot purchase debit
#   ActiveRecord::Base.transaction do
#     wallet.total_credits -= amount
#     wallet.save!
#
#     CreditLedgerService.record_entry(
#       user: user,
#       movement_type: :debit_spot,
#       amount: -amount,
#       source: spot_purchase,
#       description: "Spot purchase in #{game_session.name}"
#     )
#   end
#
class CreditLedgerService
  # Custom error for balance mismatches
  class BalanceMismatchError < StandardError; end

  class << self
    # Record a credit ledger entry.
    #
    # @param user [User] the user whose credits changed
    # @param movement_type [Symbol] one of :purchase, :debit_spot, :refund, :admin_adjustment
    # @param amount [Integer] signed integer (positive for credits, negative for debits)
    # @param source [ActiveRecord::Base, nil] the source record (BtcTransaction, SpotPurchase, etc.)
    # @param description [String, nil] human-readable description
    # @param metadata [Hash] additional context (default: {})
    # @param ip_address [String, nil] IP address for fraud detection
    # @param admin_user [User, nil] admin performing adjustment (required for admin_adjustment)
    #
    # @return [CreditLedgerEntry] the created entry
    # @raise [ActiveRecord::RecordInvalid] if entry cannot be saved
    # @raise [BalanceMismatchError] if calculated balance doesn't match wallet
    #
    def record_entry(user:, movement_type:, amount:, source: nil, description: nil,
                     metadata: {}, ip_address: nil, admin_user: nil)

      # Must be called within a transaction
      unless ActiveRecord::Base.connection.transaction_open?
        raise "CreditLedgerService.record_entry must be called within a transaction"
      end

      # Reload user to get fresh wallet balance
      user.reload
      wallet = user.user_credit_wallet

      raise "User has no wallet" unless wallet

      # Calculate what balance should be after this entry
      # The wallet has already been updated by the calling code
      balance_after = wallet.total_credits

      # Verify balance integrity: previous balance + amount should equal new balance
      previous_entry = user.credit_ledger_entries.order(created_at: :desc).first
      if previous_entry
        expected_balance = previous_entry.balance_after + amount
        if expected_balance != balance_after
          raise BalanceMismatchError.new(
            "Balance mismatch detected. Previous: #{previous_entry.balance_after}, " \
            "Amount: #{amount}, Expected: #{expected_balance}, Actual: #{balance_after}"
          )
        end
      else
        # First entry - balance should equal amount
        if amount != balance_after
          raise BalanceMismatchError.new(
            "First ledger entry balance mismatch. Amount: #{amount}, Balance: #{balance_after}"
          )
        end
      end

      # Enrich metadata with source details
      enriched_metadata = metadata.merge(build_source_metadata(source))

      # Create the ledger entry
      entry = CreditLedgerEntry.create!(
        user: user,
        movement_type: movement_type,
        amount: amount,
        balance_after: balance_after,
        source: source,
        description: description,
        metadata: enriched_metadata,
        ip_address: ip_address,
        admin_user: admin_user
      )

      Rails.logger.info "Created ledger entry: user=#{user.id}, type=#{movement_type}, " \
                        "amount=#{amount}, balance=#{balance_after}"

      entry
    end

    # Verify that a user's wallet balance matches their ledger.
    #
    # @param user [User] the user to verify
    # @return [Boolean] true if balance matches
    # @raise [BalanceMismatchError] if balance doesn't match
    #
    def verify_balance(user)
      wallet = user.user_credit_wallet
      return true unless wallet # No wallet = no verification needed

      latest_entry = user.credit_ledger_entries.order(created_at: :desc).first

      if latest_entry.nil?
        # No ledger entries - balance should be zero or match initial state
        if wallet.total_credits != 0
          raise BalanceMismatchError.new(
            "Wallet has #{wallet.total_credits} credits but no ledger entries"
          )
        end
      else
        # Compare wallet balance to latest ledger entry
        if wallet.total_credits != latest_entry.balance_after
          raise BalanceMismatchError.new(
            "Wallet balance (#{wallet.total_credits}) doesn't match " \
            "latest ledger entry (#{latest_entry.balance_after})"
          )
        end
      end

      true
    end

    # Calculate expected balance by replaying entire ledger (slow but thorough).
    #
    # @param user [User] the user to verify
    # @return [Hash] { expected: Integer, actual: Integer, matches: Boolean }
    #
    def audit_balance(user)
      wallet = user.user_credit_wallet
      entries = user.credit_ledger_entries.chronological

      calculated_balance = 0
      entries.each do |entry|
        calculated_balance += entry.amount

        # Verify each entry's balance_after is correct
        if entry.balance_after != calculated_balance
          raise BalanceMismatchError.new(
            "Entry #{entry.id} has incorrect balance_after. " \
            "Expected: #{calculated_balance}, Actual: #{entry.balance_after}"
          )
        end
      end

      {
        expected: calculated_balance,
        actual: wallet&.total_credits || 0,
        matches: calculated_balance == (wallet&.total_credits || 0)
      }
    end

    private

    # Build metadata hash from source object
    def build_source_metadata(source)
      return {} unless source

      case source
      when BtcTransaction
        {
          source_type: "BtcTransaction",
          invoice_id: source.invoice_id,
          package_credits: source.credit_package.credits,
          btc_amount: source.received_btc.to_s
        }
      when SpotPurchase
        {
          source_type: "SpotPurchase",
          game_session_id: source.game_session_id,
          game_session_name: source.game_session.name,
          spot_number: source.spot_number
        }
      else
        {
          source_type: source.class.name,
          source_id: source.id
        }
      end
    end
  end
end
