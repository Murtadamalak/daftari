#!/usr/bin/env python3
"""
Master icon generator script
Regenerates all platform icons from assets/icon.png
Run this whenever you update the source icon
"""

import os
import sys
import subprocess

def run_script(script_name):
    """Run a Python script and report status"""
    print(f"\n{'='*60}")
    print(f"Running: {script_name}")
    print(f"{'='*60}")
    try:
        result = subprocess.run([sys.executable, script_name], cwd=os.path.dirname(os.path.abspath(__file__)))
        if result.returncode == 0:
            print(f"✅ {script_name} completed successfully")
            return True
        else:
            print(f"❌ {script_name} failed with return code {result.returncode}")
            return False
    except Exception as e:
        print(f"❌ Error running {script_name}: {e}")
        return False

def main():
    project_root = os.path.dirname(os.path.abspath(__file__))
    source_icon = os.path.join(project_root, "assets", "icon.png")
    
    print("╔════════════════════════════════════════════════════════╗")
    print("║          Icon Generator - All Platforms               ║")
    print("╚════════════════════════════════════════════════════════╝")
    
    # Verify source icon exists
    if not os.path.exists(source_icon):
        print(f"❌ ERROR: Icon not found at {source_icon}")
        sys.exit(1)
    
    print(f"\n📦 Source icon: {source_icon}")
    
    # List of scripts to run
    scripts = [
        "generate_icons.py",           # Web & Android
        "generate_ios_icons.py",        # iOS
        "generate_desktop_icons.py",    # macOS, Windows, Linux
        "copy_web_icons.py",            # Web dashboards
    ]
    
    results = []
    for script in scripts:
        script_path = os.path.join(project_root, script)
        if os.path.exists(script_path):
            success = run_script(script)
            results.append((script, success))
        else:
            print(f"⚠️  Script not found: {script}")
            results.append((script, False))
    
    # Summary
    print(f"\n{'='*60}")
    print("SUMMARY")
    print(f"{'='*60}")
    
    total = len(results)
    successful = sum(1 for _, success in results if success)
    
    for script, success in results:
        status = "✅" if success else "❌"
        print(f"{status} {script}")
    
    print(f"\nTotal: {successful}/{total} scripts completed successfully")
    
    if successful == total:
        print("\n🎉 All icons have been successfully regenerated!")
        print("\nNext steps:")
        print("  1. Run: flutter clean && flutter pub get")
        print("  2. Rebuild your app: flutter run")
        sys.exit(0)
    else:
        print(f"\n⚠️  {total - successful} script(s) failed. Please check the output above.")
        sys.exit(1)

if __name__ == "__main__":
    main()
