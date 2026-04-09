#!/usr/bin/env bash
set -euo pipefail

search_dir="${1:-./assets}"
print_each="${PRINT_EACH:-0}"

if [[ ! -d "${search_dir}" ]]; then
  echo "Error: directory not found: ${search_dir}" >&2
  exit 1
fi

tmp_sizes="$(mktemp)"
tmp_candidates="$(mktemp)"
tmp_hashes="$(mktemp)"
trap 'rm -f "${tmp_sizes}" "${tmp_candidates}" "${tmp_hashes}"' EXIT
find "${search_dir}" -type f \( \
  -iname '*.gif' -o \
  -iname '*.png' -o \
  -iname '*.jpg' -o \
  -iname '*.jpeg' -o \
  -iname '*.webp' -o \
  -iname '*.bmp' -o \
  -iname '*.avif' -o \
  -iname '*.tif' -o \
  -iname '*.tiff' \
\) -printf '%s\t%p\n' > "${tmp_sizes}"

if [[ ! -s "${tmp_sizes}" ]]; then
  echo "No matching image files found in ${search_dir}."
  exit 0
fi

declare -A size_counts

while IFS=$'\t' read -r size _; do
  size_counts["${size}"]=$(( ${size_counts["${size}"]:-0} + 1 ))
done < "${tmp_sizes}"

candidate_files=0
while IFS=$'\t' read -r size file; do
  if (( ${size_counts["${size}"]:-0} > 1 )); then
    printf '%s\0' "${file}" >> "${tmp_candidates}"
    ((candidate_files += 1))
  fi
done < "${tmp_sizes}"

if (( candidate_files == 0 )); then
  echo "No duplicate image contents found in ${search_dir}."
  exit 0
fi

xargs -0 sha256sum --zero -- < "${tmp_candidates}" > "${tmp_hashes}"

declare -A hash_counts
declare -A first_file
declare -A dup_files_by_hash

while IFS= read -r -d '' record; do
  hash="${record%% *}"
  file="${record#* }"
  file="${file# }"

  hash_counts["${hash}"]=$(( ${hash_counts["${hash}"]:-0} + 1 ))
  if [[ -z "${first_file["${hash}"]:-}" ]]; then
    first_file["${hash}"]="${file}"
  else
    dup_files_by_hash["${hash}"]+="${file}"$'\n'
  fi
done < "${tmp_hashes}"

duplicate_groups=0
duplicate_files=0
deleted_files=0

for hash in "${!hash_counts[@]}"; do
  count="${hash_counts["${hash}"]:-0}"

  if (( count > 1 )); then
    duplicate_groups=$((duplicate_groups + 1))
    duplicate_files=$((duplicate_files + count))

    keep_file="${first_file["${hash}"]}"

    if [[ "${print_each}" == "1" ]]; then
      echo "SHA-256: ${hash}"
      echo "Duplicates: ${count} files"
      echo "Keeping: ${keep_file}"
    fi

    while IFS= read -r file; do
      [[ -z "${file}" ]] && continue
      rm -f -- "${file}"
      deleted_files=$((deleted_files + 1))
      if [[ "${print_each}" == "1" ]]; then
        echo "  - ${file} (deleted)"
      fi
    done <<< "${dup_files_by_hash["${hash}"]:-}"

    if [[ "${print_each}" == "1" ]]; then
      echo
    fi
  fi
done

if (( duplicate_groups == 0 )); then
  echo "No duplicate image contents found in ${search_dir}."
else
  extra_copies=$((duplicate_files - duplicate_groups))
  echo "Found ${duplicate_groups} duplicate groups (${duplicate_files} files total, ${extra_copies} extra copies)."
  echo "Deleted ${deleted_files} duplicate files."
  if [[ "${print_each}" != "1" ]]; then
    echo "Set PRINT_EACH=1 to print each deleted file."
  fi
fi
