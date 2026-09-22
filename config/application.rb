require_relative "boot"
require "rails"
require "action_controller/railtie"
require "active_record/railtie"

Bundler.require(*Rails.groups)

module CoachValerie
  class Application < Rails::Application
    config.load_defaults 8.1
    config.api_only = true
    config.eager_load = Rails.env.production?
    config.secret_key_base = ENV.fetch("SECRET_KEY_BASE") { Rails.env.production? ? nil : "local-test-only-" * 8 }
    config.logger = ActiveSupport::Logger.new($stdout)
    config.log_level = :info

    if Rails.env.production?
      config.assume_ssl = true
      config.force_ssl = true
      config.hosts << ENV.fetch("RENDER_EXTERNAL_HOSTNAME")
      config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
    end
  end
end
