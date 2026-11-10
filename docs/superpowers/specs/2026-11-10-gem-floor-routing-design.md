# GEM walking routes and 2.5D view

Approved in chat on 10 November 2026.

All four public maps use a common floor router. The normal MuseumGraph entry
points retain named destinations, arbitrary floor origins, tours, redirects,
stairs exclusion, estimated distance and duration, and portal instructions.
A* searches four-pixel floor cells. Visibility checks visit every crossed cell,
including adjacent cells at diagonal corners. Smoothing connects the furthest
visible path point. A clear straight walk produces a single segment.

Cross-map Dijkstra search connects portal landings using actual floor routes.
Its costs and rendered geometry use the same polylines. Floor and portal costs
remain separate. Upper-floor attractions on the ground-floor illustration use
their explicit lift links. Same-map lift trips split the drawing at the portal.

The camera leans 39 degrees from overhead. Building and room wall heights are
increased. Routes, the current-location beacon and arrival markers project from
the floor plane. A failed replan clears the preceding route. A tap outside the
traced floor requests another floor tap.

## Source and interpretation

The four-page GEM_Digital_Map_English.pdf found in Downloads matches the supplied
SVG maps. Its metadata identifies Digital_Brochure_R16, modified 16 November
2025. Page 4 supplied 109 missing rectangular display footprints, now included
in both Tutankhamun SVG themes and the navigation masks.

The official map landing page is
https://gem.eg/visit/plan-your-visit/museum-maps/
Its search listing was available during research, but direct access returned
HTTP 403. The locally available publisher brochure was used for the tracing.

The visitor plan is schematic. Campus white parcel boundaries are interpreted
as walking connections, with a ten-SVG-pixel trace width. The plaza and campus
perimeter are hand-traced. Small floor-color boundaries inside the Main Building
are treated as changes in floor area. Dotted Tutankhamun thematic boundaries
are excluded from obstacles. Closed display outlines are filled as obstacles.
Only the entrance-connected floor component is retained.

Destination pins inside footprints use the nearest open cell within 80 SVG
pixels. The Main Building campus destination uses its existing entrance portal.
Other doorway coordinates and floor-transfer links retain the project catalogue.
These approaches, path widths, access permissions, wall semantics and portal
positions need on-site verification. They are not surveyed dimensions.
The existing map distance scales, stair lengths and lift wait are estimates.

## Regeneration and verification

Run tools/trace_walking_floors.py from the repository root with Python packages
cairosvg, pillow, numpy and scipy. It reads the four light SVGs and emits the
checked-in floor_masks.dart. Runtime routing requires no network or PDF parsing.

Regression coverage exercises the normal screen's I'm here and Start route
buttons, origin changes that clear a route, every POI from its map entrance,
all-four-map round trips, stairs exclusion, every rendered walking segment,
thin walls, diagonal contact, invalid taps and camera inversion.
