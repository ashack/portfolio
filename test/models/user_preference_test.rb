# frozen_string_literal: true

require "test_helper"

class UserPreferenceTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email: "pref_test@example.com",
      password: "Password123!",
      first_name: "Test",
      last_name: "User",
      confirmed_at: Time.current
    )
  end

  teardown do
    UserPreference.where(user: @user).destroy_all if @user
    @user&.destroy!
  end

  test "valid user preference" do
    preference = UserPreference.new(
      user: @user,
      pagination_settings: { "users" => 50, "teams" => 20 }
    )

    assert preference.valid?
  end

  test "requires user" do
    preference = UserPreference.new(
      pagination_settings: { "users" => 50 }
    )

    assert_not preference.valid?
    assert_includes preference.errors[:user], "must exist"
  end

  test "one preference per user" do
    UserPreference.create!(
      user: @user,
      pagination_settings: { "users" => 50 }
    )

    duplicate = UserPreference.new(
      user: @user,
      pagination_settings: { "teams" => 20 }
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  test "pagination_settings defaults to empty hash" do
    preference = UserPreference.new(user: @user)

    assert_equal({}, preference.pagination_settings)
  end

  test "get_items_per_page returns setting for controller" do
    preference = UserPreference.create!(
      user: @user,
      pagination_settings: { "users" => 50, "teams" => 100 }
    )

    assert_equal 50, preference.get_items_per_page("users")
    assert_equal 100, preference.get_items_per_page("teams")
    assert_nil preference.get_items_per_page("posts")
  end

  test "set_items_per_page updates setting for controller" do
    preference = UserPreference.create!(
      user: @user,
      pagination_settings: { "users" => 50 }
    )

    preference.set_items_per_page("teams", 100)
    preference.save!
    preference.reload

    assert_equal 50, preference.pagination_settings["users"]
    assert_equal 100, preference.pagination_settings["teams"]
  end

  test "set_items_per_page validates allowed values" do
    preference = UserPreference.create!(
      user: @user,
      pagination_settings: {}
    )

    # Valid values
    [ 10, 20, 50, 100 ].each do |value|
      assert preference.set_items_per_page("users", value)
      assert_equal value, preference.pagination_settings["users"]
    end

    # Invalid values - should not update
    [ 5, 15, 200, -1, 0 ].each do |invalid_value|
      assert_not preference.set_items_per_page("users", invalid_value)
      assert_not_equal invalid_value, preference.pagination_settings["users"]
    end
  end

  test "clear_pagination_settings removes all settings" do
    preference = UserPreference.create!(
      user: @user,
      pagination_settings: { "users" => 50, "teams" => 100 }
    )

    preference.clear_pagination_settings
    preference.save!
    preference.reload

    assert_equal({}, preference.pagination_settings)
  end

  test "user association" do
    preference = UserPreference.create!(
      user: @user,
      pagination_settings: {}
    )

    assert_equal @user, preference.user
    assert_equal preference, @user.reload.user_preference
  end
end
