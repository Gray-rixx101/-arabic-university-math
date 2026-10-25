# رفع «أثر» إلى TestFlight بدون جهاز Mac

يبني GitHub Actions التطبيق على جهاز Mac سحابي، ويوقّعه، ويرفعه إلى TestFlight. تحتاج فقط متصفحًا (حتى من الجوال).

## ١. حساب مطوّر Apple

اشترك في **Apple Developer Program** (99 دولارًا سنويًا) من تطبيق **Apple Developer** على الآيفون أو من developer.apple.com. انتظر حتى يُفعَّل الحساب (عادة خلال يوم إلى يومين).

## ٢. اختر معرّف الحزمة (Bundle ID)

معرّف فريد باسمك، بأحرف إنجليزية صغيرة، مثل: `com.assad.athar`. سنسميه **المعرّف** في باقي الخطوات.

## ٣. سجّل المعرّفات في developer.apple.com

ادخل **Certificates, Identifiers & Profiles** ثم **Identifiers**:

1. اضغط **+** واختر **App Groups**. الاسم: `Athar`، والمعرّف: `group.` + المعرّف، مثل `group.com.assad.athar`.
2. اضغط **+** واختر **App IDs** ثم **App**:
   - الوصف: `Athar`، و Bundle ID (Explicit): المعرّف، مثل `com.assad.athar`.
   - من القائمة فعّل **App Groups**، ثم اضغط **Configure** واختر المجموعة من الخطوة 1.
3. كرر الخطوة 2 للودجت: الوصف `Athar Widget`، و Bundle ID: المعرّف + `.widget`، مثل `com.assad.athar.widget`، وفعّل **App Groups** واختر المجموعة نفسها.

## ٤. أنشئ التطبيق في App Store Connect

في appstoreconnect.apple.com ادخل **Apps**، ثم **+**، ثم **New App**:

- المنصة: iOS، والاسم: `أثر` (إن كان محجوزًا جرّب اسمًا مثل `أثر - متتبع العادات`).
- اللغة الأساسية: Arabic.
- Bundle ID: اختر المعرّف من الخطوة 3.
- SKU: أي نص، مثل `athar-001`.

## ٥. أنشئ مفتاح API

في App Store Connect ادخل **Users and Access**، ثم **Integrations**، ثم **App Store Connect API**، ثم **Team Keys**:

1. اضغط **+**، والاسم `GitHub`، والصلاحية **Admin**. صلاحية Admin لازمة ليتمكن Xcode من إنشاء شهادة التوقيع تلقائيًا.
2. احفظ **Issuer ID** (أعلى الصفحة) و **Key ID**.
3. اضغط **Download** لتنزيل ملف `AuthKey_XXXX.p8`. يمكن تنزيله **مرة واحدة فقط**، فاحتفظ به في مكان آمن.

**Team ID** تجده في developer.apple.com ثم **Account** ثم **Membership details**.

## ٦. أضف الأسرار في GitHub

في المستودع ادخل **Settings**، ثم **Secrets and variables**، ثم **Actions**.

في تبويب **Secrets** أضف بالزر **New repository secret**:

| الاسم | القيمة |
|---|---|
| `APP_STORE_CONNECT_KEY_ID` | Key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID |
| `APPLE_TEAM_ID` | Team ID |
| `APP_STORE_CONNECT_PRIVATE_KEY` | محتوى ملف `.p8` كاملًا، من `-----BEGIN PRIVATE KEY-----` حتى `-----END PRIVATE KEY-----` |

وفي تبويب **Variables** أضف بالزر **New repository variable**:

| الاسم | القيمة |
|---|---|
| `BUNDLE_ID` | المعرّف، مثل `com.assad.athar` |

## ٧. ارفع النسخة

ادخل **Actions**، ثم **TestFlight**، ثم **Run workflow**. يستغرق 5 إلى 15 دقيقة.

بعد نجاحه، تظهر النسخة في App Store Connect تحت **TestFlight** خلال 10 إلى 30 دقيقة من المعالجة. بعدها:

1. في **Internal Testing** أنشئ مجموعة وأضف نفسك (بريد حساب Apple).
2. نزّل تطبيق **TestFlight** من App Store على الآيفون، وافتح الدعوة، ثم ثبّت «أثر».

كل مرة تشغّل فيها الـ workflow يرتفع رقم النسخة تلقائيًا. النسخة الداخلية في TestFlight تبقى صالحة 90 يومًا.

## مشاكل شائعة

- **No suitable application records were found**: الخطوة 4 لم تكتمل، أو المعرّف مختلف عن `BUNDLE_ID`.
- **Provisioning / App Group errors**: تأكد من تفعيل App Groups على المعرّفين (التطبيق والودجت) واختيار المجموعة نفسها، وأن اسمها `group.` + المعرّف بالضبط.
- **Cloud signing permission**: صلاحية المفتاح يجب أن تكون Admin.
- **Missing Compliance** في TestFlight: لا تحتاج شيئًا، فالتطبيق يصرّح بأنه لا يستخدم تشفيرًا خاصًا.
