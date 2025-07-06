# اختبارات التطبيق - App Tests

## 📋 نظرة عامة

هذا المجلد يحتوي على جميع اختبارات التطبيق، بما في ذلك اختبارات الوحدات (Unit Tests) واختبارات الواجهة (Widget Tests) واختبارات التكامل (Integration Tests).

## 🗂️ هيكل الملفات

### اختبارات الوحدات (Unit Tests)
- `auth_controller_test.dart` - اختبارات وحدة التحكم بالمصادقة
- `user_model_test.dart` - اختبارات نموذج المستخدم

### اختبارات الواجهة (Widget Tests)
- `widget_test.dart` - اختبارات التطبيق الرئيسي
- `home_screen_test.dart` - اختبارات الشاشة الرئيسية
- `profile_screen_test.dart` - اختبارات شاشة الملف الشخصي
- `add_story_screen_test.dart` - اختبارات شاشة إضافة القصة
- `inspiration_screen_test.dart` - اختبارات شاشة الإلهام

### اختبارات التكامل (Integration Tests)
- `integration_test.dart` - اختبارات التكامل الشاملة

## 🚀 تشغيل الاختبارات

### تشغيل جميع الاختبارات
```bash
flutter test
```

### تشغيل اختبار محدد
```bash
flutter test test/widget_test.dart
flutter test test/home_screen_test.dart
flutter test test/profile_screen_test.dart
```

### تشغيل اختبارات التكامل
```bash
flutter test test/integration_test.dart
```

### تشغيل الاختبارات مع تغطية
```bash
flutter test --coverage
```

## 📊 أنواع الاختبارات

### 1. اختبارات الوحدات (Unit Tests)
- اختبار المنطق التجاري
- اختبار النماذج (Models)
- اختبار وحدات التحكم (Controllers)

### 2. اختبارات الواجهة (Widget Tests)
- اختبار عرض العناصر
- اختبار التفاعل مع المستخدم
- اختبار التنقل بين الشاشات
- اختبار الوضع الليلي/النهاري

### 3. اختبارات التكامل (Integration Tests)
- اختبار سير العمل الكامل
- اختبار التفاعل بين المكونات
- اختبار قاعدة البيانات

## 🎯 ما يتم اختباره

### الشاشة الرئيسية (Home Screen)
- ✅ عرض القصص الثابتة
- ✅ زر إضافة قصة جديدة
- ✅ التنقل بين الشاشات
- ✅ عرض عدد القصص

### شاشة الإلهام (Inspiration Screen)
- ✅ عرض الاقتباسات العشوائية
- ✅ زر تغيير الاقتباس
- ✅ عرض الصور العشوائية
- ✅ عداد القصص

### شاشة الملف الشخصي (Profile Screen)
- ✅ معلومات المستخدم
- ✅ تبديل الوضع الليلي/النهاري
- ✅ عدد القصص الشخصية
- ✅ خيارات الإعدادات

### شاشة إضافة القصة (Add Story Screen)
- ✅ نموذج إضافة القصة
- ✅ أنواع القصص
- ✅ التحقق من صحة البيانات
- ✅ إرسال القصة

## 🔧 إعداد الاختبارات

### التبعيات المطلوبة
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4
  build_runner: ^2.4.7
  flutter_lints: ^2.0.0
```

### تشغيل Mock Generation
```bash
flutter packages pub run build_runner build
```

## 📈 تغطية الاختبارات

### الأهداف
- **تغطية الكود**: 80% على الأقل
- **اختبارات الوحدات**: جميع المنطق التجاري
- **اختبارات الواجهة**: جميع الشاشات الرئيسية
- **اختبارات التكامل**: سير العمل الأساسي

### قياس التغطية
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```
