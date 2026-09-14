# Production 6,588 Run

The completed-novel bulk workflow remains manually dispatchable. For a controlled production launch from `main`, the workflow also accepts the exact commit-message marker `[RUN-6588]`; all other pushes are ignored by the production jobs.

The initial guarded launch was stopped at healthcheck by a stale validator regression assertion. The validator test was corrected in private engine commit `61a6be0b71c26de0c75009638b665462bb50d9d0`, and this merge launches the clean retry.
