#!/bin/bash
cd "$(dirname "$0")"
chmod +x Scripts/benchmark.sh
export FUSION_RUNNER=command
Scripts/benchmark.sh
echo
echo "Press Return to close"
read -r _
