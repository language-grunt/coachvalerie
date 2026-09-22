require "minitest/autorun"
require "rack/mock"
require_relative "../lib/staging_access"

class StagingAccessTest < Minitest::Test
  def setup
    @calls = 0
    app = ->(_env) { @calls += 1; [200, { "content-type" => "text/plain" }, ["private content"]] }
    @request = Rack::MockRequest.new(StagingAccess.new(app,
      enabled: true, username: "preview", password: "test-password"))
  end

  def authorization(value)
    { "HTTP_AUTHORIZATION" => "Basic #{[value].pack("m0")}" }
  end

  def test_missing_wrong_and_malformed_credentials_never_reach_app
    [nil, "Bearer test", "Basic", "Basic !!!", "Basic #{["preview"].pack("m0")}"].each do |value|
      assert_equal 401, @request.get("/", "HTTP_AUTHORIZATION" => value).status
    end
    ["preview:wrong", "wrong:test-password", ":", "preview:"].each do |value|
      assert_equal 401, @request.get("/", authorization(value)).status
    end
    assert_equal 0, @calls
  end

  def test_valid_credentials_allow_pages_and_assets_on_any_candidate_host
    ["coachvalerie-staging.onrender.com", "next.coachvalerie.com"].each do |host|
      ["/", "/assets/private.jpg"].each do |path|
        response = @request.get("https://#{host}#{path}", authorization("preview:test-password"))
        assert_equal 200, response.status
        assert_equal "private, no-store", response["cache-control"]
        assert_equal "noindex, nofollow, noarchive", response["x-robots-tag"]
      end
    end
  end

  def test_denied_responses_are_private_and_not_indexable
    response = @request.get("/assets/private.jpg")
    assert_equal 401, response.status
    assert_equal "private, no-store", response["cache-control"]
    assert_equal "noindex, nofollow, noarchive", response["x-robots-tag"]
    assert_equal "no-referrer", response["referrer-policy"]
    assert_empty @request.head("/").body
  end

  def test_only_exact_health_get_and_head_bypass_gate
    %w[GET HEAD].each { |method| assert_equal 200, @request.request(method, "/up").status }
    %w[POST PUT PATCH DELETE OPTIONS].each do |method|
      assert_equal 401, @request.request(method, "/up").status
    end
    ["/up/", "/up/private", "/UP", "/%75p", "/up%2f..%2f"].each do |path|
      assert_equal 401, @request.get(path).status
    end
  end

  def test_missing_credentials_fail_closed_at_startup
    [nil, "", " "].each do |missing|
      assert_raises(ArgumentError) { StagingAccess.new(nil, enabled: true, username: "preview", password: missing) }
      assert_raises(ArgumentError) { StagingAccess.new(nil, enabled: true, username: missing, password: "password") }
    end
  end

  def test_explicitly_disabled_local_gate_passes_through
    app = ->(_env) { [200, {}, ["local"]] }
    response = Rack::MockRequest.new(StagingAccess.new(app, enabled: false)).get("/")
    assert_equal "local", response.body
    assert_nil response["x-robots-tag"]
  end
end
