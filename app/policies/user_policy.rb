class UserPolicy < ApplicationPolicy
  def index?
    admin?
  end

  def show?
    admin? || @user == @record
  end

  def set_status?
    admin?
  end

  def impersonate?
    admin? && @user != @record
  end

  def destroy?
    super_admin? || (team_admin? && same_team?)
  end

  private

  def team_admin?
    @user&.team_role == "admin"
  end

  def same_team?
    @user&.team_id == @record&.team_id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if @user.super_admin?
        scope.all
      elsif @user.site_admin?
        scope.where.not(system_role: "super_admin")
      elsif @user.team_admin?
        scope.where(team_id: @user.team_id)
      else
        scope.none
      end
    end
  end
end
