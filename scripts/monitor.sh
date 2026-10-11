#!/usr/bin/env bash
# Report service health and error entries from the last 60 minutes in /var/log/syslog.
set -u -o pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <systemd-service>" >&2
  exit 64
fi

service="$1"
if [[ ! "$service" =~ ^[a-zA-Z0-9_.@-]+$ ]]; then
  echo "Invalid service name: $service" >&2
  exit 64
fi

if ! systemctl cat "$service" >/dev/null 2>&1; then
  echo "Service '$service' was not found." >&2
  exit 4
fi

if systemctl is-active --quiet "$service"; then
  echo "Service '$service': active"
else
  echo "Service '$service': inactive"
  echo "Last 10 log entries:"
  journalctl -u "$service" -n 10 --no-pager || true
fi

if [[ ! -r /var/log/syslog ]]; then
  echo "Errors in /var/log/syslog during the last hour: unavailable (file is absent or unreadable)"
  exit 0
fi

# Syslog omits the year. mktime uses the current year, sufficient for the rolling one-hour window.
cutoff_epoch=$(date --date='1 hour ago' +%s)
current_year=$(date +%Y)
errors=$(
  grep -Eia 'error|failed|fatal|critical' /var/log/syslog 2>/dev/null \
    | awk -v cutoff="$cutoff_epoch" -v year="$current_year" '
      BEGIN { split("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec", month_names, " "); for (i = 1; i <= 12; i++) months[month_names[i]] = i }
      months[$1] && $2 ~ /^[0-9]+$/ && $3 ~ /^[0-9]{2}:[0-9]{2}:[0-9]{2}$/ {
        split($3, time, ":")
        stamp = mktime(year " " months[$1] " " $2 " " time[1] " " time[2] " " time[3])
        if (stamp >= cutoff) count++
      }
      END { print count + 0 }
    '
)
echo "Errors in /var/log/syslog during the last hour: $errors"
