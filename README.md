# System Temperature Monitor

A modular system temperature monitoring tool for CPU, RAM, and drive temperatures with colored output.

## File Structure

```
system-monitor/
├── system-monitor.sh          # Main script
├── lib/                        # Library modules
│   ├── colors.sh               # Color formatting functions
│   ├── cpu_temp.sh             # CPU temperature detection
│   ├── ram_temp.sh             # RAM temperature detection
│   ├── drive_temp.sh           # Drive temperature detection
│   └── display.sh              # Output formatting and display
└── README.md                   # This file
```

## Module Description

### `system-monitor.sh` (Main Script)
- Entry point for the application
- Handles command-line arguments (`--refresh` / `-r`)
- Controls the monitoring loop and signal handling
- Sources all required library modules

### `lib/colors.sh`
- Color formatting utilities
- Temperature-based color coding (green, yellow, orange, red)
- Separate thresholds for CPU, RAM, and drive temperatures

### `lib/cpu_temp.sh`
- CPU temperature detection functions
- Supports multiple methods:
  - lm-sensors (preferred)
  - Linux thermal zones
  - hwmon interface
  - macOS powermetrics

### `lib/ram_temp.sh`
- RAM and memory controller temperature detection functions
- Supports multiple detection methods:
  - lm-sensors memory temperature sensors
  - Memory controller thermal sensors
  - hwmon memory controller interfaces
  - Memory-specific thermal zones
  - I2C SPD temperature sensors (server hardware)
  - IPMI memory sensors (enterprise hardware)
  - DMI/SMBIOS memory temperature data
  - Intel x86 package temperature (memory controller)

### `lib/drive_temp.sh`
- Drive temperature and information functions
- Works with both SATA and NVMe drives
- Uses smartctl for drive information and temperature
- Supports various drive model naming patterns

### `lib/display.sh`
- Output formatting and display functions
- Single-run mode display
- Continuous monitoring display (buffered output)
- Sources all other library modules

## Usage

```bash
# Single temperature check
./system-monitor.sh

# Continuous monitoring (refreshes every 3 seconds)
./system-monitor.sh --refresh
./system-monitor.sh -r
```

## Sample Output

```
=== CPU Temperature(s) ===
CPU Core0 temperature: +51.0°C
CPU Core1 temperature: +51.0°C
CPU Core2 temperature: +51.0°C
CPU Core3 temperature: +51.0°C

=== RAM Temperature(s) ===
Memory Controller Thermal Zone 1 (x86_pkg_temp) temperature: 52°C

=== SATA Drive Temperature(s) ===
/dev/sda (HGST HUS724040ALA640) temperature: 57°C
/dev/sdb (WDC WD20EZRZ-00Z5HB0) temperature: 48°C

=== NVMe Drive Temperature(s) ===
/dev/nvme0n1 (KBG40ZNS256G NVMe KIOXIA 256GB) temperature: 62°C
---
Updated: 2025-07-13 19:27:51
Press Ctrl+C to stop monitoring
```

*Note: Temperatures are color-coded based on the thresholds above.*

## Dependencies

- `smartctl` (smartmontools package) - for drive temperature monitoring
- `sensors` (lm-sensors package) - for CPU and memory temperature monitoring (optional)
- `dmidecode` - for DMI/SMBIOS memory information (optional)
- `i2c-tools` - for I2C memory sensor detection (optional, server hardware)
- `ipmitool` - for IPMI memory sensors (optional, enterprise hardware)
- `sudo` access - required for drive temperature readings and some memory sensors

## Temperature Thresholds

### CPU Temperatures
- **Green** (Cool): ≤ 50°C
- **Yellow** (Warm): 51-70°C
- **Orange** (Hot): 71-85°C
- **Red** (Very Hot): 86-95°C
- **Bold Red** (Critical): > 95°C

### RAM/Memory Controller Temperatures
- **Green** (Cool): ≤ 40°C
- **Yellow** (Warm): 41-50°C
- **Orange** (Hot): 51-60°C
- **Red** (Very Hot): 61-70°C
- **Bold Red** (Critical): > 70°C

### Drive Temperatures
- **Green** (Cool): ≤ 35°C
- **Yellow** (Warm): 36-45°C
- **Orange** (Hot): 46-55°C
- **Red** (Very Hot): 56-65°C
- **Bold Red** (Critical): > 65°C

## RAM Temperature Monitoring

The system includes comprehensive RAM temperature detection that works on various hardware configurations:

### Consumer Systems
- **Intel x86 Package Temperature**: Most common method on Intel systems, provides memory controller temperature
- **Thermal Zones**: System-specific memory thermal zones when available

### Server/Enterprise Systems
- **IPMI Sensors**: Memory module temperature sensors via IPMI
- **I2C SPD Sensors**: Direct memory module temperature reading via I2C bus
- **DMI/SMBIOS**: Memory temperature data from system firmware

### Detection Priority
The system tries detection methods in order of reliability:
1. Direct memory temperature sensors (lm-sensors)
2. Memory controller temperatures
3. Hardware monitoring interfaces (hwmon)
4. Memory-specific thermal zones
5. I2C SPD temperature sensors
6. IPMI memory sensors
7. DMI/SMBIOS memory data
8. Intel package temperature (memory controller)

If no RAM temperature sensors are available, the system will display "N/A (sensors not available)".

## Benefits of Modular Structure

1. **Maintainability**: Each module has a single responsibility
2. **Reusability**: Functions can be used independently
3. **Testing**: Individual modules can be tested separately
4. **Extensibility**: New temperature sources can be added easily (like the new RAM monitoring)
5. **Readability**: Smaller, focused files are easier to understand
6. **Cross-platform Support**: Different detection methods for various hardware configurations
7. **Enterprise Ready**: Supports enterprise hardware features (IPMI, I2C sensors)
