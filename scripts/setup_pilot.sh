#!/usr/bin/env bash
# Downloads the open-source SysML v2 Pilot Implementation (the reference
# implementation from the OMG Systems Modeling Community) into .pilot/
# and compiles the small Java tools in tools/.
#
# Needs: Java 17+, Python 3, curl. Run from the repository root.
set -euo pipefail

VERSION="0.63.1"
PKG="jupyter-sysml-kernel-${VERSION}-pyhd8ed1ab_0.conda"
URL="https://conda.anaconda.org/conda-forge/noarch/${PKG}"
PILOT_DIR=".pilot"

if [ -f "${PILOT_DIR}/sysml.jar" ] && [ -d "${PILOT_DIR}/sysml.library" ]; then
  echo "Pilot implementation already installed in ${PILOT_DIR}/"
else
  mkdir -p "${PILOT_DIR}/download"
  echo "Downloading SysML v2 Pilot Implementation ${VERSION} ..."
  curl -fsSL -o "${PILOT_DIR}/download/${PKG}" "${URL}"

  echo "Unpacking ..."
  # On Windows, "python3" can be a Microsoft Store shortcut that does not run Python, so test each candidate.
  PY=""
  # The first Python that is 3.8+ and has pip wins (an active virtual environment comes first).
  for candidate in python python3 py; do
    if "${candidate}" -c "import sys; sys.exit(0 if sys.version_info >= (3, 8) else 1)" >/dev/null 2>&1 \
       && "${candidate}" -m pip --version >/dev/null 2>&1; then
      PY="${candidate}"
      break
    fi
  done
  if [ -z "${PY}" ]; then
    echo "Python 3.8 or newer with pip was not found. Install it from python.org and tick 'Add python.exe to PATH'." >&2
    exit 1
  fi
  "${PY}" -m pip install --quiet zstandard 2>/dev/null || "${PY}" -m pip install --quiet --break-system-packages zstandard
  "${PY}" - "${PILOT_DIR}" "${PKG}" <<'EOF'
import glob, io, shutil, sys, tarfile, zipfile
import zstandard

pilot, pkg = sys.argv[1], sys.argv[2]
outer = zipfile.ZipFile(f"{pilot}/download/{pkg}")
inner = next(n for n in outer.namelist() if n.startswith("pkg-"))
reader = zstandard.ZstdDecompressor().stream_reader(io.BytesIO(outer.read(inner)))
archive = tarfile.open(fileobj=reader, mode="r|")
try:
    archive.extractall(f"{pilot}/download/pkg", filter="data")
except TypeError:  # Python versions without extraction filters
    archive.extractall(f"{pilot}/download/pkg")

kernel = f"{pilot}/download/pkg/share/jupyter/kernels/sysml"
shutil.copy(glob.glob(f"{kernel}/*-all.jar")[0], f"{pilot}/sysml.jar")
shutil.copytree(f"{kernel}/sysml.library", f"{pilot}/sysml.library", dirs_exist_ok=True)
EOF
  rm -rf "${PILOT_DIR}/download"
fi

echo "Compiling tools ..."
javac -encoding UTF-8 -cp "${PILOT_DIR}/sysml.jar" -d "${PILOT_DIR}/classes" tools/*.java
echo "Done."
