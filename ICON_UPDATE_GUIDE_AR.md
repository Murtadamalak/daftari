# 📱 دليل تحديث أيقونة التطبيق

## نظرة عامة
تم تحديث أيقونة التطبيق الجديدة `icon.png` من مجلد `assets/` عبر جميع المنصات والتطبيقات.

## المنصات المحدثة

### ✅ **Flutter Mobile (iOS و Android)**
- **iOS**: 21 أيقونة بأحجام مختلفة من 20x20 إلى 1024x1024
- **Android**: 10 أيقونات في مستويات كثافة مختلفة (MDPI, HDPI, XHDPI, XXHDPI, XXXHDPI)
- **الملف المصدر**: `pubspec.yaml` يشير إلى `assets/icon.png`

### ✅ **Flutter Desktop**
- **macOS**: 7 أيقونات من 16x16 إلى 1024x1024
- **Windows**: ملف ICO واحد متعدد الأحجام (16-256px)
- **Linux**: 6 أيقونات PNG بأحجام معيارية

### ✅ **Web Applications**
- **Web (Flutter)**: Icon-192.png, Icon-512.png والمتغيرات Maskable
- **Admin Dashboard**: favicon.ico في `admin-dashboard/public/`
- **Daftari Web**: favicon.ico في `daftari-web/public/`

## ملفات البرامج النصية (Scripts)

تم إنشاء عدة برامج Python لأتمتة عملية توليد الأيقونات:

### 1. **generate_icons.py**
توليد أيقونات الويب و Android من `assets/icon.png`
```bash
python generate_icons.py
```

### 2. **generate_ios_icons.py**
توليد جميع أيقونات iOS بالأحجام المطلوبة
```bash
python generate_ios_icons.py
```

### 3. **generate_desktop_icons.py**
توليد أيقونات macOS و Windows و Linux
```bash
python generate_desktop_icons.py
```

### 4. **copy_web_icons.py**
نسخ الأيقونات إلى مجلدات Web Dashboard العامة (public)
```bash
python copy_web_icons.py
```

### 5. **regenerate_all_icons.py** (🎯 الأفضل)
برنامج سيد يشغل جميع البرامج النصية بالترتيب الصحيح
```bash
python regenerate_all_icons.py
```

## كيفية تحديث الأيقونة في المستقبل

### الخطوة 1: استبدال ملف الأيقونة
ضع ملف الأيقونة الجديد في:
```
assets/icon.png
```
**المتطلبات:**
- الحد الأدنى للحجم: 1024x1024 بكسل (يفضل أكثر)
- الصيغة: PNG (بدعم القناة الشفافة RGBA)

### الخطوة 2: تشغيل برنامج توليد الأيقونات
```bash
cd /path/to/project
python regenerate_all_icons.py
```

### الخطوة 3: إعادة بناء التطبيق
```bash
flutter clean
flutter pub get
flutter run
```

## قائمة الملفات المحدثة

### أيقونات الويب 🌐
```
web/icons/
├── Icon-192.png
├── Icon-512.png
├── Icon-maskable-192.png
├── Icon-maskable-512.png
└── manifest.json (يشير إلى الأيقونات)

web/favicon.png
```

### أيقونات Android 🤖
```
android/app/src/main/res/
├── mipmap-mdpi/
│   ├── ic_launcher.png (48x48)
│   └── launcher_icon.png (48x48)
├── mipmap-hdpi/
│   ├── ic_launcher.png (72x72)
│   └── launcher_icon.png (72x72)
├── mipmap-xhdpi/
│   ├── ic_launcher.png (96x96)
│   └── launcher_icon.png (96x96)
├── mipmap-xxhdpi/
│   ├── ic_launcher.png (144x144)
│   └── launcher_icon.png (144x144)
└── mipmap-xxxhdpi/
    ├── ic_launcher.png (192x192)
    └── launcher_icon.png (192x192)
```

### أيقونات iOS 🍎
```
ios/Runner/Assets.xcassets/AppIcon.appiconset/
├── Icon-App-20x20@1x.png
├── Icon-App-20x20@2x.png
├── Icon-App-20x20@3x.png
├── Icon-App-29x29@1x.png
├── ... (جميع الأحجام المطلوبة)
├── Icon-App-76x76@2x.png
├── Icon-App-83.5x83.5@2x.png
└── Icon-App-1024x1024@1x.png
```

### أيقونات macOS 🖥️
```
macos/Runner/Assets.xcassets/AppIcon.appiconset/
├── app_icon_16.png
├── app_icon_32.png
├── app_icon_64.png
├── app_icon_128.png
├── app_icon_256.png
├── app_icon_512.png
└── app_icon_1024.png
```

### أيقونات Windows 🪟
```
windows/runner/resources/
└── app_icon.ico (متعدد الأحجام)
```

### أيقونات Linux 🐧
```
linux/runner/resources/
├── 16x16/apps/com.example.daftar_debt_manager.png
├── 32x32/apps/com.example.daftar_debt_manager.png
├── 64x64/apps/com.example.daftar_debt_manager.png
├── 128x128/apps/com.example.daftar_debt_manager.png
├── 256x256/apps/com.example.daftar_debt_manager.png
└── 512x512/apps/com.example.daftar_debt_manager.png
```

### أيقونات Dashboard Admin 🔧
```
admin-dashboard/
├── public/favicon.ico
└── index.html (تم تحديثه ليشير إلى favicon.ico)
```

### أيقونات Daftari Web 💼
```
daftari-web/
├── public/favicon.ico
└── index.html (تم تحديثه ليشير إلى favicon.ico)
```

## ملاحظات تقنية

### جودة إعادة التحجيم
- تم استخدام خوارزمية **Lanczos resampling** عالية الجودة
- تم الحفاظ على شفافية القناة RGBA لجميع الأيقونات
- لا يوجد فقدان جودة أثناء إعادة التحجيم

### التوافقية
- **iOS**: جميع الأيقونات تتبع معايير Apple HIG
- **Android**: الأيقونات تغطي جميع كثافات الشاشة المعيارية
- **Web**: الأيقونات متوافقة مع معايير PWA
- **Desktop**: الأيقونات بدقة عالية لمختلف دقة الشاشات

## استكشاف الأخطاء

### المشكلة: الأيقونة لا تتغير بعد التحديث
**الحل:**
```bash
flutter clean
rm -rf build/
flutter pub get
flutter run
```

### المشكلة: خطأ في توليد الأيقونات
**المتطلبات:**
- Python 3.6 أو أحدث
- مكتبة Pillow (للمعالجة): `pip install Pillow`

```bash
pip install --upgrade Pillow
python regenerate_all_icons.py
```

### المشكلة: الأيقونة ضبابية على الويب
- تأكد من أن ملف `assets/icon.png` يحتوي على دقة عالية (1024x1024 أو أكثر)
- أعد تشغيل برنامج التوليد
- امسح ذاكرة التخزين المؤقت للمتصفح

## مراجع إضافية

- [معايير Apple Xcode Documentation](https://developer.apple.com/design/human-interface-guidelines/ios/icons-and-images/app-icons/)
- [Material Design Icon Guidelines](https://material.io/design/iconography/system-icons.html)
- [Android Icon Guidelines](https://developer.android.com/guide/practices/ui_guidelines/icon_design_status_bar)
- [Flutter Icon Guide](https://flutter.dev/docs/ui/assets/assets-and-images)

---

**آخر تحديث**: 31 مايو 2026
**الإصدار**: 1.0
