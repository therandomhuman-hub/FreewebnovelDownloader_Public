# FreeWebNovel Downloader — Public Scheduler

The public repository contains the GitHub Actions scheduler only. The downloader engine and master novel URL list remain in the private repository `therandomhuman-hub/FreewebnovelDownloader_Private`.

## Architecture

There is one workflow, `.github/workflows/webnovel.yml`, using a 20-worker matrix. Scheduled executions run all 20 workers in parallel; manual executions can run a single worker and optionally use dry-run mode.

## Schedule

The workflow runs every 6 hours at 15 minutes past the hour: 00:15, 06:15, 12:15, and 18:15 UTC. This gives 4 scheduled runs per day.

Each worker processes two batches of 5 URLs, for 10 URLs per worker run. The full fleet therefore has a target capacity of 20 × 4 × 10 = 800 URL checks per day.

The private engine uses a deterministic six-hour slot and cycle calculation. Every cycle partitions the source list into disjoint 200-URL blocks, then assigns 10 URLs to each worker. When the end of the list is reached, the next cycle starts again from the beginning. Duplicate URLs are removed before scheduling, so the same normalized novel URL is not assigned twice within a cycle.

## Source and storage

Master source list:

`FreewebnovelDownloader_Private/data/scraped_novels.json`

Dropbox storage:

`/WebNovel`

Dropbox is used for downloaded EPUB novels and spreadsheet files only. The source URL list is not stored in Dropbox.

## Processing rules

For every assigned URL, the engine reads the novel's own FreeWebNovel page and extracts an explicit status label.

- `Completed` / `Complete` / `Finished` → eligible for EPUB generation and Dropbox upload.
- `Ongoing` → tracked, not downloaded.
- `Unknown` / missing status → tracked, not downloaded.
- Metadata or download errors → tracked and retried in a later cycle.

The engine also validates the converter's chapter count against the source page before accepting an EPUB.

## Google Sheet

The tracker sheet tab is `Novels` by default. Workers write to fixed source-index rows, allowing the 20 workers to update different rows concurrently without append-order races.

## Actions secrets

| Secret | Purpose |
|---|---|
| `PRIVATE_REPO_TOKEN` | GitHub token/PAT with read access to the private repository |
| `DROPBOX_ACCESS_TOKEN` | Dropbox API token with write access |
| `GOOGLE_SERVICE_ACCOUNT_JSON` | Complete Google service-account JSON |
| `GOOGLE_SHEET_ID` | Existing Google spreadsheet ID used as the tracker |
| `GOOGLE_SHEET_SHARE_EMAIL` | Optional account email used by older sheet-creation flows |

Manual testing is available through **Actions → WebNovel Downloader → Run workflow**. Set `worker_id` to `0` and `dry_run` to `true` to perform a metadata-only test without generating or uploading EPUBs.

Only use this system for material you are authorized to download and archive, and comply with applicable terms and copyright law.
