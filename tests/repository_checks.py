"""Audit the index before commit: source/text manifests only, no asset payloads."""
from pathlib import Path
import json
import subprocess

ROOT = Path(__file__).resolve().parents[1]
ROOT_FILES = {".gitignore", ".gitattributes", "README.md", "README.txt", "AGENTS.md",
              "DESIGN_REFERENCE.txt", "STAGE1_DESIGN_AUDIT.txt", "project.godot", "Play.cmd"}
ROOT_FILES.update(f"Play Level {number}.cmd" for number in range(2, 13))
MANIFESTS = {"assets/effects_manifest.json", "assets/audio/district/sources.json",
             "assets/audio/enemies/sources.json", "assets/terrain/ferr2d/source_manifest.json",
             "assets/terrain/ferr2d/README.txt"}

def allowed(path):
    parts = path.split("/")
    if path in ROOT_FILES or path in MANIFESTS:
        return True
    if len(parts) != 2:
        return False
    if parts[0] in {"scripts", "tests"}:
        return path.endswith((".gd", ".gd.uid", ".gdshader", ".gdshader.uid", ".py"))
    return parts[0] == "scenes" and path.endswith(".tscn")

def small_strings(value):
    if isinstance(value, str):
        return len(value) < 4096
    if isinstance(value, dict):
        return all(small_strings(k) and small_strings(v) for k, v in value.items())
    if isinstance(value, list):
        return all(small_strings(item) for item in value)
    return True

def main():
    entries = subprocess.check_output(["git", "ls-files", "--stage", "-z"], cwd=ROOT).split(b"\0")
    blobs = []
    for entry in filter(None, entries):
        mode_sha_stage, raw_path = entry.split(b"\t", 1)
        mode, sha, stage = mode_sha_stage.split()
        path = raw_path.decode("utf-8")
        assert stage == b"0" and mode in {b"100644", b"100755"}, f"Unexpected index mode/stage: {path}"
        assert allowed(path), f"Asset or non-source path in index: {path}"
        blobs.append((path, sha))
    assert len(blobs) > 1, "Stage the source files before running this audit"
    result = subprocess.run(["git", "cat-file", "--batch"], cwd=ROOT,
                            input=b"\n".join(sha for _, sha in blobs)+b"\n",
                            stdout=subprocess.PIPE, check=True).stdout
    offset = total = 0
    for path, _ in blobs:
        end = result.index(b"\n", offset)
        _, kind, length = result[offset:end].split()
        size = int(length)
        assert kind == b"blob" and size <= 262144, f"Unexpected binary/large object: {path}"
        data = result[end+1:end+1+size]
        assert b"\0" not in data, f"Binary data in source file: {path}"
        text = data.decode("utf-8-sig")
        assert "[sub_resource type=\"Image" not in text and "[sub_resource type=\"AudioStream" not in text, f"Embedded media: {path}"
        if path.endswith(".json"):
            assert small_strings(json.loads(text)), f"Possible encoded media in JSON: {path}"
        total += size
        offset = end+size+2
    print(f"PASS: {len(blobs)} staged source/text files, {total:,} bytes; no asset files or binary payloads")

if __name__ == "__main__":
    main()
