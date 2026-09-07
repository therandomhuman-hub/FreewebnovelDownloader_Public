# FreeWebNovel Downloader — Public Scheduler

The public repository contains only GitHub Actions orchestration and non-secret scheduler state. The downloader engine and master novel URL list remain in the private repository `therandomhuman-hub/FreewebnovelDownloader_Private`.

## Production architecture

There is one workflow: `.github/workflows/webnovel.yml`.

A health check validates the private engine, source list, Google Sheet access, Google Drive OAuth/folder access, and basic FreeWebNovel reachability before processing starts. A coordinator reads the persistent `state/scheduler_state.json` and assigns one deterministic `run_index` to a 20-worker matrix.

Each worker receives two batches of 5 unique URLs, for 10 URLs per run. The fleet targets 20 × 10 = 200 URL checks per 6-hour run, or up to 800 URL checks per day.

Workers write `worker_result.json` artifacts and never update Google Sheets directly. One tracker job validates worker results and performs the spreadsheet update. Scheduler state advances only when the scheduled worker matrix succeeds, the expected worker results are present and valid, and the tracker update succeeds.

## Schedule

The workflow runs every 6 hours at 15 minutes past the hour: 00:15, 06:15, 12:15, and 18:15 UTC. Scheduled execution can be delayed by GitHub platform load.

## Source list

The master source list is stored only in the private repository:

`FreewebnovelDownloader_Private/data/scraped_novels.json`

The loader canonicalizes valid `https://freewebnovel.com/novel/...` URLs and removes duplicates for scheduling. `self_check.py` verifies the source and worker partition model before external processing.

## Status policy

For every assigned novel, the engine reads the explicit status from that novel's own FreeWebNovel page metadata.

- `Completed`, `Complete`, or `Finished` → eligible for EPUB generation.
- `Ongoing` → tracked but not downloaded.
- Missing/unknown/unrecognized status → tracked but not downloaded.
- Metadata or download errors → recorded and retried on a later cycle.

The engine does not infer completion from chapter numbers, titles, dates, or lack of recent activity.

## Download and storage

Completed novels are converted to EPUB and chapter-count checked before storage.

Google Drive is the production novel-storage layer. The uploader authenticates with Google user OAuth and uploads into the configured `My Drive/Webnovel` folder. It checks for `<novel-slug>.epub` before generation to avoid unnecessary duplicate work.

Dropbox is not used by the production downloader.

## Google Sheet

The existing `Sheet1` tab is the tracker. It records title, source URL, source status, genre, chapters, download status, Google Drive path, Drive file ID, Drive URL, timestamps, source index, worker, cycle, run index, and errors.

Only the tracker job writes the spreadsheet, preventing concurrent worker append races.

## Retry and cycle behavior

The scheduler state advances only after a complete scheduled run and tracker operation succeed. If a worker fails, the current `run_index` remains unchanged and the same 200-URL block is retried later. Existing Drive files are recognized and skipped.

After the final source block, the scheduler wraps to the beginning for the next cycle so ongoing novels are revisited.

## Dry run

Use **Actions → WebNovel Downloader → Run workflow** with:

```text
worker_id = 0
dry_run = true
```

This checks one worker's 10 URLs and updates tracker results without generating or uploading EPUBs. Manual runs do not advance scheduler state.

## Secrets

- `PRIVATE_REPO_TOKEN` — GitHub token/PAT with read access to the private repository.
- `GOOGLE_SERVICE_ACCOUNT_JSON` — service-account JSON used for the Google Sheet.
- `GOOGLE_SHEET_ID` — ID of the existing Google spreadsheet.
- `GOOGLE_DRIVE_CLIENT_ID` — OAuth client ID for Drive user access.
- `GOOGLE_DRIVE_CLIENT_SECRET` — OAuth client secret for Drive user access.
- `GOOGLE_DRIVE_REFRESH_TOKEN` — OAuth refresh token for unattended Drive access.
- `GOOGLE_DRIVE_FOLDER_ID` — ID of the `Webnovel` Drive folder.

`GOOGLE_SHEET_SHARE_EMAIL` may remain configured but is not required by the current tracker.

## Security

Keep all credentials in GitHub Actions Secrets and out of the repositories. Maintain the OAuth application according to Google's current testing/publishing requirements so unattended refresh-token access remains valid.

Only use this downloader for material you are authorized to download and archive, and comply with applicable terms and copyright law.
