# GAlpine
> [!TIP]
> _GNU C Library compatibility layer for Alpine Linux_

GAlpine is an Alpine Linux adaptation that allows it to run packages that
depend on dynamic linking with the GNU C Library. This works by installing
`glibc` to the prefix `/usr/glibc` as a special `.apk` package, that is rigged
with an apk trigger modifies the linker configuration giving preference to
`glibc` only when packages are installed to certain directories, allowing
`musl` and `glibc` to work side-by-side.


## Usage

Images are published to the GitHub Container Registry for every platform the
official `alpine` image supports (`amd64`, `arm64`, `arm/v7`, `arm/v6`, `386`,
`ppc64le`, `riscv64`, `s390x`), tagged by Alpine version:

```sh
docker pull ghcr.io/platforges/galpine:latest
docker pull ghcr.io/platforges/galpine:3.24
docker pull ghcr.io/platforges/galpine:3.23
```

## Building

```sh
make build ALPINE_VERSION=3.24   # build for linux/amd64
make test  ALPINE_VERSION=3.24   # Miniconda + numpy smoke test
make build PLATFORM=linux/arm64  # other platforms need QEMU/binfmt
```

glibc is cross-compiled on the build host, so only the packaging stages run
under emulation for non-native platforms.
