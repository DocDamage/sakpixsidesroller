# Level design continuity

The user explicitly asked that the supplied Silksong walkthrough be studied and
revisited when its lessons become unclear. Before changing stage layouts,
composition, traversal or prop placement, read `DESIGN_REFERENCE.txt` and
`STAGE1_DESIGN_AUDIT.txt`. For a task focused on a particular area, reopen the
relevant timestamped images or source passage in `artifacts/reference-study/`.
Re-examine footage when uncertain; do not substitute a vague memory of the game.

The recorded study sampled the whole visual timeline and four denser windows.
It did not inspect every second or hear audio. Preserve that distinction.
Research footage and its extracted images must never become shipped game assets.

Author room solids, ceilings, openings, actions, encounters, landmarks and return
loops before scattering props. Passing connectivity and placement checks does not
prove level-design quality. Inspect composition with the normal gameplay camera
and play with enemies active, ordinary keyboard/controller inputs, both directions
and missed optional items. Preserve physical post-boss return access.

Stage 1 remains the current design focus; the other eleven stages still need
individual review. Use the user's local asset packs and requested Haunted Manor
soundtrack. Keep research output excluded from Godot import with `.gdignore`.

The user rejected oversized background house sprites and disconnected facade
pieces. Playable buildings now use the matching House Inside/Outside assets in
`Stages/GandalfHardcore Pixel Art Medieval Fantasy Assets/` at a consistent source
pixel scale, with continuous foundations, roof edges and room-aware cutaways.
Keep small Halloween house silhouettes in distant scenery. Check architectural
joins and complete silhouettes in actual renders, including closed exteriors.

GitHub is code-only by explicit user instruction. Never commit or push asset
packs, images, audio, music, engine binaries, generated media or research footage.
Keep the strict .gitignore allowlist; JSON exceptions are path/settings manifests.
Run tests/repository_checks.py against the staged content before committing.
