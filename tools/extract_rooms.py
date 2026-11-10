"""Extract room polygons from GEM_Digital_Map_English.pdf (page 2 = Main Building).
PDF point (x, y) -> app SVG units: ix = y, iy = 1080 - x, then x*1.0661, y*1.0661 - 39.446
(verified: the PDF floor outline matches assets/maps/light/main_building.svg to 0.01).
Requires: pdfplumber, shapely.  Usage: python tools/extract_rooms.py PDF
"""
import sys, pdfplumber
from shapely.geometry import Polygon, Point

W, H = 1625, 885
TAN = (0.8, 0.63, 0.49)
PINS = {}  # fill from lib/data/gem_map_data.dart: {'mb_r1': (1123, 521, 'Zooba'), ...}

def tf(pt):
    x, y = pt
    return (y * 1.0661, (1080 - x) * 1.0661 - 39.446)

def rooms(pdf_path):
    page = pdfplumber.open(pdf_path).pages[1]
    out = []
    for o in page.curves:
        c = o.get('non_stroking_color')
        if not o.get('fill') or not c or tuple(round(v, 2) for v in c) != TAN or len(o['pts']) < 3:
            continue
        pg = Polygon([tf(t) for t in o['pts']]).buffer(0)
        if 300 < pg.area < 12000:
            out.append(pg)
    return out

if __name__ == '__main__':
    rs = rooms(sys.argv[1])
    for pid, (x, y, name) in PINS.items():
        hit = [g for g in rs if g.contains(Point(x, y))]
        if hit:
            print(pid, min(hit, key=lambda g: g.area).simplify(0.6).wkt)
