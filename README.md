# دکان مینجمنٹ ایپ — Phase 1 + Phase 2

Multi-Business Shop Management App کا offline-first data layer، authentication،
اور multi-business/multi-user کا بنیادی ڈھانچہ۔ Framework: **Flutter** (صرف
Android/iOS، اس فیز میں web/desktop شامل نہیں)۔

## اس فیز میں کیا شامل ہے

- SQLite کے ذریعے مکمل offline local database (`users`, `businesses`,
  `business_users`)
- UUID + `last_updated` timestamp پر مبنی sync design (آپ کے پہلے طے شدہ
  design کے مطابق)
- PHP/MySQL REST API سے مطابقت (push → pull، ہر table کے لیے generic)
- Offline login/signup (انٹرنیٹ کے بغیر بھی کام کرتا ہے)
- ایک اکاؤنٹ سے متعدد دکانیں (multi-business switcher)
- کردار پر مبنی اجازتیں (owner / manager / staff) — ماڈل کی سطح پر تیار،
  UI میں فیز 2/3 میں مکمل استعمال ہوگا
- اردو/انگریزی locale سیٹ اپ (RTL/LTR خودکار)

## اگلے فیزز (اس پرومپٹ کے مطابق)

| فیز | مواد |
|---|---|
| 2 | Inventory, Billing/POS, Zakat Calculator |
| 3 | Customer, Supplier, Employee/Payroll Ledgers |
| 4 | Reports, PDF Invoicing, Export |
| 5 | Dark mode polish, Biometric lock, Play Store packaging |

## چلانے کا طریقہ (Local Setup)

### 1. Flutter App

```bash
flutter pub get
flutter run
```

Emulator میں `10.0.2.2` استعمال ہوتا ہے تاکہ Android emulator آپ کے
XAMPP localhost تک پہنچ سکے (یہ `lib/core/constants/app_constants.dart`
میں پہلے سے سیٹ ہے)۔ اصلی موبائل ڈیوائس پر ٹیسٹ کرنے کے لیے اپنے کمپیوٹر کا
لوکل IP استعمال کریں، یا لائیو ہوسٹنگ کا URL:

```bash
flutter run --dart-define=API_BASE_URL=https://yourdomain.com/pos_api
```

### 2. PHP/MySQL Backend (`pos_api/`)

1. `pos_api/schema.sql` کو phpMyAdmin (XAMPP) یا اپنے ہوسٹنگ پینل میں چلائیں۔
2. Database credentials environment variables سے سیٹ کریں
   (`DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASS`) — یا لوکل ٹیسٹنگ کے لیے
   `pos_api/config/db.php` میں موجود XAMPP defaults استعمال ہوں گے۔
3. `pos_api/` فولڈر کو XAMPP کے `htdocs` میں یا InfinityFree/Hostinger پر
   اپلوڈ کریں۔ `mod_rewrite` فعال ہونا ضروری ہے (`.htaccess` شامل ہے)۔

## اہم فن تعمیر (Architecture) نوٹس

- **کوئی بھی hosting URL کوڈ میں سیدھا نہیں لکھا گیا** — ہمیشہ
  `AppConstants.apiBaseUrl` سے پڑھا جاتا ہے، جو build کے وقت
  `--dart-define` سے تبدیل ہو سکتا ہے۔ اسی طرح `pos_api/config/db.php`
  بھی ماحول (environment) سے پڑھتا ہے۔
- **ہر table میں `uuid`, `last_updated`, `is_deleted`, `is_synced`** — یہی
  pattern فیز 2/3 کی نئی tables (items, sales, ledgers) میں بھی دہرایا
  جائے گا تاکہ sync engine میں کوئی تبدیلی نہ کرنی پڑے۔
- **Sync engine** (`lib/core/services/sync_service.dart`) مکمل طور پر
  generic ہے — نئی table شامل کرنے کے لیے صرف `syncableTables` لسٹ میں
  نام بڑھانا ہوگا۔
- **موجودہ حفاظتی خلا (فیز 1 میں جان بوجھ کر چھوڑا گیا)**: `pos_api/sync/index.php`
  میں ابھی session token کی تصدیق شامل نہیں۔ فیز 2 سے پہلے یہ ضرور شامل کریں،
  ورنہ کوئی بھی شخص آپ کے API endpoint پر ڈیٹا push/pull کر سکتا ہے۔

## فولڈر ڈھانچہ

