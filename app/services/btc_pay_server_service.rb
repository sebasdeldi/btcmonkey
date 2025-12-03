# Service for integrating with BTCPay Server API to process Bitcoin payments.
#
# This service handles all communication with the BTCPay Server API, including:
# - Creating Bitcoin invoices for credit package purchases
# - Retrieving invoice status and payment details
# - Extracting Bitcoin addresses and amounts from API responses
#
# BTCPay Server is a self-hosted, open-source cryptocurrency payment processor
# that allows accepting Bitcoin payments without third-party intermediaries.
#
# Configuration:
# This service requires three environment variables to be set:
# - BTCPAY_SERVER_URL: The base URL of your BTCPay Server instance
# - BTCPAY_API_KEY: Your BTCPay Server API key (generate in Store Settings > Access Tokens)
# - BTCPAY_STORE_ID: Your BTCPay Server store ID
#
# @example Creating an invoice
#   service = BtcPayServerService.new
#   invoice = service.create_invoice(
#     amount_usd: 19.00,
#     order_id: 123,
#     buyer_email: 'user@example.com'
#   )
#   # => { invoice_id: "abc123", btc_address: "bc1q...", expected_btc: 0.0005, checkout_link: "https://..." }
#
# @example Retrieving invoice status
#   service = BtcPayServerService.new
#   invoice = service.get_invoice("abc123")
#   # => { status: "Settled", btc_address: "bc1q...", expected_btc: 0.0005, received_btc: 0.0005 }
#
# @example Handling configuration errors
#   # If environment variables are missing:
#   service = BtcPayServerService.new
#   # => BtcPayServerService::Error: BTCPay Server is not configured. Missing environment variables: BTCPAY_SERVER_URL, BTCPAY_API_KEY
#
# @example Handling API errors
#   service.create_invoice(amount_usd: -10, order_id: 1)
#   # => BtcPayServerService::ApiError: Client error (400): Invalid amount
#
class BtcPayServerService
  include HTTParty

  # Base error class for all BTCPay Server service errors.
  class Error < StandardError; end

  # Raised when BTCPay Server API returns an error response.
  class ApiError < Error; end

  # Initialize the BTCPay Server service.
  #
  # Loads configuration from environment variables and validates that all
  # required settings are present. Sets the base URI for HTTParty requests.
  #
  # @raise [Error] if any required environment variables are missing
  def initialize
    @api_url = ENV["BTCPAY_SERVER_URL"]
    @api_key = ENV["BTCPAY_API_KEY"]
    @store_id = ENV["BTCPAY_STORE_ID"]

    validate_configuration!

    self.class.base_uri @api_url
  end

  # Create a new Bitcoin invoice in BTCPay Server.
  #
  # Creates an invoice for the specified USD amount and returns payment details
  # including the Bitcoin address, expected BTC amount, and checkout link.
  # The invoice will redirect to the transaction show page after payment.
  #
  # @param amount_usd [Decimal] the amount to charge in US dollars
  # @param order_id [Integer] the BtcTransaction ID for tracking
  # @param buyer_email [String, nil] optional email address of the buyer
  # @return [Hash] invoice details
  # @option return [String] :invoice_id the BTCPay Server invoice ID
  # @option return [String] :btc_address the Bitcoin address for payment
  # @option return [Decimal] :expected_btc the expected Bitcoin amount
  # @option return [String] :checkout_link the BTCPay Server checkout page URL
  # @raise [ApiError] if the API request fails
  #
  # @example
  #   service.create_invoice(amount_usd: 19.00, order_id: 123)
  #   # => {
  #   #   invoice_id: "4jGnEqMQ2stdeoqHepeqdA",
  #   #   btc_address: "bc1q...",
  #   #   expected_btc: 0.00052,
  #   #   checkout_link: "https://btcpay.example.com/i/4jGnEqMQ2stdeoqHepeqdA"
  #   # }
  def create_invoice(amount_usd:, order_id:, buyer_email: nil)
    payload = {
      amount: amount_usd.to_s,
      currency: "USD",
      metadata: {
        orderId: order_id,
        buyerEmail: buyer_email
      }.compact,
      checkout: {
        redirectURL: callback_url(order_id)
      }
    }

    response = self.class.post(
      "/api/v1/stores/#{@store_id}/invoices",
      body: payload.to_json,
      headers: headers
    )

    handle_response(response)

    {
      invoice_id: response["id"],
      btc_address: extract_btc_address(response),
      expected_btc: extract_expected_btc(response),
      checkout_link: response["checkoutLink"]
    }
  rescue StandardError => e
    raise ApiError, "Failed to create invoice: #{e.message}"
  end

  # Retrieve invoice details from BTCPay Server.
  #
  # Fetches the current status and payment details for an existing invoice.
  # This is typically called by the webhook handler to check payment status.
  #
  # @param invoice_id [String] the BTCPay Server invoice ID
  # @return [Hash] invoice details
  # @option return [String] :status the invoice status (New, Processing, Settled, Expired, Invalid)
  # @option return [String] :btc_address the Bitcoin address for payment
  # @option return [Decimal] :expected_btc the expected Bitcoin amount
  # @option return [Decimal] :received_btc the actual Bitcoin amount received
  # @raise [ApiError] if the API request fails
  #
  # @example
  #   service.get_invoice("4jGnEqMQ2stdeoqHepeqdA")
  #   # => {
  #   #   status: "Settled",
  #   #   btc_address: "bc1q...",
  #   #   expected_btc: 0.00052,
  #   #   received_btc: 0.00052
  #   # }
  def get_invoice(invoice_id)
    response = self.class.get(
      "/api/v1/stores/#{@store_id}/invoices/#{invoice_id}",
      headers: headers
    )

    handle_response(response)

    {
      status: response["status"],
      btc_address: extract_btc_address(response),
      expected_btc: extract_expected_btc(response),
      received_btc: extract_received_btc(response)
    }
  rescue StandardError => e
    raise ApiError, "Failed to fetch invoice: #{e.message}"
  end

  private

  # Build HTTP headers for BTCPay Server API requests.
  #
  # @return [Hash] headers including Content-Type and Authorization
  def headers
    {
      "Content-Type" => "application/json",
      "Authorization" => "token #{@api_key}"
    }
  end

  # Handle API response and raise errors for non-success status codes.
  #
  # @param response [HTTParty::Response] the HTTP response
  # @return [Hash] the parsed JSON response body
  # @raise [ApiError] if response code indicates an error
  def handle_response(response)
    case response.code
    when 200..299
      response.parsed_response
    when 400..499
      raise ApiError, "Client error (#{response.code}): #{response.body}"
    when 500..599
      raise ApiError, "Server error (#{response.code}): #{response.body}"
    else
      raise ApiError, "Unexpected response (#{response.code}): #{response.body}"
    end
  end

  # Extract Bitcoin address from invoice response.
  #
  # Searches the payment methods array for the BTC payment method and
  # extracts the destination address.
  #
  # @param invoice_response [Hash] the parsed invoice response
  # @return [String, nil] the Bitcoin address or nil if not found
  def extract_btc_address(invoice_response)
    payment_methods = invoice_response.dig("checkout", "paymentMethods")
    return nil unless payment_methods

    btc_method = payment_methods.find { |pm| pm["cryptoCode"] == "BTC" }
    btc_method&.dig("destination")
  end

  # Extract expected Bitcoin amount from invoice response.
  #
  # Searches the payment methods array for the BTC payment method and
  # extracts the expected amount.
  #
  # @param invoice_response [Hash] the parsed invoice response
  # @return [Decimal, nil] the expected BTC amount or nil if not found
  def extract_expected_btc(invoice_response)
    payment_methods = invoice_response.dig("checkout", "paymentMethods")
    return nil unless payment_methods

    btc_method = payment_methods.find { |pm| pm["cryptoCode"] == "BTC" }
    btc_method&.dig("amount")&.to_d
  end

  # Extract received Bitcoin amount from invoice response.
  #
  # Sums up all payment values from the payments array.
  #
  # @param invoice_response [Hash] the parsed invoice response
  # @return [Decimal] the total BTC received (0 if no payments)
  def extract_received_btc(invoice_response)
    payments = invoice_response["payments"]
    return 0 unless payments

    payments.sum { |p| p["value"].to_d }
  end

  # Generate the callback URL for invoice redirects.
  #
  # After completing or canceling payment, BTCPay Server will redirect
  # the user to this URL to view their transaction details.
  #
  # @param order_id [Integer] the BtcTransaction ID
  # @return [String] the full callback URL
  def callback_url(order_id)
    Rails.application.routes.url_helpers.credit_purchase_url(order_id, host: ENV.fetch("APP_HOST", "localhost:3000"))
  end

  # Validate that all required environment variables are configured.
  #
  # @return [void]
  # @raise [Error] if any required environment variables are missing
  def validate_configuration!
    missing = []
    missing << "BTCPAY_SERVER_URL" if @api_url.blank?
    missing << "BTCPAY_API_KEY" if @api_key.blank?
    missing << "BTCPAY_STORE_ID" if @store_id.blank?

    if missing.any?
      raise Error, "BTCPay Server is not configured. Missing environment variables: #{missing.join(', ')}. Please check the .env.example file for configuration instructions."
    end
  end
end
