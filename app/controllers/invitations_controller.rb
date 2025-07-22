# Controller for handling public invitation acceptance flow
# Allows invited users to view, accept, or decline team/enterprise invitations
# Publicly accessible since invited users don't have accounts yet
class InvitationsController < ApplicationController
  # Allow public access - invited users aren't authenticated yet
  skip_before_action :authenticate_user!
  # Skip authorization - public invitation handling
  skip_after_action :verify_authorized
  # Load invitation for all actions
  before_action :set_invitation

  # GET /invitations/:token
  # Display invitation details to invited user
  # Shows team/enterprise info and accept/decline options
  def show
    # Check invitation status and redirect if invalid
    if @invitation.accepted?
      redirect_to root_path, alert: "This invitation has already been accepted."
    elsif @invitation.expired?
      redirect_to root_path, alert: "This invitation has expired."
    end
    # If valid, render invitation details view
  end

  # PATCH /invitations/:token/accept
  # Accept invitation and redirect to registration
  # Stores invitation token for registration process
  def accept
    # Prevent logged-in users from accepting invitations
    # They need to sign out first to create a new invited user account
    if user_signed_in?
      redirect_to root_path, alert: "You are already signed in. Please sign out to accept this invitation."
      return
    end

    # Validate invitation status
    if @invitation.accepted?
      redirect_to root_path, alert: "This invitation has already been accepted."
    elsif @invitation.expired?
      redirect_to root_path, alert: "This invitation has expired."
    else
      # Store invitation token in session for the registration process
      # This allows the registration controller to access invitation details
      session[:invitation_token] = @invitation.token
      # Redirect to devise registration with invitation token in URL
      redirect_to new_user_registration_path(invitation_token: @invitation.token)
    end
  end

  # PATCH /invitations/:token/decline
  # Decline invitation and delete it from the system
  # Permanently removes the invitation
  def decline
    if @invitation.destroy
      redirect_to root_path, notice: "Invitation declined."
    else
      redirect_to root_path, alert: "Failed to decline invitation."
    end
  end

  private

  # Load invitation by secure token from URL parameter
  # Raises ActiveRecord::RecordNotFound if token is invalid
  def set_invitation
    @invitation = Invitation.find_by!(token: params[:id])
  end
end
