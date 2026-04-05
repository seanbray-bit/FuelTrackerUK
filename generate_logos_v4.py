from PIL import Image, ImageDraw, ImageFont
import math

SIZE = 1024

def get_fonts():
    try:
        font_sm = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 50)
        font_md = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 80)
        font_lg = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 140)
        font_xl = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 200)
        return font_sm, font_md, font_lg, font_xl
    except:
        f = ImageFont.load_default()
        return f, f, f, f

BLK = '#111111'
WHT = '#FFFFFF'
LGRY = '#CCCCCC'
DGRY = '#333333'

def draw_uk_outline(draw, cx, cy, scale=1.0, fill=WHT):
    """Simplified UK map outline"""
    # Great Britain simplified shape
    raw_points = [
        # Scotland top
        (0, -400), (30, -380), (60, -350), (40, -320),
        (70, -300), (50, -270), (80, -250),
        # East scotland
        (60, -220), (80, -190), (70, -160),
        # England east coast
        (90, -130), (100, -100), (110, -60),
        (120, -20), (100, 20), (110, 60),
        (130, 100), (120, 140), (100, 170),
        # South east
        (110, 200), (80, 230), (60, 250),
        # South coast
        (30, 260), (0, 250), (-30, 270),
        (-60, 260), (-80, 240),
        # South west / Cornwall
        (-120, 250), (-140, 230), (-130, 200),
        (-100, 180),
        # Wales
        (-120, 150), (-140, 120), (-130, 80),
        (-120, 40), (-140, 0),
        # West england
        (-120, -40), (-100, -80),
        # West scotland
        (-110, -120), (-100, -160), (-120, -200),
        (-100, -240), (-80, -280),
        (-60, -320), (-40, -360), (-20, -390),
        (0, -400),
    ]
    points = [(cx + x * scale, cy + y * scale) for x, y in raw_points]
    draw.polygon(points, fill=fill)

def draw_nozzle(draw, cx, cy, scale=1.0, fill=WHT, bg=BLK):
    """Petrol nozzle - handle + trigger + spout"""
    s = scale
    # Handle grip (vertical bar)
    draw.rounded_rectangle([cx - 30*s, cy - 180*s, cx + 30*s, cy + 40*s], radius=int(15*s), fill=fill)

    # Trigger guard
    draw.rounded_rectangle([cx - 80*s, cy - 40*s, cx - 20*s, cy + 10*s], radius=int(8*s), fill=fill)

    # Trigger
    draw.rounded_rectangle([cx - 70*s, cy - 20*s, cx - 30*s, cy + 40*s], radius=int(5*s), fill=fill)

    # Nozzle body (angled spout going down-left)
    spout_points = [
        (cx - 20*s, cy + 20*s),
        (cx + 20*s, cy + 20*s),
        (cx + 10*s, cy + 180*s),
        (cx - 10*s, cy + 180*s),
    ]
    draw.polygon(spout_points, fill=fill)

    # Nozzle tip
    draw.rounded_rectangle([cx - 18*s, cy + 170*s, cx + 18*s, cy + 220*s], radius=int(5*s), fill=fill)

    # Drip from nozzle
    drop_points = []
    dcx, dcy = cx, cy + 270*s
    drop_points.append((dcx, dcy - 30*s))
    for angle in range(-60, 241, 10):
        rad = math.radians(angle)
        x = dcx + 18*s * math.cos(rad)
        y = dcy + 5*s + 18*s * math.sin(rad)
        drop_points.append((x, y))
    drop_points.append((dcx, dcy - 30*s))
    draw.polygon(drop_points, fill=fill)


# ============================================================
# LOGO 1: UK map with nozzle overlaid - Black bg
# ============================================================
def logo1():
    img = Image.new('RGB', (SIZE, SIZE), BLK)
    draw = ImageDraw.Draw(img)
    font_sm, font_md, font_lg, font_xl = get_fonts()
    cx, cy = SIZE//2, SIZE//2

    # UK outline - large, centered
    draw_uk_outline(draw, cx - 20, cy - 20, scale=1.1, fill=WHT)

    # Nozzle overlaid on top right of UK
    draw_nozzle(draw, cx + 60, cy - 30, scale=0.7, fill=BLK, bg=WHT)

    img.save('/Users/sb/Desktop/Fuel app/logo_v4_1.png')

# ============================================================
# LOGO 2: UK map with nozzle overlaid - White bg
# ============================================================
def logo2():
    img = Image.new('RGB', (SIZE, SIZE), WHT)
    draw = ImageDraw.Draw(img)
    font_sm, font_md, font_lg, font_xl = get_fonts()
    cx, cy = SIZE//2, SIZE//2

    # UK outline
    draw_uk_outline(draw, cx - 20, cy - 20, scale=1.1, fill=BLK)

    # Nozzle overlaid
    draw_nozzle(draw, cx + 60, cy - 30, scale=0.7, fill=WHT, bg=BLK)

    img.save('/Users/sb/Desktop/Fuel app/logo_v4_2.png')

