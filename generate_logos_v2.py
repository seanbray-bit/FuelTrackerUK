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
# LOGO A: Hand catching a fuel drop - "We've got you"
# ============================================================
def logo_a():
    img = Image.new('RGB', (SIZE, SIZE), '#16A34A')
    draw = ImageDraw.Draw(img)
    font_sm, font_md, font_lg, font_xl = get_fonts()

    cx, cy = SIZE//2, SIZE//2

    # Open hand (cupped) - bottom half
    # Palm
    draw.ellipse([cx-200, cy+50, cx+200, cy+300], fill='white')
    # Fingers - curved up
    for i, offset in enumerate([-150, -70, 10, 90]):
        fw = 45
        draw.rounded_rectangle([cx+offset, cy-30, cx+offset+fw, cy+150], radius=22, fill='white')
    # Thumb
    draw.rounded_rectangle([cx-210, cy+20, cx-160, cy+200], radius=25, fill='white')

    # Fuel drop falling into hand
    drop_points = []
    dcx, dcy = cx, cy - 120
    drop_points.append((dcx, dcy - 180))
    for angle in range(-60, 241, 5):
        rad = math.radians(angle)
        x = dcx + 100 * math.cos(rad)
        y = dcy + 20 + 100 * math.sin(rad)
        drop_points.append((x, y))
    drop_points.append((dcx, dcy - 180))
    draw.polygon(drop_points, fill='white')

    # £ inside drop
    draw.text((dcx, dcy), "£", fill='#16A34A', font=font_md, anchor='mm')

    # Small downward arrow showing price dropping
    arr_x = cx + 250
    arr_y = cy - 50
    draw.line([(arr_x, arr_y-80), (arr_x, arr_y+80)], fill='white', width=14)
    draw.polygon([(arr_x-35, arr_y+50), (arr_x+35, arr_y+50), (arr_x, arr_y+110)], fill='white')

    img.save('/Users/sb/Desktop/Fuel app/logo_v2_a.png')

# ============================================================
# LOGO B: Fuel drop as piggy bank - saving money on fuel
# ============================================================
def logo_b():
    img = Image.new('RGB', (SIZE, SIZE), '#0F766E')
    draw = ImageDraw.Draw(img)
    font_sm, font_md, font_lg, font_xl = get_fonts()

    cx, cy = SIZE//2, SIZE//2

    # Large fuel drop shape
    drop_points = []
    drop_points.append((cx, cy - 280))
    for angle in range(-60, 241, 5):
        rad = math.radians(angle)
        x = cx + 200 * math.cos(rad)
        y = cy + 60 + 200 * math.sin(rad)
        drop_points.append((x, y))
    drop_points.append((cx, cy - 280))
    draw.polygon(drop_points, fill='white')

    # Coin slot on top of drop
    draw.rounded_rectangle([cx-50, cy-200, cx+50, cy-175], radius=8, fill='#0F766E')

    # £ symbol - big and bold
    draw.text((cx, cy+20), "£", fill='#0F766E', font=font_xl, anchor='mm')

    # Small coins falling in from top
    draw.ellipse([cx-15, cy-290, cx+15, cy-260], fill='#FCD34D')
    draw.ellipse([cx+20, cy-330, cx+50, cy-300], fill='#FCD34D', outline='#F59E0B', width=2)

    img.save('/Users/sb/Desktop/Fuel app/logo_v2_b.png')

# ============================================================
# LOGO C: Shield protecting £ from high prices - arrow bouncing off
# ============================================================
def logo_c():
    img = Image.new('RGB', (SIZE, SIZE), '#DC2626')
    draw = ImageDraw.Draw(img)
    font_sm, font_md, font_lg, font_xl = get_fonts()

    cx, cy = SIZE//2, SIZE//2

    # Background - gradient from red (expensive) to green (saving)
    for y in range(SIZE):
        factor = y / SIZE
        r = int(220 - factor * 200)
        g = int(38 + factor * 155)
        b = int(38 + factor * 60)
        draw.line([(0, y), (SIZE, y)], fill=(r, g, b))

    draw = ImageDraw.Draw(img)

    # Shield shape
    shield_points = [
        (cx, cy - 280),      # top
        (cx + 220, cy - 180), # top right
        (cx + 220, cy + 50),  # mid right
        (cx + 140, cy + 180), # lower right
        (cx, cy + 280),       # bottom point
        (cx - 140, cy + 180), # lower left
        (cx - 220, cy + 50),  # mid left
        (cx - 220, cy - 180), # top left
    ]
    draw.polygon(shield_points, fill='white')

    # Fuel pump icon inside shield
    # Pump body
    draw.rounded_rectangle([cx-70, cy-120, cx+50, cy+100], radius=10, fill='#16A34A')
    # Pump screen
    draw.rounded_rectangle([cx-55, cy-95, cx+35, cy-30], radius=5, fill='white')
    # Pump base
    draw.rounded_rectangle([cx-80, cy+100, cx+60, cy+130], radius=5, fill='#16A34A')
    # Nozzle
    draw.arc([cx+30, cy-110, cx+120, cy-20], 270, 45, fill='#16A34A', width=10)
    draw.line([(cx+105, cy-65), (cx+105, cy+10)], fill='#16A34A', width=10)

    # £ on pump screen
    draw.text((cx-10, cy-62), "£", fill='#16A34A', font=font_sm, anchor='mm')

    img.save('/Users/sb/Desktop/Fuel app/logo_v2_c.png')

