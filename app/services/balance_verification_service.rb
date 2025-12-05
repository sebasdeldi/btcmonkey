# Service for verifying credit balance integrity.
#
# Provides tools to:
# - Verify individual user balances
# - Audit entire user base
# - Detect anomalies and fraud patterns
# - Generate reconciliation reports
#
# @example Verify single user
#   service = BalanceVerificationService.new(user)
#   if service.verify
#     puts "Balance OK"
#   else
#     puts "Balance mismatch: #{service.errors}"
#   end
#
# @example Audit all users
#   results = BalanceVerificationService.audit_all_users
#   puts "Mismatches: #{results[:mismatches].count}"
#
class BalanceVerificationService
  attr_reader :user, :errors

  def initialize(user)
    @user = user
    @errors = []
  end

  # Verify user's balance matches ledger
  def verify
    CreditLedgerService.verify_balance(@user)
    true
  rescue CreditLedgerService::BalanceMismatchError => e
    @errors << e.message
    false
  end

  # Perform deep audit by replaying entire ledger
  def audit
    result = CreditLedgerService.audit_balance(@user)

    unless result[:matches]
      @errors << "Balance mismatch: Expected #{result[:expected]}, got #{result[:actual]}"
    end

    result
  end

  # Get transaction summary for user
  def transaction_summary
    entries = @user.credit_ledger_entries

    {
      total_entries: entries.count,
      total_credits_added: entries.credits_added.sum(:amount),
      total_credits_spent: entries.credits_deducted.sum(:amount).abs,
      current_balance: @user.user_credit_wallet&.total_credits || 0,
      first_transaction: entries.chronological.first&.created_at,
      last_transaction: entries.recent_first.first&.created_at
    }
  end

  # Class methods for bulk operations

  class << self
    # Audit all users (use with caution - can be slow)
    def audit_all_users(limit: nil)
      users = User.includes(:user_credit_wallet, :credit_ledger_entries)
      users = users.limit(limit) if limit

      results = {
        total: 0,
        verified: 0,
        mismatches: [],
        errors: []
      }

      users.find_each do |user|
        results[:total] += 1

        service = new(user)
        if service.verify
          results[:verified] += 1
        else
          results[:mismatches] << {
            user_id: user.id,
            errors: service.errors
          }
        end
      rescue StandardError => e
        results[:errors] << {
          user_id: user.id,
          error: e.message
        }
      end

      results
    end

    # Find users with suspicious patterns
    def detect_anomalies(days: 7)
      cutoff = days.days.ago

      # Look for users with:
      # 1. Large number of transactions in short time
      # 2. Unusual spending patterns
      # 3. Failed balance verifications

      suspicious_users = []

      # High transaction volume
      high_volume = CreditLedgerEntry
        .where("created_at >= ?", cutoff)
        .group(:user_id)
        .having("COUNT(*) > ?", 50)
        .count

      high_volume.each do |user_id, count|
        suspicious_users << {
          user_id: user_id,
          reason: "High transaction volume",
          count: count
        }
      end

      # Users with balance mismatches
      User.includes(:user_credit_wallet, :credit_ledger_entries).find_each do |user|
        service = new(user)
        unless service.verify
          suspicious_users << {
            user_id: user.id,
            reason: "Balance mismatch",
            errors: service.errors
          }
        end
      end

      suspicious_users
    end
  end
end
