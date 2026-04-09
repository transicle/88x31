#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
assets_dir="${repo_root}/assets"
readme_file="${repo_root}/README.md"
gallery_file="${repo_root}/GALLERY.md"
row_size=8

bash "${script_dir}/update-assets.sh"
bash "${script_dir}/rm-dupes.sh" "${assets_dir}"

format_number() {
  local n out
  n="$1"
  out=""

  while [[ ${#n} -gt 3 ]]; do
    out=",${n: -3}${out}"
    n="${n:0:${#n}-3}"
  done

  printf '%s%s' "${n}" "${out}"
}

if [[ ! -d "${assets_dir}" ]]; then
  echo "Error: assets directory not found at ${assets_dir}" >&2
  exit 1
fi

mapfile -t files < <(find "${assets_dir}" -maxdepth 1 -type f -printf '%f\n' | sort)
total_count="${#files[@]}"
preview_count="${PREVIEW_COUNT:-304}"

if ! [[ "${preview_count}" =~ ^[0-9]+$ ]]; then
  echo "Error: PREVIEW_COUNT must be a non-negative integer." >&2
  exit 1
fi

if (( preview_count > total_count )); then
  preview_count="${total_count}"
fi

formatted_total_count="$(format_number "${total_count}")"
formatted_preview_count="$(format_number "${preview_count}")"

: > "${readme_file}"
: > "${gallery_file}"

cat > "${readme_file}" <<'EOF'
<div align="center">
  <h1><i>The</i> Repository for 88x31 Buttons</h1>
EOF

printf '  <p>Showing first %s of %s buttons. See <a href="./GALLERY.md">GALLERY.md</a> for the full list.</p>\n\n' "${formatted_preview_count}" "${formatted_total_count}" >> "${readme_file}"

cat > "${gallery_file}" <<'EOF'
<div align="center">
  <h1>Full 88x31 Gallery</h1>
EOF

count=0
for file in "${files[@]}"; do
  if (( count < preview_count )); then
    if (( count % row_size == row_size - 1 )); then
      printf '  <img src="./assets/%s" width="88" height="31"><br>\n' "${file}" >> "${readme_file}"
    else
      printf '  <img src="./assets/%s" width="88" height="31">\n' "${file}" >> "${readme_file}"
    fi
  fi

  if (( count % row_size == row_size - 1 )); then
    printf '  <img src="./assets/%s" width="88" height="31"><br>\n' "${file}" >> "${gallery_file}"
  else
    printf '  <img src="./assets/%s" width="88" height="31">\n' "${file}" >> "${gallery_file}"
  fi

  ((count += 1))
done

printf '</div>\n' >> "${readme_file}"
printf '</div>\n' >> "${gallery_file}"

echo "Updated ${readme_file} with ${formatted_preview_count} image tags (preview) and ${gallery_file} with ${formatted_total_count} image tags (full)."
