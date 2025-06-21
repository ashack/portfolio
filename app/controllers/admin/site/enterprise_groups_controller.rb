class Admin::Site::EnterpriseGroupsController < Admin::Site::BaseController
  before_action :set_enterprise_group, only: [ :show ]

  def show
    authorize @enterprise_group, :show?
    @members = @enterprise_group.users
    @pending_invitations = @enterprise_group.invitations.pending.includes(:invited_by)
  end

  private

  def set_enterprise_group
    @enterprise_group = EnterpriseGroup.find_by!(slug: params[:id])
  end
end
