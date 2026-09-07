# FreeWebNovel Downloader — Public Scheduler

The public repository contains only GitHub Actions orchestration and scheduler state. Downloader implementation and the master novel URL list remain in `therandomhuman-hub/FreewebnovelDownloader_Private`.

## Production flow

The single active workflow is `.github/workflows/webnovel.yml`.

Each scheduled run performs:

1. Health checks for source integrity, Google Sheets, Google Drive and source-page access.
2. Deterministic coordinator assignment using persistent `state/scheduler_state.json`.
3. A 20-worker matrix, with 10 URLs per worker (two 5-URL batches) and 200 URLs per run.
4. Exact status extraction from each novel's own FreeWebNovel metadata.
5. `Completed` only: check Drive for `<novel-slug>.epub` before generating anything; existing files are skipped.
6. New EPUB: generate, verify chapter count and filename, then resumably upload to Google Drive.
7. Workers emit result artifacts; only the tracker job writes Google Sheets.
8. Tracker maintains `Sheet1` for Completed and `Sheet2` for Ongoing/unknown/error/non-completed rows.
9. Scheduled state advances only after the expected worker set and tracker operation succeed.

## Schedule and capacity

The workflow runs every 6 hours at 15 minutes past the hour: 00:15, 06:15, 12:15 and 18:15 UTC. GitHub may delay scheduled starts.

Capacity is 20 × 10 = 200 URL checks per run and up to 800 checks per day. The source list currently partitions into deterministic blocks without overlap or gaps; failed scheduled runs retain the same `run_index` for retry.

## Status policy

The downloader uses the source novel page's explicit metadata status. It does not infer completion from chapter numbers, titles, dates, summaries, or activity.

- `Completed`, `Complete`, `Finished` → `Sheet1` and eligible for download.
- `Ongoing` → `Sheet2`, never downloaded.
- Unknown/unrecognized status → `Sheet2`, never downloaded.
- Metadata/download errors → `Sheet2`, retried on later runs.

When a novel later changes from Ongoing to Completed, its next assigned check moves it to `Sheet1` and makes it eligible for download.

## Storage

Google Drive is the production storage layer, under the configured `Webnovel` folder. Dropbox is not part of the production download path.

## Manual modes

`worker_id` selects the worker for a manual run. `dry_run=true` performs metadata/status checks without generating or uploading EPUBs and does not advance scheduler state.

`test_url` provides a one-novel end-to-end test path. For a Completed novel, the workflow verifies that the worker reports successful Drive state with a Drive file ID/URL. Running the same test again should take the `Already in Google Drive` path and avoid EPUB regeneration.

## Secrets

`PRIVATE_REPO_TOKEN`

`GOOGLE_SERVICE_ACCOUNT_JSON`

`GOOGLE_SHEET_ID`

`GOOGLE_DRIVE_CLIENT_ID`

`GOOGLE_DRIVE_CLIENT_SECRET`

`GOOGLE_DRIVE_REFRESH_TOKEN`

`GOOGLE_DRIVE_FOLDER_ID`

Keep all credentials in GitHub Actions Secrets and out of the repositories.

Only use this downloader for material you are authorized to download and archive, and comply with applicable terms and copyright law.