```
lib/
  core/
    constants/     — app-wide config (API URL, table names, roles)
    database/      — SQLite schema + generic CRUD/sync helpers
    models/        — User, Business, BusinessUser
    services/      — AuthService, ApiClient, SyncService, AppState
    utils/         — UUID, password hashing
  features/
    auth/          — Login, Signup screens
    business/      — Business switcher
    home/          — Dashboard placeholder (Phase 2 replaces this)
pos_api/
  config/db.php    — DB connection (env-based)
  sync/index.php   — Generic sync endpoint (GET pull / POST push)
  schema.sql       — MySQL schema matching the SQLite schema exactly
```

---

## Phase 2 — اس فیز میں کیا شامل ہوا

- **Bottom Navigation Shell**: ڈیش بورڈ | بلنگ | انوینٹری | کھاتہ | مزید
  (`lib/features/shell/main_shell.dart`)
- **انوینٹری**: مکمل CRUD، کیٹیگری dropdown، بار کوڈ فیلڈ + کیمرہ سکین
  (`mobile_scanner`)، کم اسٹاک انڈیکیٹر
- **بلنگ/POS**: نیا بل، گاہک منتخب کرتے ہی پرانا بقایا (رنگین banner)،
  "+ نئی چیز شامل کریں" کا segmented-control فلو (تلاش / بار کوڈ سکین)،
  ادائیگی اور بقایا کا خودکار حساب — سب کچھ ایک ہی SQLite transaction میں
- **زکوٰۃ کیلکولیٹر**: نصاب تھریشولڈ (سونا/چاندی معیار)، صاحبِ نصاب بننے
  کی تاریخ، قمری سال (~354 دن) کا حساب، سونا/چاندی ریٹ کی دستی انٹری
  (آن لائن auto-fetch اختیاری ہے — دیکھیں
  `lib/core/services/metal_rate_service.dart`)
- **فلوٹنگ کیلکولیٹر**: ڈیش بورڈ، بلنگ، اور انوینٹری فارم پر دستیاب،
  نتیجہ فیلڈ میں براہ راست insert ہو سکتا ہے
- **کھاتہ (بنیاد)**: `customers` ٹیبل اور balance ٹریکنگ اسی فیز میں
  بن چکی ہے (بلنگ کے due banner کے لیے ضروری تھی)؛ مکمل Khatabook طرز
  UI (سپلائرز، یاد دہانیاں) فیز 3 میں اسی ٹیبل پر بنے گا
- **بل کی سیٹنگز**: فونٹ/کارنر/واٹرمارک انتخاب اور Live Preview محفوظ
  ہو جاتے ہیں؛ اصل PDF بل پر ان کا اطلاق فیز 4 میں ہوگا
- ڈیٹابیس میں 4 نئی tables (`items`, `customers`, `sales`, `sale_items`)
  — موجودہ (فیز 1) ڈیوائسز کے لیے خودکار migration کے ساتھ، ڈیٹا ضائع
  ہوئے بغیر
- Sync engine اور `pos_api/` دونوں میں نئی tables شامل کر دی گئی ہیں

### نیا ضروری سیٹ اپ قدم: کیمرہ اجازت (Camera Permission)

`mobile_scanner` استعمال کرنے کے لیے، اگر آپ نے ابھی تک `flutter create .`
نہیں چلایا (یعنی `android/` اور `ios/` فولڈرز موجود نہیں)، پہلے وہ چلائیں،
پھر:

- **Android** (`android/app/src/main/AndroidManifest.xml`) میں شامل کریں:
  ```xml
  <uses-permission android:name="android.permission.CAMERA" />
  ```
- **iOS** (`ios/Runner/Info.plist`) میں شامل کریں:
  ```xml
  <key>NSCameraUsageDescription</key>
  <string>بار کوڈ سکین کرنے کے لیے کیمرہ درکار ہے</string>
  ```

### معلوم حد (Known limitation)

`Item.copyWith` / `Customer.copyWith` وغیرہ Phase 1 کے اسی pattern پر
ہیں جہاں nullable فیلڈ کو خالی کر کے `null` پر واپس لانا ممکن نہیں
(نیا مقدار نہ ہونے کی صورت میں پرانی قدر برقرار رہتی ہے) — مثال کے طور
پر بار کوڈ فیلڈ خالی کر کے محفوظ کرنے سے پرانا بار کوڈ رہ سکتا ہے۔ عملی
طور پر شاذ و نادر پیش آنے والا مسئلہ ہے؛ اگر ضرورت ہو تو Phase 3 میں
`clearBarcode()` جیسا علیحدہ method شامل کیا جا سکتا ہے۔

