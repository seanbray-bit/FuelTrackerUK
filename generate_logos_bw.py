from PIL import Image, ImageDraw, ImageFont
import math

SIZE = 1024

def get_fonts():
    try:
        font_sm = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 60)
        font_md = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 100)
        font_lg = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 160)
        font_xl = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 220)
        return font_sm, font_md, font_lg, font_xl
    except:
        f = ImageFont.load_default()
        return f, f, f, f

BLK = '#111111'
WHT = '#FFFFFF'
GRY = '#888888'

# ============================================================
# A: Price drop arrow + fuel drop - Black bg, white icon
# ============================================================
def logo_a():
    img = Image.new('RGB', (SIZE, SIZE), BLK)
    draw = ImageDraw.Draw(img)
    _, font_md, _, _ = get_fonts()
    cx, cy = SIZE//2, SIZE//2

    arrow_body = [
        (cx - 70, cy - 300),
        (cx + 70, cy - 300),
        (cx + 70, cy + 30),
        (cx + 210, cy + 30),
        (cx, cy + 300),
        (cx - 210, cy + 30),
        (cx - 70, cy + 30),
    ]
    draw.polygon(arrow_body, fill=WHT)

    drop_points = []
    dcx, dcy = cx, cy - 90
    drop_points.append((dcx, dcy - 150))
    for angle in range(-60, 241, 5):
        rad = math.radians(angle)
        x = dcx + 90 * math.cos(rad)
        y = dcy + 15 + 90 * math.sin(rad)
        drop_points.append((x, y))
    drop_points.append((dcx, dcy - 150))
    draw.polygon(drop_points, fill=BLK)

    draw.text((dcx, dcy - 5), "£", fill=WHT, font=font_md, anchor='mm')

    img.save('/Users/sb/Desktop/Fuel app/logo_bw_a.png')

# ============================================================
# B: Shield + fuel pump - White bg, black icon
# ============================================================
def logo_b():
    img = Image.new('RGB', (SIZE, SIZE), WHT)
    draw = ImageDraw.Draw(img)
    font_sm, _, _, _ = get_fonts()
    cx, cy = SIZE//2, SIZE//2

    shield_points = [
        (cx, cy - 300),
        (cx + 240, cy - 190),
        (cx + 240, cy + 60),
        (cx + 150, cy + 200),
        (cx, cy + 300),
        (cx - 150, cy + 200),
        (cx - 240, cy + 60),
        (cx - 240, cy - 190),
    ]
    draw.polygon(shield_points, fill=BLK)

    draw.rounded_rectangle([cx - 80, cy - 130, cx + 60, cy + 110], radius=12, fill=WHT)
    draw.rounded_rectangle([cx - 62, cy - 105, cx + 42, cy - 30], radius=6, fill=BLK)
    draw.text((cx - 10, cy - 67), "£", fill=WHT, font=font_sm, anchor='mm')
    draw.rounded_rectangle([cx - 90, cy + 110, cx + 70, cy + 145], radius=6, fill=WHT)
    draw.arc([cx + 40, cy - 120, cx + 140, cy - 20], 270, 45, fill=WHT, width=12)
    draw.line([(cx + 120, cy - 70), (cx + 120, cy + 20)], fill=WHT, width=12)
    draw.polygon([(cx + 105, cy + 15), (cx + 135, cy + 15), (cx + 145, cy + 55), (cx + 95, cy + 55)], fill=WHT)

    img.save('/Users/sb/Desktop/Fuel app/logo_bw_b.png')

