class EnterpriseGroupPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.system_role == "super_admin" || user&.system_role == "site_admin"
        scope.all
      else
        scope.none
      end
    end
  end

  def index?
    admin?
  end

  def show?
    admin?
  end

  def create?
    super_admin?
  end

  def new?
    create?
  end

  def update?
    super_admin?
  end

  def edit?
    update?
  end

  def destroy?
    super_admin? && record.users.empty?
  end

  private

  def super_admin?
    user&.super_admin?
  end

  def admin?
    super_admin? || user&.site_admin?
  end
end
