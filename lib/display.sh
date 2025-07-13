#!/bin/bash

# Display and output formatting functions

# Source required libraries
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
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

# Function to create a temperature graph bar
create_temp_graph() {
  local temp_str="$1"
  local temp_type="${2:-cpu}"
  local max_width="${3:-40}"

  # Extract numeric value from temperature string
  local temp_num=$(echo "$temp_str" | grep -o '[0-9]\+' | head -1)

  # If no numeric value found, return N/A
  if [[ $temp_num == '' ]]; then
    echo "N/A"
    return
  fi

  # Define max temperature for scaling based on component type
  local max_temp
  if [[ $temp_type == "drive" ]]; then
    max_temp=70
  elif [[ $temp_type == "ram" ]]; then
    max_temp=80
  else
    max_temp=100  # CPU
  fi

  # Calculate bar width (percentage of max_width)
  local bar_width=$(( (temp_num * max_width) / max_temp ))
  if [[ $bar_width -gt $max_width ]]; then
    bar_width=$max_width
  fi

  # Define colors directly for better control
  local RESET='\033[0m'
  local GREEN='\033[32m'     # Cool - good temps
  local YELLOW='\033[33m'    # Warm - acceptable temps
  local ORANGE='\033[38;5;208m'  # Hot - concerning temps
  local RED='\033[31m'       # Very hot - dangerous temps
  local BOLD_RED='\033[1;31m'    # Critical - immediate attention

  # Set temperature thresholds based on component type
  local cool_max warm_max hot_max critical_max
  if [[ $temp_type == "drive" ]]; then
    cool_max=35
    warm_max=45
    hot_max=55
    critical_max=65
  elif [[ $temp_type == "ram" ]]; then
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

  # Choose color and character based on temperature
  local color
  local fill_char
  if [[ $temp_num -le $cool_max ]]; then
    color=$GREEN
    fill_char="█"  # Solid block for cool temps
  elif [[ $temp_num -le $warm_max ]]; then
    color=$YELLOW
    fill_char="█"  # Solid block for warm temps
  elif [[ $temp_num -le $hot_max ]]; then
    color=$ORANGE
    fill_char="▓"  # Dense pattern for hot temps
  elif [[ $temp_num -le $critical_max ]]; then
    color=$RED
    fill_char="▒"  # Medium pattern for very hot temps
  else
    color=$BOLD_RED
    fill_char="░"  # Light pattern for critical temps (more alarming)
  fi

  # Create the colored bar
  local filled_bar=""
  local empty_bar=""
  local empty_char="─"

  # Build filled portion with color
  for ((i=0; i<bar_width; i++)); do
    filled_bar+="$fill_char"
  done

  # Build empty portion
  for ((i=bar_width; i<max_width; i++)); do
    empty_bar+="$empty_char"
  done

  # Apply color to filled portion
  local colored_filled="${color}${filled_bar}${RESET}"

  # Create percentage indicator with color
  local percentage=$(( (temp_num * 100) / max_temp ))
  if [[ $percentage -gt 100 ]]; then
    percentage=100
  fi

  # Color the temperature string and percentage based on level
  local colored_temp="${color}${temp_str}${RESET}"
  local colored_percentage="${color}(${percentage}%)${RESET}"

  # Return the formatted graph with colored components
  echo "[${colored_filled}${empty_bar}] ${colored_temp} ${colored_percentage}"
}

