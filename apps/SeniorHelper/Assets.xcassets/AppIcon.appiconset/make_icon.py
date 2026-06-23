"""Generate SeniorHelper 1024x1024 AppIcon (RGB, no alpha)."""
import math
from PIL import Image, ImageDraw

S = 1024
SS = 4            # supersample factor for smooth edges
W = S * SS

img = Image.new("RGB", (W, W))
px = img.load()

# --- Warm teal vertical gradient background ---
# top lighter, bottom deeper, around #2A9D8F
top = (58, 184, 165)     # #3AB8A5
bot = (30, 122, 110)     # #1E7A6E
for y in range(W):
    t = y / (W - 1)
    r = round(top[0] + (bot[0] - top[0]) * t)
    g = round(top[1] + (bot[1] - top[1]) * t)
    b = round(top[2] + (bot[2] - top[2]) * t)
    for x in range(W):
        px[x, y] = (r, g, b)

draw = ImageDraw.Draw(img)

WHITE = (255, 255, 255)
cx, cy = W * 0.43, W * 0.40          # lens center, offset up-left
ring_r = W * 0.20                    # ring outer radius
ring_w = W * 0.055                   # ring stroke width

# --- Handle (rounded thick line from ring toward bottom-right) ---
ang = math.radians(45)
h_start = (cx + math.cos(ang) * (ring_r - ring_w * 0.2),
           cy + math.sin(ang) * (ring_r - ring_w * 0.2))
h_end = (cx + math.cos(ang) * (ring_r + W * 0.20),
         cy + math.sin(ang) * (ring_r + W * 0.20))
draw.line([h_start, h_end], fill=WHITE, width=int(W * 0.072))
# rounded cap
hr = W * 0.036
draw.ellipse([h_end[0] - hr, h_end[1] - hr, h_end[0] + hr, h_end[1] + hr], fill=WHITE)

# --- Lens ring (white outer ring, gradient-colored glass center) ---
draw.ellipse([cx - ring_r, cy - ring_r, cx + ring_r, cy + ring_r], fill=WHITE)
inner_r = ring_r - ring_w
# Fill glass with a subtle lighter tint of the background
gl = (235, 250, 247)
draw.ellipse([cx - inner_r, cy - inner_r, cx + inner_r, cy + inner_r], fill=gl)

# --- Glass highlight (a soft white arc/shine) ---
sh_r = inner_r * 0.62
sx, sy = cx - inner_r * 0.33, cy - inner_r * 0.33
draw.ellipse([sx - sh_r, sy - sh_r, sx + sh_r, sy + sh_r], fill=WHITE)
# re-cut to leave a crescent: overlay glass-colored circle slightly offset
co_r = sh_r * 0.86
ox, oy = sx + sh_r * 0.30, sy + sh_r * 0.30
draw.ellipse([ox - co_r, oy - co_r, ox + co_r, oy + co_r], fill=gl)

# downscale (antialias) and save as RGB, no alpha
out = img.resize((S, S), Image.LANCZOS)
out.save("AppIcon-1024.png", "PNG")

# verify mode
chk = Image.open("AppIcon-1024.png")
print("saved", chk.size, chk.mode)
