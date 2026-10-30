"""Extract one explicitly selected material from the user's local Unity package."""
from pathlib import Path
import sys
import tarfile

TARGET = "Assets/Ferr/2DTerrain/Examples/Assets/Materials/RockyFill.png"

def main():
    package = Path(sys.argv[1]).resolve(strict=True)
    destination = Path(__file__).resolve().parents[1] / "assets/terrain/ferr2d"
    with tarfile.open(package, "r:*") as archive:
        members = {member.name: member for member in archive.getmembers() if member.isfile()}
        for name, member in members.items():
            if not name.endswith("/pathname"):
                continue
            path = archive.extractfile(member).read().decode("utf-8-sig").strip()
            if path != TARGET:
                continue
            asset = members[name.rsplit("/", 1)[0] + "/asset"]
            data = archive.extractfile(asset).read()
            assert data.startswith(b"\x89PNG\r\n\x1a\n"), "Expected the selected PNG material"
            destination.mkdir(parents=True, exist_ok=True)
            # No extractall(), archive-supplied destination or Unity scripts.
            (destination / "RockyFill.png").write_bytes(data)
            print("Extracted local Ferr2D neutral fill; media remains excluded from Git")
            return
    raise SystemExit("The selected Ferr2D example material is absent from this package")

if __name__ == "__main__":
    main()
