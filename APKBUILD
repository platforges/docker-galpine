pkgname="glibc"
pkgver="$GLIBC_VERSION"
pkgrel="0"
pkgdesc="GNU C Library compatibility layer for Alpine Linux"
url="https://github.com/platforges/docker-galpine"
arch="all"
options="!check !tracedeps lib64"
license="LGPL-2.1-or-later"
subpackages="$pkgname-dev $pkgname-bin $pkgname-i18n:i18n:noarch"
source="glibc-bin.tar.xz ld.so.conf"
triggers="$pkgname-bin.trigger=/lib:/usr/lib:/usr/glibc/lib"

package() {
    mkdir -p $pkgdir/lib $pkgdir/lib64 $pkgdir/usr/glibc/lib/locale $pkgdir/usr/glibc/lib64 $pkgdir/etc
    cp -a $srcdir/usr $pkgdir
    cp $srcdir/ld.so.conf $pkgdir/usr/glibc/etc/ld.so.conf
    rm $pkgdir/usr/glibc/etc/rpc
    rm -rf $pkgdir/usr/glibc/bin
    rm -rf $pkgdir/usr/glibc/sbin
    rm -rf $pkgdir/usr/glibc/lib/gconv
    rm -rf $pkgdir/usr/glibc/lib/getconf
    rm -rf $pkgdir/usr/glibc/lib/audit
    rm -rf $pkgdir/usr/glibc/share
    rm -rf $pkgdir/usr/glibc/var
    # Expose the glibc dynamic loader at the standard paths for this arch
    for loader in $srcdir/usr/glibc/lib/ld-*.so.* $srcdir/usr/glibc/lib/ld64.so.*; do
        [ -e "$loader" ] || continue
        name=$(basename "$loader")
        ln -s /usr/glibc/lib/$name $pkgdir/lib/$name
        ln -s /usr/glibc/lib/$name $pkgdir/lib64/$name
        ln -s /usr/glibc/lib/$name $pkgdir/usr/glibc/lib64/$name
    done
    ln -s /usr/glibc/etc/ld.so.cache $pkgdir/etc/ld.so.cache
}

bin() {
    depends="$pkgname libgcc"
    mkdir -p $subpkgdir/usr/glibc
    cp -a $srcdir/usr/glibc/bin  $subpkgdir/usr/glibc
    cp -a $srcdir/usr/glibc/sbin $subpkgdir/usr/glibc
}

i18n() {
    depends="$pkgname-bin"
    mkdir -p $subpkgdir/usr/glibc
    cp -a $srcdir/usr/glibc/share $subpkgdir/usr/glibc
}

