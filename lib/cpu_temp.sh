#!/bin/bash

# CPU temperature detection functions

# Function to retrieve all CPU core temperatures
get_all_core_temperatures() {
  local output=""
  local found_temps=false

  # Try different methods to get CPU temperature
  # Method 1: lm-sensors (if available) - get all cores
  if command -v sensors >/dev/null 2>&1; then
    local sensor_output=$(sensors 2>/dev/null | grep 'Core [0-9]:')
    if [[ $sensor_output != '' ]]; then
      while IFS= read -r line; do
        local core_num=$(echo "$line" | awk '{print $1 $2}' | sed 's/://g')
        local temp=$(echo "$line" | awk '{print $3}')
        output+="CPU $core_num temperature: $temp\n"
        found_temps=true
      done <<< "$sensor_output"
    fi
  fi

  # Method 2: Try thermal zone files (Linux) - check multiple zones
  if [[ $found_temps == false ]]; then
    for zone in /sys/class/thermal/thermal_zone*/temp; do
      if [[ -f "$zone" ]]; then
        local zone_num=$(echo "$zone" | grep -o 'thermal_zone[0-9]*' | grep -o '[0-9]*')
        local temp_millidegrees=$(cat "$zone" 2>/dev/null)
        if [[ $temp_millidegrees != '' ]] && [[ $temp_millidegrees -gt 10000 ]]; then
          local temp_celsius=$((temp_millidegrees / 1000))
          output+="Thermal Zone $zone_num temperature: ${temp_celsius}°C\n"
          found_temps=true
        fi
      fi
    done
  fi

  # Method 3: Try hwmon files (Linux) - look for CPU cores
  if [[ $found_temps == false ]]; then
    for hwmon_dir in /sys/class/hwmon/hwmon*; do
      if [[ -d "$hwmon_dir" ]]; then
        local name_file="$hwmon_dir/name"
        if [[ -f "$name_file" ]]; then
          local hwmon_name=$(cat "$name_file" 2>/dev/null)
          # Look for CPU-related hwmon devices
          if [[ $hwmon_name == *"coretemp"* ]] || [[ $hwmon_name == *"k10temp"* ]] || [[ $hwmon_name == *"cpu"* ]]; then
            for temp_file in "$hwmon_dir"/temp*_input; do
              if [[ -f "$temp_file" ]]; then
                local temp_millidegrees=$(cat "$temp_file" 2>/dev/null)
                if [[ $temp_millidegrees != '' ]] && [[ $temp_millidegrees -gt 10000 ]]; then
                  local temp_celsius=$((temp_millidegrees / 1000))
                  local temp_label=$(basename "$temp_file" | sed 's/_input//')
                  output+="CPU $temp_label temperature: ${temp_celsius}°C\n"
                  found_temps=true
                fi
              fi
            done
          fi
        fi
      fi
    done
  fi

  # Method 4: macOS temperature (if on macOS)
  if [[ $found_temps == false ]] && [[ "$(uname)" == "Darwin" ]]; then
    if command -v powermetrics >/dev/null 2>&1; then
      local mac_temp=$(sudo powermetrics --samplers smc -n 1 -i 1 2>/dev/null | grep "CPU die temperature" | awk '{print $4$5}')
      if [[ $mac_temp != '' ]]; then
        output+="CPU die temperature: $mac_temp\n"
        found_temps=true
      fi
    fi
  fi

  # Return the output (remove trailing newline)
  echo -e "${output%\\n}"
}
