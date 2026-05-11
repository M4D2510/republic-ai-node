#!/bin/bash
# disk-cleanup.sh
# Reclaim disk space on a Republic AI validator host
# Vacuums journal, truncates logs, clears apt caches, drops old syslogs

set -e

echo "=== Disk usage BEFORE ==="
df -h / | awk 'NR==2 {print $5 " used (" $3 " / " $2 ")"}'

echo ""
echo "--- Journal vacuum (keep last 7 days) ---"
journalctl --vacuum-time=7d 2>&1 | tail -5

echo ""
echo "--- APT clean ---"
apt-get clean -y 2>&1 | tail -3

echo ""
echo "--- Old syslog ---"
find /var/log -name "*.gz" -mtime +14 -delete -print 2>/dev/null | wc -l

echo ""
echo "--- Truncate large log files (>100MB) ---"
find /var/log -type f -size +100M -exec truncate -s 0 {} \; -print 2>/dev/null

echo ""
echo "=== Disk usage AFTER ==="
df -h / | awk 'NR==2 {print $5 " used (" $3 " / " $2 ")"}'
