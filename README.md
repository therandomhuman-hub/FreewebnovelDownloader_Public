# FreeWebNovel Downloader — Public Scheduler

The public repository contains the GitHub Actions scheduler and a small non-secret scheduler state file. The downloader engine and master novel URL list remain in the private repository `therandomhuman-hub/FreewebnovelDownloader_Private`.

## Production workflow

There is one workflow: `.github/workflows/webnovel.yml`.

A coordinator reads `state/scheduler_state.json` and assigns one deterministic `run_index`. A 20-worker matrix then processes that same run index in parallel. Each worker receives two batches of 5 unique URLs, for 10 URLs per run. The full fleet targets 20 × 4 × 10 = 800 URL checks per day.

Workers produce `worker_result.json` artifacts and never write Google Sheets directly. A single tracker job runs after the matrix and executes `sheet_aggregator.py`, serializing tracker updates into one operation.

The scheduler state advances only when the scheduled worker matrix succeeds. If a worker fails, the run index is not advanced, so the same 200-URL block is retried on the next scheduled execution. Dropbox duplicate protection prevents successful novels from being downloaded twice.

## Schedule

The workflow runs every 6 hours at 15 minutes past the hour: 00:15, 06:15, 12:15, and 18:15 UTC.

## Scheduling and duplicate protection

Each run index maps to a disjoint 200-URL block (20 workers × 10 URLs). The private source loader normalizes URLs and removes duplicates before assigning deterministic unique indexes. After the final block, a new cycle begins. This means ongoing novels are revisited automatically without relying on a calendar-month reset.

## Source and storage

Master source list:

`FreewebnovelDownloader_Private/data/scraped_novels.json`

Dropbox output folder:

`/WebNovel`

Dropbox is used for downloaded EPUB novels and spreadsheet files only. The source URL list is not stored in Dropbox.

## Processing rules

For every assigned URL, the engine reads the explicit status from the novel's own FreeWebNovel page metadata.

- `Completed` / `Complete` / `Finished` → eligible for EPUB generation and Dropbox upload.
- `Ongoing` → tracked, not downloaded.
- `Unknown` / missing status → tracked, not downloaded.
- Metadata/download errors → tracked and retried in a later cycle.

Before an EPUB is accepted, its converter chapter count is compared with the source page chapter count.

## Google Sheet

The workflow updates the existing `Sheet1` tab. The tracker job matches results by normalized URL, updates existing rows, and appends new rows. Because only the tracker job writes the sheet, the 20 workers cannot race over append order.

## Manual test

Use **Actions → WebNovel Downloader → Run workflow**.

Recommended first test:

```text
worker_id = 0
dry_run = true
```

This uses the current scheduler state, checks exactly that worker's 10 URLs, writes tracker results, and does not generate or upload EPUBs. Manual runs do not advance scheduler state.

## Secrets

- `PRIVATE_REPO_TOKEN` — GitHub token/PAT with read access to the private repository.
- `DROPBOX_ACCESS_TOKEN` — Dropbox API token with write access to `/WebNovel`.
- `GOOGLE_SERVICE_ACCOUNT_JSON` — complete Google service-account JSON.
- `GOOGLE_SHEET_ID` — ID of the existing Google spreadsheet.

Only use this system for material you are authorized to download and archive, and comply with applicable terms and copyright law.
