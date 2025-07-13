#!/bin/bash

# Drive temperature and information detection functions

# Function to get drive model/name
get_drive_name() {
  local drive="$1"
  local info="$(sudo smartctl -i "$drive" 2>/dev/null)"
  local drive_name=""

  # Try different patterns to get drive name
  # Method 1: Device Model (most common)
  drive_name=$(echo "$info" | grep -i 'Device Model:' | awk -F': ' '{print $2}' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')

  # Method 2: Model Number (for some drives)
  if [[ $drive_name == '' ]]; then
    drive_name=$(echo "$info" | grep -i 'Model Number:' | awk -F': ' '{print $2}' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
  fi

  # Method 3: Product (for some drives)
  if [[ $drive_name == '' ]]; then
    drive_name=$(echo "$info" | grep -i 'Product:' | awk -F': ' '{print $2}' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
  fi

  # Method 4: Model Family (fallback)
  if [[ $drive_name == '' ]]; then
    drive_name=$(echo "$info" | grep -i 'Model Family:' | awk -F': ' '{print $2}' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
  fi

  # If still no name found, try to get it from a different pattern
  if [[ $drive_name == '' ]]; then
    drive_name=$(echo "$info" | grep -E '^(Device|Model|Product)' | head -1 | awk -F': ' '{print $2}' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
  fi

  # Return the drive name or "Unknown" if not found
  if [[ $drive_name != '' ]]; then
    echo "$drive_name"
  else
    echo "Unknown Drive"
  fi
}

# Function to check if a drive exists and retrieve its temperature
get_drive_temperature() {
  local drive="$1"
  local info="$(sudo smartctl -a $drive)"
  local temp=""

  # Try different temperature patterns for various drive types
  # Traditional SATA drives
  temp=$(echo "$info" | grep '194 Temp' | awk '{print $10}')
  if [[ $temp == '' ]]; then
    temp=$(echo "$info" | grep '190 Airflow' | awk '{print $10}')
  fi

  # NVMe drives - common patterns
  if [[ $temp == '' ]]; then
    temp=$(echo "$info" | grep 'Temperature:' | head -1 | awk '{print $2}' | sed 's/°C//')
  fi
  if [[ $temp == '' ]]; then
    temp=$(echo "$info" | grep 'Temperature Sensor 1:' | awk '{print $4}')
  fi
  if [[ $temp == '' ]]; then
    temp=$(echo "$info" | grep 'Current Drive Temperature:' | awk '{print $4}')
  fi

  # Additional NVMe patterns
  if [[ $temp == '' ]]; then
    temp=$(echo "$info" | grep 'Composite Temperature:' | awk '{print $3}')
  fi
  if [[ $temp == '' ]]; then
    temp=$(echo "$info" | grep -i 'temperature' | head -1 | grep -o '[0-9]\+' | head -1)
  fi

  echo "$temp"
}
