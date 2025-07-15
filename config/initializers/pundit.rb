# Configure Pundit to handle Noticed notification subclasses
Rails.application.config.to_prepare do
  # Override Pundit's policy finder for notifications
  Pundit::PolicyFinder.class_eval do
    alias_method :original_policy, :policy unless method_defined?(:original_policy)

    def policy
      # If the object is any kind of Noticed notification, use NotificationPolicy
      if object.is_a?(Noticed::Notification) ||
         (object.class.respond_to?(:ancestors) && object.class.ancestors.include?(Noticed::Notification))
        ::NotificationPolicy
      else
        original_policy
      end
    end
  end
end
