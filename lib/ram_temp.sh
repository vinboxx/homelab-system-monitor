#!/bin/bash

# RAM temperature detection functions

# Function to get RAM temperature
get_ram_temperature() {
  local output=""
  local found_temps=false

  # Method 1: Try lm-sensors for memory temperature sensors
  if command -v sensors >/dev/null 2>&1; then
    # Look for memory-related temperature sensors
    local sensor_output=$(sensors 2>/dev/null | grep -i -E '(memory|dimm|ram|ddr)')
    if [[ $sensor_output != '' ]]; then
      while IFS= read -r line; do
        if [[ $line == *"°C"* ]]; then
          local temp=$(echo "$line" | awk '{for(i=1;i<=NF;i++) if($i ~ /°C/) print $i}' | head -1)
          local label=$(echo "$line" | awk -F':' '{print $1}' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
          output+="$label temperature: $temp\n"
          found_temps=true
        fi
      done <<< "$sensor_output"
    fi

    # Also check for memory controller temperatures (broader search)
    if [[ $found_temps == false ]]; then
      local mc_output=$(sensors 2>/dev/null | grep -i -E '(temp[0-9]*|Package)')
      if [[ $mc_output != '' ]]; then
        # Look through all sensors output for potential memory controller temps
        local full_output=$(sensors 2>/dev/null)
        local current_chip=""
        while IFS= read -r line; do
          if [[ $line == *":"* ]] && [[ $line != *"°C"* ]] && [[ $line != *"+"* ]] && [[ $line != *"RPM"* ]]; then
            current_chip="$line"
          elif [[ $line == *"°C"* ]] && [[ $current_chip == *"memory"* || $current_chip == *"mem"* ]]; then
            local temp=$(echo "$line" | awk '{for(i=1;i<=NF;i++) if($i ~ /°C/) print $i}' | head -1)
            local label=$(echo "$line" | awk -F':' '{print $1}' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
            output+="Memory Controller $label temperature: $temp\n"
            found_temps=true
          fi
        done <<< "$full_output"
      fi
    fi
  fi

  # Method 2: Check hwmon for memory controllers
  if [[ $found_temps == false ]]; then
    for hwmon_dir in /sys/class/hwmon/hwmon*; do
      if [[ -d "$hwmon_dir" ]]; then
        local name_file="$hwmon_dir/name"
        if [[ -f "$name_file" ]]; then
          local hwmon_name=$(cat "$name_file" 2>/dev/null)
          # Look for memory controller related hwmon devices
          if [[ $hwmon_name == *"mem"* ]] || [[ $hwmon_name == *"dimm"* ]] || [[ $hwmon_name == *"ddr"* ]] || [[ $hwmon_name == *"sodimm"* ]]; then
            for temp_file in "$hwmon_dir"/temp*_input; do
              if [[ -f "$temp_file" ]]; then
                local temp_millidegrees=$(cat "$temp_file" 2>/dev/null)
                if [[ $temp_millidegrees != '' ]] && [[ $temp_millidegrees -gt 10000 ]]; then
                  local temp_celsius=$((temp_millidegrees / 1000))
                  local temp_label=$(basename "$temp_file" | sed 's/_input//')
                  output+="Memory $temp_label temperature: ${temp_celsius}°C\n"
                  found_temps=true
                fi
              fi
            done
          fi
        fi
      fi
    done
  fi

  # Method 3: Check for specific memory thermal zones
  if [[ $found_temps == false ]]; then
    for zone in /sys/class/thermal/thermal_zone*/temp; do
      if [[ -f "$zone" ]]; then
        local zone_type_file=$(dirname "$zone")/type
        if [[ -f "$zone_type_file" ]]; then
          local zone_type=$(cat "$zone_type_file" 2>/dev/null)
          # Check if this thermal zone is memory-related
          if [[ $zone_type == *"mem"* ]] || [[ $zone_type == *"dimm"* ]] || [[ $zone_type == *"ddr"* ]] || [[ $zone_type == *"ram"* ]]; then
            local zone_num=$(echo "$zone" | grep -o 'thermal_zone[0-9]*' | grep -o '[0-9]*')
            local temp_millidegrees=$(cat "$zone" 2>/dev/null)
            if [[ $temp_millidegrees != '' ]] && [[ $temp_millidegrees -gt 10000 ]]; then
              local temp_celsius=$((temp_millidegrees / 1000))
              output+="Memory Thermal Zone $zone_num ($zone_type) temperature: ${temp_celsius}°C\n"
              found_temps=true
            fi
          fi
        fi
      fi
    done
  fi

  # Method 4: Try to read from i2c sensors if available (for server-grade hardware)
  if [[ $found_temps == false ]] && command -v i2cdetect >/dev/null 2>&1; then
    # This is a more advanced method that might work on some server hardware
    # Look for SPD temperature sensors on memory modules
    for bus in {0..9}; do
      if i2cdetect -y $bus 2>/dev/null | grep -q "18\|19\|1a\|1b"; then
        # These are common addresses for memory SPD temperature sensors
        for addr in 0x18 0x19 0x1a 0x1b; do
          if command -v i2cget >/dev/null 2>&1; then
            local temp_raw=$(i2cget -y $bus $addr 0x05 2>/dev/null)
            if [[ $temp_raw != '' ]] && [[ $temp_raw != "0x00" ]] && [[ $temp_raw != "0xff" ]]; then
              # Convert hex to decimal
              local temp_celsius=$((temp_raw))
              if [[ $temp_celsius -gt 0 ]] && [[ $temp_celsius -lt 100 ]]; then
                output+="Memory SPD Sensor (bus $bus, addr $addr) temperature: ${temp_celsius}°C\n"
                found_temps=true
              fi
            fi
          fi
        done
      fi
    done
  fi

  # Method 5: Check for IPMI sensors (if available)
  if [[ $found_temps == false ]] && command -v ipmitool >/dev/null 2>&1; then
    local ipmi_output=$(ipmitool sdr list 2>/dev/null | grep -i -E '(memory|dimm|ram|ddr)')
    if [[ $ipmi_output != '' ]]; then
      while IFS= read -r line; do
        if [[ $line == *"degrees"* ]] || [[ $line == *"°C"* ]]; then
          local sensor_name=$(echo "$line" | awk -F'|' '{print $1}' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
          local temp=$(echo "$line" | grep -o '[0-9]\+\s*degrees\|[0-9]\+°C' | head -1)
          if [[ $temp != '' ]]; then
            output+="$sensor_name temperature: $temp\n"
            found_temps=true
          fi
        fi
      done <<< "$ipmi_output"
    fi
  fi

  # Method 6: Check DMI/SMBIOS for memory information (some systems expose temp here)
  if [[ $found_temps == false ]] && command -v dmidecode >/dev/null 2>&1; then
    local dmi_output=$(sudo dmidecode -t memory 2>/dev/null | grep -i temperature)
    if [[ $dmi_output != '' ]]; then
      while IFS= read -r line; do
        if [[ $line == *"°C"* ]] || [[ $line == *"Temperature"* ]]; then
          local temp=$(echo "$line" | grep -o '[0-9]\+°C\|[0-9]\+ C' | head -1)
          if [[ $temp != '' ]]; then
            output+="DMI Memory temperature: $temp\n"
            found_temps=true
          fi
        fi
      done <<< "$dmi_output"
    fi
  fi

  # Method 7: Check for Intel memory controller thermal sensors
  if [[ $found_temps == false ]]; then
    for zone in /sys/class/thermal/thermal_zone*/temp; do
      if [[ -f "$zone" ]]; then
        local zone_type_file=$(dirname "$zone")/type
        if [[ -f "$zone_type_file" ]]; then
          local zone_type=$(cat "$zone_type_file" 2>/dev/null)
          # Check for Intel memory controller thermal zones
          if [[ $zone_type == *"x86_pkg_temp"* ]] || [[ $zone_type == *"INT3403"* ]] || [[ $zone_type == *"pch"* ]]; then
            local zone_num=$(echo "$zone" | grep -o 'thermal_zone[0-9]*' | grep -o '[0-9]*')
            local temp_millidegrees=$(cat "$zone" 2>/dev/null)
            if [[ $temp_millidegrees != '' ]] && [[ $temp_millidegrees -gt 10000 ]] && [[ $temp_millidegrees -lt 100000 ]]; then
              local temp_celsius=$((temp_millidegrees / 1000))
              # Only report if temperature seems reasonable for memory controller
              if [[ $temp_celsius -gt 20 ]] && [[ $temp_celsius -lt 80 ]]; then
                output+="Memory Controller Thermal Zone $zone_num ($zone_type) temperature: ${temp_celsius}°C\n"
                found_temps=true
              fi
            fi
          fi
        fi
      fi
    done
  fi

  # Return the output (remove trailing newline)
  if [[ $found_temps == true ]]; then
    echo -e "${output%\\n}"
  else
    echo ""
  fi
}
