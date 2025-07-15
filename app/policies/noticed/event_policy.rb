# Policy for Noticed::Event (notification events)
# Super admins and site admins can view all events
module Noticed
  class EventPolicy < ApplicationPolicy
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
end
