# gpu-hotswitch-vfio

Hot-switch discrete GPU between host and VFIO passthrough for KVM virtual machines — no reboot required.

Designed for hybrid GPU laptops (NVIDIA/AMD discrete + integrated GPU) to dynamically bind/unbind the discrete GPU to `vfio-pci` for VM passthrough.

## Features

- **Auto-detection** of discrete GPU (NVIDIA or AMD) and IOMMU groups
- **Safe process management** — automatically stops systemd services using the GPU; interactively lists and terminates user applications with graceful shutdown (SIGTERM → SIGKILL)
- **Compositor integration** — auto-configures [niri](https://github.com/YaLTeR/niri) to ignore dGPU DRM devices and render on iGPU
- **Hugepage management** — separate subcommands for allocating/releasing hugepages with OOM safety checks
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

# Allocate hugepages for VM (optional, run before starting VM)
sudo gpu-hotswitch-vfio hugepages-alloc

# Start your VM...

# After VM shutdown, release hugepages
sudo gpu-hotswitch-vfio hugepages-free

# Disable GPU passthrough (restores original driver)
sudo gpu-hotswitch-vfio off

# Check current status
sudo gpu-hotswitch-vfio status
```

### Typical workflow

```
on → hugepages-alloc → start VM → stop VM → hugepages-free → off
```

Hugepage allocation is optional. If your VM XML does not include `<hugepages/>` in `<memoryBacking>`, you can skip the hugepages steps entirely.

## Requirements

- Linux kernel with IOMMU and vfio-pci support (module or built-in)
- `iommu=pt` kernel parameter (AMD IOMMU is auto-enabled; Intel needs `intel_iommu=on`)
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
6. Loads vfio-pci (handles both loadable module and built-in) and binds all IOMMU group devices
7. Advises on hugepage allocation if VM is configured for it
8. Restarts stopped services (they rebind to iGPU if possible; failures reported)

### `gpu-hotswitch-vfio off`

1. Checks if passthrough is active (exits early if not)
2. Stops services that were restarted on iGPU
3. Unbinds devices from vfio-pci
4. Reloads original GPU driver modules
5. Reprobes devices
6. Releases hugepages if any are allocated
7. Restarts all tracked services (now with dGPU available)

### `gpu-hotswitch-vfio hugepages-alloc`

1. Checks if any VM in `/etc/libvirt/qemu/` is configured with `<hugepages/>`
2. Verifies sufficient available memory (leaves 2GB headroom for host)
3. Allocates 2MB hugepages on demand for the VM memory size
4. Skips allocation if no VM uses hugepages

### `gpu-hotswitch-vfio hugepages-free`

Releases all allocated hugepages (both 1GB and 2MB).

## Companion tool: gpu-select

[gpu-select](https://github.com/ParticleG/gpu-select) provides per-app GPU assignment. Use it to prevent applications from accessing the NVIDIA GPU before hotswitch:

```bash
# Prevent apps from using NVIDIA (full isolation)
gpu-select set QQ igpu
gpu-select set valent igpu
gpu-select apply
```

Apps configured with `gpu-select set <app> igpu` will not hold `/dev/nvidia*` devices, making `gpu-hotswitch-vfio on` seamless without needing to kill them.

## Notes

- **Compositor config is persistent** — after the first `on`, niri's `render-drm-device` and `ignore-drm-device` settings remain in your config. This ensures niri always uses the iGPU for rendering, making future hotswitch operations safe.
- **NVIDIA support is more mature** than AMD — NVIDIA path includes full retry logic, interactive process confirmation, and module unload verification. AMD path has basic process detection but less robust error handling.
- **vfio-pci built-in** — on kernels where vfio-pci is compiled in (not a loadable module), the tool detects this and proceeds without `modprobe`.

## Related

- [gpu-select](https://github.com/ParticleG/gpu-select) — per-app GPU selection for hybrid GPU laptops
- [gpu-passthrough-manager](https://github.com/uwzis/gpu-passthrough-manager) — GUI tool for static VFIO driver binding (requires reboot)
- [Arch Wiki: PCI passthrough via OVMF](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF)
- [Looking Glass](https://looking-glass.io/) — low-latency VM display for GPU passthrough

## License

MIT
