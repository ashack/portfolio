module ValidationHelpers
  extend ActiveSupport::Concern

  class_methods do
    def validates_human_name(field, options = {})
      validates field,
        length: {
          maximum: options[:maximum] || 50,
          message: "must be #{options[:maximum] || 50} characters or less"
        },
        format: {
          with: /\A[a-zA-Z\s\-'\.]*\z/,
          message: "can only contain letters, spaces, hyphens, apostrophes, and periods"
        },
        allow_blank: options[:allow_blank] != false
    end

    def validates_proper_email(field = :email, options = {})
      validates field,
        presence: { message: "is required" },
        uniqueness: { message: "is already taken" },
        format: {
          with: URI::MailTo::EMAIL_REGEXP,
          message: "must be a valid email address"
        }
    end

    def validates_role_transition(from_field, to_field, valid_transitions)
      validate do
        if send("#{from_field}_changed?")
          old_value = send("#{from_field}_was")
          new_value = send(from_field)

          unless valid_transitions[old_value]&.include?(new_value)
            errors.add(from_field, "cannot be changed from #{old_value} to #{new_value}")
          end
        end
      end
    end
  end

  # Instance methods for custom validations
  def validate_no_self_promotion(current_user_id, field, message = nil)
    if id == current_user_id && send("#{field}_changed?")
      errors.add(field, message || "cannot be changed by yourself")
    end
  end

  def validate_business_rules_intact
    # Override in models to add custom business rule validations
  end

  def validation_context_from_thread
    # Get validation context from thread-local storage if available
    Thread.current[:validation_context] || {}
  end

  def human_attribute_errors(attribute)
    errors[attribute].map do |error|
      "#{attribute.to_s.humanize} #{error}"
    end
  end

  def critical_field_changed?
    %w[email system_role status user_type].any? { |field| send("#{field}_changed?") }
  end

  def security_sensitive_change?
    %w[system_role status].any? { |field| send("#{field}_changed?") }
  end
end
