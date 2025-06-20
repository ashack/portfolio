class TabNavigationComponent < ViewComponent::Base
  renders_many :tabs, TabComponent

  def initialize(variant: :default, remember: false, id: nil)
    @variant = variant
    @remember = remember
    @id = id || SecureRandom.hex(4)
  end

  private

  attr_reader :variant, :remember, :id

  class TabComponent < ViewComponent::Base
    attr_reader :name, :path, :count, :badge, :badge_class, :active

    def initialize(name:, path: nil, count: nil, badge: nil, badge_class: nil, active: false)
      @name = name
      @path = path
      @count = count
      @badge = badge
      @badge_class = badge_class
      @active = active
    end

    def call
      # Rendered by parent component
    end

    def tab_id
      @tab_id ||= name.parameterize
    end

    def active?
      return @active if defined?(@active)
      return false unless path
      
      helpers.current_page?(path)
    end

    def tab_classes
      if active?
        "border-indigo-500 text-indigo-600"
      else
        "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
      end
    end

    def badge_classes
      if active?
        "bg-indigo-100 text-indigo-600"
      else
        "bg-gray-100 text-gray-900"
      end
    end
  end
end