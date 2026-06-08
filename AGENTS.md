# AGENTS.md

## Project

Single-file Bash script for hot-switching a discrete GPU between host drivers and VFIO passthrough on Linux hybrid GPU laptops. Published as an AUR package.

## Commands

```bash
# Install locally
sudo make install

# Run (requires root)
sudo gpu-hotswitch-vfio on
sudo gpu-hotswitch-vfio off
sudo gpu-hotswitch-vfio status
sudo gpu-hotswitch-vfio hugepages-alloc
sudo gpu-hotswitch-vfio hugepages-free

# Syntax check
bash -n gpu-hotswitch-vfio

# Build package locally
makepkg -si
```

## Architecture

Single script: `gpu-hotswitch-vfio` (~880 lines of Bash).

Key sections:
- **Auto-detection** (`detect_dgpu`, `get_iommu_group_devices`, `get_current_driver`) — finds discrete GPU by PCI vendor ID, resolves IOMMU groups
- **Hugepage management** (`allocate_hugepages`, `release_hugepages`) — 2MB hugepage allocation with OOM safety; checks VM XML for `<hugepages/>` before allocating
- **Process management** (`safe_kill_nvidia_users`) — uses `fuser /dev/nvidia*` to find GPU holders, categorizes into systemd services (auto-stopped) and user processes (interactive confirmation), traces Electron/Chromium parent chains
- **Compositor integration** (`ensure_compositor_ignores_dgpu`) — patches niri config to set `render-drm-device` and `ignore-drm-device`
- **Passthrough lifecycle** (`passthrough_on`, `passthrough_off`) — full driver unbind/rebind, vfio-pci binding, service lifecycle management
- **Status** (`passthrough_status`) — shows GPU devices, drivers, VFIO bindings, hugepage state

## Key conventions

- Bash with `set -euo pipefail`
- All sysfs writes wrapped in `timeout 5 bash -c "..."` to prevent kernel deadlocks
- Protected process list prevents killing compositors/display managers
- Stopped services tracked in `/run/gpu-hotswitch-vfio-stopped-services` for restore
- `modprobe` failures handled gracefully (vfio-pci may be built-in)
- Hugepage allocation is opt-in via `hugepages-alloc` subcommand, not automatic

## Gotchas

- Script must run as root (checks `$EUID` at entry)
- `fuser /dev/nvidia*` includes `/dev/nvidiactl` holders — all are treated as potential blockers for driver unload
- NVIDIA module unload order matters: `nvidia_drm` → `nvidia_modeset` → `nvidia_uvm` → `nvidia`
- Never manually unbind from nvidia/amdgpu driver via sysfs — risks kernel deadlock; only `rmmod` is safe
- AMD dGPU detection excludes bus `00:` to avoid matching the iGPU
- Compositor config changes are persistent (survive reboot) by design

## Release

- AUR package: `gpu-hotswitch-vfio`
- GitHub Actions: `.github/workflows/release.yml` — creates GitHub Release + pushes to AUR on `v*` tag
- Version bumped in PKGBUILD by CI; tag format: `v1.0.0`
