#!/bin/bash
set -eu # Increase bash error strictness

if [[ -n "${GITHUB_WORKSPACE}" ]]; then
  cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit
fi

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

# Only scan added and modified files to reduce volume of output
# - avoids hitting 65535 character Github API limit.
export FILES=$(git diff --diff-filter=AM --name-status "${GITHUB_BASE_REF}" | cut -f2)
echo "Checking files: ${FILES}"

# NOTE: ${VAR,,} Is bash 4.0 syntax to make strings lowercase.
echo "[action-remark-lint] Checking markdown code with the remark-lint linter and reviewdog..."
remark --rc-path=/src/remarkrc.suggestion ${FILES} ${INPUT_REMARK_ARGS} 2>&1 |
  sed 's/\x1b\[[0-9;]*m//g' | # Removes ansi codes see https://github.com/reviewdog/errorformat/issues/51
  reviewdog -f=remark-lint \
    -name="${INPUT_TOOL_NAME}" \
    -reporter="${INPUT_REPORTER}" \
    -filter-mode="${INPUT_FILTER_MODE}" \
    -fail-on-error="false" \
    -level="info" \
    -tee \
    ${INPUT_REVIEWDOG_FLAGS}

remark --rc-path=/src/remarkrc.problem ${FILES}: ${INPUT_REMARK_ARGS} 2>&1 |
  sed 's/\x1b\[[0-9;]*m//g' | # Removes ansi codes see https://github.com/reviewdog/errorformat/issues/51
  reviewdog -f=remark-lint \
    -name="${INPUT_TOOL_NAME}" \
    -reporter="${INPUT_REPORTER}" \
    -filter-mode="${INPUT_FILTER_MODE}" \
    -fail-on-error="true" \
    -level="error" \
    -tee \
    ${INPUT_REVIEWDOG_FLAGS}
