class InvitationPolicy < ApplicationPolicy
  def index?
    super_admin? || team_admin_for_team? || enterprise_admin_for_group?
  end

  def show?
    super_admin? || team_admin_for_team? || enterprise_admin_for_group? || invitation_recipient?
  end

  def create?
    super_admin? || team_admin_for_team? || enterprise_admin_for_group?
  end

  def resend?
    create?
  end

  def revoke?
    create?
  end

  def accept?
    invitation_recipient? && !@record.accepted?
  end

  def decline?
    accept?
  end

  private

  def team_admin_for_team?
    return false unless @record.team_invitation?
    @user&.team_id == @record&.team_id && @user&.team_role == "admin"
  end

  def enterprise_admin_for_group?
    return false unless @record.enterprise_invitation?
    return false unless @user&.enterprise?

    # Check if user is admin of the enterprise group
    @user.enterprise_group_id == @record.invitable_id && @user.enterprise_group_role == "admin"
  end

  def invitation_recipient?
    @record&.email == @user&.email
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if @user.super_admin?
        scope.all
      elsif @user.team_admin?
        scope.where(team_id: @user.team_id)
      elsif @user.enterprise_admin?
        scope.where(invitable_type: "EnterpriseGroup", invitable_id: @user.enterprise_group_id)
      else
        scope.none
      end
    end
  end
end
