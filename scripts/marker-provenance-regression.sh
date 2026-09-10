#!/usr/bin/env bash
set -euo pipefail

workflow_file="${1:-.github/workflows/webnovel.yml}"
grep -q 'status=completed' "$workflow_file"
grep -q 'status=process_failed' "$workflow_file"
grep -q 'worker_execution_marker.json' "$workflow_file"
grep -q '.workflow_id == $worker and .run_index == $run and .workflow_count == $total and (.rows | arrays)' "$workflow_file"
