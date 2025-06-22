module Cacheable
  extend ActiveSupport::Concern

  included do
    # Clear model caches after save
    after_commit :clear_model_caches
  end

  class_methods do
    # Cache key for collections
    def cache_key_for_collection(scope = :all)
      # Uses the maximum updated_at timestamp and count for cache busting
      max_updated_at = maximum(:updated_at)&.utc&.to_fs(:number) || "0"
      count = send(scope).count
      "#{model_name.cache_key}/collection-#{scope}-#{count}-#{max_updated_at}"
    end
  end

  # Instance cache key including attributes that affect display
  def cache_key_with_version
    "#{model_name.cache_key}/#{id}-#{updated_at.utc.to_fs(:number)}"
  end

  private

  def clear_model_caches
    # Override in models to clear specific caches
  end
end
