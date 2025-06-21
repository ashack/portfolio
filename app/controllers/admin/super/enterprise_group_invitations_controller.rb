class Admin::Super::EnterpriseGroupInvitationsController < ApplicationController
  include ActivityTrackable
  
  layout "admin"
  before_action :require_super_admin!
  before_action :set_enterprise_group
  before_action :set_invitation, only: [:resend, :revoke]
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  def index
    @invitations = policy_scope(@enterprise_group.invitations).includes(:invited_by).order(created_at: :desc)
    @pagy, @invitations = pagy(@invitations)
  end

  def resend
    authorize @invitation
    
    if !@invitation.accepted? && !@invitation.expired?
      # Reset expiration to 7 days from now
      @invitation.update!(expires_at: 7.days.from_now)
      
      # Resend the invitation email
      if Rails.env.development?
        EnterpriseGroupMailer.admin_invitation(@invitation, @enterprise_group).deliver_now
      else
        EnterpriseGroupMailer.admin_invitation(@invitation, @enterprise_group).deliver_later
      end
      
      redirect_to admin_super_enterprise_group_path(@enterprise_group), 
                  notice: "Invitation was resent to #{@invitation.email}."
    else
      redirect_to admin_super_enterprise_group_path(@enterprise_group), 
                  alert: "Cannot resend this invitation."
    end
  end

  def revoke
    authorize @invitation
    
    if @invitation.accepted?
      redirect_to admin_super_enterprise_group_path(@enterprise_group), 
                  alert: "Cannot revoke an accepted invitation."
    elsif @invitation.destroy
      redirect_to admin_super_enterprise_group_path(@enterprise_group), 
                  notice: "Invitation was revoked."
    else
      redirect_to admin_super_enterprise_group_path(@enterprise_group), 
                  alert: "Failed to revoke invitation."
    end
  end

  private

  def require_super_admin!
    unless current_user&.super_admin?
      flash[:alert] = "You must be a super admin to access this area."
      redirect_to root_path
    end
  end

  def set_enterprise_group
    @enterprise_group = EnterpriseGroup.find_by!(slug: params[:enterprise_group_id])
  end

  def set_invitation
    @invitation = @enterprise_group.invitations.find(params[:id])
  end
end