ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class SmokeTest < ActionDispatch::IntegrationTest
  test "root serves the Rails staging proof" do
    get "/"
    assert_response :success
    assert_equal "hello world\n", response.body
    assert_equal "noindex, nofollow", response.headers["X-Robots-Tag"]
  end

  test "health endpoint succeeds" do
    get "/up"
    assert_response :success
  end

  test "root really reads the database" do
    ActiveRecord::Base.connection.execute("UPDATE greetings SET message = 'changed' WHERE id = 1")
    assert_raises(RuntimeError) { get "/" }
  end
end
