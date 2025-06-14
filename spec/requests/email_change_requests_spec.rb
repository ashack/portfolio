require 'rails_helper'

RSpec.describe "EmailChangeRequests", type: :request do
  describe "GET /new" do
    it "returns http success" do
      get "/email_change_requests/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/email_change_requests/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/email_change_requests/show"
      expect(response).to have_http_status(:success)
    end
  end
end
