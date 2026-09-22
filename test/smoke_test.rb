ENV["RAILS_ENV"] ||= "test"
ENV["STAGING_ACCESS_ENABLED"] = "true"
ENV["STAGING_ACCESS_USERNAME"] = "test-preview"
ENV["STAGING_ACCESS_PASSWORD"] = "test-only-not-a-deployed-password"
require_relative "../config/environment"
require "rails/test_help"

class SmokeTest < ActionDispatch::IntegrationTest
  def preview_headers
    { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials(
      ENV.fetch("STAGING_ACCESS_USERNAME"), ENV.fetch("STAGING_ACCESS_PASSWORD")) }
  end

  test "root serves the Rails staging proof" do
    get "/preview-health/database", headers: preview_headers
    assert_response :success
    assert_equal "hello world\n", response.body
    assert_equal "noindex, nofollow, noarchive", response.headers["X-Robots-Tag"]
    assert_equal "private, no-store", response.headers["Cache-Control"]
  end

  test "health endpoint succeeds" do
    get "/up"
    assert_response :success
  end

  test "root really reads the database" do
    ActiveRecord::Base.connection.execute("UPDATE greetings SET message = 'changed' WHERE id = 1")
    get "/preview-health/database", headers: preview_headers
    assert_response :internal_server_error
  end

  test "anonymous pages assets and unknown routes require authentication" do
    ["/", "/assets/private.jpg", "/missing", "/up/", "/robots.txt"].each do |path|
      get path
      assert_response :unauthorized
      assert_match(/Basic/, response.headers["WWW-Authenticate"])
    end
  end

  test "wrong credentials do not reach the database backed controller" do
    get "/", headers: { "Authorization" => "Basic #{["wrong:wrong"].pack("m0")}" }
    assert_response :unauthorized
  end

  test "health exception is limited to GET and HEAD" do
    head "/up"
    assert_response :success
    assert_equal "private, no-store", response.headers["Cache-Control"]
    post "/up"
    assert_response :unauthorized
  end

  test "gate precedes the static file middleware" do
    stack = Rails.application.middleware.map(&:klass)
    assert_operator stack.index(StagingAccess), :<, stack.index(ActionDispatch::Static)
  end
end

