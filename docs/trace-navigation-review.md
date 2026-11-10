# Trace navigation integration — experimental review mode

Open the original map screen and tap the small route-icon button at the right
(bottom offset 190), or navigate to /trace-navigation.

## Implemented
- Keeps the original museum screen intact.
- Adds a 2D SVG trace-navigation screen with the existing four detailed vector
  assets, light/dark selection, typed tappable place markers, origin/destination
  selection, map switching and polyline overlays without curve smoothing.
- Adds a separate minimum-estimated-time router preserving exact directed edges,
  parallel edge identity, redirects, floor portals and zero-length trips.
- Separates unknown IDs, insufficient reviewed connectivity, provisional paths
  and paths whose edges are all marked reviewed.
- Strict mode is the default. Explicitly opt into unreviewed draft routes to
  inspect the old graph; this is NOT a new physically verified corridor network.
- No automatic nearest-junction fallback and no fabricated off-floor stair links.
- Confirmed obstacle footprints can filter complete walking polylines. Unknown
  outlines do not become walls. Door openings must be modelled by appropriately
  split barrier geometry; the router does not infer openings from artwork.
- Strict step-free mode requires reviewed edges with affirmative stepFreeVerified.
  Draft stair exclusion alone is explicitly not labelled wheelchair accessibility.

## Data status / limitations
The adapter currently imports the existing kEdgePaths, kPinLinks, graph edges and
portals. All imported edges are marked UNREVIEWED. No reviewed barriers, surveyed
approach points or new floor plans are claimed. The earlier 1,764-subpath semantic
review has NOT been promoted to navigation topology. The original SVG artwork is
preserved, not replaced by guessed extruded walls. Draft routes can retain old
geometry mistakes. The review mode makes those limitations explicit.

SVG scale, walking/stair speeds and lift waits are estimates. A time-optimal path
in this graph is not a guaranteed fastest physical route in the museum. Strict
mode saying connectivity needs review does not mean a real passage is blocked.
Cross-map portal travel is costed but never drawn as a straight line between two
unrelated coordinate systems. This screen does not provide turn-by-turn portal
instructions yet. Existing routing on the original screen is not changed.

## Validation
flutter analyze
flutter test test/trace_navigation_test.dart

Ten regression tests are included. Flutter/Dart executables were unavailable in
the preparation environment; these tests and the UI have NOT been compiled/run.
Only a lexical delimiter check was run on the Dart sources. Do not merge as a
production navigation release until Flutter checks and physical geometry review
are complete. No agent delegation was used for these changes.
