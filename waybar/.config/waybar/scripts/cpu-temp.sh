#!/bin/bash
# Read max core temp from coretemp.0 hwmon (stable platform path).
# Outputs JSON for waybar custom module.
set -euo pipefail

hwmon_dir=$(echo /sys/devices/platform/coretemp.0/hwmon/hwmon*)
if [ ! -d "$hwmon_dir" ]; then
  echo '{"text":"--","tooltip":"coretemp not found","class":"unavailable"}'
  exit 0
fi

# Take the package temp (temp1_input) — represents the highest of any core
val_m=$(cat "$hwmon_dir/temp1_input")
celsius=$(( val_m / 1000 ))

# Tooltip with all sensors
tt=""
for f in "$hwmon_dir"/temp*_input; do
  label_file="${f%_input}_label"
  label="?"
  [ -r "$label_file" ] && label=$(cat "$label_file")
  c=$(( $(cat "$f") / 1000 ))
  tt="${tt}${label}: ${c}°C\n"
done
# Strip trailing \n
tt=${tt%\\n}

class="normal"
[ "$celsius" -ge 80 ] && class="warning"
[ "$celsius" -ge 90 ] && class="critical"

# JSON-escape: replace newlines so waybar parses correctly
tt_json=$(printf '%s' "$tt" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e ':a;N;$!ba;s/\n/\\n/g')

printf '{"text":"%d°C","tooltip":"%s","class":"%s"}\n' "$celsius" "$tt_json" "$class"
