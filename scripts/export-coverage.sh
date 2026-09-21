#!/usr/bin/env bash
#
# Runs the test suite with code coverage enabled and exports the result as an
# lcov report — the format Codecov consumes.
#
# Usage:
#   scripts/export-coverage.sh [output-file]
#
# The report defaults to `coverage.lcov` in the repository root. A human
# readable summary is printed to stdout as well.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly repo_root

# The export runs from the repository root, so resolve a relative output path
# against the caller's directory before moving there.
output="${1:-${repo_root}/coverage.lcov}"
[[ "${output}" == /* ]] || output="$(pwd)/${output}"
readonly output

# Coverage measures the shipped sources only. Test code and the dependency
# sources checked out under .build are not part of the metric.
readonly excluded_paths='(^|/)(\.build|Tests)/'

cd "${repo_root}"

# llvm-cov lives inside the active toolchain on macOS and on PATH in the
# official Swift container images.
if command -v xcrun >/dev/null 2>&1; then
    llvm_cov=(xcrun llvm-cov)
elif command -v llvm-cov >/dev/null 2>&1; then
    llvm_cov=(llvm-cov)
else
    echo "error: llvm-cov not found; install the Swift toolchain's LLVM tools." >&2
    exit 1
fi

swift test --enable-code-coverage

bin_path="$(swift build --show-bin-path)"
readonly bin_path
readonly profdata="${bin_path}/codecov/default.profdata"

if [[ ! -f "${profdata}" ]]; then
    echo "error: no coverage profile at ${profdata}." >&2
    exit 1
fi

# SwiftPM emits each test target as a bundle directory on Darwin and as a bare
# executable everywhere else. This package has two test targets, and each one
# links a different module: the macro implementation is only in the expansion
# test binary. llvm-cov reports on the binaries it is handed, so collect all of
# them — passing just one would silently describe half the package.
test_binaries=()
for bundle in "${bin_path}"/*.xctest; do
    if [[ -d "${bundle}" ]]; then
        candidate="${bundle}/Contents/MacOS/$(basename "${bundle}" .xctest)"
    elif [[ -f "${bundle}" ]]; then
        candidate="${bundle}"
    else
        continue
    fi
    if [[ -x "${candidate}" ]]; then
        test_binaries+=("${candidate}")
    fi
done

if [[ ${#test_binaries[@]} -eq 0 ]]; then
    echo "error: no test binary found in ${bin_path}." >&2
    exit 1
fi

# llvm-cov takes the first binary positionally and every other one behind
# -object. Indexed rather than sliced so this stays valid under bash 3.2,
# which is what macOS ships.
cov_objects=("${test_binaries[0]}")
index=1
while [[ ${index} -lt ${#test_binaries[@]} ]]; do
    cov_objects+=(-object "${test_binaries[${index}]}")
    index=$((index + 1))
done

# llvm-cov records absolute source paths. Codecov matches coverage against the
# repository tree, so rewrite them relative to the repository root.
"${llvm_cov[@]}" export -format=lcov "${cov_objects[@]}" \
    -instr-profile "${profdata}" \
    -ignore-filename-regex="${excluded_paths}" \
    | awk -v prefix="SF:${repo_root}/" '
        index($0, prefix) == 1 { $0 = "SF:" substr($0, length(prefix) + 1) }
        { print }
    ' > "${output}"

"${llvm_cov[@]}" report "${cov_objects[@]}" \
    -instr-profile "${profdata}" \
    -ignore-filename-regex="${excluded_paths}"

echo "Wrote lcov report to ${output}"
