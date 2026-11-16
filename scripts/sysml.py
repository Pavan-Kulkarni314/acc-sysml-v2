"""Validate the ACC model and render its diagrams with the SysML v2 Pilot Implementation.

Works on Windows, macOS and Linux:

    python scripts/sysml.py validate    # check every model file
    python scripts/sysml.py diagrams    # write SVG diagrams to docs/diagrams/
    python scripts/sysml.py setup       # only find/download the pilot implementation and compile the tools

The pilot implementation is taken from the active conda environment if the
"jupyter-sysml-kernel" package is installed (see environment.yml). Otherwise
it is downloaded once into .pilot/. Java 17+ (with javac) is needed, and
Graphviz ("dot") is needed for diagrams.
"""

from __future__ import annotations

import glob
import io
import os
import shutil
import subprocess
import sys
import tarfile
import urllib.request
import zipfile
from pathlib import Path

VERSION = "0.63.1"
PACKAGE = f"jupyter-sysml-kernel-{VERSION}-pyhd8ed1ab_0.conda"
URL = f"https://conda.anaconda.org/conda-forge/noarch/{PACKAGE}"

ROOT = Path(__file__).resolve().parent.parent
PILOT = ROOT / ".pilot"
CLASSES = PILOT / "classes"

DIAGRAMS = [
    "ACC_Context|TREE|01_context",
    "ACC_SystemRequirements|TREE|03_system_requirements",
    "ACC_LogicalArchitecture::provideAcc|ACTION|04_functional_chain",
    "ACC_Behaviour::AccStates|STATE|05_state_machine",
    "ACC_PhysicalArchitecture::vehicleDesign|INTERCONNECTION|06_physical_architecture|noattributes",
    "ACC_Verification::brakeOverrideTest|ACTION|09_tc07_brake_override",
]


def fail(message: str) -> None:
    print(f"\nERROR: {message}", file=sys.stderr)
    sys.exit(2)


def find_pilot() -> tuple[Path, Path] | None:
    """Returns (jar, library) from the conda environment or from .pilot/, if present."""
    kernel_dir = Path(sys.prefix) / "share" / "jupyter" / "kernels" / "sysml"
    jars = sorted(kernel_dir.glob("*-all.jar"))
    if jars and (kernel_dir / "sysml.library").is_dir():
        return jars[-1], kernel_dir / "sysml.library"
    if (PILOT / "sysml.jar").is_file() and (PILOT / "sysml.library").is_dir():
        return PILOT / "sysml.jar", PILOT / "sysml.library"
    return None


def download_pilot() -> tuple[Path, Path]:
    print(f"Downloading SysML v2 Pilot Implementation {VERSION} (about 120 MB) ...")
    try:
        import zstandard
    except ImportError:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "--quiet", "zstandard"])
        import zstandard

    with urllib.request.urlopen(URL) as response:
        data = response.read()
    print("Unpacking ...")
    outer = zipfile.ZipFile(io.BytesIO(data))
    inner = next(name for name in outer.namelist() if name.startswith("pkg-"))
    reader = zstandard.ZstdDecompressor().stream_reader(io.BytesIO(outer.read(inner)))
    tmp = PILOT / "download"
    archive = tarfile.open(fileobj=reader, mode="r|")
    try:
        archive.extractall(tmp, filter="data")
    except TypeError:  # Python versions without extraction filters
        archive.extractall(tmp)

    kernel = tmp / "share" / "jupyter" / "kernels" / "sysml"
    shutil.copy(next(kernel.glob("*-all.jar")), PILOT / "sysml.jar")
    shutil.copytree(kernel / "sysml.library", PILOT / "sysml.library", dirs_exist_ok=True)
    shutil.rmtree(tmp)
    return PILOT / "sysml.jar", PILOT / "sysml.library"


def compile_tools(jar: Path) -> None:
    sources = sorted((ROOT / "tools").glob("*.java"))
    classes = [CLASSES / (s.stem + ".class") for s in sources]
    if all(c.exists() and c.stat().st_mtime >= s.stat().st_mtime for c, s in zip(classes, sources)):
        return
    javac = shutil.which("javac")
    if not javac:
        fail("javac not found. Install a Java JDK 17 or newer, for example with "
             "'conda env create -f environment.yml' (see README).")
    print("Compiling tools ...")
    CLASSES.mkdir(parents=True, exist_ok=True)
    subprocess.check_call([javac, "-encoding", "UTF-8", "-cp", str(jar), "-d", str(CLASSES),
                           *[str(s) for s in sources]])


def prepare() -> tuple[Path, Path]:
    if not shutil.which("java"):
        fail("java not found. Install Java 17 or newer, for example with "
             "'conda env create -f environment.yml' (see README).")
    found = find_pilot()
    if found is None:
        PILOT.mkdir(exist_ok=True)
        found = download_pilot()
    jar, library = found
    compile_tools(jar)
    return jar, library


def run_java(jar: Path, main_class: str, args: list[str], env: dict | None = None) -> int:
    command = [
        "java", "-Dfile.encoding=UTF-8", "-Dstdout.encoding=UTF-8", "-Djava.awt.headless=true",
        "-cp", f"{jar}{os.pathsep}{CLASSES}", main_class, *args,
    ]
    process = subprocess.Popen(command, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                               text=True, encoding="utf-8", errors="replace", env=env)
    for line in process.stdout:
        if line.startswith(("Reading ", "log4j", "Picked up ")):
            continue
        print(line, end="")
    return process.wait()


def library_arg(library: Path) -> str:
    # The pilot implementation expects the library folder with a trailing slash.
    return library.resolve().as_posix().rstrip("/") + "/"


def validate() -> int:
    jar, library = prepare()
    files = sorted(str(Path(f).relative_to(ROOT)) for f in glob.glob(str(ROOT / "model" / "*.sysml")))
    print(f"Validating {len(files)} model files (loading the standard library can take a minute) ...")
    return run_java(jar, "Validate", [library_arg(library), *files])


def diagrams() -> int:
    jar, library = prepare()
    dot = shutil.which("dot")
    if not dot:
        fail("Graphviz 'dot' not found. Install Graphviz, for example with "
             "'conda env create -f environment.yml' (see README).")
    env = dict(os.environ, GRAPHVIZ_DOT=dot)
    print("Rendering diagrams (loading the standard library can take a minute) ...")
    return run_java(jar, "Render", [library_arg(library), str(ROOT / "model"),
                                    str(ROOT / "docs" / "diagrams"), *DIAGRAMS], env=env)


def setup() -> int:
    jar, library = prepare()
    print(f"Ready.\n  Pilot implementation: {jar}\n  Standard library:     {library}")
    return 0


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(errors="replace")
    commands = {"setup": setup, "validate": validate, "diagrams": diagrams}
    if len(sys.argv) != 2 or sys.argv[1] not in commands:
        print(__doc__)
        return 1
    return commands[sys.argv[1]]()


if __name__ == "__main__":
    sys.exit(main())
