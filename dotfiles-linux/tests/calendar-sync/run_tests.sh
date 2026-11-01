#!/usr/bin/env bash
set -euo pipefail
this_dir=$(cd "$(dirname "$0")" && pwd)
source_dir=$(cd "$this_dir/../.." && pwd)
bridge_python=${CALENDAR_TEST_PYTHON:-$HOME/.local/share/pipx/venvs/khalorg/bin/python}
# Do not let test imports change a frozen source checkout.
export PYTHONDONTWRITEBYTECODE=1
bash "$this_dir/test_calsync.sh"
bash "$this_dir/test_mycalsync.sh"
"$bridge_python" "$this_dir/test_calendar_bridge.py"
python3 "$this_dir/test_calendar_submit.py"
"$bridge_python" "$this_dir/test_calendar_bridge_integration.py"
bash -n "$source_dir/bin/calsync" "$source_dir/bin/mycalsync" "$source_dir/bin/calendar-bridge-local"
