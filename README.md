# sakpixsidesroller

Game made with Sakpix assets. A Godot 4.7.2 sidescroller source project with twelve
stages, controller support, combat, water, weather and exploration routes.

This repository is **code only**. Art, sound, music, asset packs, derived WAVs,
engine executables, screenshots and research footage stay local. The allowlist in
`.gitignore` intentionally excludes them; do not force-add those directories.
The small JSON manifests contain resource paths, settings and source provenance.

## Run locally

Use the existing asset-populated project folder. Open `project.godot` in Godot
4.7.2 and run the main scene, or use `Play.cmd` when the local `Godot/` executable
is installed. `Play Level 2.cmd` through `Play Level 12.cmd` select later stages.
A fresh clone requires the corresponding locally owned asset folders at the
exact resource paths referenced by the scripts and manifests. It is not a
standalone game download, and missing packs are not fetched automatically.

The excluded local directories include `Stages/`, `Hero/`, `Enemies/`, `Props/`,
`NPCs/`, `UI/`, `VFX/`, `SFX/`, `Soundtrack/`, `Shaders/`, `Character Generator/`,
the media under `assets/`, and `Godot/`. Retain them when updating this checkout.
The soundtrack is the local Haunted Manor pack requested for this project.

With the original SFX kit in place and FFmpeg available, regenerate the derived
enemy attack cues using `python scripts/build_enemy_audio.py`. The original and
generated audio files are excluded from Git. Ferr2D's Unity package is not a
runtime dependency: its contour/edge/fill approach is adapted in
`scripts/contour_terrain.gd`, with the extracted local fill documented beside its
source manifest. `python scripts/import_ferr2d.py PACKAGE_PATH` extracts that fill.

## Current design pass

Stage 1 is the active design focus. Its court/apothecary/bell loop has cutaway
houses, two offset interior climbs, a roof crossing, a tower ascent and a callable
return cage. The chapel retains a physical post-boss return route even when
optional switches were missed. The cistern, long return gallery and remaining
eleven stages still need individual design review; automated connectivity does
not establish visual quality or first-clear pacing.

The latest pass replaces scaffold icons in ladders, widens ladder rails, grounds
interior furnishings, separates interior window panes from exterior shutters,
uses mounted torches and outdoor lantern posts, aligns animated campfire light
to the flames, and binds terrain fill/collision/shadows to shared contours.
Enemy attack trails, actual damage windows and attack sounds follow visible
attack phases. Interrupted swings lose their trails; anticipating/recovering
enemies do not deal body-contact damage.

Read `DESIGN_REFERENCE.txt`, `STAGE1_DESIGN_AUDIT.txt` and `AGENTS.md` before
changing architecture, traversal or prop composition. Reference media stays local.
`README.txt` contains the existing controls and longer development notes.

## Verification

Run against the local asset-populated project, for example:

```powershell
$godot = '.\Godot\Godot_v4.7.2-stable_win64_console.exe'
& $godot --headless --path . --script tests/fixture_checks.gd --fixed-fps 60
& $godot --headless --path . --script tests/district_checks.gd --fixed-fps 60
& $godot --headless --path . --script tests/district_combat_checks.gd --fixed-fps 60
& $godot --headless --path . --script tests/bell_loop_playthrough.gd --fixed-fps 60
& $godot --headless --path . --script tests/bell_loop_playthrough.gd --fixed-fps 60 -- --keyboard
& $godot --headless --path . --script tests/district_return_checks.gd --fixed-fps 60
& $godot --headless --path . --script tests/placement_checks.gd --fixed-fps 60
python tests/repository_checks.py
```

Render fixtures such as `tests/attack_visuals.gd` and `tests/district_visuals.gd`
require a rendering device. Captures and logs belong in the ignored `artifacts/`
folder. Normal-input route replays and visual inspection complement the targeted
checks; test counts are not a claim that all twelve stages are polished.

The legacy campaign, sight/recovery and awareness harnesses target the original
layouts: append `-- --original-layout` when running those scripts. District
harnesses target the current default Stage 1.
