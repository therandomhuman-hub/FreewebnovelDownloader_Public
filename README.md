# FreeWebNovel Downloader — Public Scheduler

The public repository contains the GitHub Actions scheduler and a small non-secret scheduler state file. The downloader engine and master novel URL list remain in the private repository `therandomhuman-hub/FreewebnovelDownloader_Private`.

## Production workflow

There is one workflow: `.github/workflows/webnovel.yml`.

A coordinator reads `state/scheduler_state.json` and assigns one deterministic `run_index`. A 20-worker matrix then processes that same run index in parallel. Each worker receives two batches of 5 unique URLs, for 10 URLs per run. The full fleet targets 20 × 4 × 10 = 800 URL checks per day.

Workers produce `worker_result.json` artifacts and never write Google Sheets directly. A single tracker job validates the expected worker results and runs `sheet_aggregator.py`, serializing tracker updates into one operation.

The scheduler state advances only after the scheduled worker matrix succeeds, all expected worker results are present and consistent, and the Google Sheet update succeeds. A tracker/state failure leaves the current run index unchanged for retry.

## Schedule

The workflow runs every 6 hours at 15 minutes past the hour: 00:15, 06:15, 12:15, and 18:15 UTC.

## Scheduling and duplicate protection

Each run index maps to a disjoint 200-URL block (20 workers × 10 URLs). The private source loader validates FreeWebNovel URLs, normalizes them, and removes duplicate entries before assigning deterministic unique indexes. After the final block, a new cycle begins, so ongoing novels are revisited automatically.

## Source and storage

Master source list:

`FreewebnovelDownloader_Private/data/scraped_novels.json`

Google Drive output folder:

`My Drive/Webnovel`

Google Drive is the novel-file storage layer. Dropbox is no longer used by the production downloader.

## Processing rules

For every assigned URL, the engine reads the explicit status from the novel's own FreeWebNovel page metadata.

- `Completed` / `Complete` / `Finished` → eligible for EPUB generation and Google Drive upload.
- `Ongoing` → tracked, not downloaded.
- `Unknown` / missing status → tracked, not downloaded.
- Metadata/download errors → tracked and retried in a later cycle.

Before an EPUB is accepted, its converter chapter count is compared with the source page chapter count.

## Google Drive

Workers authenticate with the configured Google user OAuth credentials and upload EPUBs into the configured `GOOGLE_DRIVE_FOLDER_ID`. Before generation/upload, the engine checks that folder for an existing `<novel-slug>.epub` and records the existing Drive file instead of creating a duplicate.

## Google Sheet

The workflow updates the existing `Sheet1` tab. Only the tracker job writes the sheet, preventing 20-worker append races. Tracker columns include Google Drive path, file ID, and file URL.

## Preflight and safety

Every worker compiles the Python entrypoints and runs `self_check.py` before external processing. The health check validates source JSON integrity, Google Sheet access, Google Drive OAuth/folder access, and basic FreeWebNovel reachability.

## Manual test

Use **Actions → WebNovel Downloader → Run workflow**.

Recommended first test:

```text
worker_id = 0
dry_run = true
```

This checks exactly one worker's 10 URLs, creates tracker results, and does not generate or upload EPUBs. Manual runs never advance scheduler state.

## Secrets

- `PRIVATE_REPO_TOKEN` — GitHub token/PAT with read access to the private repository.
- `GOOGLE_SERVICE_ACCOUNT_JSON` — service-account JSON used for the Google Sheet.
- `GOOGLE_SHEET_ID` — ID of the existing Google spreadsheet.
- `GOOGLE_DRIVE_CLIENT_ID` — OAuth client ID for Drive user access.
- `GOOGLE_DRIVE_CLIENT_SECRET` — OAuth client secret for Drive user access.
- `GOOGLE_DRIVE_REFRESH_TOKEN` — OAuth refresh token for unattended Drive access.
- `GOOGLE_DRIVE_FOLDER_ID` — ID of the `Webnovel` Drive folder.

`GOOGLE_SHEET_SHARE_EMAIL` may remain configured for compatibility, but the existing spreadsheet is accessed using the service account configured above.

Only use this system for material you are authorized to download and archive, and comply with applicable terms and copyright law.
