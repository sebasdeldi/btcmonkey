# Base controller for admin-only actions.
#
# For now, admin access is console-only, but this controller is created
# for future admin UI functionality. All admin controllers should inherit
# from this base controller.
#
# Future: Add authentication/authorization logic here (Pundit, CanCanCan, etc.)
#
class Admin::BaseController < ApplicationController
  # Future: Add admin authentication
  # before_action :authenticate_admin!

  layout "application" # Future: Admin-specific layout
end
