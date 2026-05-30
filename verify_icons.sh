#!/bin/bash
# Quick verification script to confirm all icons were updated
# This script checks if all generated icons exist

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔍 Verifying icon generation..."
echo "======================================"

# Check Web icons
echo "✓ Checking Web icons..."
for size in 192 512; do
    [ -f "$PROJECT_ROOT/web/icons/Icon-$size.png" ] && echo "  ✓ Icon-$size.png" || echo "  ✗ Icon-$size.png MISSING"
    [ -f "$PROJECT_ROOT/web/icons/Icon-maskable-$size.png" ] && echo "  ✓ Icon-maskable-$size.png" || echo "  ✗ Icon-maskable-$size.png MISSING"
done

# Check Android icons
echo "\n✓ Checking Android icons..."
for density in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
    [ -f "$PROJECT_ROOT/android/app/src/main/res/mipmap-$density/launcher_icon.png" ] && echo "  ✓ mipmap-$density/launcher_icon.png" || echo "  ✗ mipmap-$density/launcher_icon.png MISSING"
done

# Check iOS icons
echo "\n✓ Checking iOS icons..."
[ -f "$PROJECT_ROOT/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png" ] && echo "  ✓ Icon-App-1024x1024@1x.png" || echo "  ✗ Icon-App-1024x1024@1x.png MISSING"

# Check macOS icons
echo "\n✓ Checking macOS icons..."
[ -f "$PROJECT_ROOT/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png" ] && echo "  ✓ app_icon_1024.png" || echo "  ✗ app_icon_1024.png MISSING"

# Check Windows icon
echo "\n✓ Checking Windows icon..."
[ -f "$PROJECT_ROOT/windows/runner/resources/app_icon.ico" ] && echo "  ✓ app_icon.ico" || echo "  ✗ app_icon.ico MISSING"

# Check Linux icons
echo "\n✓ Checking Linux icons..."
[ -f "$PROJECT_ROOT/linux/runner/resources/512x512/apps/com.example.daftar_debt_manager.png" ] && echo "  ✓ 512x512/apps/com.example.daftar_debt_manager.png" || echo "  ✗ 512x512 MISSING"

echo "\n✅ Verification complete!"
