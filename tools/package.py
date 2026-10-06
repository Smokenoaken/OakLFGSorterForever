"""Build a clean, installable addon ZIP using only the Python standard library."""
from pathlib import Path
import re
import xml.etree.ElementTree as ET
from zipfile import ZipFile, ZIP_DEFLATED

root = Path(__file__).resolve().parents[1]
name = "OakLFGSorterForever"
toc = root / f"{name}.toc"
text = toc.read_text(encoding="utf-8-sig")
version = re.search(r"^## Version:\s*(\S+)", text, re.MULTILINE).group(1)
files = [toc.name, "Bindings.xml", "LICENSE", "CHANGELOG.md"]
files.extend(line.strip() for line in text.splitlines() if line.strip() and not line.startswith("#"))
assert "Bindings.xml" not in files[4:], "Bindings.xml must be loaded by WoW's binding loader"
assert ET.parse(root / "Bindings.xml").find("Binding").get("category"), "Binding needs a category"
files.extend(str(path.relative_to(root)) for path in sorted((root / "Media").glob("*")) if path.is_file())
for file in files:
    assert (root / file).is_file(), f"Missing package file: {file}"
output = root / "dist" / f"{name}-v{version}.zip"
output.parent.mkdir(exist_ok=True)
with ZipFile(output, "w", ZIP_DEFLATED) as archive:
    for file in files:
        archive.write(root / file, f"{name}/{Path(file).as_posix()}")
with ZipFile(output) as archive:
    assert archive.testzip() is None, "ZIP integrity failure"
print(f"Built {output.name}: {len(files)} files")
