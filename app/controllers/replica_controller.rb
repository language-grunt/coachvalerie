require "json"

# Temporary, read-only migration reference. CMS content will replace these snapshots.
class ReplicaController < ActionController::API
  ROOT = Rails.root.join("replica")
  MANIFEST = JSON.parse(ROOT.join("routes.json").read).freeze
  POLICY = "default-src 'none'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self' data:; media-src 'self'; connect-src 'none'; form-action 'none'; frame-src 'none'; frame-ancestors 'none'; base-uri 'none'; object-src 'none'".freeze

  def show
    response.set_header("Content-Security-Policy", POLICY)
    response.set_header("X-Content-Type-Options", "nosniff")
    path = request.path
    if (target = MANIFEST.fetch("aliases")[path])
      redirect_to target, status: :found, allow_other_host: false
    elsif (file = MANIFEST.fetch("pages")[path])
      render body: ROOT.join(file).read, content_type: "text/html; charset=utf-8"
    else
      render html: '<!doctype html><html lang="en"><title>Page not in preview</title><h1>This page is not in the preview yet.</h1><p><a href="/">Return to Coach Valerie</a></p></html>'.html_safe, status: :not_found
    end
  end
end
