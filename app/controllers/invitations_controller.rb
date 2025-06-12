class InvitationsController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_invitation

  def show
    if @invitation.accepted?
      redirect_to root_path, alert: "This invitation has already been accepted."
    elsif @invitation.expired?
      redirect_to root_path, alert: "This invitation has expired."
    end
  end

  def accept
    if user_signed_in?
      redirect_to root_path, alert: "You are already signed in. Please sign out to accept this invitation."
      return
    end

    if @invitation.accepted?
      redirect_to root_path, alert: "This invitation has already been accepted."
    elsif @invitation.expired?
      redirect_to root_path, alert: "This invitation has expired."
    else
      # Redirect to devise registration with invitation token
      redirect_to new_user_registration_path(invitation_token: @invitation.token)
    end
  end

  def decline
    if @invitation.destroy
      redirect_to root_path, notice: "Invitation declined."
    else
      redirect_to root_path, alert: "Failed to decline invitation."
    end
  end

  private

  def set_invitation
    @invitation = Invitation.find_by!(token: params[:id])
  end
end
