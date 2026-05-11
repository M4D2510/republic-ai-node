#!/bin/bash
# disk-report.sh - chain home dir disk usage breakdown
du -sh "$HOME/.republicd"/* 2>/dev/null | sort -h
