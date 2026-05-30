#!/usr/bin/env python3
"""
Copy new icon to web dashboards
"""

import os
import shutil

project_root = os.path.dirname(os.path.abspath(__file__))
source_icon = os.path.join(project_root, "assets", "icon.png")

print(f"Copying icon to web dashboards...")

if not os.path.exists(source_icon):
    print(f"ERROR: Icon not found at {source_icon}")
    exit(1)

# Copy to admin-dashboard
admin_dashboard_public = os.path.join(project_root, "admin-dashboard", "public")
os.makedirs(admin_dashboard_public, exist_ok=True)
admin_favicon = os.path.join(admin_dashboard_public, "favicon.ico")
shutil.copy(source_icon, admin_favicon)
print(f"✓ Copied to admin-dashboard/public/favicon.ico")

# Copy to daftari-web public (if exists)
daftari_web_public = os.path.join(project_root, "daftari-web", "public")
if os.path.exists(daftari_web_public):
    daftari_favicon = os.path.join(daftari_web_public, "favicon.ico")
    shutil.copy(source_icon, daftari_favicon)
    print(f"✓ Copied to daftari-web/public/favicon.ico")
else:
    os.makedirs(daftari_web_public, exist_ok=True)
    daftari_favicon = os.path.join(daftari_web_public, "favicon.ico")
    shutil.copy(source_icon, daftari_favicon)
    print(f"✓ Created and copied to daftari-web/public/favicon.ico")

# Update web/favicon.png if it exists
web_favicon = os.path.join(project_root, "web", "favicon.png")
if os.path.exists(web_favicon):
    shutil.copy(source_icon, web_favicon)
    print(f"✓ Updated web/favicon.png")

print("\n✅ All web assets updated!")
