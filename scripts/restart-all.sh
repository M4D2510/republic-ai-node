#!/bin/bash
# restart-all.sh - safe restart of validator stack
set -e
systemctl restart republicd && sleep 5 && systemctl status republicd --no-pager | head -10
