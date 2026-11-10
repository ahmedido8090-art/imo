"""Extract main-building room polygons from the shipped SVG map.

This script assigns footprints to room/service pins by finding the smallest
filled SVG path that contains each pin point.

Inputs:
  - assets/maps/light/main_building.svg
  - lib/data/gem_map_data.dart (Main Building places + pin coordinates)

Usage:
  python tools/extract_rooms.py > /tmp/rooms.dart

Dependencies:
  pip install shapely svgpathtools
"""

from __future__ import annotations

import argparse
import re
import sys
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from shapely.geometry import Point, Polygon
from svgpathtools import parse_path

ROOT = Path(__file__).resolve().parents[1]
SVG_PATH = ROOT / "assets/maps/light/main_building.svg"
MAP_DATA_PATH = ROOT / "lib/data/gem_map_data.dart"
VIEW_W, VIEW_H = 1625.0, 885.0

TARGET_CATEGORIES = {"restaurant", "shop", "facility"}
EXCLUDE_IDS = {"mb_clinic", "mb_atm", "mb_lift1", "mb_lift2", "mb_access1", "mb_access2", "mb_info1", "mb_info3"}


@dataclass(frozen=True)
class PlacePin:
    id: str
    name: str
    x: float
    y: float
    category: str


def _matrix(s: str | None) -> tuple[float, float, float, float, float, float]:
    if not s:
        return (1, 0, 0, 1, 0, 0)
    m = re.search(r"matrix\(([^)]+)\)", s)
    if not m:
        return (1, 0, 0, 1, 0, 0)
    vals = [float(v.strip()) for v in m.group(1).split(",")]
    if len(vals) != 6:
        return (1, 0, 0, 1, 0, 0)
    return tuple(vals)  # type: ignore[return-value]


def _mul(
    a: tuple[float, float, float, float, float, float],
    b: tuple[float, float, float, float, float, float],
) -> tuple[float, float, float, float, float, float]:
    a1, b1, c1, d1, e1, f1 = a
    a2, b2, c2, d2, e2, f2 = b
    return (
        a1 * a2 + c1 * b2,
        b1 * a2 + d1 * b2,
        a1 * c2 + c1 * d2,
        b1 * c2 + d1 * d2,
        a1 * e2 + c1 * f2 + e1,
        b1 * e2 + d1 * f2 + f1,
    )


def _apply(m: tuple[float, float, float, float, float, float], x: float, y: float) -> tuple[float, float]:
    a, b, c, d, e, f = m
    return (a * x + c * y + e, b * x + d * y + f)


def parse_pins(path: Path) -> list[PlacePin]:
    src = path.read_text(encoding="utf-8")
    block = re.search(r"final GemMap mainBuildingMap = GemMap\((.*?)\n\s*junctions:", src, re.S)
    if not block:
        raise RuntimeError("Could not find Main Building block in gem_map_data.dart")
    out: list[PlacePin] = []
    rx = re.compile(
        r"MapPlace\(\s*id: '([^']+)'.*?name: '([^']+)'.*?position: _mb\(([\d.]+),\s*([\d.]+)\).*?category: PlaceCategory\.([a-z]+)",
        re.S,
    )
    for m in rx.finditer(block.group(1)):
        pid, name, x, y, cat = m.groups()
        if cat not in TARGET_CATEGORIES or pid in EXCLUDE_IDS:
            continue
        out.append(PlacePin(pid, name.replace("\\'", "'"), float(x), float(y), cat))
    return out


def _path_points(d: str, mtx: tuple[float, float, float, float, float, float]) -> list[tuple[float, float]]:
    path = parse_path(d)
    pts: list[tuple[float, float]] = []
    for seg in path:
        steps = max(4, int(seg.length(error=1e-3) // 8))
        for i in range(steps):
            z = seg.point(i / steps)
            pts.append(_apply(mtx, z.real, z.imag))
    if path:
        z = path[-1].point(1)
        pts.append(_apply(mtx, z.real, z.imag))
    return pts


def extract_polygons(svg_path: Path) -> list[Polygon]:
    root = ET.fromstring(svg_path.read_text(encoding="utf-8"))
    ns = {"svg": "http://www.w3.org/2000/svg"}
    group = root.find("svg:g", ns)
    base = _matrix(group.attrib.get("transform") if group is not None else None)
    polys: list[Polygon] = []
    for el in root.findall(".//svg:path", ns):
        fill = (el.attrib.get("fill") or "").lower()
        if fill in {"", "none"}:
            continue
        d = el.attrib.get("d")
        if not d:
            continue
        mtx = _mul(base, _matrix(el.attrib.get("transform")))
        pts = _path_points(d, mtx)
        if len(pts) < 3:
            continue
        poly = Polygon(pts).buffer(0)
        if not poly.is_valid or poly.area < 200 or poly.area > 20000:
            continue
        polys.append(poly)
    return polys


def _norm(poly: Polygon) -> list[tuple[float, float]]:
    ring = list(poly.exterior.coords)[:-1]
    return [(round(x / VIEW_W, 4), round(y / VIEW_H, 4)) for x, y in ring]


def _kind(cat: str) -> str:
    return "RegionKind.zone" if cat in {"restaurant", "shop", "facility"} else "RegionKind.hall"


def build_regions(pins: Iterable[PlacePin], polys: list[Polygon]) -> list[str]:
    lines: list[str] = []
    for pin in pins:
        hit = [p for p in polys if p.contains(Point(pin.x, pin.y))]
        if not hit:
            continue
        poly = min(hit, key=lambda p: p.area).simplify(1.4, preserve_topology=True)
        pts = _norm(poly)
        if len(pts) < 3:
            continue
        cx = sum(x for x, _ in pts) / len(pts)
        cy = sum(y for _, y in pts) / len(pts)
        coords = ",".join(f"{x:.4f},{y:.4f}" for x, y in pts)
        safe_name = pin.name.replace("'", "\\'")
        lines.append(
            "  MapRegion("
            f"id: 'mbr_{pin.id}', mapId: 'main_building', name: '{safe_name}', "
            f"kind: {_kind(pin.category)}, labelAt: Offset({cx:.4f}, {cy:.4f}), "
            f"placeId: '{pin.id}', showLabel: false, points: _p(const [{coords}])),"
        )
    return lines


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--svg", type=Path, default=SVG_PATH)
    ap.add_argument("--map-data", type=Path, default=MAP_DATA_PATH)
    args = ap.parse_args()

    pins = parse_pins(args.map_data)
    polys = extract_polygons(args.svg)
    regions = build_regions(pins, polys)

    print("// GENERATED by tools/extract_rooms.py from assets/maps/light/main_building.svg.")
    print("import 'package:flutter/painting.dart';")
    print("import '../models/map_models.dart';")
    print("List<Offset> _p(List<double> v) => [for (var i = 0; i < v.length; i += 2) Offset(v[i], v[i + 1])];")
    print("final List<MapRegion> kRoomRegions = [")
    for line in regions:
        print(line)
    print("];")
    print(f"// emitted {len(regions)} room regions", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
