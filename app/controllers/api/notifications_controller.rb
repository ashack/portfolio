# frozen_string_literal: true

# API Notifications Controller
#
# PURPOSE:
# Provides a JSON API interface for the notification system, enabling real-time
# notification management through AJAX/JavaScript requests. This controller complements
# the HTML-based NotificationsController by providing lightweight JSON endpoints
# for dynamic notification interactions without full page reloads.
#
# AUTHENTICATION & AUTHORIZATION:
# - Requires user authentication (authenticate_user!)
# - Users can only access their own notifications through current_user scoping
# - No additional authorization policies needed as access is implicitly user-scoped
# - Inherits from ApplicationController to maintain session-based authentication
#
# JSON API STRUCTURE:
# All responses follow a consistent JSON format with:
# - Main data wrapped in descriptive keys (notifications, count, etc.)
# - Standardized notification objects with id, type, message, read status
# - Metadata like unread_count, has_more for UI state management
# - Success indicators for mutation operations
# - Consistent error handling through ApplicationController
#
# INTEGRATION WITH MAIN APPLICATION:
# - Integrates with Noticed gem notification system
# - Provides API layer for notification dropdown/bell icon functionality
# - Supports real-time UI updates without page refreshes
# - Used by Stimulus controllers for interactive notification management
# - Complements HTML notifications views for full-page notification management
#
# SECURITY CONSIDERATIONS:
# - All queries scoped to current_user to prevent data leakage
# - No bulk operations that could affect other users' notifications
# - Uses standard Rails parameter filtering and CSRF protection
# - Notification content is pre-sanitized through the Noticed event system
# - No sensitive data exposure in API responses
#
# RATE LIMITING:
# - Inherits rate limiting from Rack::Attack configuration
# - GET endpoints have higher rate limits for real-time polling
# - POST/PATCH endpoints have standard mutation rate limits
# - No additional API-specific rate limiting due to authentication requirement
#
# DIFFERENCES FROM HTML CONTROLLERS:
# - Returns JSON instead of rendering HTML templates
# - More granular endpoints for specific notification actions
# - Includes metadata for JavaScript state management
# - Optimized for AJAX requests with minimal data transfer
# - No redirect logic - returns success/error status in JSON
#
# EXTERNAL INTEGRATIONS:
# - No direct external API integrations
# - Could be extended for webhook notification delivery
# - Designed to support mobile app API consumption
# - Ready for real-time updates via Action Cable integration
#
# PERFORMANCE CONSIDERATIONS:
# - Includes eager loading for notification events to prevent N+1 queries
# - Limits results to 10 notifications for initial load
# - Provides has_more flag for pagination implementation
# - Separate unread_count endpoint for lightweight polling
#
module Api
  class NotificationsController < ApplicationController
    # Security: Ensure user authentication for all API endpoints
    before_action :authenticate_user!

    # Load specific notification for actions that operate on individual notifications
    # Automatically scoped to current_user to prevent unauthorized access
    before_action :set_notification, only: [ :mark_as_read ]

    # GET /api/notifications
    # Returns paginated list of user's notifications with filtering support
    #
    # Query Parameters:
    # - filter: "unread" | "read" | nil (default: all notifications)
    #
    # Response Format:
    # {
    #   "notifications": [notification_objects],
    #   "unread_count": integer,
    #   "has_more": boolean
    # }
    #
    # Used by: Notification dropdown, notification management interfaces
    def index
      # Base query: Get user's notifications with eager loading to prevent N+1 queries
      # Order by most recent first and limit to 10 for initial load performance
      @notifications = current_user.notifications
                                   .includes(:event)
                                   .order(created_at: :desc)
                                   .limit(10)

      # Apply optional filtering based on read status
      # Supports: "unread", "read", or nil (all notifications)
      case params[:filter]
      when "unread"
        @notifications = @notifications.unread
      when "read"
        @notifications = @notifications.read
      end

      # Return structured JSON response with notification data and metadata
      # Includes unread count for badge display and pagination flag
      render json: {
        notifications: @notifications.map { |n| notification_json(n) },
        unread_count: current_user.notifications.unread.count,
        has_more: current_user.notifications.count > 10
      }
    end

    # GET /api/notifications/unread_count
    # Lightweight endpoint for polling unread notification count
    #
    # Response Format:
    # {
    #   "count": integer,
    #   "has_unread": boolean
    # }
    #
    # Used by: Notification bell icon for real-time count updates
    # Performance: Optimized for frequent polling with minimal data transfer
    def unread_count
      # Return both count and boolean flag for different UI needs
      # count: For numeric badge display
      # has_unread: For boolean UI state (show/hide bell indicator)
      render json: {
        count: current_user.notifications.unread.count,
        has_unread: current_user.notifications.unread.exists?
      }
    end

    # PATCH /api/notifications/:id/mark_as_read
    # Marks a specific notification as read
    #
    # Response Format:
    # {
    #   "success": boolean,
    #   "notification": notification_object,
    #   "unread_count": integer
    # }
    #
    # Used by: Individual notification click handlers
    # Security: Notification automatically scoped to current_user via set_notification
    def mark_as_read
      # Mark the notification as read using the Noticed gem method
      # This updates the read_at timestamp and triggers any associated callbacks
      @notification.mark_as_read!

      # Return success status, updated notification object, and new unread count
      # Updated notification includes new read status for UI state management
      render json: {
        success: true,
        notification: notification_json(@notification),
        unread_count: current_user.notifications.unread.count
      }
    end

    # PATCH /api/notifications/mark_all_as_read
    # Marks all of the user's unread notifications as read
    #
    # Response Format:
    # {
    #   "success": boolean,
    #   "unread_count": 0
    # }
    #
    # Used by: "Mark all as read" bulk action buttons
    # Performance: Uses bulk update for efficiency with large notification counts
    def mark_all_as_read
      # Bulk mark all unread notifications as read using Noticed gem bulk method
      # More efficient than individual updates for large notification counts
      current_user.notifications.unread.mark_as_read!

      # Return success status and reset unread count to 0
      # No need to recalculate count since we know it's now 0
      render json: {
        success: true,
        unread_count: 0
      }
    end

    private

    # Load and authorize access to a specific notification
    # Automatically scoped to current_user to prevent unauthorized access
    # Will raise ActiveRecord::RecordNotFound if notification doesn't belong to user
    def set_notification
      @notification = current_user.notifications.find(params[:id])
    end

    # Transform a notification object into a standardized JSON representation
    #
    # Returns a hash containing all necessary notification data for client-side rendering:
    # - id: Unique identifier for the notification
    # - type: Event class name for type-specific handling
    # - message: Human-readable notification message
    # - icon: Phosphor icon name for visual representation
    # - icon_color: Tailwind CSS color class based on notification type
    # - url: Target URL for notification click action
    # - read: Boolean read status for UI state
    # - created_at: Full timestamp for detailed views
    # - time_ago: Human-friendly relative time display
    # - params: Additional event-specific parameters
    #
    # Integration: Works with the Noticed event system to extract event data
    def notification_json(notification)
      # Extract the associated Noticed event for data access
      event = notification.event

      # Build comprehensive notification object for JSON response
      # Includes all data needed for client-side rendering and interaction
      {
        id: notification.id,                                    # For API operations (mark as read, etc.)
        type: event.class.name,                                # For type-specific client handling
        message: event.message,                                # Display text for the notification
        icon: event.icon,                                      # Phosphor icon name
        icon_color: icon_color_for(event),                    # Tailwind CSS color class
        url: event.url,                                       # Click destination URL
        read: notification.read?,                             # Read status for UI styling
        created_at: notification.created_at,                  # Full timestamp for sorting/details
        time_ago: time_ago_in_words(notification.created_at), # Human-friendly time display
        params: event.params                                  # Additional event-specific data
      }
    end

    # Determine the appropriate Tailwind CSS color class for notification icons
    # Based on the notification type to provide visual context and hierarchy
    #
    # Color scheme:
    # - Green: Positive changes (status updates, account improvements)
    # - Indigo: Administrative actions (role changes, admin actions)
    # - Red: Security alerts requiring attention
    # - Yellow: Email changes requiring verification
    # - Gray: Default for unclassified notifications
    #
    # Integration: Used with Phosphor icons to create consistent visual language
    def icon_color_for(event)
      case event.notification_type
      when "status_change", "account_update"
        "text-green-600"    # Positive, success-oriented actions
      when "role_change", "admin_action"
        "text-indigo-600"   # Administrative, neutral but important
      when "security_alert"
        "text-red-600"      # Critical, requires immediate attention
      when "email_change"
        "text-yellow-600"   # Warning, requires verification
      else
        "text-gray-600"     # Default for unknown or general notifications
      end
    end
  end
end
