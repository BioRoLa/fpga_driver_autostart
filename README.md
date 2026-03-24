# FPGA Auto-Start Setup - NI sbRIO-9629

A robust service management system for `grpccore` and `fpga_driver` on NI Linux Real-Time. Optimized for high reliability and Flash memory longevity (zero-log design).

## Modified Files

| File | Location | Purpose |
|------|----------|---------|
| `rc.local` | `/etc/rc.local` | [cite_start]Automates startup during the boot sequence[cite: 2]. |
| `start_fpga.sh` | `/home/admin/` | [cite_start]Handles environment variables and binary execution[cite: 1]. |
| `fpga_control.sh` | `/home/admin/` | [cite_start]Provides CLI for status, start, stop, and restart[cite: 3]. |

## Key Features

- [cite_start]**No Logging**: Redirects all output to `/dev/null` to prevent unnecessary Flash memory wear[cite: 3].
- [cite_start]**Dependency Fix**: Includes both `lib` and `lib64` paths to support `libyaml-cpp` and other shared libraries[cite: 1].
- [cite_start]**Race Condition Prevention**: Implements locking and staggered startup (5s delay between core and driver)[cite: 1, 3].
- **Unix-Ready**: Scripts are designed to be immune to CRLF (Windows) line-ending issues.

## Usage

### Quick Commands
After setup, you can use the `fpga` command globally:

```bash
fpga status   # Check if services are running
fpga start    # Manually start services (includes retries)
fpga stop     # Kill all FPGA-related processes
fpga restart  # Clean stop followed by a fresh start
```

## Deployment Instructions

### 1. File Preparation
Ensure all scripts use **Unix (LF)** line endings. If you edited them on Windows, run:
```bash
sed -i 's/\r$//' /home/admin/*.sh
sed -i 's/\r$//' /etc/rc.local
```

### 2. Permissions & Links
```bash
chmod +x /home/admin/start_fpga.sh /home/admin/fpga_control.sh /etc/rc.local
ln -sf /home/admin/fpga_control.sh /usr/local/bin/fpga
```

### 3. Verify Boot Setup
[cite_start]Ensure `/etc/rc.local` is executable so the init system can trigger it[cite: 2]:
```bash
ls -la /etc/rc.local  # Should be executable (-rwxr-xr-x)
```

## What Happens on Boot
1. [cite_start]The system waits **30 seconds** for networking and FPGA managers to initialize[cite: 2].
2. [cite_start]`fpga_control.sh` attempts to start services as the `admin` user[cite: 2, 3].
3. [cite_start]`grpccore` launches first, followed by a **5-second buffer**[cite: 1].
4. [cite_start]`fpga_driver` launches with an explicit `LD_LIBRARY_PATH` that includes `lib64`[cite: 1].

## Troubleshooting
If `fpga status` shows **STOPPED** after a manual start:
1. [cite_start]Verify the binary path in `start_fpga.sh`[cite: 1].
2. [cite_start]Ensure no other instance is running: `fpga stop`[cite: 3].
3. Manually check for missing dependencies: 
   ```bash
   export LD_LIBRARY_PATH=/home/admin/.local/lib:/home/admin/.local/lib64
   /home/admin/corgi_ws/fpga_driver/build/fpga_driver
   ```
