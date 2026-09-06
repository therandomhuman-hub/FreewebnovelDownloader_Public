# FreeWebNovel Downloader — Public Scheduler

The public repository contains 20 scheduled worker workflows. The downloader engine and source list remain in the private repository `therandomhuman-hub/FreewebnovelDownloader_Private`.

## Schedule

Each worker runs every 6 hours, giving 4 runs per day. Each run processes two batches of 5 novels, so the fleet targets 20 × 4 × 10 = 800 novel URLs per day.

The workers use a deterministic month-based slot calculation. Worker IDs 0–19 receive non-overlapping URL ranges for each 6-hour slot. The source loader also removes duplicate novel slugs before scheduling, preventing duplicate work across the fleet.

The source list is stored at `FreewebnovelDownloader_Private/data/scraped_novels.json`. Dropbox `/WebNovel` is reserved for downloaded EPUB novels and spreadsheet files; the source URL list is not stored there.

The monthly schedule resets to the start of the list at the beginning of each month. With the current list size, all URLs fit within the early part of each month; the remaining scheduled slots are idle. This naturally provides a monthly re-check cycle.

## Processing rules

Each novel's own FreeWebNovel page metadata is checked for status. Only `Completed` novels are eligible for EPUB generation and Dropbox upload. `Ongoing`, `Unknown`, and metadata errors stay tracked in the Google Sheet and are checked again in the next monthly cycle.

Dropbox destination: `/WebNovel`

Google Sheet tab: `Novels`

## Actions secrets

| Secret | Purpose |
|---|---|
| `PRIVATE_REPO_TOKEN` | GitHub token/PAT with read access to the private repository |
| `DROPBOX_ACCESS_TOKEN` | Dropbox API token with write access |
| `GOOGLE_SERVICE_ACCOUNT_JSON` | Complete Google service-account JSON |
| `GOOGLE_SHEET_ID` | Existing Google spreadsheet ID to use as the tracker |
| `GOOGLE_SHEET_SHARE_EMAIL` | Optional email to share a newly created sheet with |

Only use this for material you are authorized to download and archive, and comply with applicable terms and copyright law.
