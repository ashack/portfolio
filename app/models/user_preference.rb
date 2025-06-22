# frozen_string_literal: true

# UserPreference model stores user-specific preferences
# Currently used for pagination settings per controller
# 
# Each user can have one UserPreference record
# Pagination settings are stored as JSON with controller names as keys
# 
# Example pagination_settings structure:
#   {
#     "users" => 50,        # Show 50 users per page
#     "teams" => 20,        # Show 20 teams per page
#     "invitations" => 100  # Show 100 invitations per page
#   }
#
# This allows users to have different pagination preferences
# for different sections of the application
#
class UserPreference < ApplicationRecord
  # Valid values for items per page
  # Must match the values in Paginatable concern
  # These are the only values users can select
  ALLOWED_PER_PAGE_VALUES = [ 10, 20, 50, 100 ].freeze

  # Each preference belongs to exactly one user
  belongs_to :user

  # Ensure each user has at most one preference record
  validates :user_id, uniqueness: true

  # JSON column for storing pagination settings
  # Defaults to empty hash if not set
  # Keys are controller names, values are items per page
  attribute :pagination_settings, :json, default: {}

  # Retrieves the saved items per page preference for a specific controller
  # @param controller_name [String] The name of the controller (e.g., "users")
  # @return [Integer, nil] The saved preference or nil if not set
  def get_items_per_page(controller_name)
    pagination_settings[controller_name]
  end

  # Sets the items per page preference for a specific controller
  # Validates that the value is in the allowed list
  # @param controller_name [String] The name of the controller (e.g., "users")
  # @param value [Integer] The number of items per page
  # @return [Boolean] true if value was valid and set, false otherwise
  def set_items_per_page(controller_name, value)
    return false unless ALLOWED_PER_PAGE_VALUES.include?(value)

    self.pagination_settings = pagination_settings.merge(controller_name => value)
    true
  end

  # Removes all pagination preferences
  # Resets the user to default pagination for all controllers
  # Call save after this to persist the change
  def clear_pagination_settings
    self.pagination_settings = {}
  end
end
