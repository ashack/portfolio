# frozen_string_literal: true

# Paginatable Concern
#
# OVERVIEW:
# This concern provides comprehensive pagination functionality to controllers across
# the triple-track SaaS system. It handles pagination parameters, user preferences,
# filter preservation, and provides helper methods for consistent pagination
# behavior throughout the application.
#
# PURPOSE:
# - Standardize pagination across all controllers and user types
# - Persist user pagination preferences per controller
# - Preserve filter parameters across page navigation  
# - Validate pagination parameters for security
# - Support modern UX with Turbo Frame AJAX pagination
# - Provide consistent pagination URLs and helpers
#
# INTEGRATION WITH TRIPLE-TRACK SYSTEM:
# This concern works universally across all user contexts:
# 1. DIRECT USERS: Personal pagination preferences in individual dashboard
# 2. TEAM MEMBERS: Team-scoped pagination preferences  
# 3. ENTERPRISE USERS: Enterprise-scoped pagination preferences
# 4. ADMIN USERS: Admin-specific pagination for user/team management
#
# KEY FEATURES:
# - Automatic pagination parameter handling (page, per_page)
# - User preference persistence per controller
# - Filter parameter preservation across page navigation
# - Validation of allowed per_page values
# - Turbo Frame support for AJAX pagination
# - Helper methods for views
# - URL generation with preserved filters
#
# SECURITY CONSIDERATIONS:
# - Validates per_page values against allowed list
# - Prevents excessive page sizes that could impact performance
# - Sanitizes pagination parameters to prevent injection
# - Preserves only permitted filter parameters
#
# PERFORMANCE OPTIMIZATIONS:
# - Efficient database pagination with Pagy gem
# - Smart caching of user preferences
# - Minimal database queries for preference loading
# - Optimized filter parameter handling
#
# EXTERNAL DEPENDENCIES:
# - Pagy gem for efficient pagination
# - UserPreference model for storing user settings
# - Rails strong parameters for security
#
# USAGE EXAMPLES:
# 1. Basic controller integration:
#    class UsersController < ApplicationController
#      include Paginatable
#
#      def index
#        @pagy, @users = pagy(User.all, items: @items_per_page)
#      end
#    end
#
# 2. With custom filters:
#    class TeamsController < ApplicationController
#      include Paginatable
#
#      private
#
#      def filter_params
#        params.permit(:search, :status, :created_since).to_h.symbolize_keys
#      end
#    end
#
# 3. View usage with Turbo Frames:
#    <%= turbo_frame_tag "users_list" do %>
#      <!-- user list content -->
#      <%= render 'shared/pagination', pagy: @pagy, turbo_frame: 'users_list' %>
#    <% end %>
#
# BUSINESS LOGIC:
# - Each controller can have independent pagination preferences
# - Pagination state survives across filter changes
# - User preferences are controller-specific for better UX
# - Anonymous users get default pagination without persistence
#
module Paginatable
  extend ActiveSupport::Concern

  # Allowed values for items per page dropdown
  # These values are enforced both in UI and backend validation
  ALLOWED_PER_PAGE_VALUES = [ 10, 20, 50, 100 ].freeze

  # Default number of items per page when no preference is set
  DEFAULT_PER_PAGE = 20

  included do
    # Set pagination parameters before each action
    before_action :set_pagination_params

    # Make these methods available in views
    # pagination_url_for: Generates URLs with preserved filters and pagination
    # pagy_url_for: Wrapper for Pagy's URL generation
    # filter_params: Returns current filter parameters
    # filters_active?: Checks if any filters are applied
    # active_filter_count: Returns count of active filters
    # pagination_params: Returns current pagination parameters
    helper_method :pagination_url_for, :pagy_url_for, :filter_params, :filters_active?, :active_filter_count, :pagination_params
  end

  private

  # Sets @page and @items_per_page instance variables based on:
  # 1. URL parameters (highest priority)
  # 2. User preferences (if signed in)
  # 3. Default values
  # Also handles per_page updates when user changes the dropdown
  def set_pagination_params
    @items_per_page = valid_items_per_page
    @page = params[:page].to_i
    @page = 1 if @page < 1
  end

  # Validates and returns the items per page value
  # Priority order:
  # 1. Valid per_page param from URL (saves to preference)
  # 2. User's saved preference for this controller
  # 3. Default value (20)
  def valid_items_per_page
    requested = params[:per_page].to_i

    # Check if requested value is in allowed list
    if ALLOWED_PER_PAGE_VALUES.include?(requested)
      # Save preference for logged in users
      save_user_preference(requested) if current_user
      return requested
    end

    # Check user preference if no valid param provided
    if current_user&.user_preference
      stored_value = current_user.user_preference.get_items_per_page(controller_name)
      return stored_value if stored_value && ALLOWED_PER_PAGE_VALUES.include?(stored_value)
    end

    # Return default if not valid
    DEFAULT_PER_PAGE
  end

  # Saves the user's items per page preference for the current controller
  # Creates UserPreference record if it doesn't exist
  # Each controller can have its own items per page setting
  def save_user_preference(items_per_page)
    return unless current_user

    preference = current_user.user_preference || current_user.build_user_preference
    preference.set_items_per_page(controller_name, items_per_page)
    preference.save
  end

  # Returns current pagination parameters merged with filter params
  # Used by views to generate forms and links that preserve state
  # Includes: page, per_page, and all active filters
  def pagination_params
    {
      page: @page,
      per_page: @items_per_page
    }.merge(filter_params)
  end

  # Returns filter parameters that should be preserved across page navigation
  # Override this method in controllers to customize which params to preserve
  # Default implementation includes common filter parameter names
  def filter_params
    # Default implementation preserves common filter params
    params.permit(
      :search, :query, :q,           # Search params
      :status, :state,               # Status filters
      :user_type, :role,             # User filters
      :start_date, :end_date,        # Date range filters
      :sort, :order, :direction,     # Sorting params
      :filter                        # Generic filter param
    ).to_h.symbolize_keys
  end

  # Generates a URL for pagination links while preserving all filters
  # @param page [Integer] The page number to link to
  # @param per_page [Integer] Items per page (optional)
  # @param extra_params [Hash] Additional parameters to include
  # @return [String] The generated URL with all parameters
  def pagination_url_for(page: nil, per_page: nil, **extra_params)
    url_params = filter_params.merge(
      page: page || @page,
      per_page: per_page || @items_per_page
    ).merge(extra_params)

    url_for(url_params.compact)
  end

  # Wrapper method for Pagy's URL generation
  # Required because Pagy expects positional arguments
  # while our pagination_url_for uses keyword arguments
  # @param pagy [Pagy] The Pagy instance (not used but required by Pagy)
  # @param page [Integer] The page number to link to
  def pagy_url_for(pagy, page)
    pagination_url_for(page: page)
  end

  # Checks if any filter parameters are present
  # Used to show/hide "Clear filters" button in views
  # @return [Boolean] true if any filters are active
  def filters_active?
    filter_params.any?
  end

  # Returns the number of active filters
  # Used to display filter count badge in views
  # @return [Integer] Count of active filter parameters
  def active_filter_count
    filter_params.count
  end
end
