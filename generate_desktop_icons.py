#!/usr/bin/env python3
"""
Comprehensive icon generator for all platforms
Generates: macOS, Windows ICO, and Linux icons from source icon.png
"""

import os
from PIL import Image

# Get the project root
project_root = os.path.dirname(os.path.abspath(__file__))
source_icon = os.path.join(project_root, "assets", "icon.png")

print(f"Generating desktop platform icons from: {source_icon}")

if not os.path.exists(source_icon):
    print(f"ERROR: Icon not found at {source_icon}")
    exit(1)

# Open the source image
img = Image.open(source_icon)
print(f"Loaded icon: {img.size} - {img.format}\n")

# macOS icons
print("Generating macOS icons...")
macos_path = os.path.join(project_root, "macos", "Runner", "Assets.xcassets", "AppIcon.appiconset")
macos_sizes = [
    (16, "app_icon_16.png"),
    (32, "app_icon_32.png"),
    (64, "app_icon_64.png"),
    (128, "app_icon_128.png"),
    (256, "app_icon_256.png"),
    (512, "app_icon_512.png"),
    (1024, "app_icon_1024.png"),
]

for size, filename in macos_sizes:
    full_path = os.path.join(macos_path, filename)
    resized = img.resize((size, size), Image.Resampling.LANCZOS)
    resized.save(full_path, "PNG")
    print(f"  ✓ {filename} ({size}x{size})")

# Linux icons
print("\nGenerating Linux icons...")
linux_icons_path = os.path.join(project_root, "linux", "runner", "resources")
os.makedirs(linux_icons_path, exist_ok=True)

linux_sizes = [16, 32, 64, 128, 256, 512]
for size in linux_sizes:
    filename = f"{size}x{size}/apps/com.example.daftar_debt_manager.png"
    full_dir = os.path.join(linux_icons_path, os.path.dirname(filename))
    os.makedirs(full_dir, exist_ok=True)
    
    full_path = os.path.join(linux_icons_path, filename)
    resized = img.resize((size, size), Image.Resampling.LANCZOS)
    resized.save(full_path, "PNG")
    print(f"  ✓ {filename} ({size}x{size})")

# Windows ICO
print("\nGenerating Windows ICO...")
windows_path = os.path.join(project_root, "windows", "runner", "resources")
os.makedirs(windows_path, exist_ok=True)

# Create Windows ICO with multiple sizes
ico_sizes = [(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
ico_images = []

for size, _ in ico_sizes:
    resized = img.resize((size, size), Image.Resampling.LANCZOS)
    # Convert RGBA to RGB if needed for ICO compatibility
    if resized.mode == 'RGBA':
        # Create a white background
        background = Image.new('RGB', resized.size, (255, 255, 255))
        background.paste(resized, mask=resized.split()[3])
        ico_images.append(background)
    else:
        ico_images.append(resized)

# Save as ICO
ico_path = os.path.join(windows_path, "app_icon.ico")
if ico_images:
    ico_images[0].save(ico_path, "ICO", sizes=[(s, s) for s, _ in ico_sizes], append_images=ico_images[1:])
    print(f"  ✓ app_icon.ico (multiple sizes)")

print("\n✅ All desktop platform icons generated successfully!")
