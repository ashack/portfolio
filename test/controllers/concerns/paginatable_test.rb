# frozen_string_literal: true

require "test_helper"

class PaginatableTest < ActionDispatch::IntegrationTest
  # Create a test controller that includes the concern
  class TestController < ApplicationController
    include Paginatable

    skip_after_action :verify_policy_scoped, only: :index

    def index
      @test_records = User.all
      @pagy, @records = pagy(@test_records, items: @items_per_page)
      render json: {
        page: @page.to_s,
        items_per_page: @items_per_page,
        records: @records.map(&:id),
        total_pages: @pagy.pages,
        total_count: @pagy.count
      }
    end
  end

  setup do
    # Temporarily add route for testing
    Rails.application.routes.draw do
      get "test_pagination", to: "paginatable_test/test#index"
      devise_for :users
    end

    @user = sign_in_with(email: "pagination_test@example.com")

    # Create test data - unique emails to avoid conflicts
    @test_users = []
    30.times do |i|
      @test_users << User.create!(
        email: "pagination_user_#{i}@example.com",
        password: "Password123!",
        first_name: "User",
        last_name: "Test#{('A'..'Z').to_a[i % 26]}",
        confirmed_at: Time.current
      )
    end

    # Count total users for test assertions
    @total_users = User.count
  end

  teardown do
    # Reload original routes
    Rails.application.reload_routes!
    # Clean up only our test users
    @test_users&.each(&:destroy!) if @test_users
    @user&.destroy! if @user
  end

  test "sets default pagination params" do
    get test_pagination_path

    assert_response :success
    json = JSON.parse(response.body)

    assert_equal "1", json["page"]
    assert_equal 20, json["items_per_page"]
  end

  test "accepts page parameter" do
    get test_pagination_path, params: { page: 2 }

    assert_response :success
    json = JSON.parse(response.body)

    assert_equal "2", json["page"]
  end

  test "accepts per_page parameter from allowed values" do
    [ 10, 20, 50, 100 ].each do |per_page|
      get test_pagination_path, params: { per_page: per_page }

      assert_response :success
      json = JSON.parse(response.body)

      assert_equal per_page, json["items_per_page"]
    end
  end

  test "rejects invalid per_page values and uses default" do
    [ 5, 15, 25, 200, -1, 0 ].each do |invalid_per_page|
      get test_pagination_path, params: { per_page: invalid_per_page }

      assert_response :success
      json = JSON.parse(response.body)

      assert_equal 20, json["items_per_page"], "Failed for per_page=#{invalid_per_page}"
    end
  end

  test "handles string per_page values" do
    get test_pagination_path, params: { per_page: "50" }

    assert_response :success
    json = JSON.parse(response.body)

    assert_equal 50, json["items_per_page"]
  end

  test "handles nil per_page value" do
    get test_pagination_path, params: { per_page: nil }

    assert_response :success
    json = JSON.parse(response.body)

    assert_equal 20, json["items_per_page"]
  end

  test "pagination returns correct number of records" do
    get test_pagination_path, params: { per_page: 10 }

    assert_response :success
    json = JSON.parse(response.body)

    assert_equal 10, json["records"].length
    assert_equal @total_users, json["total_count"]
    assert_equal (@total_users.to_f / 10).ceil, json["total_pages"]
  end

  test "pagination handles last page correctly" do
    # Calculate last page and expected records
    per_page = 10
    last_page = (@total_users.to_f / per_page).ceil
    expected_on_last_page = @total_users % per_page
    expected_on_last_page = per_page if expected_on_last_page == 0

    get test_pagination_path, params: { page: last_page, per_page: per_page }

    assert_response :success
    json = JSON.parse(response.body)

    assert_equal expected_on_last_page, json["records"].length
  end
end
