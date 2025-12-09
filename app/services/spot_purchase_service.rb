# Service object for purchasing a spot in a game session using credits.
#
# This service handles the complete spot purchase flow:
# 1. Validates game session is accepting purchases
# 2. Checks user has sufficient credits
# 3. Deducts credits from user's wallet (immediately, no locking)
# 4. Creates spot purchase record with assigned spot number
# 5. Updates game session status if all spots are sold
# 6. Automatically creates new identical session when last spot sold
#
# Race condition protection:
# - Uses database transaction with pessimistic locking on game_session
# - Database unique constraint on [game_session_id, spot_number] prevents duplicates
# - Database unique constraint on [game_session_id, user_id] prevents duplicate user purchases
#
# All operations are wrapped in a database transaction to ensure atomicity.
# If any step fails, the entire operation is rolled back.
#
# @example Successful spot purchase
#   service = SpotPurchaseService.new(
#     user: current_user,
#     game_session: session
#   )
#
#   if service.call
#     spot_purchase = service.spot_purchase
#     # User's credits deducted, spot assigned
#   else
#     service.errors # => ["Insufficient credits"]
#   end
#
# @example Failed purchase (insufficient credits)
#   # User has 5 credits, session costs 10
#   service = SpotPurchaseService.new(user: user, game_session: session)
#   service.call # => false
#   service.errors # => ["Insufficient available credits"]
#
# @example Failed purchase (session full)
#   service = SpotPurchaseService.new(user: user, game_session: full_session)
#   service.call # => false
#   service.errors # => ["Game session has no available spots"]
#
class SpotPurchaseService
  # @return [SpotPurchase, nil] the created spot purchase if successful
  attr_reader :spot_purchase

  # @return [Array<String>] array of error messages if purchase fails
  attr_reader :errors

  # Initialize the spot purchase service.
  #
  # @param user [User] the user purchasing the spot
  # @param game_session [GameSession] the session to purchase a spot in
  # @param quantity [Integer] number of spots to purchase (default: 1)
  def initialize(user:, game_session:, quantity: 1)
    @user = user
    @game_session = game_session
    @quantity = quantity
    @errors = []
  end

  # Execute the spot purchase process.
  #
  # Performs validations, deducts credits, creates spot purchase, creates game runs,
  # and updates game session status if needed. All within a database transaction.
  #
  # @return [Boolean] true if purchase succeeds, false otherwise
  def call
    validate_purchase
    return false unless @errors.empty?

    begin
      ActiveRecord::Base.transaction do
        # Lock the game session to prevent race conditions
        @game_session = GameSession.lock.find(@game_session.id)

        # Re-validate after acquiring lock (another transaction may have changed state)
        validate_session_availability
        return false unless @errors.empty?

        deduct_credits
        create_spot_purchase_without_broadcast
        record_spot_debit_in_ledger
        update_session_status_if_full
      end
    rescue ActiveRecord::RecordInvalid => e
      @errors << "Failed to create game runs: #{e.message}"
      Rails.logger.error("SpotPurchaseService transaction failed: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      return false
    rescue StandardError => e
      @errors << "Purchase failed: #{e.message}"
      Rails.logger.error("SpotPurchaseService unexpected error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      return false
    end

    success?
  end

  # Check if the purchase was successful.
  #
  # @return [Boolean] true if no errors and spot purchase is persisted
  def success?
    @errors.empty? && @spot_purchase&.persisted?
  end

  private

  # Validate that the purchase can proceed.
  #
  # Checks:
  # - Game session is active and accepting purchases
  # - User hasn't already purchased a spot in this session
  # - User has sufficient credits
  #
  # @return [void]
  def validate_purchase
    validate_session_availability
    validate_user_eligibility
    validate_sufficient_credits
  end

  # Validate game session is available for purchase.
  #
  # @return [void]
  def validate_session_availability
    unless @game_session.active?
      @errors << "Game session is not active"
    end

    unless @game_session.spots_remaining >= @quantity
      @errors << "Not enough spots available. Only #{@game_session.spots_remaining} remaining."
    end
  end

  # Validate user hasn't already purchased in this session.
  # REMOVED: Now users can purchase multiple spots
  #
  # @return [void]
  def validate_user_eligibility
    # Users can now purchase unlimited spots - no validation needed
    if @quantity <= 0
      @errors << "Quantity must be greater than 0"
    end

    # TODO: Make this dynamic
    if @quantity > 10
      @errors << "Cannot purchase more than 10 spots at once"
    end
  end

  # Validate user has sufficient credits for purchase.
  #
  # @return [void]
  def validate_sufficient_credits
    wallet = @user.user_credit_wallet
    total_cost = @game_session.price_in_credits * @quantity

    if wallet.nil? || wallet.total_credits < total_cost
      @errors << "Insufficient credits. You need #{total_cost} credits but have #{wallet&.total_credits || 0}."
    end
  end

  # Deduct credits from user's wallet.
  #
  # Per requirements: "Deduct credits immediately (no locking mechanism)"
  # Directly reduces total_credits without using lock/unlock cycle.
  #
  # @return [void]
  # @raise [ActiveRecord::Rollback] if credit deduction fails
  def deduct_credits
    wallet = @user.user_credit_wallet
    total_cost = @game_session.price_in_credits * @quantity

    new_total = wallet.total_credits - total_cost

    if new_total < 0
      @errors << "Insufficient credits for purchase"
      raise ActiveRecord::Rollback
    end

    wallet.total_credits = new_total

    unless wallet.save
      @errors.concat(wallet.errors.full_messages)
      raise ActiveRecord::Rollback
    end

    # Store pending ledger data (will be recorded after spot_purchase is created)
    @pending_ledger_recording = {
      amount: -total_cost,
      description: "Purchased #{@quantity} spot(s) in #{@game_session.name}"
    }
  end

  # Create the spot purchase record without broadcasting.
  #
  # Assigns the next sequential spot number and records the credits spent.
  # Broadcasts are handled separately after transaction commit.
  #
  # @return [void]
  # @raise [ActiveRecord::Rollback] if spot purchase creation fails
  def create_spot_purchase_without_broadcast
    total_cost = @game_session.price_in_credits * @quantity

    @spot_purchase = @user.spot_purchases.build(
      game_session: @game_session,
      credits_spent: total_cost,
      spot_number: @game_session.next_spot_number,
      quantity: @quantity
    )

    unless @spot_purchase.save
      @errors.concat(@spot_purchase.errors.full_messages)
      raise ActiveRecord::Rollback
    end
  end

  # Record spot debit in the credit ledger.
  #
  # Uses pending data stored by deduct_credits and the newly created spot_purchase.
  #
  # @return [void]
  # @raise [ActiveRecord::Rollback] if ledger recording fails
  def record_spot_debit_in_ledger
    return unless @pending_ledger_recording && @spot_purchase

    begin
      CreditLedgerService.record_entry(
        user: @user,
        movement_type: :debit_spot,
        amount: @pending_ledger_recording[:amount],
        source: @spot_purchase,
        description: @pending_ledger_recording[:description],
        metadata: {
          game_session_id: @game_session.id,
          game_session_type: @game_session.game_session_type,
          spot_number: @spot_purchase.spot_number,
          quantity: @quantity,
          price_per_spot: @game_session.price_in_credits
        }
      )
    rescue CreditLedgerService::BalanceMismatchError => e
      @errors << "Ledger error: #{e.message}"
      Rails.logger.error "Ledger balance mismatch for user #{@user.id}: #{e.message}"
      raise ActiveRecord::Rollback
    rescue StandardError => e
      @errors << "Failed to record ledger entry: #{e.message}"
      Rails.logger.error "Failed to create ledger entry for user #{@user.id}: #{e.message}"
      raise ActiveRecord::Rollback
    end
  end

  # Update game session status to 'full' if all spots are sold.
  # Automatically creates new identical session when last spot sold.
  # Sets completion deadline when session becomes full.
  #
  # @return [void]
  # @raise [ActiveRecord::Rollback] if status update fails
  def update_session_status_if_full
    # Reload to get accurate count after insert
    @game_session.reload

    if @game_session.spots_remaining <= 0
      @game_session.status = :full

      unless @game_session.save
        @errors.concat(@game_session.errors.full_messages)
        raise ActiveRecord::Rollback
      end

      # Set completion deadline (2.5 hours from now)
      @game_session.set_completion_deadline!

      # Auto-create new session with identical settings
      recreate_game_session
    end
  end

  # Automatically create a new game session with identical settings.
  #
  # This ensures popular games are always available without admin intervention.
  # If recreation fails, the error is logged but doesn't block the spot purchase.
  #
  # @return [GameSession, nil] the newly created session or nil if failed
  def recreate_game_session
    new_session = GameSession.create!(
      game_session_type: @game_session.game_session_type,
      name: @game_session.name,
      description: @game_session.description,
      price_in_credits: @game_session.price_in_credits,
      expected_award_in_credits: @game_session.expected_award_in_credits,
      max_spots: @game_session.max_spots,
      max_users: @game_session.max_users,
      platform_fee_in_credits: @game_session.platform_fee_in_credits,
      started_at: Time.current,
      status: :active
    )

    Rails.logger.info "Auto-created new game session #{new_session.id} (clone of #{@game_session.id})"
    new_session
  rescue => e
    # Log but don't fail the purchase
    Rails.logger.error "Failed to auto-create game session: #{e.message}"
    nil
  end
end