# ============================================================
# LOGO 3: Circle badge - UK inside, nozzle crossing over
# ============================================================
def logo3():
    img = Image.new('RGB', (SIZE, SIZE), BLK)
    draw = ImageDraw.Draw(img)
    font_sm, font_md, font_lg, font_xl = get_fonts()
    cx, cy = SIZE//2, SIZE//2

    # White circle
    draw.ellipse([cx - 380, cy - 380, cx + 380, cy + 380], fill=WHT)
    # Black inner circle
    draw.ellipse([cx - 340, cy - 340, cx + 340, cy + 340], fill=BLK)

    # UK outline inside circle
    draw_uk_outline(draw, cx - 30, cy, scale=0.75, fill=WHT)

    # Nozzle across the right side
    draw_nozzle(draw, cx + 100, cy - 20, scale=0.6, fill=BLK)
    # Redraw nozzle in white on the outer ring area

    img.save('/Users/sb/Desktop/Fuel app/logo_v4_3.png')

# ============================================================
# LOGO 4: Nozzle forming the shape pointing down into UK
# ============================================================
def logo4():
    img = Image.new('RGB', (SIZE, SIZE), BLK)
    draw = ImageDraw.Draw(img)
    font_sm, font_md, font_lg, font_xl = get_fonts()
    cx, cy = SIZE//2, SIZE//2

    # UK outline - bottom half
    draw_uk_outline(draw, cx, cy + 120, scale=0.8, fill=DGRY)

    # Large nozzle in foreground - white
    # Handle at top
    draw.rounded_rectangle([cx - 40, cy - 380, cx + 40, cy - 80], radius=20, fill=WHT)

    # Nozzle housing
    draw.rounded_rectangle([cx - 60, cy - 100, cx + 60, cy - 40], radius=10, fill=WHT)

    # Trigger
    draw.rounded_rectangle([cx - 100, cy - 120, cx - 50, cy - 50], radius=8, fill=WHT)

    # Spout going down
    spout = [
        (cx - 25, cy - 50),
        (cx + 25, cy - 50),
        (cx + 15, cy + 140),
        (cx - 15, cy + 140),
    ]
    draw.polygon(spout, fill=WHT)

    # Nozzle tip
    draw.rounded_rectangle([cx - 22, cy + 130, cx + 22, cy + 190], radius=6, fill=WHT)

    # Drip - fuel drop
    drop_points = []
    dcx, dcy = cx, cy + 250
    drop_points.append((dcx, dcy - 40))
    for angle in range(-60, 241, 10):
        rad = math.radians(angle)
        x = dcx + 25 * math.cos(rad)
        y = dcy + 8 + 25 * math.sin(rad)
        drop_points.append((x, y))
    drop_points.append((dcx, dcy - 40))
    draw.polygon(drop_points, fill=WHT)

    # £ in the drip
    draw.text((dcx, dcy + 2), "£", fill=BLK, font=font_sm, anchor='mm')

    img.save('/Users/sb/Desktop/Fuel app/logo_v4_4.png')

# ============================================================
# LOGO 5: Split design - UK left, Nozzle right, £ center
# ============================================================
def logo5():
    img = Image.new('RGB', (SIZE, SIZE), WHT)
    draw = ImageDraw.Draw(img)
    font_sm, font_md, font_lg, font_xl = get_fonts()
    cx, cy = SIZE//2, SIZE//2

    # Left half black
    draw.rectangle([0, 0, SIZE//2, SIZE], fill=BLK)

    # UK on left side (white on black)
    draw_uk_outline(draw, cx - 200, cy, scale=0.65, fill=WHT)

    # Nozzle on right side (black on white)
    # Handle
    draw.rounded_rectangle([cx + 160, cy - 280, cx + 220, cy + 0], radius=15, fill=BLK)
    # Housing
    draw.rounded_rectangle([cx + 140, cy - 20, cx + 240, cy + 30], radius=8, fill=BLK)
    # Trigger
    draw.rounded_rectangle([cx + 100, cy - 40, cx + 150, cy + 20], radius=6, fill=BLK)
    # Spout
    spout = [
        (cx + 170, cy + 20),
        (cx + 210, cy + 20),
        (cx + 200, cy + 180),
        (cx + 180, cy + 180),
    ]
    draw.polygon(spout, fill=BLK)
    # Tip
    draw.rounded_rectangle([cx + 172, cy + 170, cx + 208, cy + 220], radius=5, fill=BLK)
    # Drip
    drop_points = []
    dcx, dcy = cx + 190, cy + 275
    drop_points.append((dcx, dcy - 35))
    for angle in range(-60, 241, 10):
        rad = math.radians(angle)
        x = dcx + 20 * math.cos(rad)
        y = dcy + 5 + 20 * math.sin(rad)
        drop_points.append((x, y))
    drop_points.append((dcx, dcy - 35))
    draw.polygon(drop_points, fill=BLK)

    # £ symbol spanning the center divide
    draw.text((cx, cy), "£", fill=LGRY, font=font_xl, anchor='mm')

    img.save('/Users/sb/Desktop/Fuel app/logo_v4_5.png')

logo1()
logo2()
logo3()
logo4()
logo5()
print("All 5 UK+Nozzle B&W logos generated!")
