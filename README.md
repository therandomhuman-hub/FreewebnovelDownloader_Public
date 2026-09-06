# FreeWebNovel Downloader — Public Workflow

The public repository contains the scheduler/orchestration only. The downloader engine remains in the private repository `therandomhuman-hub/FreewebnovelDownloader_Private`.

## Behavior

- Runs automatically on the last day of every month.
- Can also be started manually with **Run workflow**.
- The private engine reads the source URL list from Dropbox `/WebNovel/_source_urls.json`.
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
| `GOOGLE_SHEET_ID` | Optional existing spreadsheet ID; omit to create a new spreadsheet |

Only use this for material you are authorized to download and archive, and comply with applicable terms and copyright law.