# ============================================================
# LOGO D: Downward price arrow with fuel drop - prices coming down
# ============================================================
def logo_d():
    img = Image.new('RGB', (SIZE, SIZE), '#1E293B')
    draw = ImageDraw.Draw(img)
    font_sm, font_md, font_lg, font_xl = get_fonts()

    cx, cy = SIZE//2, SIZE//2

    # Large downward arrow - GREEN = savings
    arrow_body = [
        (cx - 60, cy - 300),
        (cx + 60, cy - 300),
        (cx + 60, cy + 50),
        (cx + 200, cy + 50),
        (cx, cy + 300),
        (cx - 200, cy + 50),
        (cx - 60, cy + 50),
    ]
    draw.polygon(arrow_body, fill='#22C55E')

    # Fuel drop cutout/overlay in the arrow
    drop_points = []
    dcx, dcy = cx, cy - 80
    drop_points.append((dcx, dcy - 140))
    for angle in range(-60, 241, 5):
        rad = math.radians(angle)
        x = dcx + 80 * math.cos(rad)
        y = dcy + 10 + 80 * math.sin(rad)
        drop_points.append((x, y))
    drop_points.append((dcx, dcy - 140))
    draw.polygon(drop_points, fill='white')

    # £ in the drop
    draw.text((dcx, dcy-10), "£", fill='#22C55E', font=font_md, anchor='mm')

    img.save('/Users/sb/Desktop/Fuel app/logo_v2_d.png')

# ============================================================
# LOGO E: Life ring around fuel drop - rescue from fuel costs
# ============================================================
def logo_e():
    img = Image.new('RGB', (SIZE, SIZE), '#1D4ED8')
    draw = ImageDraw.Draw(img)
    font_sm, font_md, font_lg, font_xl = get_fonts()

    cx, cy = SIZE//2, SIZE//2

    # Life ring (alternating green and white segments)
    # Outer ring
    draw.ellipse([cx-350, cy-350, cx+350, cy+350], fill='#22C55E')
    # White segments
    for angle in [0, 90, 180, 270]:
        rad = math.radians(angle)
        for r in range(280, 351):
            for a in range(angle-20, angle+21):
                ar = math.radians(a)
                x = cx + r * math.cos(ar)
                y = cy + r * math.sin(ar)
                if 0 <= x < SIZE and 0 <= y < SIZE:
                    draw.point((x, y), fill='white')

    # Inner cutout
    draw.ellipse([cx-250, cy-250, cx+250, cy+250], fill='#1D4ED8')

    # Fuel drop in center
    drop_points = []
    drop_points.append((cx, cy - 200))
    for angle in range(-60, 241, 5):
        rad = math.radians(angle)
        x = cx + 130 * math.cos(rad)
        y = cy + 30 + 130 * math.sin(rad)
        drop_points.append((x, y))
    drop_points.append((cx, cy - 200))
    draw.polygon(drop_points, fill='white')

    # £ in drop
    draw.text((cx, cy), "£", fill='#1D4ED8', font=font_lg, anchor='mm')

    # Rope lines on ring
    draw.line([(cx-340, cy-100), (cx-260, cy-60)], fill='#FCD34D', width=12)
    draw.line([(cx+260, cy-60), (cx+340, cy-100)], fill='#FCD34D', width=12)
    draw.line([(cx-340, cy+100), (cx-260, cy+60)], fill='#FCD34D', width=12)
    draw.line([(cx+260, cy+60), (cx+340, cy+100)], fill='#FCD34D', width=12)

    img.save('/Users/sb/Desktop/Fuel app/logo_v2_e.png')

logo_a()
logo_b()
logo_c()
logo_d()
logo_e()
print("All 5 v2 logos generated!")
