# DV Tools

Small set of shell utilities for working with MiniDV tapes and `.dv` files on modern macOS (Apple Silicon).

### Requirements
- macOS with `ffmpeg` installed (via Homebrew)
- Canon XL2 (or other DV cam) connected via FireWire → Thunderbolt adapters
- Tested on MacBook Pro 2016 M1

### Scripts

- **`capture_dv.sh`**  
  Automates DV capture from the camcorder.  
  Usage:  
  ```bash
  ./capture_dv.sh projectname
