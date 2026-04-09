#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
assets_dir="${repo_root}/assets"
readme_file="${repo_root}/README.md"

if [[ ! -d "${assets_dir}" ]]; then
  echo "Error: assets directory not found at ${assets_dir}" >&2
  exit 1
fi

mapfile -t files < <(find "${assets_dir}" -maxdepth 1 -type f -printf '%f\n' | sort)

: > "${readme_file}"

cat > "${readme_file}" <<'EOF'
<div align="center">
  <h1><i>The</i> Repository for 88x31 Buttons</h1>
  <p>The largest 88x31 90s-2000s esque button repository on the internet.
  </p>

EOF

count=0
for file in "${files[@]}"; do
  if (( count % 5 == 4 )); then
    printf '  <img src="./assets/%s" width="88" height="31"><br>\n' "${file}" >> "${readme_file}"
  else
    printf '  <img src="./assets/%s" width="88" height="31">\n' "${file}" >> "${readme_file}"
  fi

  ((count += 1))
done

printf '</div>\n' >> "${readme_file}"

echo "Updated ${readme_file} with ${count} image tags."