# Function to update only temperature values that have changed
update_temperature_values() {
  local term_cols=$(tput cols)

  # Update CPU temperatures with graphs
  local current_row=5
  local core_temperatures=$(get_all_core_temperatures)

  if [[ $core_temperatures != '' ]]; then
    local line_num=0
    while IFS= read -r line; do
      if [[ $line == *"temperature:"* ]]; then
        local temp_part=$(echo "$line" | awk -F'temperature: ' '{print $2}')
        local label_part=$(echo "$line" | awk -F'temperature: ' '{print $1}')

        # Calculate available width for the graph (leave space for label, brackets, temp and percentage)
        local label_width=${#label_part}
        local available_width=$((term_cols - label_width - 35))  # 35 chars for margins, brackets, temp and percentage
        if [[ $available_width -lt 15 ]]; then
          available_width=15
        fi

        # Create temperature graph
        local temp_graph=$(create_temp_graph "$temp_part" "cpu" "$available_width")
        local full_line="${label_part}${temp_graph}"

        # Only update if value changed
        if [[ "${PREV_CPU_TEMPS[$line_num]}" != "$full_line" ]]; then
          tput cup $((current_row + line_num)) 4
          # Clear the line first
          printf "%-$((term_cols - 8))s" ""
          tput cup $((current_row + line_num)) 4
          # Use echo -e to interpret color codes
          echo -e "$full_line"
          PREV_CPU_TEMPS[$line_num]="$full_line"
        fi
        ((line_num++))
      fi
    done <<< "$core_temperatures"
  else
    local na_msg="CPU temperature: N/A (sensors not available)"
    if [[ "${PREV_CPU_TEMPS[0]}" != "$na_msg" ]]; then
      tput cup $((current_row)) 4
      # Clear the line first
      printf "%-$((term_cols - 8))s" ""
      tput cup $((current_row)) 4
      echo "$na_msg"
      PREV_CPU_TEMPS[0]="$na_msg"
    fi
  fi

  # Update RAM temperatures with graphs
  current_row=14

  local ram_temperatures=$(get_ram_temperature)
  if [[ $ram_temperatures != '' ]]; then
    local line_num=0
    while IFS= read -r line; do
      if [[ $line == *"temperature:"* ]]; then
        local temp_part=$(echo "$line" | awk -F'temperature: ' '{print $2}')
        local label_part=$(echo "$line" | awk -F'temperature: ' '{print $1}')

        # Calculate available width for the graph (leave space for label, brackets, temp and percentage)
        local label_width=${#label_part}
        local available_width=$((term_cols - label_width - 35))  # 35 chars for margins, brackets, temp and percentage
        if [[ $available_width -lt 15 ]]; then
          available_width=15
        fi

        # Create temperature graph
        local temp_graph=$(create_temp_graph "$temp_part" "ram" "$available_width")
        local full_line="${label_part}${temp_graph}"

        # Only update if value changed
        if [[ "${PREV_RAM_TEMPS[$line_num]}" != "$full_line" ]]; then
          tput cup $((current_row + line_num)) 4
          # Clear the line first
          printf "%-$((term_cols - 8))s" ""
          tput cup $((current_row + line_num)) 4
          # Use echo -e to interpret color codes
          echo -e "$full_line"
          PREV_RAM_TEMPS[$line_num]="$full_line"
        fi
        ((line_num++))
      fi
    done <<< "$ram_temperatures"
  else
    local na_msg="RAM temperature: N/A (sensors not available)"
    if [[ "${PREV_RAM_TEMPS[0]}" != "$na_msg" ]]; then
      tput cup $((current_row)) 4
      # Clear the line first
      printf "%-$((term_cols - 8))s" ""
      tput cup $((current_row)) 4
      echo "$na_msg"
      PREV_RAM_TEMPS[0]="$na_msg"
    fi
  fi

  # Update Storage temperatures
  current_row=21

  # SATA drives with graphs
  local line_offset=0
  local sata_found=false
  for drive in /dev/sd?; do
    if [ -e "$drive" ]; then
      local temperature=$(get_drive_temperature "$drive")
      local drive_name=$(get_drive_name "$drive")
      local full_line
      if [[ $temperature != '' ]]; then
        local temp_str="${temperature}°C"
        local label="SATA $drive ($drive_name): "

        # Calculate available width for the graph
        local label_width=${#label}
        local available_width=$((term_cols - label_width - 35))  # 35 chars for margins, brackets, temp and percentage
        if [[ $available_width -lt 15 ]]; then
          available_width=15
        fi

        # Create temperature graph
        local temp_graph=$(create_temp_graph "$temp_str" "drive" "$available_width")
        full_line="${label}${temp_graph}"
      else
        full_line="SATA $drive ($drive_name): N/A"
      fi

      # Only update if value changed
      if [[ "${PREV_DRIVE_TEMPS[$drive]}" != "$full_line" ]]; then
        tput cup $((current_row + line_offset)) 4
        # Clear the line first
        printf "%-$((term_cols - 8))s" ""
        tput cup $((current_row + line_offset)) 4
        # Use echo -e to interpret color codes
        echo -e "$full_line"
        PREV_DRIVE_TEMPS[$drive]="$full_line"
      fi
      sata_found=true
      ((line_offset++))
    fi
  done

  # NVMe drives with graphs
  local nvme_found=false
  for drive in /dev/nvme?n?; do
    if [ -e "$drive" ]; then
      local temperature=$(get_drive_temperature "$drive")
      local drive_name=$(get_drive_name "$drive")
      local full_line
      if [[ $temperature != '' ]]; then
        local temp_str="${temperature}°C"
        local label="NVMe $drive ($drive_name): "

        # Calculate available width for the graph
        local label_width=${#label}
        local available_width=$((term_cols - label_width - 35))  # 35 chars for margins, brackets, temp and percentage
        if [[ $available_width -lt 15 ]]; then
          available_width=15
        fi

        # Create temperature graph
        local temp_graph=$(create_temp_graph "$temp_str" "drive" "$available_width")
        full_line="${label}${temp_graph}"
      else
        full_line="NVMe $drive ($drive_name): N/A"
      fi

      # Only update if value changed
      if [[ "${PREV_DRIVE_TEMPS[$drive]}" != "$full_line" ]]; then
        tput cup $((current_row + line_offset)) 4
        # Clear the line first
        printf "%-$((term_cols - 8))s" ""
        tput cup $((current_row + line_offset)) 4
        # Use echo -e to interpret color codes
        echo -e "$full_line"
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
      # Clear the line first
      printf "%-$((term_cols - 8))s" ""
      tput cup $((current_row)) 4
      echo "$no_drives_msg"
      PREV_DRIVE_TEMPS[no_drives]="$no_drives_msg"
    fi
  fi
}
