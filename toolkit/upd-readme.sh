#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
assets_dir="${repo_root}/assets"
readme_file="${repo_root}/README.md"
gallery_dir="${repo_root}/gallery"
row_size=8
max_gallery_per_file=1000

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

mkdir -p "${gallery_dir}"

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

gallery_page_size="${GALLERY_PAGE_SIZE:-1000}"
if ! [[ "${gallery_page_size}" =~ ^[0-9]+$ ]] || (( gallery_page_size == 0 )); then
  echo "Error: GALLERY_PAGE_SIZE must be a positive integer." >&2
  exit 1
fi
if (( gallery_page_size > max_gallery_per_file )); then
  gallery_page_size="${max_gallery_per_file}"
fi

gallery_pages=$(( (total_count + gallery_page_size - 1) / gallery_page_size ))
if (( gallery_pages == 0 )); then
  gallery_pages=1
fi

formatted_total_count="$(format_number "${total_count}")"
formatted_preview_count="$(format_number "${preview_count}")"
formatted_gallery_page_size="$(format_number "${gallery_page_size}")"

: > "${readme_file}"

rm -f "${repo_root}/GALLERY.md"
shopt -s nullglob
old_gallery_pages=("${gallery_dir}"/GALLERY_*.md)
if (( ${#old_gallery_pages[@]} > 0 )); then
  rm -f "${old_gallery_pages[@]}"
fi
shopt -u nullglob

cat > "${readme_file}" <<'EOF'
<div align="center">
  <h1><i>The</i> Repository for 88x31 Buttons</h1>
EOF

printf '  <p>Showing first %s of %s buttons. Full gallery is split into %s pages (max %s per file): <a href="./gallery/GALLERY_1.md">GALLERY_1.md</a>.</p>\n\n' "${formatted_preview_count}" "${formatted_total_count}" "${gallery_pages}" "${formatted_gallery_page_size}" >> "${readme_file}"

count=0
current_page=0
current_gallery_file=""

open_gallery_page() {
  local page="$1"
  local gallery_file="${gallery_dir}/GALLERY_${page}.md"

  cat > "${gallery_file}" <<EOF
<div align="center">
  <h1>Full 88x31 Gallery (Page ${page}/${gallery_pages})</h1>
EOF

  if (( page > 1 )); then
    printf '  <p><a href="./GALLERY_%d.md">&larr; Previous</a></p>\n' "$((page - 1))" >> "${gallery_file}"
  fi

  if (( page < gallery_pages )); then
    printf '  <p><a href="./GALLERY_%d.md">Next &rarr;</a></p>\n' "$((page + 1))" >> "${gallery_file}"
  fi

  printf '\n' >> "${gallery_file}"
  current_gallery_file="${gallery_file}"
}

for file in "${files[@]}"; do
  page_number=$(( (count / gallery_page_size) + 1 ))
  page_index=$(( count % gallery_page_size ))

  if (( page_number != current_page )); then
    if (( current_page > 0 )); then
      printf '</div>\n' >> "${current_gallery_file}"
    fi
    current_page="${page_number}"
    open_gallery_page "${current_page}"
  fi

  if (( count < preview_count )); then
    if (( count % row_size == row_size - 1 )); then
      printf '  <img src="./assets/%s" width="88" height="31"><br>\n' "${file}" >> "${readme_file}"
    else
      printf '  <img src="./assets/%s" width="88" height="31">\n' "${file}" >> "${readme_file}"
    fi
  fi

  if (( page_index % row_size == row_size - 1 )); then
    printf '  <img src="../assets/%s" width="88" height="31"><br>\n' "${file}" >> "${current_gallery_file}"
  else
    printf '  <img src="../assets/%s" width="88" height="31">\n' "${file}" >> "${current_gallery_file}"
  fi

  ((count += 1))
done

if (( current_page == 0 )); then
  open_gallery_page 1
  printf '  <p>No assets found.</p>\n' >> "${current_gallery_file}"
fi

printf '</div>\n' >> "${readme_file}"
printf '</div>\n' >> "${current_gallery_file}"

echo "Updated ${readme_file} with ${formatted_preview_count} image tags (preview) and ${gallery_pages} gallery pages in ${gallery_dir} (${formatted_total_count} image tags total)."
