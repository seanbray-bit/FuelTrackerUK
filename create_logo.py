from PIL import Image, ImageDraw, ImageFont
import math

size = 1024
img = Image.new('RGB', (size, size), 'white')
draw = ImageDraw.Draw(img)

# Draw 4 fuel nozzles side by side like the photo
# Each nozzle: handle at top, hose coming down, nozzle tip

nozzle_colors = ['#000000', '#333333', '#000000', '#333333']
nozzle_width = 180
start_x = 80
gap = 30

for i in range(4):
    x = start_x + i * (nozzle_width + gap)
    
    # Nozzle holder/cradle at top
    draw.rectangle([x + 40, 120, x + 140, 160], fill='#1a1a1a', outline='black', width=2)
    
    # Handle grip - thick rectangle
    handle_x = x + 50
    draw.rectangle([handle_x, 160, handle_x + 80, 340], fill=nozzle_colors[i], outline='black', width=3)
    
    # Grip texture lines
    for ly in range(180, 330, 20):
        draw.line([(handle_x + 10, ly), (handle_x + 70, ly)], fill='#666666', width=2)
    
    # Trigger/lever
    draw.rectangle([handle_x - 15, 250, handle_x, 310], fill='#222222', outline='black', width=2)
    
    # Nozzle body - angled downward
    # Main barrel
    draw.rectangle([handle_x + 20, 340, handle_x + 60, 500], fill=nozzle_colors[i], outline='black', width=3)
    
    # Nozzle tip - tapered
    points = [
        (handle_x + 15, 500),
        (handle_x + 65, 500),
        (handle_x + 55, 620),
        (handle_x + 25, 620)
    ]
    draw.polygon(points, fill=nozzle_colors[i], outline='black', width=3)
    
    # Drip guard / boot at tip
    draw.ellipse([handle_x + 10, 600, handle_x + 70, 640], fill='#111111', outline='black', width=2)
    
    # Hose coming from top - thick curved line
    for t in range(8):
        hx = x + 90 + t * 3
        hy = 80 + t * 5
        draw.ellipse([hx - 8, hy - 8, hx + 8, hy + 8], fill='#222222')

# Add "FUEL TRACKER" text at bottom
try:
    font_large = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 72)
    font_small = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 48)
except:
    font_large = ImageFont.load_default()
    font_small = ImageFont.load_default()

# Bottom section - dark bar with white text
draw.rectangle([0, 750, 1024, 1024], fill='black')

# FUEL TRACKER
bbox = draw.textbbox((0, 0), "FUEL TRACKER", font=font_large)
tw = bbox[2] - bbox[0]
draw.text(((size - tw) // 2, 770), "FUEL TRACKER", fill='white', font=font_large)

# UK
bbox2 = draw.textbbox((0, 0), "UK", font=font_large)
tw2 = bbox2[2] - bbox2[0]
draw.text(((size - tw2) // 2, 860), "UK", fill='white', font=font_large)

# Add fuel type labels on nozzles
labels = ["UNL", "SUP", "DSL", "PRE"]
try:
    label_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 24)
except:
    label_font = ImageFont.load_default()

for i, label in enumerate(labels):
    x = start_x + i * (nozzle_width + gap)
    handle_x = x + 50
    # Small label on handle
    lbbox = draw.textbbox((0, 0), label, font=label_font)
    lw = lbbox[2] - lbbox[0]
    draw.text((handle_x + 40 - lw // 2, 200), label, fill='white', font=label_font)

img.save("/Users/sb/Desktop/Fuel app/logo_nozzles.png", "PNG")
print("Done - saved logo_nozzles.png")
