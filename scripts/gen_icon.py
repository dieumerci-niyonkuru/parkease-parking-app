from PIL import Image, ImageDraw

CANVAS = 1024
# Generous inset so the mark reads as a compact, properly-proportioned app
# icon (roughly the central ~55%) instead of a full-bleed, oversized glyph,
# and stays clear of adaptive-icon mask cropping.
MARGIN = 230
W = H = CANVAS - 2 * MARGIN
OX = OY = MARGIN

def pt(fx, fy):
    return (OX + fx * W, OY + fy * H)

def quad_bezier(p0, p1, p2, steps=60):
    pts = []
    for i in range(steps + 1):
        t = i / steps
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t ** 2 * p2[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t ** 2 * p2[1]
        pts.append((x, y))
    return pts

img = Image.new("RGBA", (CANVAS, CANVAS), (255, 255, 255, 255))
draw = ImageDraw.Draw(img)

# Shadow ellipse
cx, cy = pt(0.5, 0.885)
ew, eh = 0.66 * W, 0.13 * H
draw.ellipse([cx - ew / 2, cy - eh / 2, cx + ew / 2, cy + eh / 2], fill=(74, 74, 74, 217))

# Cone (brown triangle with curved base)
apex = pt(0.5, 0.02)
right = pt(0.82, 0.80)
ctrl = pt(0.5, 0.855)
left = pt(0.18, 0.80)
base_curve = quad_bezier(right, ctrl, left)
cone_pts = [apex, right] + base_curve[1:] + [apex]
draw.polygon(cone_pts, fill=(122, 91, 64, 255))

# White gap stroke near the base — build a filled band (top/bottom offset
# curves) instead of a wide polyline, since PIL's line joints look jagged
# on curved multi-segment paths.
g0 = pt(0.20, 0.795)
g1 = pt(0.5, 0.845)
g2 = pt(0.80, 0.795)
gap_pts = quad_bezier(g0, g1, g2, steps=100)
stroke_w = 0.05 * H
top = [(x, y - stroke_w / 2) for x, y in gap_pts]
bottom = [(x, y + stroke_w / 2) for x, y in gap_pts]
band = top + bottom[::-1]
draw.polygon(band, fill=(255, 255, 255, 255))
r = stroke_w / 2
for p in (gap_pts[0], gap_pts[-1]):
    draw.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=(255, 255, 255, 255))

img.save(r"C:\Users\Merci\Downloads\itec_parking_fixed_2\itec_parking_fixed\assets\icon\icon.png")
print("saved")
