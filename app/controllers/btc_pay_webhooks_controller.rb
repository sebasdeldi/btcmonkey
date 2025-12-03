# Controller for receiving webhook notifications from BTCPay Server.
#
# BTCPay Server sends HTTP POST requests to this endpoint when invoice status changes
# (payment received, invoice expired, etc.). This controller validates the webhook
# signature for security, then delegates processing to BtcPayWebhookHandlerService.
#
# Security:
# - CSRF token verification is disabled (webhooks come from external system)
# - Webhook signature verification using HMAC-SHA256 ensures authenticity
# - Only requests with valid signatures are processed
#
# Routes:
# - POST /webhooks/btcpay → create (receive webhook)
#
# Configuration:
# Set up a webhook in your BTCPay Server:
# 1. Go to Store Settings → Webhooks
# 2. Create webhook pointing to: https://your-domain.com/webhooks/btcpay
# 3. Select events: Invoice Settled, Invoice Processing, Invoice Expired, Invoice Invalid
# 4. Set a secret and add it to BTCPAY_WEBHOOK_SECRET environment variable
#
# @example BTCPay Server webhook payload
#   POST /webhooks/btcpay
#   Headers: { "BTCPay-Sig" => "sha256=abc123..." }
#   Body: { "type" => "InvoiceSettled", "invoiceId" => "4jGnEqMQ2stdeoqHepeqdA" }
#
# @example Successful webhook processing
#   # Returns 200 OK if webhook processed successfully
#   # Transaction updated, credits added to user's wallet
#
# @example Failed webhook processing
#   # Returns 422 Unprocessable Entity if webhook processing fails
#   # Error logged to Rails.logger
#
# @example Invalid signature
#   # Returns 401 Unauthorized if signature verification fails
#   # Warning logged to Rails.logger
#
class BtcPayWebhooksController < ApplicationController
  # Skip CSRF token verification for webhooks (external requests)
  skip_before_action :verify_authenticity_token

  # Verify webhook signature before processing
  before_action :verify_webhook_signature

  # Process webhook notification from BTCPay Server.
  #
  # Delegates webhook processing to BtcPayWebhookHandlerService which:
  # 1. Validates the webhook payload
  # 2. Finds the corresponding transaction
  # 3. Updates transaction status based on webhook type
  # 4. Adds credits to user's wallet if payment received
  #
  # Returns appropriate HTTP status code:
  # - 200 OK: Webhook processed successfully
  # - 422 Unprocessable Entity: Webhook processing failed (errors logged)
  #
  # @return [void] returns HTTP status code with empty body
  #
  # POST /webhooks/btcpay
  def create
    service = BtcPayWebhookHandlerService.new(webhook_params)

    if service.call
      head :ok
    else
      Rails.logger.error "Webhook processing failed: #{service.errors.join(', ')}"
      head :unprocessable_entity
    end
  end

  private

  # Extract all webhook parameters.
  #
  # Permits all parameters since webhook payload structure varies by event type.
  #
  # @return [Hash] the webhook payload
  def webhook_params
    params.permit!.to_h
  end

  # Verify the webhook signature using HMAC-SHA256.
  #
  # BTCPay Server signs webhooks with a secret to prevent spoofing.
  # The signature is sent in the "BTCPay-Sig" header as "sha256=<hex_digest>".
  #
  # Security:
  # 1. Computes expected signature from request body and shared secret
  # 2. Compares with provided signature using constant-time comparison
  # 3. Returns 401 Unauthorized if signatures don't match
  #
  # If BTCPAY_WEBHOOK_SECRET is not set, signature verification is skipped
  # (useful for development, but should always be set in production).
  #
  # @return [Boolean, void] true if signature valid, or renders 401 and returns
  def verify_webhook_signature
    signature = request.headers["BTCPay-Sig"]
    webhook_secret = ENV.fetch("BTCPAY_WEBHOOK_SECRET", nil)

    # Skip verification if no secret configured (development only)
    return true if webhook_secret.blank?

    body = request.body.read
    expected_signature = OpenSSL::HMAC.hexdigest("SHA256", webhook_secret, body)

    # Use constant-time comparison to prevent timing attacks
    unless ActiveSupport::SecurityUtils.secure_compare(signature.to_s, "sha256=#{expected_signature}")
      Rails.logger.warn "Invalid webhook signature"
      head :unauthorized
    end
  rescue StandardError => e
    Rails.logger.error "Webhook signature verification failed: #{e.message}"
    head :unauthorized
  end
end
