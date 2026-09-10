#!/usr/bin/env bash
set -euo pipefail

result_file="${1:?result file required}"
expected_worker="${2:?worker id required}"
expected_run="${3:?run index required}"
expected_total="${4:?worker count required}"

if test -s "$result_file" \
  && jq empty "$result_file" >/dev/null 2>&1 \
  && jq -e --argjson worker "$expected_worker" --argjson run "$expected_run" --argjson total "$expected_total" \
       '.workflow_id == $worker and .run_index == $run and .workflow_count == $total and (.rows | arrays)' \
       "$result_file" >/dev/null; then
  jq -r '.failed // 0' "$result_file"
  exit 0
fi

exit 1
