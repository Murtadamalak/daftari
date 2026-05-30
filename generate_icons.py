#!/usr/bin/env python3
"""
Icon generator script to create all platform-specific icons from a source image.
Usage: python generate_icons.py
"""

import os
import shutil
from PIL import Image

# Get the project root
project_root = os.path.dirname(os.path.abspath(__file__))
source_icon = os.path.join(project_root, "assets", "icon.png")

print(f"Project root: {project_root}")
print(f"Source icon: {source_icon}")

if not os.path.exists(source_icon):
    print(f"ERROR: Icon not found at {source_icon}")
    exit(1)

# Open the source image
img = Image.open(source_icon)
print(f"Loaded icon: {img.size} - {img.format}")

# Define icon sizes and their output paths
icon_configs = [
    # Web icons
    ("web/icons/Icon-192.png", 192),
    ("web/icons/Icon-512.png", 512),
    ("web/icons/Icon-maskable-192.png", 192),
    ("web/icons/Icon-maskable-512.png", 512),
    
    # Android icons (mipmap folders)
    ("android/app/src/main/res/mipmap-mdpi/ic_launcher.png", 48),
    ("android/app/src/main/res/mipmap-mdpi/launcher_icon.png", 48),
    ("android/app/src/main/res/mipmap-hdpi/ic_launcher.png", 72),
    ("android/app/src/main/res/mipmap-hdpi/launcher_icon.png", 72),
    ("android/app/src/main/res/mipmap-xhdpi/ic_launcher.png", 96),
    ("android/app/src/main/res/mipmap-xhdpi/launcher_icon.png", 96),
    ("android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png", 144),
    ("android/app/src/main/res/mipmap-xxhdpi/launcher_icon.png", 144),
    ("android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png", 192),
    ("android/app/src/main/res/mipmap-xxxhdpi/launcher_icon.png", 192),
]

# Generate icons
for output_path, size in icon_configs:
    full_output_path = os.path.join(project_root, output_path)
    
    # Create output directory if needed
    output_dir = os.path.dirname(full_output_path)
    os.makedirs(output_dir, exist_ok=True)
    
    # Resize image
    resized = img.resize((size, size), Image.Resampling.LANCZOS)
    resized.save(full_output_path, "PNG")
    print(f"✓ Generated: {output_path} ({size}x{size})")

print("\n✓ All icons generated successfully!")
