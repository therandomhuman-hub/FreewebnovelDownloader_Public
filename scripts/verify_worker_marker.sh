#!/usr/bin/env bash
set -euo pipefail

# Static regression guard for the worker marker trust boundary.
# A completed marker must be impossible unless worker_result.json has
# passed the worker/run/workflow-count provenance checks.
workflow='.github/workflows/webnovel.yml'
test -s "$workflow"

# The marker's completed branch must contain the same provenance predicate
# as the validation step. This guard intentionally fails until the workflow
# couples marker status to those checks.
marker_block=$(awk '/- name: Write worker execution marker/{flag=1} flag{print} /- name: Upload worker result bundle/{flag=0}' "$workflow")

printf '%s\n' "$marker_block" | grep -q 'workflow_id'
printf '%s\n' "$marker_block" | grep -q 'run_index'
printf '%s\n' "$marker_block" | grep -q 'workflow_count'
printf '%s\n' "$marker_block" | grep -q 'EXPECTED_WORKER'
printf '%s\n' "$marker_block" | grep -q 'EXPECTED_RUN_INDEX'
printf '%s\n' "$marker_block" | grep -q 'status=completed'

echo 'Worker marker provenance guard passed.'
