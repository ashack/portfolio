# Notifier for email change request workflow
# Handles notifications for submitted, approved, and rejected email change requests
class EmailChangeRequestNotifier < ApplicationNotifier
  # Required params:
  # - email_change_request: The EmailChangeRequest object
  # - action: One of 'submitted', 'approved', 'rejected'
  # - admin: Admin who approved/rejected (optional)

  # Deliver by email
  deliver_by :email do |config|
    config.mailer = "EmailChangeMailer"
    config.method = -> { email_method }
    config.params = -> { email_params }
    config.if = -> { notification_enabled?("email", "email_changes") }
  end

  # In-app notifications are saved automatically by the Noticed gem

  # Notification content for display
  def message
    case params[:action]
    when "submitted"
      "Your email change request has been submitted for approval"
    when "approved"
      "Your email change request has been approved"
    when "rejected"
      "Your email change request has been rejected"
    else
      "Email change request status updated"
    end
  end

  # Additional details for the notification
  def details
    base_details = {
      old_email: params[:email_change_request].old_email,
      new_email: params[:email_change_request].new_email,
      requested_at: params[:email_change_request].created_at.strftime("%B %d, %Y")
    }

    case params[:action]
    when "approved"
      base_details.merge(
        approved_by: params[:admin]&.full_name || "System Administrator",
        approved_at: formatted_timestamp,
        note: "Your new email is now active"
      )
    when "rejected"
      base_details.merge(
        rejected_by: params[:admin]&.full_name || "System Administrator",
        rejected_at: formatted_timestamp,
        reason: params[:email_change_request].admin_notes || "Request did not meet requirements"
      )
    else
      base_details
    end
  end

  # URL to redirect user when clicking notification
  def url
    Rails.application.routes.url_helpers.users_profile_path(recipient)
  end

  # Icon for the notification
  def icon
    case params[:action]
    when "submitted"
      "envelope-simple"
    when "approved"
      "check-circle"
    when "rejected"
      "x-circle"
    else
      "envelope"
    end
  end

  # Notification type for filtering
  def notification_type
    "email_change"
  end

  private

  def email_method
    case params[:action]
    when "submitted"
      :request_submitted
    when "approved"
      :request_approved
    when "rejected"
      :request_rejected
    else
      :request_submitted
    end
  end

  def email_params
    {
      email_change_request: params[:email_change_request],
      user: recipient,
      admin: params[:admin]
    }
  end
end
