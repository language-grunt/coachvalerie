ENV["RAILS_ENV"] = "test"
ENV["STAGING_ACCESS_ENABLED"] = "true"
ENV["STAGING_ACCESS_USERNAME"] = "test-preview"
ENV["STAGING_ACCESS_PASSWORD"] = "test-only-not-a-deployed-password"
require_relative "../config/environment"
require "rails/test_help"
require "nokogiri"

class ReplicaTest < ActionDispatch::IntegrationTest
  def headers
    { "Authorization" => ActionController::HttpAuthentication::Basic.encode_credentials(ENV.fetch("STAGING_ACCESS_USERNAME"), ENV.fetch("STAGING_ACCESS_PASSWORD")) }
  end

  test "every archived page renders locally with isolated forms and assets" do
    manifest = ReplicaController::MANIFEST
    assert_equal 42, manifest.fetch("pages").length
    manifest.fetch("pages").each_key do |path|
      get path, headers: headers
      assert_response :success
      assert_includes response.headers["Content-Security-Policy"], "form-action 'none'"
      document = Nokogiri::HTML(response.body)
      assert_empty document.css("iframe,object,embed")
      assert_equal ["/replica-assets/preview.js"], document.css("script").map { |s| s["src"] }
      document.css("form").each { |f| assert_equal "/preview-submission", f["action"] }
      document.css("img[src],link[href]").each do |node|
        url = node["src"] || node["href"]
        next if url.to_s.empty? || url.start_with?("data:")
        assert url.start_with?("/replica-assets/"), "Remote asset: #{url}"
        assert File.file?(Rails.root.join("public", url.delete_prefix("/"))), "Missing asset: #{url}"
      end
    end
  end

  test "aliases stay inside the protected preview" do
    ReplicaController::MANIFEST.fetch("aliases").each do |source,target|
      get source, headers: headers
      assert_redirected_to target
    end
  end

  test "unknown pages fail honestly and submissions cannot reach a handler" do
    get "/not-a-page", headers: headers
    assert_response :not_found
    assert_includes response.body, "not in the preview"
    post "/preview-submission", headers: headers
    assert_response :not_found
  end

  test "pages and actual static assets require the preview password" do
    get "/Meet-Valerie"
    assert_response :unauthorized
    get "/replica-assets/preview.css"
    assert_response :unauthorized
    get "/replica-assets/preview.css", headers: headers
    assert_response :success
    assert_equal "private, no-store", response.headers["Cache-Control"]
  end

  test "case sensitive pages stay distinct and homepage preserves source navigation" do
    get "/Boundary-setting", headers: headers
    upper = response.body
    get "/boundary-setting", headers: headers
    refute_equal upper, response.body
    get "/", headers: headers
    assert_includes response.body, "Coming True"
    assert_includes response.body, '/Meet-Valerie'
    assert_includes response.body, '/journals'
  end
end
