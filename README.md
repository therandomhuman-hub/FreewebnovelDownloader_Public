# FreeWebNovel Downloader — Public Workflow

The public repository contains the scheduler/orchestration only. The downloader engine remains in the private repository `therandomhuman-hub/FreewebnovelDownloader_Private`.

## Behavior

- Runs automatically on the last day of every month.
- Can also be started manually with **Run workflow**.
- The novel source URL list is stored in this GitHub repository at `data/scraped_novels.json`.
- Dropbox `/WebNovel` is reserved for downloaded novels and spreadsheet files; the source URL list is not stored there.
- Each novel's own page metadata is checked for status.
- Only `Completed` novels are downloaded.
- `Ongoing`, `Unknown`, and failed metadata checks remain tracked and are rechecked next month.
- EPUBs are stored in Dropbox `/WebNovel`.
- Google Sheets is the durable tracker.

## Actions secrets

| Secret | Purpose |
|---|---|
| `PRIVATE_REPO_TOKEN` | GitHub token/PAT with read access to the private repository |
| `DROPBOX_ACCESS_TOKEN` | Dropbox API token with write access |
| `GOOGLE_SERVICE_ACCOUNT_JSON` | Complete Google service-account JSON |
| `GOOGLE_SHEET_ID` | Existing Google spreadsheet ID to use as the tracker |

Create the Google Sheet in the Dropbox/Google Drive location you want to use, then put that spreadsheet ID in `GOOGLE_SHEET_ID` and make sure the Google service account has access to the sheet.

Only use this for material you are authorized to download and archive, and comply with applicable terms and copyright law.
