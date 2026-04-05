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

# ============================================================
# LOGO A: Price drop arrow + fuel drop - Navy & Orange
# ============================================================
def logo_a():
    img = Image.new('RGB', (SIZE, SIZE), '#1E293B')
    draw = ImageDraw.Draw(img)
    font_sm, font_md, font_lg, font_xl = get_fonts()
    cx, cy = SIZE//2, SIZE//2

    # Large downward arrow - ORANGE = finding deals
    arrow_body = [
        (cx - 70, cy - 300),
        (cx + 70, cy - 300),
        (cx + 70, cy + 30),
        (cx + 210, cy + 30),
        (cx, cy + 300),
        (cx - 210, cy + 30),
        (cx - 70, cy + 30),
    ]
    draw.polygon(arrow_body, fill='#F97316')

    # Fuel drop in the arrow
    drop_points = []
    dcx, dcy = cx, cy - 90
    drop_points.append((dcx, dcy - 150))
    for angle in range(-60, 241, 5):
        rad = math.radians(angle)
        x = dcx + 90 * math.cos(rad)
        y = dcy + 15 + 90 * math.sin(rad)
        drop_points.append((x, y))
    drop_points.append((dcx, dcy - 150))
    draw.polygon(drop_points, fill='white')

    # £ in the drop
    draw.text((dcx, dcy-5), "£", fill='#F97316', font=font_md, anchor='mm')

    img.save('/Users/sb/Desktop/Fuel app/logo_v3_a.png')

# ============================================================
# LOGO B: Shield + fuel pump - Blue & White (trust + protection)
# ============================================================
def logo_b():
    img = Image.new('RGB', (SIZE, SIZE), '#2563EB')
    draw = ImageDraw.Draw(img)
    font_sm, font_md, font_lg, font_xl = get_fonts()
    cx, cy = SIZE//2, SIZE//2

    # Shield shape
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
    draw.polygon(shield_points, fill='white')

    # Fuel pump body
    draw.rounded_rectangle([cx-80, cy-130, cx+60, cy+110], radius=12, fill='#2563EB')
    # Pump screen
    draw.rounded_rectangle([cx-62, cy-105, cx+42, cy-30], radius=6, fill='white')
    # £ on screen
    draw.text((cx-10, cy-67), "£", fill='#2563EB', font=font_sm, anchor='mm')
    # Pump base
    draw.rounded_rectangle([cx-90, cy+110, cx+70, cy+145], radius=6, fill='#2563EB')
    # Nozzle
    draw.arc([cx+40, cy-120, cx+140, cy-20], 270, 45, fill='#2563EB', width=12)
    draw.line([(cx+120, cy-70), (cx+120, cy+20)], fill='#2563EB', width=12)
    draw.polygon([(cx+105, cy+15), (cx+135, cy+15), (cx+145, cy+55), (cx+95, cy+55)], fill='#2563EB')

    img.save('/Users/sb/Desktop/Fuel app/logo_v3_b.png')

# ============================================================
# LOGO C: Hand holding fuel drop - Orange & Dark (helping hand)
# ============================================================
def logo_c():
    img = Image.new('RGB', (SIZE, SIZE), '#F97316')
    draw = ImageDraw.Draw(img)
    font_sm, font_md, font_lg, font_xl = get_fonts()
    cx, cy = SIZE//2, SIZE//2

    # Open hand cupped
    draw.ellipse([cx-210, cy+60, cx+210, cy+320], fill='white')
    # Fingers
    for offset in [-160, -75, 10, 95]:
        fw = 50
        draw.rounded_rectangle([cx+offset, cy-20, cx+offset+fw, cy+160], radius=25, fill='white')
    # Thumb
    draw.rounded_rectangle([cx-225, cy+30, cx-170, cy+220], radius=28, fill='white')

    # Fuel drop falling into hand
    drop_points = []
    dcx, dcy = cx, cy - 130
    drop_points.append((dcx, dcy - 190))
    for angle in range(-60, 241, 5):
        rad = math.radians(angle)
        x = dcx + 110 * math.cos(rad)
        y = dcy + 20 + 110 * math.sin(rad)
        drop_points.append((x, y))
    drop_points.append((dcx, dcy - 190))
    draw.polygon(drop_points, fill='white')

    # £ inside drop
    draw.text((dcx, dcy-5), "£", fill='#F97316', font=font_lg, anchor='mm')

    img.save('/Users/sb/Desktop/Fuel app/logo_v3_c.png')

