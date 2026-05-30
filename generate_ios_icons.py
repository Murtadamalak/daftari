#!/usr/bin/env python3
"""
Generate iOS icons from the source icon.
"""

import os
from PIL import Image

# Get the project root
project_root = os.path.dirname(os.path.abspath(__file__))
source_icon = os.path.join(project_root, "assets", "icon.png")

print(f"Generating iOS icons from: {source_icon}")

if not os.path.exists(source_icon):
    print(f"ERROR: Icon not found at {source_icon}")
    exit(1)

# Open the source image
img = Image.open(source_icon)
print(f"Loaded icon: {img.size} - {img.format}")

# iOS icon sizes based on the pattern in the folder
ios_icon_sizes = [
    20, 20, 20,  # @1x, @2x, @3x
    29, 29, 29,  # @1x, @2x, @3x
    40, 40, 40,  # @1x, @2x, @3x
    50, 50,      # @1x, @2x
    57, 57,      # @1x, @2x
    60, 60,      # @2x, @3x
    72, 72,      # @1x, @2x
    76, 76,      # @1x, @2x
    83.5,        # @2x (167 pixels)
    1024,        # @1x
]

# Define the icon filenames in order
ios_icon_names = [
    "Icon-App-20x20@1x.png",
    "Icon-App-20x20@2x.png",
    "Icon-App-20x20@3x.png",
    "Icon-App-29x29@1x.png",
    "Icon-App-29x29@2x.png",
    "Icon-App-29x29@3x.png",
    "Icon-App-40x40@1x.png",
    "Icon-App-40x40@2x.png",
    "Icon-App-40x40@3x.png",
    "Icon-App-50x50@1x.png",
    "Icon-App-50x50@2x.png",
    "Icon-App-57x57@1x.png",
    "Icon-App-57x57@2x.png",
    "Icon-App-60x60@2x.png",
    "Icon-App-60x60@3x.png",
    "Icon-App-72x72@1x.png",
    "Icon-App-72x72@2x.png",
    "Icon-App-76x76@1x.png",
    "Icon-App-76x76@2x.png",
    "Icon-App-83.5x83.5@2x.png",
    "Icon-App-1024x1024@1x.png",
]

ios_path = os.path.join(project_root, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")

for size, filename in zip(ios_icon_sizes, ios_icon_names):
    size_int = int(size * 2) if size == 83.5 else int(size)
    full_path = os.path.join(ios_path, filename)
    
    # Resize and save
    resized = img.resize((size_int, size_int), Image.Resampling.LANCZOS)
    resized.save(full_path, "PNG")
    print(f"✓ Generated: {filename} ({size_int}x{size_int})")

print("\n✓ All iOS icons generated successfully!")
