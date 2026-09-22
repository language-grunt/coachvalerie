# Coach Valerie staging deployment proof

A minimal Rails 8.1 app with PostgreSQL, solely to prove GitHub to Render deployment. This is not the full Rails foundation or the public website.

## Behavior

Authenticated GET / executes `SELECT message FROM greetings WHERE id = 1` and returns `hello world`. GET/HEAD /up is the public Rails boot health check. The root response verifies the database connection and dummy row. The migration creates a greetings table and inserts the one test row; it runs before deployment.

## Local setup and test

Use Ruby 3.4.10 and PostgreSQL 18. Set DATABASE_URL to a local PostgreSQL database URL, then run:

```sh
bundle install
bundle exec ruby bin/rails db:prepare
bundle exec rackup --server webrick --host 127.0.0.1 --port 3000
```

For tests use a separate database:

```sh
RAILS_ENV=test DATABASE_URL=postgres://localhost/coachvalerie_test bundle exec ruby bin/rails db:prepare
RAILS_ENV=test DATABASE_URL=postgres://localhost/coachvalerie_test bundle exec ruby test/smoke_test.rb
bundle exec ruby test/staging_access_test.rb
```

The CI workflow provides its own disposable Postgres service. WEBrick serves this small proof only; choose the full application's server during the subsequent Rails foundation task.

## Render

Apply render.yaml from staging-smoke and assign both resources to the existing coachvalerie.com project, Staging environment. Web compute is $7/month; PostgreSQL compute is $6/month plus $0.30/month for 1 GB storage. Total approved base cost: $13.30/month before taxes or usage overages. Storage autoscaling is disabled. Both resources use Ohio. The database accepts only internal connections.

Render generates SECRET_KEY_BASE and supplies DATABASE_URL by a Blueprint reference; no secret values are committed. RENDER_EXTERNAL_HOSTNAME is supplied by Render. Production runtime settings apply to the staging application; no production business deployment is involved.

Use the generated onrender.com HTTPS hostname. Do not change CoachValerie.com DNS or the incumbent site. No CMS, customer data, storage integrations, marketing, or public pages are included.

## Protected preview (CV-024A)

The Render candidate requires HTTP Basic authentication on every path, including static assets and unknown routes. Only exact GET/HEAD `/up` requests bypass the gate. SSL redirects run before authentication; the gate runs before static file handling. Protected responses include `X-Robots-Tag: noindex, nofollow, noarchive` and `Cache-Control: private, no-store`.

`STAGING_ACCESS_ENABLED=true` enables the gate (also the default for the production Rails runtime used on staging). Startup fails if either `STAGING_ACCESS_USERNAME` or `STAGING_ACCESS_PASSWORD` is missing or blank. The Blueprint generates a staging password; retrieve it from this service's Render environment settings. Never put it in a URL, ticket, PR, screenshot or source. Local development defaults to disabled; tests exercise both gated requests and the health exception using test-only credentials.

The current staging username is `valerie`. To rotate access, update only `STAGING_ACCESS_PASSWORD` in Render and redeploy the same verified commit. The gate applies regardless of hostname, so adding the eventual `next.coachvalerie.com` hostname cannot bypass it. Custom hostname/DNS/TLS setup is a separate task. This shared preview password grants no CMS or agent permissions.

Rollback must preserve access protection: deploy the last verified protected commit or fix forward; do not return to the anonymous smoke app. No database migration is needed for the gate.

This branch is separate from main so CLI development can proceed independently. Acceptance requires passing CI, anonymous/incorrect-password 401 responses, an authenticated root 200, and a public health 200 from the verified deployed commit.
