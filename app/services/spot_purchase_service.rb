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
  def initialize(user:, game_session:)
    @user = user
    @game_session = game_session
    @errors = []
  end

  # Execute the spot purchase process.
  #
  # Performs validations, deducts credits, creates spot purchase, and updates
  # game session status if needed. All within a database transaction.
  #
  # @return [Boolean] true if purchase succeeds, false otherwise
  def call
    validate_purchase
    return false unless @errors.empty?

    ActiveRecord::Base.transaction do
      # Lock the game session to prevent race conditions
      @game_session = GameSession.lock.find(@game_session.id)

      # Re-validate after acquiring lock (another transaction may have changed state)
      validate_session_availability
      return false unless @errors.empty?

      deduct_credits
      create_spot_purchase
      update_session_status_if_full
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

    unless @game_session.spots_remaining > 0
      @errors << "Game session has no available spots"
    end
  end

  # Validate user hasn't already purchased in this session.
  #
  # @return [void]
  def validate_user_eligibility
    if @user.spot_purchases.exists?(game_session_id: @game_session.id)
      @errors << "You have already purchased a spot in this session"
    end
  end

  # Validate user has sufficient credits for purchase.
  #
  # @return [void]
  def validate_sufficient_credits
    wallet = @user.user_credit_wallet

    if wallet.nil? || wallet.total_credits < @game_session.price_in_credits
      @errors << "Insufficient available credits"
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

    new_total = wallet.total_credits - @game_session.price_in_credits

    if new_total < 0
      @errors << "Insufficient credits for purchase"
      raise ActiveRecord::Rollback
    end

    wallet.total_credits = new_total

    unless wallet.save
      @errors.concat(wallet.errors.full_messages)
      raise ActiveRecord::Rollback
    end
  end

  # Create the spot purchase record.
  #
  # Assigns the next sequential spot number and records the credits spent.
  #
  # @return [void]
  # @raise [ActiveRecord::Rollback] if spot purchase creation fails
  def create_spot_purchase
    @spot_purchase = @user.spot_purchases.build(
      game_session: @game_session,
      credits_spent: @game_session.price_in_credits,
      spot_number: @game_session.next_spot_number
    )

    unless @spot_purchase.save
      @errors.concat(@spot_purchase.errors.full_messages)
      raise ActiveRecord::Rollback
    end

    # Broadcast real-time updates via Turbo Streams
    broadcast_spot_purchase_updates
  end

  # Update game session status to 'full' if all spots are sold.
  # Automatically creates new identical session when last spot sold.
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

  # Broadcast real-time updates to all connected clients via Turbo Streams.
  #
  # Updates the following UI elements:
  # - Participants list (adds new participant)
  # - Progress bar (updates percentage)
  # - Spots remaining counter
  # - Participate button state (if session becomes full)
  #
  # @return [void]
  def broadcast_spot_purchase_updates
    # Reload to get fresh data
    @game_session.reload

    # Broadcast to game session show page
    Turbo::StreamsChannel.broadcast_replace_to(
      "game_session_#{@game_session.id}",
      target: "participants-list",
      partial: "game_sessions/participants_list",
      locals: { game_session: @game_session }
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      "game_session_#{@game_session.id}",
      target: "progress-section",
      partial: "game_sessions/progress_bar",
      locals: { game_session: @game_session }
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      "game_session_#{@game_session.id}",
      target: "spots-remaining-section",
      html: <<~HTML
        <p class="text-xs text-secondary uppercase tracking-wide mb-1">Available</p>
        <p class="text-xl font-bold">#{@game_session.spots_remaining}</p>
      HTML
    )

    # Update participate button if user is viewing
    Turbo::StreamsChannel.broadcast_replace_to(
      "game_session_#{@game_session.id}",
      target: "participate-button",
      partial: "game_sessions/participate_button",
      locals: {
        game_session: @game_session,
        user_has_purchased: @user.spot_purchases.exists?(game_session_id: @game_session.id)
      }
    )

    # Update the game session card on index page for all users
    broadcast_card_updates
  end

  # Broadcast updates to game session card on index page.
  #
  # Updates the entire game session card on the index page
  # visible to all users.
  #
  # @return [void]
  def broadcast_card_updates
    # Replace the entire game session card to update all dynamic content
    Turbo::StreamsChannel.broadcast_replace_to(
      "game_sessions_index",
      target: "game-session-#{@game_session.id}",
      partial: "components/game_session_card",
      locals: { game_session: @game_session }
    )
  end
end
