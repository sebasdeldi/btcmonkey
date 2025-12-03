# Service for handling webhook notifications from BTCPay Server.
#
# BTCPay Server sends webhooks to notify our application about invoice status changes.
# This service processes those webhooks and updates transaction records accordingly:
#
# Webhook Flow:
# 1. User pays Bitcoin invoice on BTCPay Server
# 2. BTCPay Server detects payment and sends webhook to /webhooks/btcpay
# 3. This service processes the webhook:
#    - InvoiceSettled/InvoiceProcessing → Updates transaction, adds credits to wallet
#    - InvoiceExpired → Marks transaction as expired
#    - InvoiceInvalid → Marks transaction as failed
#
# The service ensures idempotency by checking transaction status before processing.
# If a transaction is already paid/confirmed, subsequent webhooks are safely ignored.
#
# All database operations are wrapped in transactions to ensure atomicity.
# If any step fails (fetching invoice data, updating transaction, adding credits),
# the entire operation is rolled back.
#
# @example Successful webhook processing (payment received)
#   payload = {
#     "type" => "InvoiceSettled",
#     "invoiceId" => "4jGnEqMQ2stdeoqHepeqdA"
#   }
#   service = BtcPayWebhookHandlerService.new(payload)
#   service.call # => true
#   # Transaction status updated to 'paid', credits added to user's wallet
#
# @example Webhook for expired invoice
#   payload = {
#     "type" => "InvoiceExpired",
#     "invoiceId" => "expired_invoice_123"
#   }
#   service = BtcPayWebhookHandlerService.new(payload)
#   service.call # => true
#   # Transaction status updated to 'expired'
#
# @example Invalid webhook payload
#   service = BtcPayWebhookHandlerService.new({})
#   service.call # => false
#   service.errors # => ["Invoice ID is missing from webhook"]
#
# @example Transaction not found
#   payload = { "type" => "InvoiceSettled", "invoiceId" => "nonexistent" }
#   service = BtcPayWebhookHandlerService.new(payload)
#   service.call # => false
#   service.errors # => ["Transaction not found for invoice: nonexistent"]
#
class BtcPayWebhookHandlerService
  # @return [Array<String>] array of error messages if webhook processing fails
  attr_reader :errors

  # Initialize the webhook handler with the webhook payload.
  #
  # @param webhook_payload [Hash] the webhook data from BTCPay Server
  # @option webhook_payload [String] 'type' the webhook type (InvoiceSettled, InvoiceExpired, etc.)
  # @option webhook_payload [String] 'invoiceId' the BTCPay Server invoice ID
  def initialize(webhook_payload)
    @payload = webhook_payload
    @errors = []
  end

  # Process the webhook based on its type.
  #
  # Routes the webhook to the appropriate handler method based on type:
  # - InvoiceSettled/InvoiceProcessing: Payment received, update transaction and add credits
  # - InvoiceExpired: Payment window expired, mark transaction as expired
  # - InvoiceInvalid: Payment failed/invalid, mark transaction as failed
  # - Other types: Logged but not processed
  #
  # @return [Boolean] true if webhook processed successfully, false otherwise
  def call
    return false unless validate_payload

    case webhook_type
    when "InvoiceSettled", "InvoiceProcessing"
      handle_invoice_settled
    when "InvoiceExpired"
      handle_invoice_expired
    when "InvoiceInvalid"
      handle_invoice_invalid
    else
      Rails.logger.info "Unhandled webhook type: #{webhook_type}"
      true
    end
  end

  # Check if webhook processing was successful.
  #
  # @return [Boolean] true if no errors occurred
  def success?
    @errors.empty?
  end

  private

  # Validate that the webhook payload contains required fields.
  #
  # @return [Boolean] true if payload is valid, false otherwise
  def validate_payload
    if @payload.blank?
      @errors << "Webhook payload is empty"
      return false
    end

    if invoice_id.blank?
      @errors << "Invoice ID is missing from webhook"
      return false
    end

    true
  end

  # Extract the webhook type from the payload.
  #
  # @return [String, nil] the webhook type
  def webhook_type
    @payload["type"]
  end

  # Extract the invoice ID from the payload.
  #
  # @return [String, nil] the BTCPay Server invoice ID
  def invoice_id
    @payload.dig("invoiceId")
  end

  # Handle settled or processing invoice webhook.
  #
  # When payment is detected:
  # 1. Find the transaction by invoice ID
  # 2. Skip if already paid/confirmed (idempotency)
  # 3. Fetch latest invoice data from BTCPay Server
  # 4. Update transaction with received BTC and new status
  # 5. Add credits to user's wallet
  #
  # @return [Boolean] true if handled successfully, false otherwise
  def handle_invoice_settled
    # Eager load associations to prevent N+1 queries during broadcast rendering
    transaction = BtcTransaction.preload(:user, :credit_package, user: :user_credit_wallet)
                                 .find_by(invoice_id: invoice_id)

    unless transaction
      @errors << "Transaction not found for invoice: #{invoice_id}"
      return false
    end

    return true if transaction.paid? || transaction.confirmed?

    ActiveRecord::Base.transaction do
      update_transaction_from_webhook(transaction)
      add_credits_to_wallet(transaction)
    end

    # Broadcast updates after successful commit
    broadcast_transaction_updates(transaction) if success?

    success?
  end

  # Handle expired invoice webhook.
  #
  # Marks the transaction as expired if it exists.
  # Returns true even if transaction not found (webhook may arrive late).
  #
  # @return [Boolean] always returns true
  def handle_invoice_expired
    # Eager load associations for broadcast rendering
    transaction = BtcTransaction.preload(:user, :credit_package)
                                 .find_by(invoice_id: invoice_id)
    return true unless transaction

    transaction.update(status: :expired)
    broadcast_transaction_status_change(transaction)

    true
  end

  # Handle invalid invoice webhook.
  #
  # Marks the transaction as failed if it exists.
  # Returns true even if transaction not found (webhook may arrive late).
  #
  # @return [Boolean] always returns true
  def handle_invoice_invalid
    # Eager load associations for broadcast rendering
    transaction = BtcTransaction.preload(:user, :credit_package)
                                 .find_by(invoice_id: invoice_id)
    return true unless transaction

    transaction.update(status: :failed)
    broadcast_transaction_status_change(transaction)

    true
  end

  # Fetch latest invoice data from BTCPay Server and update transaction.
  #
  # Calls BTCPay Server API to get current invoice status and payment details,
  # then updates the transaction record with received BTC amount and mapped status.
  #
  # @param transaction [BtcTransaction] the transaction to update
  # @return [void]
  # @raise [ActiveRecord::Rollback] if BTCPay Server API call fails
  def update_transaction_from_webhook(transaction)
    btcpay_client = BtcPayServerClient.new
    invoice_data = btcpay_client.get_invoice(invoice_id)

    transaction.update!(
      received_btc: invoice_data[:received_btc],
      status: map_btcpay_status(invoice_data[:status])
    )
  rescue BtcPayServerClient::ApiError => e
    @errors << "Failed to fetch invoice data: #{e.message}"
    raise ActiveRecord::Rollback
  end

  # Add credits to the user's wallet after successful payment.
  #
  # Uses CreditWalletService to safely add the credits from the purchased package.
  # If credit addition fails, the entire transaction is rolled back.
  #
  # @param transaction [BtcTransaction] the transaction containing user and package info
  # @return [void]
  # @raise [ActiveRecord::Rollback] if credit addition fails
  def add_credits_to_wallet(transaction)
    wallet_service = CreditWalletService.new(transaction.user)

    unless wallet_service.add_credits(transaction.credit_package.credits, source: transaction)
      @errors.concat(wallet_service.errors)
      raise ActiveRecord::Rollback
    end
  end

  # Map BTCPay Server status to application transaction status.
  #
  # BTCPay Server uses different status names than our application:
  # - "Settled" or "Processing" → "paid" (payment received)
  # - "Expired" → "expired" (payment window expired)
  # - "Invalid" → "failed" (payment failed/invalid)
  # - Other → "pending" (default fallback)
  #
  # @param btcpay_status [String] the status from BTCPay Server
  # @return [String] the mapped application status
  def map_btcpay_status(btcpay_status)
    case btcpay_status.to_s.downcase
    when "settled", "processing"
      "paid"
    when "expired"
      "expired"
    when "invalid"
      "failed"
    else
      "pending"
    end
  end

  # Broadcast full transaction update (payment received)
  # Uses Turbo::StreamsChannel for compatibility with turbo_stream_from helper
  def broadcast_transaction_updates(transaction)
    Turbo::StreamsChannel.broadcast_render_to(
      transaction.user,
      partial: 'credit_purchases/turbo_full_update',
      formats: [:turbo_stream],
      locals: { transaction: transaction }
    )

    Rails.logger.info "Broadcasted full update for transaction #{transaction.id} to user #{transaction.user_id}"
  end

  # Broadcast status-only update (expired/failed)
  # Uses Turbo::StreamsChannel for compatibility with turbo_stream_from helper
  def broadcast_transaction_status_change(transaction)
    Turbo::StreamsChannel.broadcast_render_to(
      transaction.user,
      partial: 'credit_purchases/turbo_status_update',
      formats: [:turbo_stream],
      locals: { transaction: transaction }
    )

    Rails.logger.info "Broadcasted status update for transaction #{transaction.id} to user #{transaction.user_id}"
  end
end
