require "test_helper"

# Test model that includes Cacheable
class CacheableTestModel < ActiveRecord::Base
  include Cacheable
  
  # Create a temporary table for testing
  def self.create_test_table
    connection.create_table :cacheable_test_models, force: true do |t|
      t.string :name
      t.string :status
      t.timestamps
    end
  end
  
  def self.drop_test_table
    connection.drop_table :cacheable_test_models if connection.table_exists?(:cacheable_test_models)
  end
  
  # For testing cache clearing
  attr_accessor :cache_cleared
  
  private
  
  def clear_model_caches
    @cache_cleared = true
  end
end

# Another test model for testing different scopes
class ScopedCacheableTestModel < ActiveRecord::Base
  include Cacheable
  
  self.table_name = 'cacheable_test_models'
  
  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }
end

class CacheableTest < ActiveSupport::TestCase
  def setup
    CacheableTestModel.create_test_table
    Rails.cache.clear
    
    @model1 = CacheableTestModel.create!(name: "Model 1", status: "active")
    @model2 = CacheableTestModel.create!(name: "Model 2", status: "inactive")
    @model3 = CacheableTestModel.create!(name: "Model 3", status: "active")
  end
  
  def teardown
    CacheableTestModel.drop_test_table
  end
  
  # Class method tests
  test "cache_key_for_collection returns consistent key for all scope" do
    key1 = CacheableTestModel.cache_key_for_collection(:all)
    key2 = CacheableTestModel.cache_key_for_collection(:all)
    
    assert_equal key1, key2
    assert_match %r{cacheable_test_models/collection-all-3-\d+}, key1
  end
  
  test "cache_key_for_collection includes count in key" do
    key_before = CacheableTestModel.cache_key_for_collection(:all)
    
    CacheableTestModel.create!(name: "Model 4", status: "active")
    
    key_after = CacheableTestModel.cache_key_for_collection(:all)
    
    assert_not_equal key_before, key_after
    assert_match %r{collection-all-3}, key_before
    assert_match %r{collection-all-4}, key_after
  end
  
  test "cache_key_for_collection includes max updated_at in key" do
    key_before = CacheableTestModel.cache_key_for_collection(:all)
    
    # Sleep for a full second to ensure different timestamp
    sleep 1.1
    @model1.touch
    
    key_after = CacheableTestModel.cache_key_for_collection(:all)
    
    assert_not_equal key_before, key_after
  end
  
  test "cache_key_for_collection works with custom scopes" do
    # Use ScopedCacheableTestModel to test scopes
    active_key = ScopedCacheableTestModel.cache_key_for_collection(:active)
    inactive_key = ScopedCacheableTestModel.cache_key_for_collection(:inactive)
    
    assert_not_equal active_key, inactive_key
    assert_match %r{collection-active-2}, active_key  # 2 active models
    assert_match %r{collection-inactive-1}, inactive_key  # 1 inactive model
  end
  
  test "cache_key_for_collection handles empty collections" do
    CacheableTestModel.destroy_all
    
    key = CacheableTestModel.cache_key_for_collection(:all)
    
    assert_match %r{collection-all-0-0}, key
  end
  
  test "cache_key_for_collection handles nil max updated_at" do
    # Create a model class without any records
    CacheableTestModel.destroy_all
    
    key = CacheableTestModel.cache_key_for_collection(:all)
    
    assert_match %r{collection-all-0-0}, key
    assert_not_nil key
  end
  
  # Instance method tests
  test "cache_key_with_version returns unique key per instance" do
    key1 = @model1.cache_key_with_version
    key2 = @model2.cache_key_with_version
    
    assert_not_equal key1, key2
    assert_match %r{cacheable_test_models/#{@model1.id}-\d+}, key1
    assert_match %r{cacheable_test_models/#{@model2.id}-\d+}, key2
  end
  
  test "cache_key_with_version changes when model is updated" do
    key_before = @model1.cache_key_with_version
    
    # Sleep for a full second to ensure different timestamp
    sleep 1.1
    @model1.update!(name: "Updated Model 1")
    
    key_after = @model1.cache_key_with_version
    
    assert_not_equal key_before, key_after
  end
  
  test "cache_key_with_version includes model name" do
    key = @model1.cache_key_with_version
    
    assert_match %r{cacheable_test_models/}, key
  end
  
  test "cache_key_with_version formats timestamp correctly" do
    # Freeze time for consistent testing
    frozen_time = Time.utc(2024, 1, 15, 10, 30, 45)
    
    @model1.update_column(:updated_at, frozen_time)
    
    key = @model1.cache_key_with_version
    expected_timestamp = frozen_time.to_fs(:number)
    
    assert_match %r{#{expected_timestamp}}, key
  end
  
  # Callback tests
  test "clear_model_caches is called after commit" do
    model = CacheableTestModel.new(name: "Test Model")
    
    assert_nil model.cache_cleared
    
    model.save!
    
    assert model.cache_cleared, "clear_model_caches should be called after save"
  end
  
  test "clear_model_caches is called on update" do
    @model1.cache_cleared = false
    
    @model1.update!(name: "Updated Name")
    
    assert @model1.cache_cleared, "clear_model_caches should be called after update"
  end
  
  test "clear_model_caches is called on destroy" do
    @model1.cache_cleared = false
    
    @model1.destroy
    
    assert @model1.cache_cleared, "clear_model_caches should be called after destroy"
  end
  
  test "clear_model_caches is not called on failed save" do
    model = CacheableTestModel.new(name: "Test")
    
    # Force validation failure using a transaction rollback
    ActiveRecord::Base.transaction do
      model.save!
      raise ActiveRecord::Rollback
    end
    
    # The callback is an after_commit, so it shouldn't be called on rollback
    assert_nil model.cache_cleared, "clear_model_caches should not be called on failed save"
  end
  
  # Integration tests
  test "multiple models can include Cacheable" do
    assert CacheableTestModel.ancestors.include?(Cacheable)
    assert ScopedCacheableTestModel.ancestors.include?(Cacheable)
    
    # Both should have the class methods
    assert CacheableTestModel.respond_to?(:cache_key_for_collection)
    assert ScopedCacheableTestModel.respond_to?(:cache_key_for_collection)
    
    # Both should have the instance methods
    assert @model1.respond_to?(:cache_key_with_version)
    assert ScopedCacheableTestModel.new.respond_to?(:cache_key_with_version)
  end
  
  test "cache keys are unique across different model classes" do
    key1 = CacheableTestModel.cache_key_for_collection(:all)
    key2 = ScopedCacheableTestModel.cache_key_for_collection(:all)
    
    # Even though they use the same table, the model name should differ
    assert_match %r{cacheable_test_models/collection}, key1
    assert_match %r{scoped_cacheable_test_models/collection}, key2
  end
  
  # Edge case tests
  test "handles models with very long updated_at timestamps" do
    far_future = Time.utc(9999, 12, 31, 23, 59, 59)
    @model1.update_column(:updated_at, far_future)
    
    key = @model1.cache_key_with_version
    
    assert_not_nil key
    assert_match %r{\d{14}}, key  # Should have 14-digit timestamp
  end
  
  test "handles concurrent updates gracefully" do
    keys = []
    
    # Simulate concurrent updates with time delays
    3.times do |i|
      sleep 1.1  # Full second to ensure different timestamps
      @model1.update!(name: "Concurrent Update #{i}")
      keys << @model1.cache_key_with_version
    end
    
    # All keys should be unique
    assert_equal 3, keys.uniq.size
  end
end

# Test actual usage in Team and EnterpriseGroup models
class CacheableIntegrationTest < ActiveSupport::TestCase
  def setup
    @admin = User.create!(
      email: "admin@example.com",
      password: "Password123!",
      system_role: "super_admin",
      user_type: "direct",
      confirmed_at: Time.current
    )
    
    @team = Team.create!(
      name: "Test Team",
      admin: @admin,
      created_by: @admin
    )
    
    @plan = Plan.create!(
      name: "Enterprise Plan",
      plan_segment: "enterprise",
      amount_cents: 99900,
      active: true
    )
    
    @enterprise_group = EnterpriseGroup.create!(
      name: "Test Enterprise",
      created_by: @admin,
      plan: @plan
    )
  end
  
  test "Team model has its own caching implementation" do
    # Team model doesn't include Cacheable but has its own caching
    assert_not Team.ancestors.include?(Cacheable)
    
    # Team has its own caching methods
    assert Team.respond_to?(:find_by_slug!)
    assert @team.respond_to?(:to_param)
    
    # Test Team's custom caching
    found_team = Team.find_by_slug!(@team.slug)
    assert_equal @team.id, found_team.id
  end
  
  test "EnterpriseGroup model includes Cacheable concern" do
    assert EnterpriseGroup.ancestors.include?(Cacheable)
    assert @enterprise_group.respond_to?(:cache_key_with_version)
    assert EnterpriseGroup.respond_to?(:cache_key_for_collection)
  end
  
  test "Team has custom caching implementation" do
    # Team doesn't use Cacheable concern, it has its own implementation
    # Test find_by_slug! method
    found_team = Team.find_by_slug!(@team.slug)
    assert_equal @team.id, found_team.id
    
    # Test to_param method for caching
    assert_equal @team.slug, @team.to_param
  end
  
  test "EnterpriseGroup cache_key_for_collection works correctly" do
    key = EnterpriseGroup.cache_key_for_collection(:active)
    
    assert_match %r{enterprise_groups/collection-active-\d+-\d+}, key
  end
end