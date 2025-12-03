# Custom Devise registrations controller for user sign-up with credit wallet creation.
#
# This controller overrides Devise's default registration behavior to:
# 1. Use UserRegistrationService for business logic
# 2. Automatically create a UserCreditWallet when a user registers
# 3. Support the custom :username field in addition to standard Devise fields
#
# The service object pattern keeps the controller slim while ensuring that
# user creation and wallet creation happen atomically within a database transaction.
#
# Routes (defined by Devise):
# - GET  /users/sign_up  → new    (show registration form)
# - POST /users/sign_up  → create (process registration)
#
# @example Successful registration
#   POST /users/sign_up
#   Params: { user: { username: "player123", email: "user@example.com", password: "secure123", password_confirmation: "secure123" } }
#   Result: User and UserCreditWallet created, user signed in and redirected
#
# @example Failed registration
#   POST /users/sign_up
#   Params: { user: { username: "", email: "invalid", password: "123" } }
#   Result: Validation errors displayed, user stays on registration form
#
module Users
  class RegistrationsController < Devise::RegistrationsController
    # Configure permitted parameters for sign up
    before_action :configure_sign_up_params, only: [:create]

    # Process user registration with automatic credit wallet creation.
    #
    # Uses UserRegistrationService to handle the business logic of:
    # 1. Creating a new User record with validations
    # 2. Creating an associated UserCreditWallet (0 total_credits, 0 locked_credits)
    # 3. Rolling back both if either fails
    #
    # On success:
    # - User is signed in via Devise
    # - User is redirected to after_sign_up_path (typically root_path)
    #
    # On failure:
    # - Registration form is re-rendered with error messages
    # - No user or wallet records are created (atomic transaction)
    #
    # @return [void] signs in user and redirects, or re-renders form with errors
    #
    # POST /users/sign_up
    def create
      service = UserRegistrationService.new(sign_up_params)

      if service.call
        sign_in(service.user)
        respond_with service.user, location: after_sign_up_path_for(service.user)
      else
        # Build resource for form re-rendering
        build_resource(sign_up_params)
        resource.valid?  # Populate ActiveModel errors for form display
        clean_up_passwords(resource)
        set_minimum_password_length
        flash.now[:alert] = service.errors.join(", ")
        render :new, status: :unprocessable_entity
      end
    end

    protected

    # Configure additional permitted parameters for user sign up.
    #
    # Adds :username to the default Devise permitted parameters
    # (email, password, password_confirmation).
    #
    # @return [void]
    def configure_sign_up_params
      devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
    end
  end
end
