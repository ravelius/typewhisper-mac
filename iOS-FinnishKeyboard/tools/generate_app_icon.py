"""Create the iOS App Store icon without depending on a design service."""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

SIZE = 1024
root = Path(__file__).resolve().parents[1]
destination = root / "App/Assets.xcassets/AppIcon.appiconset/AppIcon.png"

image = Image.new("RGB", (SIZE, SIZE))
pixels = image.load()
for y in range(SIZE):
    for x in range(SIZE):
        t = (x + y) / (2 * (SIZE - 1))
        pixels[x, y] = (
            round(18 + 15 * t),
            round(49 + 91 * t),
            round(132 + 42 * t),
        )

shadow = Image.new("RGBA", (SIZE, SIZE))
draw = ImageDraw.Draw(shadow)
draw.rounded_rectangle((190, 195, 834, 839), radius=145, fill=(0, 13, 67, 80))
shadow = shadow.filter(ImageFilter.GaussianBlur(35))
image = Image.alpha_composite(image.convert("RGBA"), shadow)

draw = ImageDraw.Draw(image)
draw.rounded_rectangle((183, 172, 841, 830), radius=145, fill="white")
font = ImageFont.truetype("/System/Library/Fonts/SFNSRounded.ttf", 510)
box = draw.textbbox((0, 0), "Ä", font=font)
draw.text(((SIZE - (box[2] - box[0])) / 2 - box[0],
           (SIZE - (box[3] - box[1])) / 2 - box[1] - 20),
          "Ä", font=font, fill=(22, 75, 145))

# The small microphone distinguishes dictation from an ordinary keyboard.
draw.ellipse((670, 663, 890, 883), fill=(28, 174, 173))
draw.rounded_rectangle((760, 701, 800, 777), radius=20, fill="white")
draw.arc((740, 724, 820, 805), 0, 180, fill="white", width=13)
draw.line((780, 805, 780, 826), fill="white", width=13)
draw.line((755, 828, 805, 828), fill="white", width=13)

image.convert("RGB").save(destination, optimize=True)
