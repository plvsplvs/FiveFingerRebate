#!/usr/bin/env python3
"""Build the installable addon ZIP without repository files or user data."""
from pathlib import Path
import re
import zipfile

root = Path(__file__).resolve().parent.parent
addon = root / "PocketChange"
toc = (addon / "PocketChange.toc").read_text()
version = re.search(r"^## Version: (.+)$", toc, re.M).group(1).strip()
if not re.fullmatch(r"[0-9A-Za-z.-]+", version):
    raise SystemExit("Unsafe version in TOC")
files = [addon / "PocketChange.toc", addon / "README.txt"]
for line in toc.splitlines():
    line = line.strip()
    if line and not line.startswith("#"):
        path = addon / line
        if path.parent != addon or not path.is_file():
            raise SystemExit(f"Invalid TOC file: {line}")
        files.append(path)
output = root / "dist" / f"FiveFingerRebate-{version}.zip"
output.parent.mkdir(exist_ok=True)
with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as archive:
    for path in files:
        archive.write(path, "PocketChange/" + path.name)
    archive.write(root / "LICENSE", "PocketChange/LICENSE.txt")
with zipfile.ZipFile(output) as archive:
    assert archive.testzip() is None
    assert all(name.startswith("PocketChange/") for name in archive.namelist())
print(output)
