# Extensions for Noticed notifications to provide easy access to notifier methods
module NoticedNotificationExtensions
  extend ActiveSupport::Concern
  
  included do
    # Ensure all subclasses also get these methods
    def self.inherited(subclass)
      super
      subclass.include NoticedNotificationExtensions unless subclass.included_modules.include?(NoticedNotificationExtensions)
    end
  end

  # Create a proxy object that has access to both notification and event data
  def notifier_proxy
    @notifier_proxy ||= NotifierProxy.new(self)
  end

  def message
    notifier_proxy.message
  end

  def icon
    notifier_proxy.icon
  end

  def notification_type
    notifier_proxy.notification_type
  end

  def url
    notifier_proxy.url
  end

  def priority
    notifier_proxy.priority
  end
  
  def details
    notifier_proxy.details if notifier_proxy.respond_to?(:details)
  end

  # Proxy class that provides access to notifier methods
  class NotifierProxy
    attr_reader :notification, :event, :recipient

    def initialize(notification)
      @notification = notification
      @event = notification.event
      @recipient = notification.recipient
      @params = @event.params || {}
    end

    # Dynamically call methods defined in the notifier's notification_methods block
    def method_missing(method_name, *args, &block)
      # Get the notifier class
      notifier_class = @event.class
      
      # Create a temporary instance to access the methods
      temp_notifier = notifier_class.new(params: @params)
      temp_notifier.instance_variable_set(:@recipient, @recipient)
      temp_notifier.instance_variable_set(:@params, @params)
      
      # Define helper methods that notifiers might use
      temp_notifier.define_singleton_method(:recipient) { @recipient }
      temp_notifier.define_singleton_method(:params) { @params }
      temp_notifier.define_singleton_method(:formatted_timestamp) { Time.current.strftime("%B %d, %Y at %I:%M %p") }
      
      if temp_notifier.respond_to?(method_name)
        temp_notifier.send(method_name, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      notifier_class = @event.class
      temp_notifier = notifier_class.new(params: @params)
      temp_notifier.respond_to?(method_name) || super
    end
  end
end