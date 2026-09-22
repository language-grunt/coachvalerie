require_relative "boot"
require "rails"
require "action_controller/railtie"
require "active_record/railtie"
require_relative "../lib/staging_access"

Bundler.require(*Rails.groups)

module CoachValerie
  class Application < Rails::Application
    config.load_defaults 8.1
    config.api_only = true
    config.eager_load = Rails.env.production?
    config.secret_key_base = ENV.fetch("SECRET_KEY_BASE") { Rails.env.production? ? nil : "local-test-only-" * 8 }
    config.logger = ActiveSupport::Logger.new($stdout)
    config.log_level = :info

    access_enabled = ENV.fetch("STAGING_ACCESS_ENABLED", Rails.env.production? ? "true" : "false")
    raise "STAGING_ACCESS_ENABLED must be true or false" unless %w[true false].include?(access_enabled)
    # SSL handling runs first; the gate precedes static files, routing and controllers.
    config.middleware.insert_before Rack::Sendfile, StagingAccess,
      enabled: access_enabled == "true",
      username: ENV["STAGING_ACCESS_USERNAME"],
      password: ENV["STAGING_ACCESS_PASSWORD"]

    if Rails.env.production?
      config.assume_ssl = true
      config.force_ssl = true
      config.hosts << ENV.fetch("RENDER_EXTERNAL_HOSTNAME")
      config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
    end
  end
end
