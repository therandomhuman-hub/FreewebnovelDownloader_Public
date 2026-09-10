# FreeWebNovel Downloader — Public Scheduler

Production orchestration for the FreeWebNovel downloader. The public repository contains GitHub Actions, scheduler state, recovery workflows, discovery orchestration, and the Pages site. The private repository contains the downloader runtime and catalog.

## Architecture

```text
FreeWebNovel
    │
    ▼
Recursive discovery ──► canonical novel catalog
    │
    ▼
20 deterministic workers
    │
    ├── Completed ──► Community Library ──► Google Drive ──► Sheet1
    │
    └── Ongoing / unknown / failed ───────────────────────► Sheet2
                                                             │
                                                             ▼
                                                   monthly recheck
```

## Production guarantees

- **Gap-free scheduling:** persistent `run_index` partitions the catalog; a failed scheduled run is not silently skipped.
- **Immutable provenance:** every scheduled run records the exact private-engine commit, public commit, run ID, worker count, and scheduling parameters.
- **Deterministic workers:** every worker receives the exact private-engine revision tested by the health check.
- **Fail-closed tracking:** scheduler state advances only after all expected worker results are present, valid, integrity-checked, and successfully reconciled to Google Sheets.
- **Worker isolation:** process-level worker failures block reconciliation; per-novel failures remain retryable in Sheet2.
- **Idempotent storage:** Drive is checked before EPUB generation/upload, preventing duplicate work.
- **Safe recovery:** historical reconciliation uses the run's recorded engine revision and never advances scheduler state.
- **Discovery safety:** a partial or error-producing crawl cannot replace the known-good catalog.
- **Action integrity:** GitHub Actions are pinned to immutable commit SHAs.

## Workflows

| Workflow | Purpose |
|---|---|
| `webnovel.yml` | Scheduled production download pipeline |
| `webnovel-discovery-primary.yml` | Recursive catalog discovery |
| `monthly-ongoing-recheck.yml` | Month-end recheck of Sheet2 |
| `webnovel-tracker-reconcile.yml` | Manual reconciliation of a historical run |
| `webnovel-tracker-recovery.yml` | Historical tracker recovery without scheduler advancement |
| `production-audit.yml` | Automated production-readiness checks |
| `deploy-pages.yml` | GitHub Pages deployment |

## Scheduling

The production downloader runs four times per day with 20 workers. Each worker processes two batches of five URLs, for a maximum of 200 URL checks per scheduled run. The scheduler uses the current catalog length, so it does not depend on a hard-coded catalog size.

Manual workflow runs are operational tests only. They never advance production scheduler state.

## Discovery

The primary discovery workflow starts from the configured FreeWebNovel roots and recursively follows reachable same-site pages to collect canonical `/novel/...` URLs. Discovery state is checkpointed remotely for production continuity. The master catalog is replaced only after the crawl reports complete with zero errors.

Discovery failures are deliberately independent from downloader worker failures: a discovery problem must not silently alter or skip the downloader schedule.

## Tracking

Google Sheets uses two tabs:

- **Sheet1:** novels confirmed completed and successfully stored in Google Drive.
- **Sheet2:** ongoing, unknown, metadata-error, or download-failure rows awaiting later processing.

Only the tracker job writes the production Sheets. Workers publish result artifacts and execution markers.

## Required secrets

Configure these as GitHub Actions Secrets:

- `PRIVATE_REPO_TOKEN`
- `GOOGLE_SERVICE_ACCOUNT_JSON`
- `GOOGLE_SHEET_ID`
- `GOOGLE_DRIVE_CLIENT_ID`
- `GOOGLE_DRIVE_CLIENT_SECRET`
- `GOOGLE_DRIVE_REFRESH_TOKEN`
- `GOOGLE_DRIVE_FOLDER_ID`

Never commit credentials or generated runtime state to the repository.

## Legal / responsible use

Use the downloader only for material you are authorized to download and archive, and comply with applicable terms, copyright law, and service restrictions.
