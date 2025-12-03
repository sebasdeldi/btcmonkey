# Service object for orchestrating credit package purchases via Bitcoin.
#
# This service handles the complete purchase flow:
# 1. Validates the credit package is active and available
# 2. Creates a pending BtcTransaction record
# 3. Calls BTCPay Server API to create a Bitcoin invoice
# 4. Updates the transaction with Bitcoin payment details
# 5. Returns a checkout link for the user to complete payment
#
# The entire process is wrapped in a database transaction to ensure atomicity.
# If any step fails, the transaction is rolled back and errors are collected.
#
# After successful completion, the user should be redirected to the checkout_link
# where they can scan a QR code or copy the Bitcoin address to make payment.
# Payment confirmation happens asynchronously via BTCPay Server webhooks.
#
# @example Successful purchase initiation
#   service = CreditPurchaseService.new(
#     user: current_user,
#     credit_package: CreditPackage.find(1)
#   )
#
#   if service.call
#     redirect_to service.checkout_link
#     # User is redirected to BTCPay Server checkout page
#   else
#     flash[:alert] = service.errors.join(", ")
#   end
#
# @example Failed purchase (inactive package)
#   inactive_package = CreditPackage.find_by(active: false)
#   service = CreditPurchaseService.new(user: user, credit_package: inactive_package)
#   service.call # => false
#   service.errors # => ["Credit package is not available"]
#
# @example Failed purchase (BTCPay Server error)
#   # If BTCPay Server is misconfigured or unreachable
#   service.call # => false
#   service.errors # => ["Payment provider error: Connection refused"]
#
class CreditPurchaseService
  # @return [BtcTransaction, nil] the created transaction if purchase succeeds
  attr_reader :transaction

  # @return [Array<String>] array of error messages if purchase fails
  attr_reader :errors

  # @return [String, nil] the BTCPay Server checkout URL where user completes payment
  attr_reader :checkout_link

  # Initialize the credit purchase service.
  #
  # @param user [User] the user purchasing credits
  # @param credit_package [CreditPackage] the package being purchased
  def initialize(user:, credit_package:)
    @user = user
    @credit_package = credit_package
    @errors = []
  end

  # Execute the credit purchase process.
  #
  # Creates a BtcTransaction and BTCPay Server invoice within a database transaction.
  # If any step fails, the entire operation is rolled back and errors are collected.
  #
  # @return [Boolean] true if purchase initiation succeeds, false otherwise
  def call
    validate_package
    return false unless @errors.empty?

    ActiveRecord::Base.transaction do
      create_transaction
      create_btcpay_invoice
    end

    success?
  end

  # Check if the purchase was successful.
  #
  # @return [Boolean] true if no errors and transaction is persisted
  def success?
    @errors.empty? && @transaction&.persisted?
  end

  private

  # Validate that the credit package is active and available for purchase.
  #
  # @return [void]
  def validate_package
    unless @credit_package.active?
      @errors << "Credit package is not available"
    end
  end

  # Create a pending Bitcoin transaction record.
  #
  # The transaction is initially created with a temporary UUID invoice_id,
  # which will be replaced with the actual BTCPay Server invoice ID.
  #
  # @return [void]
  # @raise [ActiveRecord::Rollback] if transaction creation fails
  def create_transaction
    @transaction = @user.btc_transactions.build(
      credit_package: @credit_package,
      invoice_id: SecureRandom.uuid,
      status: :pending
    )

    unless @transaction.save
      @errors.concat(@transaction.errors.full_messages)
      raise ActiveRecord::Rollback
    end
  end

  # Create a BTCPay Server invoice and update the transaction with payment details.
  #
  # Calls the BTCPay Server API to generate a Bitcoin invoice for the package price.
  # The invoice includes the transaction ID as metadata and a callback URL.
  # Updates the transaction with the real invoice ID, Bitcoin address, and expected BTC amount.
  #
  # @return [void]
  # @raise [ActiveRecord::Rollback] if BTCPay Server API call fails
  def create_btcpay_invoice
    btcpay_service = BtcPayServerService.new

    invoice_data = btcpay_service.create_invoice(
      amount_usd: @credit_package.price_usd,
      order_id: @transaction.id,
      buyer_email: @user.email
    )

    @transaction.update!(
      invoice_id: invoice_data[:invoice_id],
      btc_address: invoice_data[:btc_address],
      expected_btc: invoice_data[:expected_btc]
    )

    @checkout_link = invoice_data[:checkout_link]
  rescue BtcPayServerService::Error => e
    @errors << e.message
    raise ActiveRecord::Rollback
  rescue BtcPayServerService::ApiError => e
    @errors << "Payment provider error: #{e.message}"
    raise ActiveRecord::Rollback
  end
end
