import sys
# Genera assets/icon/app_icon.png (iOS/web) y app_icon_foreground.png (Android
# adaptive). Uso: python3 tool/generate_app_icon.py assets/icon
# y después: dart run flutter_launcher_icons (revertir el project.pbxproj que
# reescribe: bug de la herramienta con la extensión Live Activity).
from PIL import Image, ImageDraw
out = sys.argv[1]
S = 4096  # supersample, final 1024
def rr(d, box, r, fill): d.rounded_rectangle([int(v) for v in box], radius=int(r), fill=fill)

def glyph(scale):
    """Mancuerna + chevron de progreso, blanco sobre transparente, centrado."""
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0)); d = ImageDraw.Draw(img)
    W = (255, 255, 255, 255)
    c = S / 2; u = S * scale / 100  # u = 1% del lienzo * escala
    cy = c + 12 * u
    # barra
    rr(d, (c - 30*u, cy - 3*u, c + 30*u, cy + 3*u), 3*u, W)
    for sgn in (-1, 1):
        # disco grande (interior)
        x0 = c + sgn * 16*u
        rr(d, (min(x0, x0+sgn*8*u), cy - 17*u, max(x0, x0+sgn*8*u), cy + 17*u), 3.2*u, W)
        # disco pequeño (exterior)
        x1 = c + sgn * 25.5*u
        rr(d, (min(x1, x1+sgn*6.5*u), cy - 11*u, max(x1, x1+sgn*6.5*u), cy + 11*u), 2.8*u, W)
    # chevron de progresión
    t = 5.5*u; half = 11*u; drop = 9*u
    for top in (cy - 42*u, cy - 31*u):
        pts = [(c - half, top + drop), (c, top), (c + half, top + drop)]
        d.line(pts, fill=W, width=int(t), joint="curve")
        for p in pts:
            d.ellipse([p[0]-t/2, p[1]-t/2, p[0]+t/2, p[1]+t/2], fill=W)
    return img

# fondo degradado diagonal 0066CC -> 004C99
bg = Image.new("RGB", (S, S)); px = bg.load()
a, b = (0x1A, 0x7A, 0xE0), (0x00, 0x4C, 0x99)
g = Image.new("L", (256, 256)); gp = g.load()
for y in range(256):
    for x in range(256):
        gp[x, y] = (x + y) // 2
grad = g.resize((S, S), Image.BILINEAR)
bg = Image.composite(Image.new("RGB", (S, S), b), Image.new("RGB", (S, S), a), grad)

full = bg.convert("RGBA"); full.alpha_composite(glyph(1.0))
full.convert("RGB").resize((1024, 1024), Image.LANCZOS).save(f"{out}/app_icon.png")
# Android adaptive: flutter_launcher_icons ya aplica un inset del 16%
glyph(1.0).resize((1024, 1024), Image.LANCZOS).save(f"{out}/app_icon_foreground.png")
