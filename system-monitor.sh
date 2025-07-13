#!/bin/bash

# System Temperature Monitor - Main Script with ncurses support
# This script monitors CPU and drive temperatures with advanced terminal control

# Get the script directory for relative paths
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

# Source all required library functions
source "$SCRIPT_DIR/lib/display.sh"

# Function to check and ensure sudo access
check_sudo_access() {
  echo "This script requires sudo access for drive and memory temperature monitoring."
  echo "Please enter your password to continue..."
  echo ""
  
  # Pre-authenticate sudo to avoid prompts during monitoring
  if sudo -v; then
    echo "✓ Sudo access granted. Starting temperature monitor..."
    echo ""
    sleep 1
    return 0
  else
    echo "✗ Sudo access denied. Exiting..."
    exit 1
  fi
}

# Check sudo access before starting
check_sudo_access

# Initialize ncurses-like terminal settings
init_terminal() {
  # Hide cursor
  tput civis
  # Clear screen
  tput clear
  # Enable alternative screen buffer
  tput smcup
  # Set up colors if supported
  if [[ $(tput colors) -ge 8 ]]; then
    export COLORS_ENABLED=true
  else
    export COLORS_ENABLED=false
  fi
}

# Restore terminal settings
cleanup_terminal() {
  # Show cursor
  tput cnorm
  # Restore normal screen buffer
  tput rmcup
  # Reset terminal
  tput sgr0
  echo -e "\n\nMonitoring stopped."
  exit 0
}

# Trap Ctrl+C and other signals to exit gracefully
trap cleanup_terminal SIGINT SIGTERM EXIT

# Initialize terminal
init_terminal

# Get terminal dimensions
TERM_COLS=$(tput cols)
TERM_ROWS=$(tput lines)

# Draw the static interface once
display_static_interface

# Start continuous temperature monitoring
loop_count=0
while true; do
  # Refresh sudo credentials every 60 iterations (approximately 5 minutes at 5-second intervals)
  if [[ $((loop_count % 60)) -eq 0 ]]; then
    sudo -v >/dev/null 2>&1
  fi
  
  # Update only the temperature values (no redraw of boxes/titles)
  update_temperature_values

  # Update status line at bottom
  tput cup $((TERM_ROWS - 2)) 0
  tput el  # Clear to end of line
  echo "Updated: $(date '+%Y-%m-%d %H:%M:%S') | Press Ctrl+C to exit"
  
  ((loop_count++))
  sleep 5
done
