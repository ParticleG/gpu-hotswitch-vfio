# gpu-passthrough

Hot-switch GPU passthrough for KVM virtual machines on hybrid GPU laptops (NVIDIA/AMD discrete + integrated GPU).

## Features

- **Auto-detection** of discrete GPU (NVIDIA or AMD) and IOMMU groups
- **Safe process management** — automatically stops systemd services using the GPU; interactively lists and terminates user applications
- **Compositor integration** — auto-configures niri to ignore dGPU DRM devices
- **Hugepage allocation** — incremental 1GB hugepage allocation to avoid system freezes
- **Timeout protection** — all sysfs operations have timeouts to prevent kernel deadlocks
- **Service lifecycle** — stopped services are restarted after passthrough enable/disable

## Installation

### From source

```bash
sudo make install
```

### Arch Linux (AUR)

```bash
# With an AUR helper
paru -S gpu-passthrough

# Or manually
makepkg -si
```

## Usage

```bash
# Enable GPU passthrough (binds dGPU to vfio-pci)
sudo gpu-passthrough on

# Check current status
sudo gpu-passthrough status

# Disable GPU passthrough (restores original driver)
sudo gpu-passthrough off
```

## Requirements

- Linux kernel with IOMMU and vfio-pci support
- `iommu=pt` and appropriate `intel_iommu=on` or `amd_iommu=on` kernel parameters
- Hybrid GPU system (integrated + discrete)

## How it works

### `gpu-passthrough on`

1. Detects discrete GPU and all devices in its IOMMU group
2. Configures compositor (niri) to ignore dGPU DRM devices
3. Stops systemd services using the GPU (auto-detected via cgroup)
4. Lists user processes using the GPU and asks for confirmation to terminate
5. Unloads GPU driver modules (nvidia/amdgpu)
6. Unbinds remaining devices (e.g., HDMI audio) from their drivers
7. Loads vfio-pci and binds all IOMMU group devices
8. Allocates hugepages (1GB pages, incrementally)
9. Restarts stopped services (they rebind to iGPU if possible)

### `gpu-passthrough off`

1. Stops services that were restarted on iGPU
2. Unbinds devices from vfio-pci
3. Reloads original GPU driver modules
4. Reprobes devices
5. Releases hugepages
6. Restarts all tracked services (now with dGPU available)

## License

MIT
