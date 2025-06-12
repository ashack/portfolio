class InvitationPolicy < ApplicationPolicy
  def index?
    super_admin? || team_admin_for_team?
  end

  def show?
    super_admin? || team_admin_for_team? || invitation_recipient?
  end

  def create?
    super_admin? || team_admin_for_team?
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
    @user&.team_id == @record&.team_id && @user&.team_role == "admin"
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
      else
        scope.none
      end
    end
  end
end