# ============================================================
# C: Hand catching fuel drop - Black bg, white icon
# ============================================================
def logo_c():
    img = Image.new('RGB', (SIZE, SIZE), BLK)
    draw = ImageDraw.Draw(img)
    _, _, font_lg, _ = get_fonts()
    cx, cy = SIZE//2, SIZE//2

    draw.ellipse([cx - 210, cy + 60, cx + 210, cy + 320], fill=WHT)
    for offset in [-160, -75, 10, 95]:
        fw = 50
        draw.rounded_rectangle([cx + offset, cy - 20, cx + offset + fw, cy + 160], radius=25, fill=WHT)
    draw.rounded_rectangle([cx - 225, cy + 30, cx - 170, cy + 220], radius=28, fill=WHT)

    drop_points = []
    dcx, dcy = cx, cy - 130
    drop_points.append((dcx, dcy - 190))
    for angle in range(-60, 241, 5):
        rad = math.radians(angle)
        x = dcx + 110 * math.cos(rad)
        y = dcy + 20 + 110 * math.sin(rad)
        drop_points.append((x, y))
    drop_points.append((dcx, dcy - 190))
    draw.polygon(drop_points, fill=WHT)

    draw.text((dcx, dcy - 5), "£", fill=BLK, font=font_lg, anchor='mm')

    img.save('/Users/sb/Desktop/Fuel app/logo_bw_c.png')

# ============================================================
# D: Fuel drop piggy bank - Black bg, white drop
# ============================================================
def logo_d():
    img = Image.new('RGB', (SIZE, SIZE), BLK)
    draw = ImageDraw.Draw(img)
    _, _, _, font_xl = get_fonts()
    cx, cy = SIZE//2, SIZE//2 + 20

    drop_points = []
    drop_points.append((cx, cy - 300))
    for angle in range(-60, 241, 5):
        rad = math.radians(angle)
        x = cx + 220 * math.cos(rad)
        y = cy + 60 + 220 * math.sin(rad)
        drop_points.append((x, y))
    drop_points.append((cx, cy - 300))
    draw.polygon(drop_points, fill=WHT)

    draw.rounded_rectangle([cx - 55, cy - 215, cx + 55, cy - 185], radius=10, fill=BLK)

    draw.text((cx, cy + 20), "£", fill=BLK, font=font_xl, anchor='mm')

    draw.ellipse([cx - 20, cy - 310, cx + 20, cy - 275], fill=WHT)
    draw.ellipse([cx + 25, cy - 355, cx + 60, cy - 320], fill=WHT)
    draw.ellipse([cx - 10, cy - 390, cx + 20, cy - 360], fill=WHT)

    img.save('/Users/sb/Desktop/Fuel app/logo_bw_d.png')

# ============================================================
# E: Fuel gauge - Black bg, white gauge
# ============================================================
def logo_e():
    img = Image.new('RGB', (SIZE, SIZE), BLK)
    draw = ImageDraw.Draw(img)
    font_sm, _, font_lg, _ = get_fonts()
    cx, cy = SIZE//2, SIZE//2 + 40

    draw.ellipse([cx - 360, cy - 360, cx + 360, cy + 360], fill=WHT)
    draw.ellipse([cx - 310, cy - 310, cx + 310, cy + 310], fill=BLK)

    for i in range(8):
        angle = math.radians(210 - i * 30)
        x1 = cx + 280 * math.cos(angle)
        y1 = cy - 280 * math.sin(angle)
        x2 = cx + 320 * math.cos(angle)
        y2 = cy - 320 * math.sin(angle)
        draw.line([(x1, y1), (x2, y2)], fill=WHT, width=8)

    draw.text((cx - 210, cy + 50), "E", fill=GRY, font=font_sm, anchor='mm')
    draw.text((cx + 210, cy + 50), "F", fill=WHT, font=font_sm, anchor='mm')

    needle_angle = math.radians(330)
    nx = cx + 230 * math.cos(needle_angle)
    ny = cy - 230 * math.sin(needle_angle)
    draw.line([(cx, cy), (nx, ny)], fill=WHT, width=14)

    draw.ellipse([cx - 28, cy - 28, cx + 28, cy + 28], fill=WHT)

    draw.text((cx, cy - 130), "£", fill=WHT, font=font_lg, anchor='mm')

    img.save('/Users/sb/Desktop/Fuel app/logo_bw_e.png')

logo_a()
logo_b()
logo_c()
logo_d()
logo_e()
print("All 5 B&W logos generated!")
