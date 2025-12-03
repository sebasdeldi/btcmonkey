# Controller for managing credit package purchases via Bitcoin.
#
# This controller handles the credit purchase flow:
# 1. Display available credit packages (index)
# 2. Initiate purchase and redirect to BTCPay Server checkout (create)
# 3. View transaction details and status (show)
#
# All actions require user authentication via Devise.
#
# Routes:
# - GET  /credit_purchases       → index  (list available packages)
# - POST /credit_purchases       → create (initiate purchase)
# - GET  /credit_purchases/:id   → show   (view transaction details)
#
# @example User flow
#   1. User visits /credit_purchases (index)
#   2. User selects a package and clicks "Buy Now"
#   3. POST to /credit_purchases with credit_package_id
#   4. CreditPurchaseService creates transaction and BTCPay invoice
#   5. User redirected to BTCPay Server checkout page
#   6. After payment, user can visit /credit_purchases/:id to see status
#
class CreditPurchasesController < ApplicationController
  # Require user authentication for all actions
  before_action :authenticate_user!

  # Load the credit package for the create action
  before_action :set_credit_package, only: [:create]

  # Display all active credit packages available for purchase.
  #
  # Packages are ordered by price (lowest to highest) for easy comparison.
  # Only active packages are shown to prevent purchasing deactivated packages.
  #
  # @return [void] renders the index view with @credit_packages
  #
  # GET /credit_purchases
  def index
    @credit_packages = CreditPackage.active.order(:price_usd)
  end

  # Initiate a credit package purchase.
  #
  # Uses CreditPurchaseService to:
  # 1. Create a pending BtcTransaction
  # 2. Generate a BTCPay Server invoice
  # 3. Add transaction to list via Turbo Stream (if Turbo request)
  # 4. Redirect user to BTCPay checkout page
  #
  # If successful, user is redirected to BTCPay Server to complete payment.
  # If failed (e.g., inactive package, API error), user is redirected back
  # to the packages list with an error message.
  #
  # @return [void] responds with Turbo Stream + redirect or standard redirect
  #
  # POST /credit_purchases
  # @param credit_package_id [Integer] the ID of the package to purchase (in params)
  def create
    service = CreditPurchaseService.new(
      user: current_user,
      credit_package: @credit_package
    )

    if service.call
      @checkout_link = service.checkout_link
      @new_transaction = service.transaction

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to service.checkout_link, allow_other_host: true }
      end
    else
      flash[:alert] = service.errors.join(", ")
      redirect_to credit_purchases_path
    end
  end

  # Display transaction details and payment status.
  #
  # Shows the current status of a Bitcoin transaction including:
  # - Transaction status (pending, paid, confirmed, expired, failed)
  # - Package details (name, credits, price)
  # - Bitcoin payment details (address, expected BTC, received BTC)
  # - Auto-refresh for pending transactions
  #
  # Only allows viewing transactions owned by the current user for security.
  #
  # @return [void] renders the show view with @transaction
  # @raise [ActiveRecord::RecordNotFound] if transaction doesn't exist or belongs to another user
  #
  # GET /credit_purchases/:id
  # @param id [Integer] the BtcTransaction ID
  def show
    @transaction = current_user.btc_transactions.find(params[:id])
  end

  private

  # Load the credit package from params.
  #
  # If package not found, redirects to index with error message.
  #
  # @return [void] sets @credit_package or redirects on error
  def set_credit_package
    @credit_package = CreditPackage.find(params[:credit_package_id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Credit package not found"
    redirect_to credit_purchases_path
  end
end
