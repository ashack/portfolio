# Policy for Noticed notifications
# This policy applies to all Noticed::Notification subclasses
class NotificationPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      # Users can only see their own notifications
      scope.where(recipient: user)
    end
  end

  # Users can view their own notifications
  def show?
    record.recipient == user
  end

  # Users can mark their own notifications as read
  def mark_as_read?
    record.recipient == user
  end

  # Users can delete their own notifications
  def destroy?
    record.recipient == user
  end
end