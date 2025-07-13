#!/bin/bash

# System Temperature Monitor - Main Script
# This script monitors CPU and drive temperatures with colored output

# Get the script directory for relative paths
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

# Source all required library functions
source "$SCRIPT_DIR/lib/display.sh"

# Trap Ctrl+C to exit gracefully
trap 'echo -e "\n\nMonitoring stopped."; exit 0' SIGINT

# Check if refresh mode is requested
if [[ "$1" == "--refresh" ]] || [[ "$1" == "-r" ]]; then
  echo "Starting temperature monitoring (refreshing every 3 seconds)..."
  echo "Press Ctrl+C to stop"
  echo

  while true; do
    # Generate all output at once, then display it instantly
    full_output=$(generate_temperature_output)

    # Move to top and display all content at once
    printf '\033[H\033[2J'  # Clear screen and move to top
    echo "$full_output"

    # Wait 3 seconds before next update
    sleep 3
  done
else
  # Single run mode (original behavior)
  display_temperatures
  echo
  echo "Tip: Use './system-monitor.sh --refresh' or './system-monitor.sh -r' for continuous monitoring"
fi
