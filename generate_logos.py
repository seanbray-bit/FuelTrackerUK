from PIL import Image, ImageDraw, ImageFont
import math

SIZE = 1024

def draw_rounded_rect(draw, xy, radius, fill):
    x0, y0, x1, y1 = xy
    draw.rounded_rectangle(xy, radius=radius, fill=fill)

# ============================================================
# LOGO 1: Fuel Drop + Map Pin (Green gradient feel)
# ============================================================
def logo1():
    img = Image.new('RGB', (SIZE, SIZE), '#1BBF5C')
    draw = ImageDraw.Draw(img)

    # Background gradient effect - darker at bottom
    for y in range(SIZE):
        factor = y / SIZE
        r = int(27 + factor * (-10))
        g = int(191 + factor * (-60))
        b = int(92 + factor * (-20))
        draw.line([(0, y), (SIZE, y)], fill=(max(0,r), max(0,g), max(0,b)))

    draw = ImageDraw.Draw(img)

    # Fuel drop shape (teardrop) - white
    cx, cy = SIZE//2, SIZE//2 - 40
    # Draw teardrop using polygon
    points = []
    # Top point
    points.append((cx, cy - 280))
    # Right curve
    for angle in range(-60, 181, 5):
        rad = math.radians(angle)
        rx = 200
        ry = 200
        x = cx + rx * math.cos(rad)
        y = cy + 80 + ry * math.sin(rad)
        points.append((x, y))
    # Left curve back up
    points.append((cx, cy - 280))

    draw.polygon(points, fill='white')

    # Small map pin dot in center of drop
    draw.ellipse([cx-45, cy+20, cx+45, cy+110], fill='#1BBF5C')

    # Pin point at bottom
    pin_points = [(cx-30, cy+280), (cx+30, cy+280), (cx, cy+340)]
    draw.polygon(pin_points, fill='white')

    img.save('/Users/sb/Desktop/Fuel app/logo_concept_1.png')

# ============================================================
# LOGO 2: Fuel Pump with £ sign
# ============================================================
def logo2():
    img = Image.new('RGB', (SIZE, SIZE), '#0D9B4A')
    draw = ImageDraw.Draw(img)

    # Fuel pump body - white
    # Main body rectangle
    draw_rounded_rect(draw, [300, 250, 620, 700], 30, 'white')

    # Pump screen
    draw_rounded_rect(draw, [340, 300, 580, 430], 15, '#0D9B4A')

    # £ sign on screen
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 120)
    except:
        font = ImageFont.load_default()
    draw.text((420, 310), "£", fill='white', font=font, anchor='mt')

    # Nozzle holder
    draw.rectangle([580, 280, 650, 340], fill='white')

    # Hose - curved line
    draw.arc([600, 200, 780, 400], 270, 90, fill='white', width=20)
    draw.line([(780, 300), (780, 500)], fill='white', width=20)

    # Nozzle
    draw.polygon([(760, 490), (800, 490), (820, 560), (740, 560)], fill='white')
    draw.rectangle([740, 560, 820, 580], fill='white')

    # Base
    draw_rounded_rect(draw, [270, 700, 650, 760], 15, 'white')

    img.save('/Users/sb/Desktop/Fuel app/logo_concept_2.png')

# ============================================================
# LOGO 3: Map Pin with £ symbol
# ============================================================
def logo3():
    img = Image.new('RGB', (SIZE, SIZE), '#FFFFFF')
    draw = ImageDraw.Draw(img)

    # Green circle background
    draw.ellipse([80, 80, SIZE-80, SIZE-80], fill='#22C55E')

    cx, cy = SIZE//2, SIZE//2 - 60

    # Map pin - white circle
    draw.ellipse([cx-180, cy-180, cx+180, cy+180], fill='white')

    # Pin point
    pin_points = [(cx-100, cy+140), (cx+100, cy+140), (cx, cy+340)]
    draw.polygon(pin_points, fill='white')

    # £ symbol in center
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 220)
    except:
        font = ImageFont.load_default()
    draw.text((cx, cy), "£", fill='#22C55E', font=font, anchor='mm')

    img.save('/Users/sb/Desktop/Fuel app/logo_concept_3.png')

# ============================================================
# LOGO 4: Fuel Gauge with £
# ============================================================
def logo4():
    img = Image.new('RGB', (SIZE, SIZE), '#111827')
    draw = ImageDraw.Draw(img)

    cx, cy = SIZE//2, SIZE//2 + 40

    # Outer ring - green
    draw.ellipse([cx-350, cy-350, cx+350, cy+350], fill='#22C55E')
    # Inner circle - dark
    draw.ellipse([cx-300, cy-300, cx+300, cy+300], fill='#111827')

    # Gauge marks
    for i in range(8):
        angle = math.radians(210 - i * 30)
        x1 = cx + 270 * math.cos(angle)
        y1 = cy - 270 * math.sin(angle)
        x2 = cx + 310 * math.cos(angle)
        y2 = cy - 310 * math.sin(angle)
        draw.line([(x1, y1), (x2, y2)], fill='#22C55E', width=8)

    # E and F labels
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 60)
        font_big = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 100)
    except:
        font = ImageFont.load_default()
        font_big = font

    draw.text((cx-200, cy+50), "E", fill='#EF4444', font=font, anchor='mm')
    draw.text((cx+200, cy+50), "F", fill='#22C55E', font=font, anchor='mm')

    # Needle pointing to cheap/full side
    needle_angle = math.radians(330)  # Pointing towards F
    nx = cx + 220 * math.cos(needle_angle)
    ny = cy - 220 * math.sin(needle_angle)
    draw.line([(cx, cy), (nx, ny)], fill='#22C55E', width=12)

    # Center dot
    draw.ellipse([cx-25, cy-25, cx+25, cy+25], fill='#22C55E')

    # £ symbol above center
    draw.text((cx, cy-120), "£", fill='white', font=font_big, anchor='mm')

    img.save('/Users/sb/Desktop/Fuel app/logo_concept_4.png')

# ============================================================
# LOGO 5: Clean fuel drop with location ring
# ============================================================
def logo5():
    img = Image.new('RGB', (SIZE, SIZE), '#16A34A')
    draw = ImageDraw.Draw(img)

    cx, cy = SIZE//2, SIZE//2 - 30

    # Location ring - white circle outline
    draw.ellipse([cx-300, cy-250, cx+300, cy+350], outline='white', width=25)

    # Fuel drop in center
    points = []
    points.append((cx, cy - 220))
    for angle in range(-60, 241, 5):
        rad = math.radians(angle)
        x = cx + 150 * math.cos(rad)
        y = cy + 50 + 150 * math.sin(rad)
        points.append((x, y))
    points.append((cx, cy - 220))
    draw.polygon(points, fill='white')

    # Small green £ inside drop
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 140)
    except:
        font = ImageFont.load_default()
    draw.text((cx, cy+30), "£", fill='#16A34A', font=font, anchor='mm')

    # Location crosshair lines
    draw.line([(cx, cy-310), (cx, cy-270)], fill='white', width=12)
    draw.line([(cx, cy+370), (cx, cy+410)], fill='white', width=12)
    draw.line([(cx-360, cy+50), (cx-320, cy+50)], fill='white', width=12)
    draw.line([(cx+320, cy+50), (cx+360, cy+50)], fill='white', width=12)

    img.save('/Users/sb/Desktop/Fuel app/logo_concept_5.png')

logo1()
logo2()
logo3()
logo4()
logo5()
print("All 5 logos generated!")
