#!/usr/bin/env bash
set -euo pipefail
this_dir=$(cd "$(dirname "$0")" && pwd)
source_dir=$(cd "$this_dir/../.." && pwd)
bash "$this_dir/test_calsync.sh"
bash "$this_dir/test_mycalsync.sh"
bash "$this_dir/test_khalorg_local.sh"
bash "$this_dir/test_export.sh"
bash -n "$source_dir/bin/calsync" "$source_dir/bin/mycalsync" "$source_dir/bin/khalorg-local"
