class TeamPolicy < ApplicationPolicy
  def show?
    super_admin? || site_admin? || team_member?
  end

  def create?
    super_admin?
  end

  def update?
    super_admin? || team_admin?
  end

  def destroy?
    super_admin?
  end

  def admin_access?
    super_admin? || team_admin?
  end

  private

  def team_member?
    @user&.team_id == @record&.id
  end

  def team_admin?
    @user&.team_id == @record&.id && @user&.team_role == 'admin'
  end
  
  class Scope < ApplicationPolicy::Scope
    def resolve
      if @user.super_admin? || @user.site_admin?
        scope.all
      elsif @user.team_id
        scope.where(id: @user.team_id)
      else
        scope.none
      end
    end
  end
end