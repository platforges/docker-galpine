#!/bin/sh
# Smoke test: a glibc-linked Miniconda must run and import numpy.
# Run as: docker run --rm -i ghcr.io/platforges/galpine sh < test.sh
set -eu

CONDA_DIR=/opt/conda
export PATH="$CONDA_DIR/bin:$PATH"
export PYTHONDONTWRITEBYTECODE=1

ARCH=$(uname -m) # x86_64 or aarch64

apk add --no-cache bash ca-certificates wget
wget -qO /tmp/miniconda.sh "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-$ARCH.sh"
bash /tmp/miniconda.sh -b -p "$CONDA_DIR"
rm /tmp/miniconda.sh

# Use conda-forge only, avoiding the Anaconda defaults channel terms of service
conda install --yes --quiet --override-channels -c conda-forge numpy

python - <<'PY'
import conda
import numpy as np

assert np.array([0, 1, 2]).tolist() == [0, 1, 2]
print(f"conda {conda.__version__}, numpy {np.__version__}: OK")
PY
