"""Regenerate navigation cells from the four shipped visitor-map SVGs.

Run from the repository root with cairosvg, pillow, numpy and scipy installed.
Perimeters below are traced in a 670-pixel-wide rendering of the GEM digital
visitor map. The publisher's diagrams are schematic and do not show every
door or exhibit clearance. A cell is accepted only if its pixels are clear.
"""
import base64
import io
import math
import re
from pathlib import Path
import xml.etree.ElementTree as ET

import cairosvg
import numpy as np
from PIL import Image, ImageDraw
from scipy.ndimage import label

PERIMETERS = {
    "gem_complex": [(61,377),(65,334),(178,337),(185,330),(185,53),
                    (348,58),(381,65),(399,78),(487,292),(497,317),
                    (494,333),(480,350),(461,365),(191,368),(185,382),(62,382)],
    "main_galleries": [(6,505),(25,433),(99,411),(105,385),(60,400),
                       (80,326),(137,305),(137,293),(27,325),(50,236),
                       (260,147),(268,168),(312,148),(320,119),(610,4),
                       (565,153),(524,168),(490,295),(531,285),(506,380),
                       (406,411),(395,444),(110,514),(119,476)],
}
ENTRANCES = {"gem_complex":(572,920),"main_building":(940,644),
             "main_galleries":(1025,717),"tutankhamun":(499,409)}

def trace(name):
    root = ET.parse(f"assets/maps/light/{name}.svg").getroot()
    w,h = int(root.get("width")),int(root.get("height"))
    group = root.find("{*}g")
    root.remove(root.find("{*}metadata"))
    # White means walking floor and black means blocked. Keep layer order.
    for index,path in enumerate(list(group)):
        if name=="tutankhamun" and index in (177,179,180):
            group.remove(path)  # dotted thematic boundaries on page 4
            continue
        f,s = path.get("fill"),path.get("stroke")
        filled = f and f != "none"
        if name == "main_building":
            floor = f == "#eee9dc"
        elif name == "tutankhamun":
            floor = filled and f != "#c9c8bb"
        elif name == "gem_complex":
            # The campus plan depicts the obelisk plaza in the same gray as
            # building footprints. Identify the plaza by its footprint.
            floor = f == "#eee9dc" or f == "#f5f0e6"
        else:
            floor = False
        if name == "main_galleries" and filled:
            # Small colored shapes mark gallery numbers in the original key.
            if f != "#c9c8bb":
                group.remove(path)
                continue
        if name == "gem_complex" and s == "#f7f1e7":
            path.set("stroke-width","10")  # schematic paths between parcels
        coords=[float(n) for n in re.findall(r"-?[0-9.]+",path.get("d",""))]
        case=max(max(a)-min(a) for a in (coords[::2],coords[1::2]))<115
        if name in ("tutankhamun","main_galleries") and not filled and case and 'Z' in path.get('d','') and s in ("#182025","#c9c8bb","#f7f1e7"):
            filled=True  # closed exhibit cases
        path.set("fill", ("white" if floor else "black") if filled else "none")
        path.set("stroke","white" if name=="gem_complex" and s=="#f7f1e7" else "black" if s else "none")
        if name=="main_building" and s=="#9aa6a4" and not filled:
            path.set("stroke","none")  # floor-color boundaries shown in the visitor guide
    image=Image.open(io.BytesIO(cairosvg.svg2png(bytestring=ET.tostring(root)))).convert("RGBA")
    background=Image.new("RGB",(w,h))
    if name in PERIMETERS:
        ImageDraw.Draw(background).polygon([(x*w/670,y*w/670) for x,y in PERIMETERS[name]], fill="white")
    background.paste(image,mask=image.getchannel("A"))
    if name == "gem_complex":
        # Public entrance plaza, bounded by gardens and the entrance facade.
        ImageDraw.Draw(background).polygon([(x*w/670,y*w/670) for x,y in
            [(218,362),(294,293),(305,295),(312,304),(324,298),(334,300),(310,361)]],fill="white")
    if name=="gem_complex":
        ImageDraw.Draw(background).line([(x*w/670,y*w/670) for x,y in [(215,358),(221,358),(287,299),(294,293),(310,302),(315,301)]],fill="white",width=10)
    pixels=np.asarray(background)[:,:,0] > 175
    if name in PERIMETERS:
        clip=Image.new("1",(w,h))
        ImageDraw.Draw(clip).polygon([(x*w/670,y*w/670) for x,y in PERIMETERS[name]],fill=1)
        pixels &= np.asarray(clip)
    cell=4
    padded=np.pad(pixels,((0,(-h)%cell),(0,(-w)%cell)))
    grid=padded.reshape(math.ceil(h/cell),cell,math.ceil(w/cell),cell).all(axis=(1,3))
    # Only the visitor-connected component can receive a destination. This
    # prevents a pin centered inside an enclosed display from snapping inside.
    labels,_=label(grid)
    x,y=ENTRANCES[name]
    yy,xx=np.nonzero(grid)
    nearest=np.argmin((xx*cell+2-x)**2+(yy*cell+2-y)**2)
    grid=labels==labels[yy[nearest],xx[nearest]]
    data=base64.b64encode(np.packbits(grid,bitorder="little")).decode()
    print(name,grid.sum(),"cells")
    return grid.shape,data

if __name__=="__main__":
    out=["// Generated by tools/trace_walking_floors.py.",
         "const floorMasks = <String, (int, int, String)>{"]
    for name in ENTRANCES:
        (rows,cols),data=trace(name)
        out.append(f"  '{name}': ({cols}, {rows},")
        out.extend(f"    '{data[i:i+100]}'" for i in range(0,len(data),100))
        out.append("  ),")
    Path("lib/data/floor_masks.dart").write_text("\n".join([*out,"};",""]))
