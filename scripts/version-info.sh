#!/bin/bash
# version-info.sh - full version banner
republicd version --long 2>&1 | head -20
