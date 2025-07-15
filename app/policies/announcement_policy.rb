# Policy for announcement management
# Super admins can manage, site admins can view
class AnnouncementPolicy < ApplicationPolicy
  def index?
    super_admin? || site_admin?
  end

  def show?
    super_admin? || site_admin?
  end

  def new?
    super_admin?
  end

  def create?
    super_admin?
  end

  def edit?
    super_admin?
  end

  def update?
    super_admin?
  end

  def destroy?
    super_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.super_admin? || user.site_admin?
        scope.all
      else
        scope.none
      end
    end
  end
end
