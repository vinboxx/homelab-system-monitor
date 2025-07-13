#!/bin/bash

# Display and output formatting functions

# Source required libraries
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIR/colors.sh"
source "$SCRIPT_DIR/cpu_temp.sh"
source "$SCRIPT_DIR/ram_temp.sh"
source "$SCRIPT_DIR/drive_temp.sh"

# Terminal control functions for ncurses-like behavior
draw_box() {
  local row=$1
  local col=$2
  local width=$3
  local height=$4
  local title="$5"

  # Top border
  tput cup $row $col
  echo -n "┌"
  for ((i=1; i<width-1; i++)); do echo -n "─"; done
  echo -n "┐"

  # Title if provided
  if [[ -n "$title" ]]; then
    local title_pos=$((col + (width - ${#title}) / 2))
    tput cup $row $title_pos
    echo -n "$title"
  fi

  # Side borders
  for ((i=1; i<height-1; i++)); do
    tput cup $((row + i)) $col
    echo -n "│"
    tput cup $((row + i)) $((col + width - 1))
    echo -n "│"
  done

  # Bottom border
  tput cup $((row + height - 1)) $col
  echo -n "└"
  for ((i=1; i<width-1; i++)); do echo -n "─"; done
  echo -n "┘"
}

# Static interface that gets drawn once
display_static_interface() {
  local term_cols=$(tput cols)
  local term_rows=$(tput lines)

  # Clear screen
  tput clear

  # Main title
  local title="System Temperature Monitor"
  local title_pos=$((term_cols / 2 - ${#title} / 2))
  tput cup 0 $title_pos
  tput bold
  echo "$title"
  tput sgr0

  # Draw separator
  tput cup 1 0
  for ((i=0; i<term_cols; i++)); do echo -n "═"; done

  # CPU Temperature Section (box only)
  draw_box 3 2 $((term_cols - 4)) 8 " CPU Temperatures "

  # RAM Temperature Section (box only)
  draw_box 12 2 $((term_cols - 4)) 6 " RAM Temperatures "

  # Storage Temperature Section (box only)
  draw_box 19 2 $((term_cols - 4)) 10 " Storage Temperatures "
}



# Global variables to store previous values
declare -A PREV_CPU_TEMPS
declare -A PREV_RAM_TEMPS
declare -A PREV_DRIVE_TEMPS

# Function to update only temperature values that have changed
update_temperature_values() {
  local term_cols=$(tput cols)

  # Update CPU temperatures
  local current_row=5
  local core_temperatures=$(get_all_core_temperatures)

  if [[ $core_temperatures != '' ]]; then
    local line_num=0
    while IFS= read -r line; do
      if [[ $line == *"temperature:"* ]]; then
        local temp_part=$(echo "$line" | awk -F'temperature: ' '{print $2}')
        local label_part=$(echo "$line" | awk -F'temperature: ' '{print $1}')
        local colored_temp=$(colorize_temperature "$temp_part" "cpu")
        local full_line="${label_part}temperature: ${colored_temp}"

        # Only update if value changed
        if [[ "${PREV_CPU_TEMPS[$line_num]}" != "$full_line" ]]; then
          tput cup $((current_row + line_num)) 4
          # Use spaces to overwrite exactly
          printf "%-$((term_cols - 8))s" "$full_line"
          PREV_CPU_TEMPS[$line_num]="$full_line"
        fi
        ((line_num++))
      fi
    done <<< "$core_temperatures"
  else
    local na_msg="CPU temperature: N/A (sensors not available)"
    if [[ "${PREV_CPU_TEMPS[0]}" != "$na_msg" ]]; then
      tput cup $((current_row)) 4
      printf "%-$((term_cols - 8))s" "$na_msg"
      PREV_CPU_TEMPS[0]="$na_msg"
    fi
  fi

  # Update RAM temperatures
  current_row=14

  local ram_temperatures=$(get_ram_temperature)
  if [[ $ram_temperatures != '' ]]; then
    local line_num=0
    while IFS= read -r line; do
      if [[ $line == *"temperature:"* ]]; then
        local temp_part=$(echo "$line" | awk -F'temperature: ' '{print $2}')
        local label_part=$(echo "$line" | awk -F'temperature: ' '{print $1}')
        local colored_temp=$(colorize_temperature "$temp_part" "ram")
        local full_line="${label_part}temperature: ${colored_temp}"

        # Only update if value changed
        if [[ "${PREV_RAM_TEMPS[$line_num]}" != "$full_line" ]]; then
          tput cup $((current_row + line_num)) 4
          printf "%-$((term_cols - 8))s" "$full_line"
          PREV_RAM_TEMPS[$line_num]="$full_line"
        fi
        ((line_num++))
      fi
    done <<< "$ram_temperatures"
  else
    local na_msg="RAM temperature: N/A (sensors not available)"
    if [[ "${PREV_RAM_TEMPS[0]}" != "$na_msg" ]]; then
      tput cup $((current_row)) 4
      printf "%-$((term_cols - 8))s" "$na_msg"
      PREV_RAM_TEMPS[0]="$na_msg"
    fi
  fi

  # Update Storage temperatures
  current_row=21

  # SATA drives
  local line_offset=0
  local sata_found=false
  for drive in /dev/sd?; do
    if [ -e "$drive" ]; then
      local temperature=$(get_drive_temperature "$drive")
      local drive_name=$(get_drive_name "$drive")
      local full_line
      if [[ $temperature != '' ]]; then
        local colored_temp=$(colorize_temperature "$temperature°C" "drive")
        full_line="SATA $drive ($drive_name): ${colored_temp}"
      else
        full_line="SATA $drive ($drive_name): N/A"
      fi

      # Only update if value changed
      if [[ "${PREV_DRIVE_TEMPS[$drive]}" != "$full_line" ]]; then
        tput cup $((current_row + line_offset)) 4
        printf "%-$((term_cols - 8))s" "$full_line"
        PREV_DRIVE_TEMPS[$drive]="$full_line"
      fi
      sata_found=true
      ((line_offset++))
    fi
  done

  # NVMe drives
  local nvme_found=false
  for drive in /dev/nvme?n?; do
    if [ -e "$drive" ]; then
      local temperature=$(get_drive_temperature "$drive")
      local drive_name=$(get_drive_name "$drive")
      local full_line
      if [[ $temperature != '' ]]; then
        local colored_temp=$(colorize_temperature "$temperature°C" "drive")
        full_line="NVMe $drive ($drive_name): ${colored_temp}"
      else
        full_line="NVMe $drive ($drive_name): N/A"
      fi

      # Only update if value changed
      if [[ "${PREV_DRIVE_TEMPS[$drive]}" != "$full_line" ]]; then
        tput cup $((current_row + line_offset)) 4
        printf "%-$((term_cols - 8))s" "$full_line"
        PREV_DRIVE_TEMPS[$drive]="$full_line"
      fi
      nvme_found=true
      ((line_offset++))
    fi
  done

  if [[ $sata_found == false && $nvme_found == false ]]; then
    local no_drives_msg="No storage drives found"
    if [[ "${PREV_DRIVE_TEMPS[no_drives]}" != "$no_drives_msg" ]]; then
      tput cup $((current_row)) 4
      printf "%-$((term_cols - 8))s" "$no_drives_msg"
      PREV_DRIVE_TEMPS[no_drives]="$no_drives_msg"
    fi
  fi
}
