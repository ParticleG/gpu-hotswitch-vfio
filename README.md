# gpu-hotswitch-vfio

Hot-switch discrete GPU between host and VFIO passthrough for KVM virtual machines — no reboot required.

Designed for hybrid GPU laptops (NVIDIA/AMD discrete + integrated GPU) to dynamically bind/unbind the discrete GPU to `vfio-pci` for VM passthrough.

## Features

- **Auto-detection** of discrete GPU (NVIDIA or AMD) and IOMMU groups
- **Safe process management** — automatically stops systemd services using the GPU; interactively lists and terminates user applications with graceful shutdown (SIGTERM → SIGKILL)
- **Compositor integration** — auto-configures [niri](https://github.com/YaLTeR/niri) to ignore dGPU DRM devices and render on iGPU
- **Hugepage allocation** — incremental 1GB hugepage allocation to avoid system freezes
- **Timeout protection** — all sysfs operations have timeouts to prevent kernel deadlocks
- **Service lifecycle** — stopped services are restarted after passthrough enable/disable; services that fail to start on iGPU are reported and retried on restore

## Installation

### From source

```bash
sudo make install
```

### Arch Linux (AUR)

```bash
paru -S gpu-hotswitch-vfio
```

## Usage

```bash
# Enable GPU passthrough (binds dGPU to vfio-pci)
sudo gpu-hotswitch-vfio on

# Check current status
sudo gpu-hotswitch-vfio status

# Disable GPU passthrough (restores original driver)
sudo gpu-hotswitch-vfio off
```

## Requirements

- Linux kernel with IOMMU and vfio-pci support
- `iommu=pt` and appropriate `intel_iommu=on` or `amd_iommu=on` kernel parameters
- Hybrid GPU system (integrated + discrete)
- `psmisc` (provides `fuser`)

## How it works

### `gpu-hotswitch-vfio on`

1. Detects discrete GPU and all devices in its IOMMU group
2. Configures compositor (niri) to ignore dGPU DRM devices and use iGPU for rendering
3. Identifies processes using the GPU:
   - Systemd services are stopped automatically (tracked for restart)
   - User processes are listed interactively for confirmation
4. Unloads GPU driver modules (nvidia/amdgpu)
5. Unbinds remaining devices (e.g., HDMI audio) from their drivers
6. Loads vfio-pci and binds all IOMMU group devices
7. Allocates hugepages (1GB pages, incrementally to avoid system freeze)
8. Restarts stopped services (they rebind to iGPU if possible; failures reported)

### `gpu-hotswitch-vfio off`

1. Checks if passthrough is active (exits early if not)
2. Stops services that were restarted on iGPU
3. Unbinds devices from vfio-pci
4. Reloads original GPU driver modules
5. Reprobes devices
6. Releases hugepages
7. Restarts all tracked services (now with dGPU available)

## Notes

- **Compositor config is persistent** — after the first `on`, niri's `render-drm-device` and `ignore-drm-device` settings remain in your config. This ensures niri always uses the iGPU for rendering, making future hotswitch operations safe.
- **NVIDIA support is more mature** than AMD — NVIDIA path includes full retry logic, interactive process confirmation, and module unload verification. AMD path has basic process detection but less robust error handling.

## Related

- [gpu-passthrough-manager](https://github.com/uwzis/gpu-passthrough-manager) — GUI tool for static VFIO driver binding (requires reboot)
- [Arch Wiki: PCI passthrough via OVMF](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF)
- [Looking Glass](https://looking-glass.io/) — low-latency VM display for GPU passthrough

## License

MIT
