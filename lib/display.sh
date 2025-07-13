#!/bin/bash

# Display and output formatting functions

# Source required libraries
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIR/colors.sh"
source "$SCRIPT_DIR/cpu_temp.sh"
source "$SCRIPT_DIR/ram_temp.sh"
source "$SCRIPT_DIR/drive_temp.sh"

# Function to generate temperature output as a string (for buffered display)
generate_temperature_output() {
  local output=""

  # Header
  output+="========================================\n"
  output+="     System Temperature Monitor\n"
  output+="========================================\n\n"

  # Get and print all CPU core temperatures
  output+="=== CPU Temperature(s) ===\n"
  local core_temperatures=$(get_all_core_temperatures)
  if [[ $core_temperatures != '' ]]; then
    # Process each line and colorize temperatures
    while IFS= read -r line; do
      if [[ $line == *"temperature:"* ]]; then
        local temp_part=$(echo "$line" | awk -F'temperature: ' '{print $2}')
        local label_part=$(echo "$line" | awk -F'temperature: ' '{print $1}')
        local colored_temp=$(colorize_temperature "$temp_part" "cpu")
        output+="${label_part}temperature: ${colored_temp}\n"
      else
        output+="$line\n"
      fi
    done <<< "$core_temperatures"
  else
    output+="CPU temperature: N/A (sensors not available)\n"
  fi
  output+="\n"

  # Print RAM temperatures
  output+="=== RAM Temperature(s) ===\n"
  local ram_temperatures=$(get_ram_temperature)
  if [[ $ram_temperatures != '' ]]; then
    # Process each line and colorize temperatures
    while IFS= read -r line; do
      if [[ $line == *"temperature:"* ]]; then
        local temp_part=$(echo "$line" | awk -F'temperature: ' '{print $2}')
        local label_part=$(echo "$line" | awk -F'temperature: ' '{print $1}')
        local colored_temp=$(colorize_temperature "$temp_part" "ram")
        output+="${label_part}temperature: ${colored_temp}\n"
      else
        output+="$line\n"
      fi
    done <<< "$ram_temperatures"
  else
    output+="RAM temperature: N/A (sensors not available)\n"
  fi
  output+="\n"

  # Print SATA drive temperatures
  output+="=== SATA Drive Temperature(s) ===\n"
  local sata_found=false
  for drive in /dev/sd?; do
    if [ -e "$drive" ]; then
      local temperature=$(get_drive_temperature "$drive")
      local drive_name=$(get_drive_name "$drive")
      if [[ $temperature != '' ]]; then
        local colored_temp=$(colorize_temperature "$temperature°C" "drive")
        output+="$drive ($drive_name) temperature: ${colored_temp}\n"
      else
        output+="$drive ($drive_name) temperature: N/A\n"
      fi
      sata_found=true
    fi
  done
  if [[ $sata_found == false ]]; then
    output+="No SATA drives found\n"
  fi
  output+="\n"

  # Print NVMe drive temperatures
  output+="=== NVMe Drive Temperature(s) ===\n"
  local nvme_found=false
  for drive in /dev/nvme?n?; do
    if [ -e "$drive" ]; then
      local temperature=$(get_drive_temperature "$drive")
      local drive_name=$(get_drive_name "$drive")
      if [[ $temperature != '' ]]; then
        local colored_temp=$(colorize_temperature "$temperature°C" "drive")
        output+="$drive ($drive_name) temperature: ${colored_temp}\n"
      else
        output+="$drive ($drive_name) temperature: N/A\n"
      fi
      nvme_found=true
    fi
  done
  if [[ $nvme_found == false ]]; then
    output+="No NVMe drives found\n"
  fi

  output+="---\n"
  output+="Updated: $(date '+%Y-%m-%d %H:%M:%S')\n"
  output+="Press Ctrl+C to stop monitoring\n\n"

  echo -e "$output"
}

# Function to display temperatures once (for single run mode)
display_temperatures() {
  # Get and print all CPU core temperatures
  echo "=== CPU Temperature(s) ==="
  core_temperatures=$(get_all_core_temperatures)
  if [[ $core_temperatures != '' ]]; then
    # Process each line and colorize temperatures
    while IFS= read -r line; do
      if [[ $line == *"temperature:"* ]]; then
        local temp_part=$(echo "$line" | awk -F'temperature: ' '{print $2}')
        local label_part=$(echo "$line" | awk -F'temperature: ' '{print $1}')
        local colored_temp=$(colorize_temperature "$temp_part" "cpu")
        echo -e "${label_part}temperature: ${colored_temp}"
      else
        echo "$line"
      fi
    done <<< "$core_temperatures"
  else
    echo "CPU temperature: N/A (sensors not available)"
  fi
  echo

  # Print RAM temperatures
  echo "=== RAM Temperature(s) ==="
  ram_temperatures=$(get_ram_temperature)
  if [[ $ram_temperatures != '' ]]; then
    # Process each line and colorize temperatures
    while IFS= read -r line; do
      if [[ $line == *"temperature:"* ]]; then
        local temp_part=$(echo "$line" | awk -F'temperature: ' '{print $2}')
        local label_part=$(echo "$line" | awk -F'temperature: ' '{print $1}')
        local colored_temp=$(colorize_temperature "$temp_part" "ram")
        echo -e "${label_part}temperature: ${colored_temp}"
      else
        echo "$line"
      fi
    done <<< "$ram_temperatures"
  else
    echo "RAM temperature: N/A (sensors not available)"
  fi
  echo

  # Print SATA drive temperatures
  echo "=== SATA Drive Temperature(s) ==="
  sata_found=false
  for drive in /dev/sd?; do
    if [ -e "$drive" ]; then
      temperature=$(get_drive_temperature "$drive")
      drive_name=$(get_drive_name "$drive")
      if [[ $temperature != '' ]]; then
        colored_temp=$(colorize_temperature "$temperature°C" "drive")
        echo -e "$drive ($drive_name) temperature: ${colored_temp}"
      else
        echo "$drive ($drive_name) temperature: N/A"
      fi
      sata_found=true
    fi
  done
  if [[ $sata_found == false ]]; then
    echo "No SATA drives found"
  fi
  echo

  # Print NVMe drive temperatures
  echo "=== NVMe Drive Temperature(s) ==="
  nvme_found=false
  for drive in /dev/nvme?n?; do
    if [ -e "$drive" ]; then
      temperature=$(get_drive_temperature "$drive")
      drive_name=$(get_drive_name "$drive")
      if [[ $temperature != '' ]]; then
        colored_temp=$(colorize_temperature "$temperature°C" "drive")
        echo -e "$drive ($drive_name) temperature: ${colored_temp}"
      else
        echo "$drive ($drive_name) temperature: N/A"
      fi
      nvme_found=true
    fi
  done
  if [[ $nvme_found == false ]]; then
    echo "No NVMe drives found"
  fi

  echo "---"
  echo "Updated: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "Press Ctrl+C to stop monitoring"
  echo
}
