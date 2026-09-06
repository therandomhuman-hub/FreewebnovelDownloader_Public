# FreeWebNovel Downloader — Public Scheduler

The public repository contains the GitHub Actions scheduler only. The downloader engine and master novel URL list remain in the private repository `therandomhuman-hub/FreewebnovelDownloader_Private`.

## Production workflow

There is one workflow: `.github/workflows/webnovel.yml`.

It uses a 20-worker matrix and runs every 6 hours at 15 minutes past the hour: 00:15, 06:15, 12:15, and 18:15 UTC. Each worker receives two batches of 5 unique URLs, for 10 URLs per run. Fleet capacity is therefore 20 × 4 × 10 = 800 URL checks per day.

The workers only process their assigned slice. They write `worker_result.json` artifacts and never write to Google Sheets directly. A single tracker job waits for the worker matrix, downloads the results, and runs `sheet_aggregator.py`, so spreadsheet writes are serialized and deterministic.

## Scheduling and duplicate protection

The private engine uses six-hour slots. Each slot is a disjoint 200-URL block: 20 workers × 10 URLs. URLs are normalized and deduplicated before assignment. After the final block, the next cycle starts at the beginning of the list. This gives repeated checks for ongoing novels without relying on a calendar-month reset.

## Source and storage

Master source list:

`FreewebnovelDownloader_Private/data/scraped_novels.json`

Dropbox output folder:

`/WebNovel`

Dropbox is for downloaded EPUB novels and spreadsheet files only. The source URL list is not stored in Dropbox.

## Processing rules

For every assigned URL, the engine reads the explicit status from the novel's own FreeWebNovel page metadata.

- `Completed` / `Complete` / `Finished` → EPUB generation and Dropbox upload.
- `Ongoing` → tracked, not downloaded.
- `Unknown` / missing status → tracked, not downloaded.
- Metadata or download errors → tracked for a later cycle.

Before an EPUB is accepted, the converter's chapter count is checked against the source page.

## Google Sheet

The current workflow updates the existing `Sheet1` tab. The tracker job matches rows by normalized URL and performs all updates/appends in one serialized step.

## Manual test

Use **Actions → WebNovel Downloader → Run workflow**.

Recommended first test:

```text
worker_id = 0
dry_run = true
```

This checks the first 10 URLs, reads their source metadata, and updates the tracker without generating or uploading EPUBs.

## Secrets

- `PRIVATE_REPO_TOKEN` — GitHub token/PAT with read access to the private repository.
- `DROPBOX_ACCESS_TOKEN` — Dropbox API token with write access to `/WebNovel`.
- `GOOGLE_SERVICE_ACCOUNT_JSON` — complete Google service-account JSON.
- `GOOGLE_SHEET_ID` — ID of the existing Google spreadsheet.

Only use this system for material you are authorized to download and archive, and comply with applicable terms and copyright law.
