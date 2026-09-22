# Coach Valerie staging deployment proof

A minimal Rails 8.1 app with PostgreSQL, solely to prove GitHub to Render deployment. This is not the full Rails foundation or the public website.

## Behavior

GET / executes `SELECT message FROM greetings WHERE id = 1` and returns `hello world`. GET /up is the Rails boot health check. The root response verifies the database connection and dummy row. The migration creates a greetings table and inserts the one test row; it runs before deployment.

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
```

The CI workflow provides its own disposable Postgres service. WEBrick serves this small proof only; choose the full application's server during the subsequent Rails foundation task.

## Render

Apply render.yaml from staging-smoke and assign both resources to the existing coachvalerie.com project, Staging environment. Web compute is $7/month; PostgreSQL compute is $6/month plus $0.30/month for 1 GB storage. Total approved base cost: $13.30/month before taxes or usage overages. Storage autoscaling is disabled. Both resources use Ohio. The database accepts only internal connections.

Render generates SECRET_KEY_BASE and supplies DATABASE_URL by a Blueprint reference; no secret values are committed. RENDER_EXTERNAL_HOSTNAME is supplied by Render. Production runtime settings apply to the staging application; no production business deployment is involved.

Use the generated onrender.com HTTPS hostname. Do not change CoachValerie.com DNS or the incumbent site. No CMS, customer data, storage integrations, marketing, or public pages are included.

This branch is separate from main so CLI development can proceed independently. Acceptance requires a successful Render deployment plus HTTPS 200 responses from / and /up. No deployment is claimed until verified.
