# FreeWebNovel Downloader — Public Scheduler

The public repository contains GitHub Actions orchestration and scheduler state. Downloader implementation, recursive discovery code, and the master novel catalog remain in `therandomhuman-hub/FreewebnovelDownloader_Private`.

## Production architecture

The system is now a continuous catalog pipeline rather than a fixed 10,727-URL batch:

```text
FreeWebNovel roots
  /home
  /sort/latest-novel/
  /sort/latest-release/
        |
        v
Recursive same-domain crawler
        |
        +--> every discovered HTML sub-link
        |       +--> links from that page
        |       +--> links from those pages
        |       +--> continue until the crawl queue is empty
        |
        v
Canonical /novel/... URL catalog
        |
        v
Completed-status pipeline
        |
        +--> Completed -> LinkToEPUB -> Community Library -> newest matching EPUB -> Drive
        +--> Ongoing   -> Sheet2 -> monthly recheck
        +--> Unknown/error -> Sheet2 -> retry later
```

The crawler canonicalizes `freewebnovel.com` and `www.freewebnovel.com`, removes fragments/query variants, rejects external/non-page links, follows pagination and genre links, and deduplicates novel URLs. The initial catalog is retained as a seed; successful discovery expands it automatically.

## Discovery workflow

`.github/workflows/webnovel-discovery.yml` runs every 6 hours and starts from the homepage plus latest-novel and latest-release roots. It recursively follows every reachable same-site HTML link and extracts all `/novel/...` URLs.

A discovery result is committed back to the private engine only when the crawl completes with zero fetch errors. This prevents a partial/failed crawl from replacing a good catalog.

## Downloader flow

`.github/workflows/webnovel.yml` is the production download workflow.

Each scheduled run performs:

1. Health checks for source integrity, Google Sheets, Google Drive and source-page access.
2. Deterministic coordinator assignment using persistent `state/scheduler_state.json`.
3. A 20-worker matrix, with 10 URLs per worker (two 5-URL batches) and 200 URLs per run.
4. Exact status extraction from each novel's own FreeWebNovel metadata.
5. `Completed` only: check Drive before generating anything.
6. New EPUB: submit to LinkToEPUB, require the existing ±25 chapter-count tolerance, and wait for the Community Library result.
7. Community Library is searched/refreshed every 5 minutes and the first matching result is selected as the newest duplicate.
8. The EPUB is uploaded to Google Drive.
9. Workers emit result artifacts; only the tracker job writes Google Sheets.
10. Tracker maintains `Sheet1` for successfully completed/downloaded novels and `Sheet2` for Ongoing, unknown, error, or failed-download rows.
11. Scheduler state advances only after the expected worker set and tracker operation succeed.

## Dynamic capacity

The 200-URL/run and 800-URL/day figures are throughput limits, not a fixed catalog size. The worker assignment is calculated from the current source-list length, so the final block automatically becomes smaller when fewer URLs remain.

As recursive discovery adds novels, the same scheduling system automatically expands to the new catalog size without a manually maintained final URL count.

## Monthly ongoing recheck

`.github/workflows/monthly-ongoing-recheck.yml` checks Sheet2 on the actual last day of each month. A novel that has become explicitly `Completed` is sent through the same hardened Community Library pipeline. Failed downloads are not promoted to Sheet1.

## Historical recovery

`.github/workflows/webnovel-tracker-recovery.yml` can reconstruct Sheet1/Sheet2 from historical worker artifacts without modifying scheduler state.

## Production audit

`.github/workflows/production-audit.yml` runs weekly and manually. It verifies Python compilation, deterministic tests, source partition checks, recursive crawler self-tests, required workflows, SHA-pinned GitHub Actions, and removal of the obsolete whole-batch retry wrapper.

## Status policy

The downloader uses the source novel page's explicit metadata status. It does not infer completion from chapter numbers, titles, dates, summaries, or activity.

- `Completed`, `Complete`, `Finished` → eligible for download.
- `Ongoing` → never downloaded until a later recheck reports completion.
- Unknown/unrecognized status → not downloaded.
- Metadata/download errors → tracked and retried later.

## Storage

Google Drive is the production storage layer under the configured `Webnovel` folder. Dropbox is not part of the production download path.

## Manual modes

`worker_id` selects the worker for a manual run. `dry_run=true` performs metadata/status checks without generating or uploading EPUBs and does not advance scheduler state.

`test_url` provides a one-novel end-to-end test path for a Completed novel. Repeating the same test should use the existing Drive file path rather than regenerate the EPUB.

## Secrets

- `PRIVATE_REPO_TOKEN`
- `GOOGLE_SERVICE_ACCOUNT_JSON`
- `GOOGLE_SHEET_ID`
- `GOOGLE_DRIVE_CLIENT_ID`
- `GOOGLE_DRIVE_CLIENT_SECRET`
- `GOOGLE_DRIVE_REFRESH_TOKEN`
- `GOOGLE_DRIVE_FOLDER_ID`

Keep all credentials in GitHub Actions Secrets and out of the repositories.

Only use this downloader for material you are authorized to download and archive, and comply with applicable terms and copyright law.
