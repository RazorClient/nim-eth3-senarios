#!/usr/bin/env bash

# Copyright (c) 2026 Status Research & Development GmbH.
# Licensed under Apache-2.0 or MIT at your option.

set -Eeuo pipefail

if [[ -n "${CONSENSUS_TEST_VECTOR_VERSIONS:-}" ]]; then
  IFS=',' read -r -a VERSIONS <<< "${CONSENSUS_TEST_VECTOR_VERSIONS}"
elif [[ "$#" -gt 0 ]]; then
  VERSIONS=("$@")
else
  echo "Set CONSENSUS_TEST_VECTOR_VERSIONS or pass at least one version (for example: v1.0.0)." >&2
  exit 1
fi

VECTOR_RELEASE_REPO="${VECTOR_RELEASE_REPO:-status-im/nim-eth3-scenarios}"

if command -v sha256sum >/dev/null 2>&1; then
  CHECKSUM_BIN=(sha256sum)
elif command -v shasum >/dev/null 2>&1; then
  CHECKSUM_BIN=(shasum -a 256)
else
  echo "Missing checksum tool: require sha256sum or shasum." >&2
  exit 1
fi

REL_PATH="$(dirname -- "${BASH_SOURCE[0]}")"
ABS_PATH="$(cd "${REL_PATH}" && pwd)"

cleanup() {
  echo
  echo "Interrupted. Cleaning partial downloads."
  cd "${ABS_PATH}"
  rm -rf tarballs/.partial-download
  exit 1
}
trap cleanup SIGINT SIGTERM

download_release() {
  local version="$1"
  local tarball_name="eth3-lean-spec-vectors-${version}.tar.gz"
  local checksum_name="${tarball_name}.sha256"
  local release_base="https://github.com/${VECTOR_RELEASE_REPO}/releases/download/${version}"
  local target_dir="tarballs/${version}"

  mkdir -p "${target_dir}"
  pushd "${target_dir}" >/dev/null

  curl --fail --location --show-error --retry 3 --retry-all-errors \
    --output "${tarball_name}" \
    "${release_base}/${tarball_name}"

  curl --fail --location --show-error --retry 3 --retry-all-errors \
    --output "${checksum_name}" \
    "${release_base}/${checksum_name}"

  "${CHECKSUM_BIN[@]}" -c "${checksum_name}"

  popd >/dev/null
}

unpack_release() {
  local version="$1"
  local tarball_name="eth3-lean-spec-vectors-${version}.tar.gz"
  local tarball_path="tarballs/${version}/${tarball_name}"
  local out_dir="tests-${version}"
  local extra_tar=()

  if tar --version 2>/dev/null | grep -qi 'gnu'; then
    extra_tar+=(--warning=no-unknown-keyword --ignore-zeros)
  fi

  rm -rf "${out_dir}"
  mkdir -p "${out_dir}"
  tar -C "${out_dir}" --strip-components 1 "${extra_tar[@]}" -xzf "${tarball_path}"
}

for version in "${VERSIONS[@]}"; do
  download_release "${version}"
  unpack_release "${version}"
done

shopt -s nullglob

for tpath in tarballs/*; do
  tdir="$(basename -- "${tpath}")"
  if [[ ! " ${VERSIONS[*]} " =~ " ${tdir} " ]]; then
    rm -rf "${tpath}"
  fi
done

for tpath in tests-*; do
  tver="${tpath#tests-}"
  if [[ ! " ${VERSIONS[*]} " =~ " ${tver} " ]]; then
    rm -rf "${tpath}"
  fi
done

shopt -u nullglob

echo "Downloaded and unpacked versions: ${VERSIONS[*]}"
