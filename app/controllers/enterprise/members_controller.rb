class Enterprise::MembersController < Enterprise::BaseController
  before_action :require_admin!, except: [ :index, :show ]
  before_action :set_member, only: [ :show, :edit, :update, :destroy ]
  skip_after_action :verify_policy_scoped, only: [ :index ]
  skip_after_action :verify_authorized, only: [ :new, :create, :edit, :update, :destroy, :resend_invitation, :revoke_invitation ]

  def index
    @members = @enterprise_group.users.includes(:ahoy_visits).order(created_at: :desc)
    @pagy_members, @members = pagy(@members, page_param: :members_page)

    @pending_invitations = @enterprise_group.invitations.pending.includes(:invited_by).order(created_at: :desc)
    @pagy_invitations, @pending_invitations = pagy(@pending_invitations, page_param: :invitations_page)
  end

  def show
    # Member profile view
  end

  def new
    @invitation = @enterprise_group.invitations.build
  end

  def create
    @invitation = @enterprise_group.invitations.build(invitation_params)
    @invitation.invited_by = current_user
    @invitation.invitation_type = "enterprise"

    if @invitation.save
      # Send invitation email
      InvitationMailer.with(invitation: @invitation).invite.deliver_now
      redirect_to members_path(enterprise_group_slug: @enterprise_group.slug),
                  notice: "Invitation sent to #{@invitation.email}"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Edit member role
  end

  def update
    if @member.update(member_params)
      redirect_to members_path(enterprise_group_slug: @enterprise_group.slug),
                  notice: "Member updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @member == current_user
      redirect_to members_path(enterprise_group_slug: @enterprise_group.slug),
                  alert: "You cannot remove yourself"
    elsif @member.destroy
      redirect_to members_path(enterprise_group_slug: @enterprise_group.slug),
                  notice: "Member removed successfully"
    else
      redirect_to members_path(enterprise_group_slug: @enterprise_group.slug),
                  alert: "Failed to remove member"
    end
  end

  # Invitation management actions
  def resend_invitation
    @invitation = @enterprise_group.invitations.find(params[:id])

    if @invitation.pending?
      InvitationMailer.with(invitation: @invitation).invite.deliver_now
      redirect_to members_path(enterprise_group_slug: @enterprise_group.slug),
                  notice: "Invitation resent to #{@invitation.email}"
    else
      redirect_to members_path(enterprise_group_slug: @enterprise_group.slug),
                  alert: "Cannot resend accepted invitation"
    end
  end

  def revoke_invitation
    @invitation = @enterprise_group.invitations.find(params[:id])

    if @invitation.pending?
      @invitation.destroy
      redirect_to members_path(enterprise_group_slug: @enterprise_group.slug),
                  notice: "Invitation revoked"
    else
      redirect_to members_path(enterprise_group_slug: @enterprise_group.slug),
                  alert: "Cannot revoke accepted invitation"
    end
  end

  private

  def require_admin!
    unless current_user.enterprise_admin?
      redirect_to enterprise_dashboard_path(enterprise_group_slug: @enterprise_group.slug),
                  alert: "You don't have permission to perform this action"
    end
  end

  def set_member
    @member = @enterprise_group.users.find(params[:id])
  end

  def invitation_params
    params.require(:invitation).permit(:email, :role)
  end

  def member_params
    params.require(:user).permit(:enterprise_group_role)
  end
end