### اگلا فیز (Phase 3)

Customer/Supplier/Employee ledgers کی مکمل Khatabook طرز UI — یاد دہانی
لنکس، سپلائرز ٹیب، ملازمین کا کھاتہ/تنخواہ — اسی `customers` ٹیبل کے
پیٹرن پر بنیں گے۔

---

## پریمیم / فیچر لاک ڈھانچہ (Feature Gating)

پیمنٹ سسٹم ابھی شامل نہیں کیا گیا — لیکن مکمل "فیچر لاک" ڈھانچہ بن چکا
ہے، تاکہ جب بھی آپ پیمنٹ کا طریقہ (Google Play Billing، اپنا
pos_api-based لائسنس، یا دونوں) طے کریں، صرف ایک جگہ جوڑنی پڑے۔

### کیسے کام کرتا ہے

- `lib/core/services/premium_service.dart` — واحد جگہ جہاں "یہ صارف
  پریمیم ہے یا نہیں" کا فیصلہ ہوتا ہے (`PremiumService.instance.isPremium`)۔
  ہر گیٹڈ فیچر ایک `PremiumFeature` enum value ہے۔
- `lib/core/widgets/premium_gate.dart` — `PremiumGate.ensure(context,
  feature, featureLabel: '...')` — کسی بھی جگہ ایک لائن میں فیچر لاک
  کرنے کے لیے استعمال ہو۔ locked ہونے پر خود بخود upgrade کا پرامپٹ
  دکھاتا ہے۔
- `lib/features/premium/upgrade_screen.dart` — پریمیم فیچرز کی فہرست +
  **عارضی ٹیسٹنگ ٹوگل** (نیچے دیکھیں)۔

### ابھی کون سے فیچرز لاک ہیں

| فیچر | کہاں لاگو ہے |
|---|---|
| کیمرے سے خودکار بار کوڈ/QR سکین | انوینٹری فارم کا سکین بٹن + بلنگ کا "بار کوڈ سکین" ٹیب |
| مکمل زکوٰۃ کیلکولیٹر/معلومات | ڈیش بورڈ کا زکوٰۃ کارڈ + "مزید" کا زکوٰۃ کیلکولیٹر |
| متعدد دکانیں | "دکان منتخب کریں" سکرین کا "+ نئی دکان" بٹن (پہلی دکان ہمیشہ مفت) |
| لامحدود انوینٹری آئٹمز | 100 آئٹمز کے بعد نئی چیز شامل کرنے پر |

`staffAccounts`, `supplierLedger`, `reports`, `pdfInvoicing`,
`multiDeviceSync` پہلے سے `PremiumFeature` enum میں شامل ہیں لیکن ابھی
کوئی سکرین نہیں (وہ Phase 3/4 میں بنیں گی) — جب وہ سکرینیں بنیں تو صرف
`PremiumGate.ensure(...)` میں لپیٹ دیں، کوئی نیا ڈھانچہ نہیں بنانا
پڑے گا۔

### ٹیسٹنگ (پیمنٹ آنے تک)

"مزید" → "پریمیم اپ گریڈ" سکرین کے نیچے ایک "🔧 ٹیسٹنگ" سیکشن ہے جہاں
سے دستی طور پر پریمیم آن/آف کر کے دونوں حالتیں (Free/Premium) ٹیسٹ کی
جا سکتی ہیں — بغیر کسی پیمنٹ کے۔ یہ صرف عارضی ہے۔

### پیمنٹ بعد میں جوڑنے کے لیے

`PremiumService.setPremium(bool value, {int? expiresAtMillis})` — یہی
واحد method ہے جو ایک حقیقی خریداری کے بعد کال ہونا چاہیے:

- **Google Play Billing**: `purchaseUpdated` سٹریم میں کامیاب خریداری کی
  تصدیق کے بعد۔
- **اپنا pos_api لائسنس**: سرور سے activation کی تصدیق ملنے کے بعد،
  expiry کے ساتھ۔

جب یہ جڑ جائے تو `UpgradeScreen` کے نیچے والا "🔧 ٹیسٹنگ" سیکشن ہٹا دیں
— باقی کچھ بھی تبدیل کرنے کی ضرورت نہیں۔
