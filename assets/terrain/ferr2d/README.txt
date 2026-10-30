Ferr2D terrain adaptation

Source: the user's Not UpdatedFerr2D Terrain Tool v2.0.3.unitypackage.
source_manifest.json records the inspected package members. RockyFill.png is
copied unchanged from its example material assets. Inspection copies of Unity
sources/material definitions remain excluded from Godot in artifacts/fixture-review.

scripts/contour_terrain.gd adapts the path/directional-edge/fill model inspected in
Ferr2D_Path.GetDirection, Ferr2DT_SegmentDescription and the Castle material.
It builds native Godot CollisionPolygon2D, Polygon2D fill and directional textured
edge strips from a single authored contour. The same contour casts the shadow.
The surface and retaining-stone courses use the existing pixel-art pack; the
subsurface fill uses Ferr2D's neutral RockyFill. No Unity runtime/editor dependency
or claim of a complete Ferr2D port. Stage 1's fourteen foundation masses use it.

Walking heights and route openings stay on the authored ledges. Lower corners
are beveled within each foundation's bounds. New irregular contours can use build()
directly; keep floor support, shadow and collision tied to that same path.
