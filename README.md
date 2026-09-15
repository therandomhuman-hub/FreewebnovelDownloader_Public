# FreeWebNovel Downloader — Production Orchestrator

The public repository contains the production GitHub Actions orchestration and the small GitHub Pages site. The private repository contains the downloader engine, tests, and the authoritative completed-novel catalog.

## Production architecture

```text
completed_novels.json (6,588 completed novels)
                │
                ▼
      26 deterministic shards
                │
        max 3 shards at once
                │
      1 novel conversion/shard
                │
                ▼
        LinkToEPUB conversion
                │
                ▼
      dynamic progress watcher
                │
                ▼
       verified EPUB download
                │
                ▼
          Google Drive
                │
                ▼
       Google Sheets tracker
          ┌─────┴─────┐
          ▼           ▼
        Sheet1      Sheet2
       completed   retryable/unresolved
```

## Production guarantees

- **Single production path:** `webnovel-completed-6588.yml` is the only downloader workflow.
- **Resumable execution:** each shard stops admitting new novels before the GitHub Actions time limit, writes its partial checkpoint, and later scheduled passes continue from the remaining catalog.
- **Hourly continuation:** the production workflow runs hourly until Sheet1 contains all 6,588 completed novels.
- **No conversion timeout:** LinkToEPUB conversion watching is state-driven and continues until the page reports success or a real conversion failure occurs.
- **Drive idempotency:** source URL provenance is used to detect an existing EPUB before generation, so later passes do not regenerate completed novels.
- **Row-level retryability:** individual failures remain retryable and do not terminate the catalog-wide process.
- **Deterministic engine pinning:** the public healthcheck tests the private engine first; every shard then uses the exact tested commit.
- **Fail-safe tracking:** worker artifacts, execution markers, failure artifacts, duplicate URLs, and engine provenance are validated before tracker aggregation.
- **Google Sheets integrity:** the tracker merges existing state with incoming results and verifies the written tabs after every pass.
- **Immutable action references:** GitHub Actions are pinned to commit SHAs.

## Workflows

| Workflow | Purpose |
|---|---|
| `webnovel-completed-6588.yml` | Production downloader, resumable hourly continuation, tracker, and progress persistence |
| `deploy-pages.yml` | GitHub Pages deployment for the public site |

All discovery, monthly recheck, legacy pipeline, tracker replay/recovery, and redundant audit workflows have been retired from the public project.

## Execution model

Each production shard has a hard ceiling below GitHub's six-hour job limit. The worker reserves a safety margin, finishes active novels, writes what it has completed, and exits cleanly. A future scheduled pass sees the same 6,588-row catalog, skips novels already confirmed in Drive, and continues unresolved work.

The production run is considered fully complete only when the tracker reports 6,588 completed Sheet1 rows. Until then, the system remains resumable and continues on later passes.

## Required secrets

Configure these as GitHub Actions Secrets:

- `PRIVATE_REPO_TOKEN`
- `GOOGLE_SERVICE_ACCOUNT_JSON`
- `GOOGLE_SHEET_ID`
- `GOOGLE_DRIVE_CLIENT_ID`
- `GOOGLE_DRIVE_CLIENT_SECRET`
- `GOOGLE_DRIVE_REFRESH_TOKEN`
- `GOOGLE_DRIVE_FOLDER_ID`

Never commit credentials or runtime artifacts containing secrets.

## Legal / responsible use

Use the downloader only for material you are authorized to download and archive, and comply with applicable terms, copyright law, and service restrictions.
