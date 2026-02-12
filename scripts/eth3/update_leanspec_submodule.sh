#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
REPO_DIR="${ROOT_DIR}/vendor/leanspec"
ENV_FILE="${ROOT_DIR}/.tmp/leanspec.env"
REF=""
DO_FETCH=1

# Keep the default vendor path initialized automatically.
if [[ "${REPO_DIR}" == "${ROOT_DIR}/vendor/leanspec" ]]; then
  git -C "${ROOT_DIR}" submodule update --init --recursive vendor/leanspec
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ref)
      REF="$2"
      shift 2
      ;;
    --repo-dir)
      REPO_DIR="$2"
      shift 2
      ;;
    --env-file)
      ENV_FILE="$2"
      shift 2
      ;;
    --skip-fetch)
      DO_FETCH=0
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "${REF}" ]]; then
  echo "Missing required --ref argument" >&2
  exit 1
fi

if [[ ! -d "${REPO_DIR}" ]]; then
  echo "leanSpec repo directory not found: ${REPO_DIR}" >&2
  exit 1
fi

if ! git -C "${REPO_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Path is not a git repository: ${REPO_DIR}" >&2
  exit 1
fi

if [[ "${DO_FETCH}" -eq 1 ]]; then
  git -C "${REPO_DIR}" fetch --tags origin
fi
git -C "${REPO_DIR}" checkout "${REF}"

LEANSPEC_SHA="$(git -C "${REPO_DIR}" rev-parse HEAD)"
LEANSPEC_SHORT_SHA="$(git -C "${REPO_DIR}" rev-parse --short=12 HEAD)"
LEANSPEC_REMOTE="$(git -C "${REPO_DIR}" remote get-url origin)"
LEANSPEC_COMMIT_DATE_UTC="$(git -C "${REPO_DIR}" show -s --format=%cI HEAD)"

mkdir -p "$(dirname -- "${ENV_FILE}")"
{
  printf 'LEANSPEC_REF_REQUESTED=%q\n' "${REF}"
  printf 'LEANSPEC_SHA=%q\n' "${LEANSPEC_SHA}"
  printf 'LEANSPEC_SHORT_SHA=%q\n' "${LEANSPEC_SHORT_SHA}"
  printf 'LEANSPEC_REMOTE=%q\n' "${LEANSPEC_REMOTE}"
  printf 'LEANSPEC_COMMIT_DATE_UTC=%q\n' "${LEANSPEC_COMMIT_DATE_UTC}"
} > "${ENV_FILE}"

echo "leanSpec ref '${REF}' resolved to ${LEANSPEC_SHA}"
echo "Wrote metadata to ${ENV_FILE}"
