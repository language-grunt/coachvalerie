# Coach Valerie protected staging replica

The staging homepage now reproduces the current public site at www.coachvalerie.com from the September 19 archive. It serves 42 pages from separate PostgreSQL content and presentation templates, 17 observed aliases and three explicit preview repairs through Rails, with local images, CSS and fonts. This is a temporary reference presentation, not the finished modular CMS. Text, media references and links are stored in PostgreSQL; templates and CSS are separate. Ordinary content changes do not require a deployment once editing actions are connected. No CMS editing interface is included yet.

All pages/assets remain behind the staging password. Original scripts/analytics/embeds are removed. A restrictive Content Security Policy blocks outbound connections and form submissions; local JavaScript supports mobile navigation, the signup dialog and explicit preview-only form feedback. Assessment scoring and live delivery are not simulated. External Amazon/course/social links still lead to their providers on deliberate clicks.

The PostgreSQL smoke probe has moved to the protected `/preview-health/database`; `/up` remains the minimal public health endpoint. Unknown pages return an honest 404. Case-sensitive routes remain distinct. A reversible migration imports the initial content into `reference_pages` once; later deployments preserve database edits.

Rebuild the initial import with `python script/build_replica.py /path/to/site_archive/2026-09-19` using Beautiful Soup 4 in a separate build environment, then run `python script/separate_replica_content.py`. The source archive is maintained in the Obsidian project. Runtime requires no Python dependency. `replica/import-report.json` records source, assets and import limitations. Some optional theme font URLs return errors; source Montserrat/EB Garamond and visible core assets are hosted locally. Current source layout/text is preserved; this is not a pixel-perfect certification of every page.

Run the three Ruby test files in `test/` after preparing a disposable PostgreSQL database. CI verifies every archived page, aliases, local asset references, CSP, password protection and database health. Browser checks cover desktop/mobile, images, menu, popup and preview form feedback.

Rollback: restore protected SHA `fc607e18a688fd2edfd2dab8c40b67daea2f7c87`; never restore the earlier anonymous proof. The replica adds no subscriptions/resources or DNS changes. Production and `main` remain unchanged.

---

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

## Content and presentation contract

- `replica/content/*.json`: source-controlled initial copy/media/link fields, grouped by source section for later migration to semantic CMS blocks. They seed PostgreSQL once and do not override live edits.
- `reference_pages.fields`: current staging content; no inline HTML/CSS is stored in these fields. Validation constrains link/media references and rendering escapes every field.
- `replica/templates/*.html`: layout and field references only, using inert `{{content:field_id}}` markers rather than executable user templates. Templates can reorganize the same fields without changing content.
- `public/replica-assets/page-*.css`: page-specific source styling; shared theme styles/fonts are separate assets. Background media are bound through content variables rather than hard-coded image URLs in page CSS.
- `replica/schemas/*.json`: field contracts and source-section/element metadata. The provisional numbered fields preserve source fidelity; named reusable CMS sections, revision workflow and authorized editing actions are still future work.

Forms are preview-only. Labels/placeholders are content; field structure remains a capability in the reference template until the Forms CMS/adapters are built. Do not edit through routine production SQL or infer that this reference import completes the full content platform.
