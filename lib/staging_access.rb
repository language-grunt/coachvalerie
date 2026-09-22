require "digest"
require "rack/auth/basic"
require "rack/utils"

# Candidate perimeter only. This does not grant CMS or agent permissions.
class StagingAccess
  PRIVATE_HEADERS = {
    "x-robots-tag" => "noindex, nofollow, noarchive",
    "cache-control" => "private, no-store",
    "referrer-policy" => "no-referrer"
  }.freeze

  def initialize(app, enabled:, username: nil, password: nil)
    @app, @enabled = app, enabled
    return unless @enabled

    if username.to_s.strip.empty? || password.to_s.strip.empty?
      raise ArgumentError, "Staging access requires both credential environment variables"
    end
    @username_digest = Digest::SHA256.hexdigest(username)
    @password_digest = Digest::SHA256.hexdigest(password)
  end

  def call(env)
    return @app.call(env) unless @enabled

    if health_request?(env) || authenticated?(env)
      status, headers, body = @app.call(env)
      return [status, headers.merge(PRIVATE_HEADERS), body]
    end

    headers = PRIVATE_HEADERS.merge(
      "www-authenticate" => 'Basic realm="Coach Valerie preview", charset="UTF-8"',
      "content-type" => "text/plain; charset=utf-8"
    )
    body = env["REQUEST_METHOD"] == "HEAD" ? [] : ["Preview access requires a password.\n"]
    [401, headers, body]
  end

  private

  def health_request?(env)
    env["PATH_INFO"] == "/up" && %w[GET HEAD].include?(env["REQUEST_METHOD"])
  end

  def authenticated?(env)
    auth = Rack::Auth::Basic::Request.new(env)
    return false unless auth.provided? && auth.basic?
    username, password = auth.credentials
    return false unless username && password

    # Compare fixed-length digests and evaluate both comparisons.
    Rack::Utils.secure_compare(Digest::SHA256.hexdigest(username), @username_digest) &
      Rack::Utils.secure_compare(Digest::SHA256.hexdigest(password), @password_digest)
  rescue ArgumentError
    false
  end
end
