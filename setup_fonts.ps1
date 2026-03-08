## تثبيت خطوط Cairo وتهيئة المشروع
## شغّل هذا الملف بالنقر المزدوج أو من PowerShell

# 1. إنشاء مجلد الأصول
New-Item -ItemType Directory -Force -Path "assets\fonts" | Out-Null

# 2. تحميل خطوط Cairo من Google Fonts
$cairoZip = "$env:TEMP\cairo.zip"
Invoke-WebRequest `
    -Uri "https://fonts.google.com/download?family=Cairo" `
    -OutFile $cairoZip

Expand-Archive -Path $cairoZip -DestinationPath "$env:TEMP\cairo_fonts" -Force

# 3. نسخ الملفات المطلوبة
$dest = "assets\fonts"
Copy-Item "$env:TEMP\cairo_fonts\static\Cairo-Regular.ttf" $dest -Force
Copy-Item "$env:TEMP\cairo_fonts\static\Cairo-Bold.ttf"    $dest -Force

Write-Host "✅ Cairo fonts installed!" -ForegroundColor Green

# 4. flutter pub get
flutter pub get

Write-Host "✅ Ready! Run: flutter run" -ForegroundColor Green