# ============================================================
# LOGO D: Fuel drop piggy bank - Navy & Gold (saving pennies)
# ============================================================
def logo_d():
    img = Image.new('RGB', (SIZE, SIZE), '#1E293B')
    draw = ImageDraw.Draw(img)
    font_sm, font_md, font_lg, font_xl = get_fonts()
    cx, cy = SIZE//2, SIZE//2 + 20

    # Large fuel drop shape
    drop_points = []
    drop_points.append((cx, cy - 300))
    for angle in range(-60, 241, 5):
        rad = math.radians(angle)
        x = cx + 220 * math.cos(rad)
        y = cy + 60 + 220 * math.sin(rad)
        drop_points.append((x, y))
    drop_points.append((cx, cy - 300))
    draw.polygon(drop_points, fill='#FCD34D')

    # Coin slot
    draw.rounded_rectangle([cx-55, cy-215, cx+55, cy-185], radius=10, fill='#1E293B')

    # £ symbol
    draw.text((cx, cy+20), "£", fill='#1E293B', font=font_xl, anchor='mm')

    # Coins dropping in
    draw.ellipse([cx-20, cy-310, cx+20, cy-275], fill='#F59E0B')
    draw.ellipse([cx+25, cy-355, cx+60, cy-320], fill='#F59E0B')
    draw.ellipse([cx-10, cy-390, cx+20, cy-360], fill='#F59E0B')

    img.save('/Users/sb/Desktop/Fuel app/logo_v3_d.png')

# ============================================================
# LOGO E: Fuel gauge - Red to Blue (struggle to relief)
# ============================================================
def logo_e():
    img = Image.new('RGB', (SIZE, SIZE), '#0F172A')
    draw = ImageDraw.Draw(img)
    font_sm, font_md, font_lg, font_xl = get_fonts()
    cx, cy = SIZE//2, SIZE//2 + 40

    # Outer ring - orange/amber
    draw.ellipse([cx-360, cy-360, cx+360, cy+360], fill='#F97316')
    # Inner circle - dark
    draw.ellipse([cx-310, cy-310, cx+310, cy+310], fill='#0F172A')

    # Gauge marks
    for i in range(8):
        angle = math.radians(210 - i * 30)
        x1 = cx + 280 * math.cos(angle)
        y1 = cy - 280 * math.sin(angle)
        x2 = cx + 320 * math.cos(angle)
        y2 = cy - 320 * math.sin(angle)
        draw.line([(x1, y1), (x2, y2)], fill='#F97316', width=8)

    # E and F labels
    draw.text((cx-210, cy+50), "E", fill='#EF4444', font=font_sm, anchor='mm')
    draw.text((cx+210, cy+50), "F", fill='#3B82F6', font=font_sm, anchor='mm')

    # Needle pointing towards F (savings)
    needle_angle = math.radians(330)
    nx = cx + 230 * math.cos(needle_angle)
    ny = cy - 230 * math.sin(needle_angle)
    draw.line([(cx, cy), (nx, ny)], fill='#F97316', width=14)

    # Center dot
    draw.ellipse([cx-28, cy-28, cx+28, cy+28], fill='#F97316')

    # £ symbol above center
    draw.text((cx, cy-130), "£", fill='white', font=font_lg, anchor='mm')

    img.save('/Users/sb/Desktop/Fuel app/logo_v3_e.png')

logo_a()
logo_b()
logo_c()
logo_d()
logo_e()
print("All 5 v3 logos generated!")
