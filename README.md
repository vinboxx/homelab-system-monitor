# System Temperature Monitor

A modular system temperature monitoring tool for CPU, RAM, and drive temperatures with colored graph visualization and real-time updates.

## File Structure

```
system-monitor/
├── system-monitor.sh          # Main script
├── lib/                        # Library modules
│   ├── cpu_temp.sh             # CPU temperature detection
│   ├── ram_temp.sh             # RAM temperature detection
│   ├── drive_temp.sh           # Drive temperature detection
│   └── display.sh              # Output formatting, graphs, and display
└── README.md                   # This file
```

## Module Description

### `system-monitor.sh` (Main Script)
- Entry point for the application
- Handles sudo authentication upfront
- Controls the continuous monitoring with ncurses-like interface
- Real-time temperature graph updates

### `lib/display.sh`
- Advanced terminal interface with boxed layout
- Colored temperature graph bars with visual indicators
- Built-in color management and temperature thresholds
- Real-time updates with minimal screen redraw
- Sources all temperature detection modules
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

## Features

### Visual Graph Interface
- **Real-time Temperature Graphs**: Horizontal bar graphs for all temperature readings
- **Color-coded Visualization**: Different colors and patterns based on temperature levels
- **Component-specific Scaling**: Each component type has appropriate maximum temperatures
- **Live Updates**: Only changed values are redrawn for smooth performance
- **Boxed Layout**: Clean terminal interface with section boxes and titles

### Graph Visualization
- **Progress Bars**: `[████████████───────]` showing temperature as percentage of maximum
- **Color Coding**: Green (cool) → Yellow (warm) → Orange (hot) → Red (critical)
- **Visual Patterns**: Different fill characters for different temperature ranges
- **Percentage Display**: Shows both actual temperature and percentage of maximum
- **Responsive Width**: Graphs adapt to terminal size automatically

## Usage

```bash
# Run the temperature monitor (requires sudo for drive/memory access)
./system-monitor.sh
```

The script will:
1. Request sudo authentication upfront
2. Display a real-time interface with temperature graphs
3. Update temperatures every 5 seconds
4. Show color-coded graphs for CPU, RAM, and storage temperatures
5. Exit cleanly with Ctrl+C

## Sample Output

```
                        System Temperature Monitor
════════════════════════════════════════════════════════════════════════════════
┌────────────────────────────────────────────────────────────────────────────┐
│ CPU Temperatures                                                           │
│                                                                            │
│    CPU Core0 [████████████████████████───────────────────] +57.0°C (57%)  │
│    CPU Core1 [████████████████████████───────────────────] +57.0°C (57%)  │
│    CPU Core2 [████████████████████████───────────────────] +57.0°C (57%)  │
│    CPU Core3 [████████████████████████───────────────────] +57.0°C (57%)  │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
┌────────────────────────────────────────────────────────────────────────────┐
│ RAM Temperatures                                                           │
│                                                                            │
│    Memory Controller [▓▓▓▓▓▓▓▓▓▓─────] 58°C (72%)                         │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
┌────────────────────────────────────────────────────────────────────────────┐
│ Storage Temperatures                                                       │
│                                                                            │
│    SATA /dev/sda: [▒▒▒▒▒▒▒▒▒▒▒▒───] 57°C (81%)                           │
│    SATA /dev/sdb: [▓▓▓▓▓▓▓▓▓▓─────] 47°C (67%)                           │
│    NVMe /dev/nvme0n1: [▒▒▒▒▒▒▒▒▒▒▒▒▒──] 62°C (88%)                       │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
Updated: 2025-07-13 22:14:41 | Press Ctrl+C to exit
```

### Graph Legend
- `█` Solid blocks: Safe/warm temperatures (green/yellow)
- `▓` Dense pattern: Hot temperatures (orange)
- `▒` Medium pattern: Very hot temperatures (red)
- `░` Light pattern: Critical temperatures (bold red)
- `─` Empty sections: Remaining temperature capacity

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

1. **Real-time Visualization**: Live temperature graphs with color-coded visual feedback
2. **Maintainability**: Each module has a single responsibility
3. **Reusability**: Functions can be used independently
4. **Performance**: Efficient updates with minimal screen redraw
5. **User Experience**: Clean terminal interface with boxed layout
6. **Extensibility**: New temperature sources can be added easily
7. **Cross-platform Support**: Different detection methods for various hardware
8. **Enterprise Ready**: Supports enterprise hardware features (IPMI, I2C sensors)
9. **Security**: Upfront sudo authentication prevents mid-session prompts
