# Maintainer: ParticleG <particle_g@outlook.com>
pkgname=gpu-passthrough
pkgver=1.0.0
pkgrel=1
pkgdesc="Hot-switch GPU passthrough for KVM virtual machines"
arch=('any')
url="https://github.com/ParticleG/gpu-passthrough"
license=('MIT')
depends=('bash' 'util-linux' 'pciutils' 'kmod')
optdepends=(
    'qemu-desktop: KVM virtual machine manager'
    'libvirt: VM management daemon'
    'looking-glass: low-latency VM display client'
)
source=("$pkgname-$pkgver.tar.gz::$url/archive/v$pkgver.tar.gz")
sha256sums=('SKIP')

package() {
    cd "$pkgname-$pkgver"
    make DESTDIR="$pkgdir" install
}
