# Service object for user registration with automatic credit wallet creation.
#
# This service encapsulates the business logic for registering a new user account.
# It ensures that both the User and UserCreditWallet records are created atomically
# within a database transaction. If either creation fails, the entire operation is
# rolled back to maintain data consistency.
#
# This service is called from Users::RegistrationsController instead of using
# Devise's default registration flow, allowing us to add custom business logic
# like automatic wallet creation.
#
# @example Successful registration
#   service = UserRegistrationService.new(
#     email: 'user@example.com',
#     username: 'player123',
#     password: 'secure_password',
#     password_confirmation: 'secure_password'
#   )
#
#   if service.call
#     user = service.user
#     # User and wallet are both created successfully
#     user.user_credit_wallet.total_credits # => 0
#   else
#     errors = service.errors
#     # => ["Email has already been taken"]
#   end
#
# @example Failed registration (validation errors)
#   service = UserRegistrationService.new(email: '', username: '', password: '')
#   service.call # => false
#   service.errors # => ["Email can't be blank", "Username can't be blank", ...]
#
class UserRegistrationService
  # @return [User, nil] the created user if registration succeeds, nil otherwise
  attr_reader :user

  # @return [Array<String>] array of error messages if registration fails
  attr_reader :errors

  # Initialize the registration service with user parameters.
  #
  # @param user_params [Hash] the parameters for creating the user
  # @option user_params [String] :email the user's email address
  # @option user_params [String] :username the user's unique username
  # @option user_params [String] :password the user's password
  # @option user_params [String] :password_confirmation password confirmation
  def initialize(user_params)
    @user_params = user_params
    @errors = []
  end

  # Execute the registration process.
  #
  # Creates a new User and associated UserCreditWallet within a database transaction.
  # If any step fails, the entire transaction is rolled back and errors are collected.
  #
  # @return [Boolean] true if registration succeeds, false otherwise
  # @example
  #   service = UserRegistrationService.new(user_params)
  #   service.call # => true or false
  def call
    ActiveRecord::Base.transaction do
      @user = User.new(@user_params)

      unless @user.save
        @errors = @user.errors.full_messages
        raise ActiveRecord::Rollback
      end

      create_credit_wallet!
    end

    success?
  end

  # Check if the registration was successful.
  #
  # @return [Boolean] true if no errors and user is persisted to database
  def success?
    @errors.empty? && @user&.persisted?
  end

  private

  # Create a credit wallet for the newly registered user.
  #
  # The wallet is initialized with 0 total_credits.
  # If wallet creation fails, errors are collected and the transaction is rolled back.
  #
  # @return [void]
  # @raise [ActiveRecord::Rollback] if wallet creation fails
  def create_credit_wallet!
    wallet = @user.build_user_credit_wallet(
      total_credits: 0
    )

    unless wallet.save
      @errors.concat(wallet.errors.full_messages)
      raise ActiveRecord::Rollback
    end
  end
end
