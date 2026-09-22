# Coach Valerie protected staging replica

The staging homepage now reproduces the current public site at www.coachvalerie.com from the September 19 archive. It serves 42 pages from separate PostgreSQL content and presentation templates, 17 observed aliases and three explicit preview repairs through Rails, with local images, CSS and fonts. This is a temporary reference presentation, not the finished modular CMS. Text, media references and links are stored in PostgreSQL; templates and CSS are separate. Ordinary content changes do not require a deployment once editing actions are connected. No CMS editing interface is included yet.

All pages/assets remain behind the staging password. Original scripts/analytics/embeds are removed. A restrictive Content Security Policy blocks outbound connections and form submissions; local JavaScript supports mobile navigation, the signup dialog and explicit preview-only form feedback. Assessment scoring and live delivery are not simulated. External Amazon/course/social links still lead to their providers on deliberate clicks.

The PostgreSQL smoke probe has moved to the protected `/preview-health/database`; `/up` remains the minimal public health endpoint. Unknown pages return an honest 404. Case-sensitive routes remain distinct. A reversible migration imports the initial content into `reference_pages` once; later deployments preserve database edits.

Rebuild the initial import with `python script/build_replica.py /path/to/site_archive/2026-09-19` using Beautiful Soup 4 in a separate build environment, then run `python script/separate_replica_content.py`. The source archive is maintained in the Obsidian project. Runtime requires no Python dependency. `replica/import-report.json` records source, assets and import limitations. Some optional theme font URLs return errors; source Montserrat/EB Garamond and visible core assets are hosted locally. Current source layout/text is preserved; this is not a pixel-perfect certification of every page.

Run the three Ruby test files in `test/` after preparing a disposable PostgreSQL database. CI verifies every archived page, aliases, local asset references, CSP, password protection and database health. Browser checks cover desktop/mobile, images, menu, popup and preview form feedback.

Rollback: restore protected SHA `fc607e18a688fd2edfd2dab8c40b67daea2f7c87`; never restore the earlier anonymous proof. The replica adds no subscriptions/resources or DNS changes. Production and `main` remain unchanged.

## Content and presentation contract

- `replica/content/*.json`: source-controlled initial copy/media/link fields, grouped by source section for later migration to semantic CMS blocks. They seed PostgreSQL once and do not override live edits.
- `reference_pages.fields`: current staging content; no inline HTML/CSS is stored in these fields. Validation constrains link/media references and rendering escapes every field.
- `replica/templates/*.html`: layout and field references only, using inert `{{content:field_id}}` markers rather than executable user templates. Templates can reorganize the same fields without changing content.
- `public/replica-assets/page-*.css`: page-specific source styling; shared theme styles/fonts are separate assets. Background media are bound through content variables rather than hard-coded image URLs in page CSS.
- `replica/schemas/*.json`: field contracts and source-section/element metadata. The provisional numbered fields preserve source fidelity; named reusable CMS sections, revision workflow and authorized editing actions are still future work.

Forms are preview-only. Labels/placeholders are content; field structure remains a capability in the reference template until the Forms CMS/adapters are built. Do not edit through routine production SQL or infer that this reference import completes the full content platform.

## Runtime and access

Ruby 3.4.10, Rails 8.1.3.1, PostgreSQL 18. Run `bundle install`, `bundle exec ruby bin/rails db:prepare`, then `bundle exec rackup --server webrick --host 127.0.0.1 --port 3000` with a local DATABASE_URL. Run tests against a separate test database. The existing smoke server remains WEBrick pending the broader foundation task.

Render uses the existing Ohio staging web/database, reported $13.30/month base. `render.yaml` declares environment variables; credentials stay server-side. `STAGING_ACCESS_ENABLED=true` requires both username/password and fails startup if absent. Username is `valerie`; retrieve the current password from Render settings. Only GET/HEAD `/up` bypasses authentication. Rotate through Render and redeploy without logging the password. Main and live-site DNS are unchanged; the custom candidate hostname remains a separate task.
