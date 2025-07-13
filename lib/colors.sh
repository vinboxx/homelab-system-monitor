#!/bin/bash

# Color utility functions for temperature monitoring

# Function to colorize temperature based on heat level
colorize_temperature() {
  local temp="$1"
  local temp_type="${2:-cpu}"  # cpu or drive, defaults to cpu

  # Extract numeric value from temperature string
  local temp_num=$(echo "$temp" | grep -o '[0-9]\+' | head -1)

  # If no numeric value found, return as-is
  if [[ $temp_num == '' ]]; then
    echo "$temp"
    return
  fi

  # Define color codes
  local RESET='\033[0m'
  local GREEN='\033[32m'     # Cool - good temps
  local YELLOW='\033[33m'    # Warm - acceptable temps
  local ORANGE='\033[38;5;208m'  # Hot - concerning temps
  local RED='\033[31m'       # Very hot - dangerous temps
  local BOLD_RED='\033[1;31m'    # Critical - immediate attention

  # Set temperature thresholds based on component type
  local cool_max warm_max hot_max critical_max
  if [[ $temp_type == "drive" ]]; then
    # Drive temperature thresholds (typically lower than CPU)
    cool_max=35
    warm_max=45
    hot_max=55
    critical_max=65
  elif [[ $temp_type == "ram" ]]; then
    # RAM temperature thresholds (typically lower than CPU, similar to drives)
    cool_max=40
    warm_max=50
    hot_max=60
    critical_max=70
  else
    # CPU temperature thresholds
    cool_max=50
    warm_max=70
    hot_max=85
    critical_max=95
  fi

  # Choose color based on temperature
  local color
  if [[ $temp_num -le $cool_max ]]; then
    color=$GREEN
  elif [[ $temp_num -le $warm_max ]]; then
    color=$YELLOW
  elif [[ $temp_num -le $hot_max ]]; then
    color=$ORANGE
  elif [[ $temp_num -le $critical_max ]]; then
    color=$RED
  else
    color=$BOLD_RED
  fi

  # Return colorized temperature
  echo -e "${color}${temp}${RESET}"
}
