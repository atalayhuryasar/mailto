# MacMail — `mailto:` Yönlendirici (Mailway klonu) Uygulama Planı

> Referans: [Mailway](https://sindresorhus.com/mailway) — Sindre Sorhus, App Store id `6766044904`, v1.0.1, minOS 26.4, ~4.9 MB.
> Bu plan, Mailway'in web sitesi + App Store açıklaması + ekran görüntüleri + yerel macOS SDK/LSDB incelemesine dayanarak hazırlandı.

---

## 0. Yasal / isimlendirme notu (kısa, önemli)

Mailway **ticari, ücretli, kapalı kaynaklı** bir uygulamadır. Birebir klon:

- **Kişisel kullanım** için sorun değil.
- **"Mailway" adı, ikonu ve birebir UI kopyası dağıtılmamalı** (marka / telif). Bu yüzden projeyi `MacMail` adıyla, **kendi ikonunuzla** ve **kendi görsel dilinizle** yapıyoruz. İşlevler ve bilgi mimarisi birebir aynı olacak — bu, "birebir aynısını yapmak" isteğinin karşılanması için yeterlidir.
- App Store'a koyacaksanız: isim/favicon/ikon değişmeli, ücretlendirme modeli kendinize ait olmalı.

---

## 1. Uygulamanın tam işlev envanteri (Mailway'den çıkarıldı)

### Çekirdek davranış
| # | Davranış | Detay |
|---|---|---|
| C1 | `mailto:` handler olmak | Uygulama **sistem varsayılan e-posta uygulaması** olur. macOS `mailto:` linklerini ona yönlendirir. |
| C2 | On-demand çalışma | Arka planda **hiç çalışmaz**. Link tıklandığında ayağa kalkar, yönlendirir, kapanır. Boştayken 0% CPU / 0 MB. |
| C3 | Kurulum gerektirmez | Mail hesabı, hesap girişi, launch at login yok. |

### Genel sekmesi
- **Primary email app** — tek satır, hedef seçici (ikon + ad).
- **Alternative email app** — Fn basılıyken kullanılan hedef, tüm kuralları atlar. Alt satırda ipucu metni: *"Hold Fn to use this target, skipping rules."*

### Hedef (target) tipleri
1. **Native e-posta uygulaması** — Mac'te kurulu herhangi bir mail client (Mail, Outlook, Spark, Airmail, Proton Mail, …). `LSUIElement` olanlar dahil.
2. **Webmail** — hazır şablonlarla: Gmail, Fastmail, Outlook 365, Outlook.com, Yahoo, Yandex, AOL, Zoho.
3. **Custom URL** — kullanıcı kendi compose URL'ini URI Template değişkenleriyle girer.
4. **Copy to Clipboard** — hiçbir şey açmaz, sadece e-posta adresini panoya kopyalar.

### Rules sekmesi
- Liste: `toggle + ad + "N recipient matcher(s) → Hedef"` (tek satır özet).
- Her satırda enable/disable anahtarı, sağ tıkla veya hover → **Edit** ve **Delete**.
- Boş durumda listenin altında `+` butonu.
- **Sıralama önemli**: ilk eşleşen kural kazanır (list sırası = öncelik).

### Edit Rule sheet (modal)
- Başlık: "Edit Rule" / "New Rule".
- **Name** — metin alanı.
- **Open in** — hedef seçici.
- **Recipient Matchers** — başlık + `+` butonu. Her satır:
  - `Detect via` → dropdown: **Email address / Domain / Domain and subdomains**
  - metin alanı (`work.com`)
  - sağda **trash** butonu
  - altında **açıklama satırı** (türe göre değişir):
    - Domain → *"Matches addresses on the exact domain. It does not match subdomains."*
    - Domain and subdomains → *"Matches the domain and any of its subdomains."*
    - Email address → *"Matches the exact email address."*
- **Source Apps** — başlık + `+`. Boşken *"No source apps"* placeholder + alt açıklama: *"The email link must have been clicked in one of these apps."*
- Altta **Cancel / Save** (Save = mavi prominent, `.borderedProminent`).

### Kuralların semantiği
- Kural eşleşmesi = **tüm koşullar AND** (varsa).
- `Recipient Matchers` **birden fazla olabilir**, biri tutsa yeter.
- `Source Apps` listesi **boşsa** bu koşul yok sayılır.
- `Source Apps` **varsa** ve link o listedeki uygulamalardan birinde tıklanmadıysa kural tutmaz.
- Sadece alıcı (to/cc/bcc) üzerinden eşleşme yapılır. Konu/gövde eşleşmesi **yok**. Regex **yok**.

### Diğer
- **Webmail** tarayıcıda compose penceresini alıcı/konu/gövde doldurulmuş açar.
- **Custom URL template değişkenleri**: `{to}`, `{cc}`, `{bcc}`, `{subject}`, `{body}`, `{mailto}`, `{domain}`.
- **Çoklu alıcı** (to/cc/bcc) desteklenir, webmail'e de aktarılır.
- **Shortcuts / App Intents**:
  - E-posta oluştur (Compose Email)
  - Primary target al / ayarla
  - Alternative target al / ayarla
  - Kural etkinleştir / devre dışı bırak
- Geri bildirim butonu (uygulama içinde) — isteğe bağlı.

---

## 2. Sistem tarafı incelemesi (bu makineden doğrulandı)

Bu, planın en kritik kısmı — yanlış yapılırsa uygulama hiç çalışmaz.

### 2.1 macOS varsayılan e-posta uygulaması nasıl olunur?

`/System/Applications/Mail.app/Contents/Info.plist` ve LaunchServices veritabanı (`lsregister -dump`) incelendi. Mail şunları claim ediyor:

```
claimed UTIs:    com.apple.mail.ewsmbox, com.apple.mail.email,
                 com.apple.default-app.mail-client, com.apple.mail.emlx,
                 public.item, com.apple.mail.mbox, com.apple.mail.imapmbox
claimed schemes: mail-pref-pane:, mailto:, message:
```

`com.apple.mail.email` → `conforms to: public.data, public.email-message`

Yani **üç ayrı şey** claim etmek gerekiyor:

1. **URL scheme claim** → `mailto:` linklerini yakalamak için
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLName</key><string>Email Address URL</string>
       <key>CFBundleURLSchemes</key><array><string>mailto</string></array>
       <key>LSHandlerRank</key><string>Owner</string>
     </dict>
   </array>
   ```
2. **Document type claim** → System Settings ▸ General ▸ Default Apps ▸ **Email** listesinde görünmek için
   ```xml
   <key>CFBundleDocumentTypes</key>
   <array>
     <dict>
       <key>CFBundleTypeName</key><string>Email Message</string>
       <key>CFBundleTypeRole</key><string>Viewer</string>
       <key>LSItemContentTypes</key><array>
         <string>com.apple.mail.email</string>
         <string>public.email-message</string>
       </array>
       <key>LSHandlerRank</key><string>Owner</string>
     </dict>
   </array>
   ```
3. **Opsiyonel:** `com.apple.default-app.mail-client` UTI'sini de claim et (Default Apps paneli bunu kullanıyor olabilir). → **Faz 0'da empirik doğrulanacak.**

### 2.2 Doğrulanmış public API'ler (SDK'dan teyit edildi)

| İş | API |
|---|---|
| Link'i almak | `AppDelegate.application(_:open:)` (`kInternetEventClass/kAEGetURL`) |
| **Tüm mailto handler uygulamalarını listelemek** (picker'ı doldurmak için) | `NSWorkspace.URLsForApplicationsToOpenURL(_:)` — macOS 12+ |
| Mevcut handler | `NSWorkspace.URLForApplicationToOpenURL(_:)` |
| **Belirli bir uygulamaya mailto açtırmak** | `NSWorkspace.openURLs(_:withApplicationAtURL:configuration:completionHandler:)` — macOS 10.15+ |
| Varsayılanı **programatik** değiştirmek | `NSWorkspace.setDefaultApplicationAtURL(_:toOpenURLsWithScheme:completionHandler:)` — macOS 12+ |
| UTI ile varsayılan değiştirmek | `setDefaultApplicationAtURL(_:toOpenContentType:)` |
| UTI → app çözümü | `URLForApplicationToOpenContentType(_:)` |
| **Fn tuşu** | `CGEventSource.flagsState(.combinedSessionState)` & `.maskSecondaryFn` (`NX_SECONDARYFNMASK`, CGEventTypes.h:92) |
| Erişilebilirlik izni | `AXIsProcessTrustedWithOptions` |
| Pano | `NIPasteboard.general` |
| Kısayollar | `AppIntents` / `AppShortcutsProvider` |

---

## 3. En kritik 3 teknik risk + spike planı

Bunlar yanlış giderse uygulamanın tamamı çalışmaz. **Faz 0'da küçük bir PoC ile doğrulanmalı.**

### 🔴 R1 — "Source app" (linkin hangi uygulamada tıklandığı) tespiti

Uygulama, LS tarafından `GURL` Apple Event ile uyandırılır. `NSAppleEventManager` gönderen süreci vermez (gönderen `launchservicesd`'dir). Adaylar:

| Yöntem | Nasıl | Risk |
|---|---|---|
| **A. `NSWorkspace.frontmostApplication`** | `LSUIElement = true` (agent app) yapılır → LS onu öne getirmez → frontmost app hâlâ **tıklandığı uygulama**dır. `applicationWillFinishLaunching` içinde oku. | En temiz, izin gerektirmez. **Aktivasyon yarışı** riski. |
| **B. Accessibility (`AXFocusedApplication`)** | `AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute)` | %100 doğru, ama **Erişilebilirlik izni** istiyor (kötü UX, Mailway'de iznin istenmediğini düşünüyoruz) |
| **C. `CGWindowListCopyWindowInfo`** | En üstteki pencerenin `kCGWindowOwnerPID` → app | İzin yok, ama kırılgan (masaüstü pencereleri, menubar) |

**Plan:** Önce **A**'yı dene. Çalışmazsa **B**'ye düş (izin isteyen tek ekran), sonra **C**.

### 🔴 R2 — Fn tuşunu algılamak için izin gerekiyor mu?

`CGEventSource.flagsState(.combinedSessionState).contains(.maskSecondaryFn)` — bu **Erişilebilirlik izni olmadan** doğru değer döndürüyor mu? StackOverflow'daki tartışmalar çelişkili.

**Plan:** PoC'te izin verilmemiş/verilmiş iki durumda test et.
- Erişilebilirlik zorunlu çıkarsa: `AXIsProcessTrustedWithOptions(prompt: true)` + kullanıcıyı bilgilendiren tek bir açıklama satırı.
- Alternatif: `NSEvent` global monitor (`addGlobalMonitorForEvents` → **Input Monitoring** izni) — daha ağır, tercih edilmez.

**Bonus (R2b):** Mailway sitesi "modifier key" diyor, ekran görüntüsü "Fn". **Varsayılan: `Fn`** (Globe), ayarlanabilir seçenek olarak `⌥ Option` de sun.

### 🟡 R3 — Varsayılan e-posta uygulaması ayarı

`setDefaultApplicationAtURL(_:toOpenURLsWithScheme:)` macOS 13+ çoğu durumda **sessizce başarısız** olabilir ( kullanıcı onayı gerekir).

**Plan:**
1. Bir **"Set as default email app"** durum göstergesi ekle (yoksa turuncu uyarı rozeti).
2. Birincil yol: `x-apple.systempreferences:com.apple.settings?PrivacySecurityExtensionPoint` — hayır, doğru yol `com.apple.systempreferences:com.apple.DefaultApps-Settings.extension` veya kullanıcıyı System Settings'e yönlendir.
3. `setDefaultApplicationAtURL` dene, hata gelirse UI'ı göster.

**Ayrıca `com.apple.default-app.mail-client` claim'inin Default Apps listesinde gerekli olup olmadığını empirik test et** (ilk Info.plist varyantıyla bak: listede görünüyor mu?).

---

## 4. Mimari

```
              ┌────────────────────────────────────────────┐
  mailto: ──► │ LS → GURL Apple Event → AppDelegate        │
              │   (LSUIElement = true, önce frontmostApp'ı  │
              │    yakala → RouteContext)                   │
              └───────────────┬────────────────────────────┘
                              ▼
                     ┌─────────────────┐
                     │    Router       │  Fn? → Alternative
                     └────────┬────────┘  (kurallar atlanır)
                              │ değilse
                     ┌────────▼────────┐
                     │  RuleEngine     │  ilk eşleşen kural
                     │  (sıralı, AND)  │  yoksa → Primary
                     └────────┬────────┘
                              ▼
                   ┌──────────────────────┐
                   │  TargetDispatcher    │
                   ├──────────────────────┤
                   │ nativeApp → openURLs(withApplicationAtURL:)
                   │ webmail   → şablon expand + open (default browser)
                   │ customURL → aynı
                   │ clipboard → NSPasteboard
                   └──────────┬───────────┘
                              ▼
                  NSApp.terminate()  (normal açılış değilse)
```

### Modül / dosya yapısı

```
MacMail/
├── project.yml                     # XcodeGen (opsiyonel, Xcode projesi de olur)
├── Sources/
│   ├── App/
│   │   ├── MacMailApp.swift              # @main, SwiftUI App
│   │   ├── AppDelegate.swift             # application(_:open:), launch context
│   │   └── LaunchContext.swift           # normal-launch vs route-launch ayrımı
│   ├── Model/
│   │   ├── EmailTarget.swift             # enum: nativeApp / webmail / customURL / clipboard
│   │   ├── WebmailProvider.swift         # hazır şablonlar (Gmail, Fastmail, …)
│   │   ├── Rule.swift                    # Codable, id, name, isEnabled, target, matchers, sourceApps
│   │   ├── RecipientMatcher.swift        # .emailAddress / .domain / .domainAndSubdomains
│   │   ├── InstalledMailApp.swift        # bundleId + url + ad + ikon
│   │   └── Settings.swift                # primary / alternative target, persistence
│   ├── Routing/
│   │   ├── MailtoParser.swift            # to/cc/bcc/subject/body + hfields
│   │   ├── RuleEngine.swift              # eşleştirme
│   │   ├── Router.swift                  # Fn → alternative, kurallar, primary
│   │   ├── SourceAppResolver.swift       # R1 spike'ının sonucu buraya
│   │   └── ModifierKeyReader.swift       # R2 spike'ının sonucu
│   ├── Dispatch/
│   │   ├── TargetDispatcher.swift
│   │   ├── NativeAppLauncher.swift
│   │   ├── WebmailURLBuilder.swift       # URI template expansion + percent-encode
│   │   └── ClipboardWriter.swift
│   ├── Intents/
│   │   ├── ComposeEmailIntent.swift
│   │   ├── TargetIntents.swift           # get/set primary + alternative
│   │   ├── RuleToggleIntents.swift       # enable/disable
│   │   └── MacMailShortcuts.swift        # AppShortcutsProvider + phrases
│   └── UI/
│       ├── RootView.swift                # General / Rules segment
│       ├── GeneralView.swift
│       ├── RulesView.swift
│       ├── RuleEditorSheet.swift
│       ├── TargetPickerRow.swift         # ikon + ad + chevron.up.chevron.down
│       ├── TargetPickerMenu.swift
│       ├── SourceAppPicker.swift
│       └── MailAppDiscovery.swift         # NSWorkspace.URLsForApplicationsToOpenURL
├── Resources/
│   ├── Assets.xcassets                   # AppIcon + AccentColor
│   ├── Info.plist                        # yukarıdaki LS claim'leri
│   └── MacMail.entitlements
└── Tests/
    ├── MailtoParserTests.swift
    ├── RuleEngineTests.swift
    ├── WebmailURLBuilderTests.swift
    └── TargetPersistenceTests.swift
```

---

## 5. Kritik uygulama detayları

### 5.1 `MailtoParser`

`mailto:?to=a@b.com&cc=c@d.com&subject=Hi&body=Hello%20world`

- `URLComponents` ile `queryItems`; `+` → boşluk dönüşümü **dikkatli** yapılmalı (mailto'da `+` literal `+` olabilir → `+` yerine `%2B` aranmalı, çünkü birçok web sitesi mailto'yu form-encoded üretir: **önce `+`→space dönüştür, sonra `%XX` decode et** — RFC 6068 `+` literal olmalı ama pratikte form-encoding kazanır).
- Alıcılar `?to=John%20Doe%20<john@x.com>` olabilir → **display name ayrıştır**, sadece adresi kullan.
- Tanınmayan `h*` header'ları yoksay.
- Hiç alıcı yoksa → target'a göre davranış (clipboard'ta boş string, webmail'de boş compose).

### 5.2 `RuleEngine`

```swift
struct MatchContext {
    let recipients: [EmailAddress]   // to + cc + bcc
    let sourceAppBundleIdentifier: String?
}

func matches(_ rule: Rule, _ ctx: MatchContext) -> Bool {
    guard rule.isEnabled else { return false }

    // Source app koşulu (varsa)
    if !rule.sourceAppBundleIdentifiers.isEmpty {
        guard let id = ctx.sourceAppBundleIdentifier,
              rule.sourceAppBundleIdentifiers.contains(id) else { return false }
    }

    // Alıcı koşulu — hiçbiri tanımlı değilse kayıt, koşul yok demektir
    guard !rule.recipientMatchers.isEmpty else { return true }

    return rule.recipientMatchers.contains { matcher in
        ctx.recipients.contains { recipient in matcher.matches(recipient) }
    }
}
```

Eşleştirme:
- `.emailAddress` → tam, **case-insensitive** eşitlik
- `.domain` → `recipient.domain == pattern` (alt domain **eşleşmez**)
- `.domainAndSubdomains` → `recipient.domain == pattern || recipient.domain.hasSuffix("." + pattern)`

### 5.3 Webmail şablonları

Değişkenler (URI Template, ama pratikte basit `{}` placeholder):
`{to}` `{cc}` `{bcc}` `{subject}` `{body}` `{mailto}` `{domain}`

| Sağlayıcı | Compose URL şablonu | Durum |
|---|---|---|
| Gmail | `https://mail.google.com/mail/?view=cm&fs=1&to={to}&cc={cc}&bcc={bcc}&su={subject}&body={body}` | doğrulanmalı |
| Fastmail | `https://app.fastmail.com/mail/compose?to={to}&cc={cc}&bcc={bcc}&subject={subject}&body={body}` | doğrulanmalı |
| Outlook 365 | `https://outlook.office.com/mail/deeplink/compose?to={to}&cc={cc}&bcc={bcc}&subject={subject}&body={body}` | doğrulanmalı |
| Outlook.com | `https://outlook.live.com/mail/deeplink/compose?to={to}&cc={cc}&bcc={bcc}&subject={subject}&body={body}` | doğrulanmalı |
| Yahoo | `https://compose.mail.yahoo.com/?to={to}&cc={cc}&bcc={bcc}&subject={subject}&body={body}` | doğrulanmalı |
| Yandex | `https://mail.yandex.com/compose?to={to}&cc={cc}&bcc={bcc}&subject={subject}&body={body}` | doğrulanmalı |
| AOL | `https://mail.aol.com/compose?to={to}&cc={cc}&bcc={bcc}&subject={subject}&body={body}` | doğrulanmalı |
| Zoho | `https://mail.zoho.com/mail/compose?to={to}&cc={cc}&bcc={bcc}&subject={subject}&body={body}` | doğrulanmalı |

Kurallar:
- Tüm değerler **`URLQueryAllowed` dışı karakterler için percent-encode** edilir (özellikle `&`, `=`, `#`, `+`, boşluk).
- **URL uzunluk koruması**: tarayıcılar ~32k–2MB sınırı koyar. Gövde çok uzunsa **gövdeyi kırp** ve uyarı göster (ya da gövdeyi hiç gönderme).
- `{mailto}` = **orijinal, encode edilmiş `mailto:` URL'inin tamamı** → self-hosted servisler için.
- `{domain}` = birinci alıcının domain'i.
- **Çoklu alıcı**: `{to}` = virgülle birleştirilmiş.

### 5.4 Native app hedefi

```swift
// Tüm mailto handler'ları bul (picker + hedef çözümü)
let candidates = NSWorkspace.shared.urlsForApplications(toOpen: mailtoURL)

// Belirli bir uygulamaya zorla aç
var config = NSWorkspace.OpenConfiguration()
config.activates = true
config.addsToRecentItems = false
NSWorkspace.shared.openURLs([mailtoURL],
                            withApplicationAtURL: targetAppURL,
                            configuration: config)
```
> Not: Hedef uygulama `LSUIElement` ise `openURLs(_:withApplicationAtURL:)` yine de çalışır (LaunchServices hedefi uygulamaya AE yollar).
> **Döngü koruması:** hedef uygulama bizim bundle ID'miz ise → engelle.

### 5.5 Launch context ve kapanma davranışı

```swift
func application(_ application: NSApplication, open urls: [URL]) {
    guard let mailto = urls.first(where: { $0.scheme == "mailto" }) else { return }

    // ⚠️ Kaynak uygulamayı BURADA, aktivasyondan ÖNCE yakala
    let sourceApp = SourceAppResolver.resolveFrontmostApp()

    let ctx = RouteContext(mailto: mailto, sourceApp: sourceApp)
    router.route(ctx)

    if !settingsWindowIsOpen { NSApp.terminate(nil) }
}
```
- `NSApp.terminate` **routing tamamlanana kadar ertele** (`NSWorkspace.open` async → completion handler'da terminate).
- Normal kullanıcı açılışı (`open -a MacMail` / Finder'dan çift tık) → ayar penceresi açılır, süreç yaşar.
- Ayar penceresi açıkken gelen mailto → route + **pencereyi kapatma**.

### 5.6 UI (SwiftUI, macOS 26)

Ekran görüntülerinden çıkarılan detaylar:
- Pencere ~**560×290 pt**, `titlebarAppearsTransparent = false`, toolbar **yok**, sidebar **yok**.
- Başlık çubuğunda solda traffic lights, **ortada sekme adı** ("General" / "Rules").
- Altında **2 büyük ikon-button** (General: gear, Rules: git-branch fork ikonu) — seçili olanın etrafında rounded-rect vurgu + **mavi accent label + ikon**, seçili olmayan gri.
- İçerik: `Form { }.formStyle(.grouped)` — rounded iç container, satır ayırıcıları, satır yüksekliği ~44pt.
- Satır içi hedef seçici: **ikon + ad + `chevron.up.chevron.down`** butonu → NSMenu.
- Alt bilgi metni: label, `.secondary`, küçük punto (`Alternative email app` altındaki ipucu).
- Sheet: `Edit Rule`, üstteki Name/Open-in grubu, ortada bölüm başlıkları + `+`, altta ayraç ve Cancel/Save.

---

## 6. Aşamalar (Roadmap)

### Faz 0 — Spike / risk doğrulama (0.5–1 gün) ⛔ EN ÖNEMLİ
Çıktı: çalışan **10 satırlık** PoC uygulaması + bulgu dokümanı.
- [ ] `Info.plist` LS claim'leri yaz → `lsregister -dump` içinde kayıt görünüyor mu?
- [ ] System Settings ▸ Default Apps ▸ Email listesinde görünüyor mu? `com.apple.default-app.mail-client` claim'i fark yaratıyor mu?
- [ ] Varsayılan olarak kendini atayabiliyor mu (`setDefaultApplicationAtURL`)? Hata veriyor mu?
- [ ] **R1**: `mailto:` event'i geliyor mu? `LSUIElement=true` iken `frontmostApplication` gerçekten tıklandığı uygulama mı? (Safari, Mail, Slack, Notes, Finder, Terminal'de test)
- [ ] **R2**: `flagsState(.combinedSessionState).maskSecondaryFn` izin vermeden çalışıyor mu?
- [ ] `openURLs(_:withApplicationAtURL:)` ile hedef uygulamaya (Mail + bir 3. parti client) mailto iletiliyor mu?
- [ ] Sonuç: `SPIKE-RESULTS.md` — hangi yöntem seçildi, gerekçesi

### Faz 1 — Çekirdek model + parser (1 gün)
- [ ] `MailtoParser` + birim testleri (to/cc/bcc/subject/body, display name, `+`, boş alıcı, hfields)
- [ ] `EmailTarget`, `Rule`, `RecipientMatcher`, `InstalledMailApp` modelleri (Codable)
- [ ] `Settings` + `UserDefaults` kalıcılık (kural listesi JSON olarak tek anahtarda)
- **Çıktı:** `MacMailParserTests` yeşil

### Faz 2 — Yönlendirme motoru + dispatcher (1–1.5 gün)
- [ ] `RuleEngine` + testler (3 matcher tipi × çoklu matcher × source app kombinasyonu × devre dışı kural)
- [ ] `WebmailURLBuilder` + testler (encoding, `{domain}`, `{mailto}`, uzun URL koruması)
- [ ] `NativeAppLauncher`, `ClipboardWriter`, `TargetDispatcher`
- [ ] `Router` + Fn/alternative mantığı
- [ ] `MailAppDiscovery` (kurulu mail client'ları listeleme, sıralama: Apple Mail üstte, alfabetik)
- **Çıktı:** Konsol/log ile uçtan uca routing testi geçiyor

### Faz 3 — Webmail sağlayıcı kataloğu (0.5 gün)
- [ ] 8 sağlayıcının URL'lerini **gerçek tarayıcıda tek tek test et**, çalışmayan parametreleri düzelt
- [ ] Gmail custom-domain senaryosunu test et
- [ ] Özel (self-hosted) servis için `{mailto}` değişkeni ile test
- **Çıktı:** `WEBMAIL.md` — doğrulanmış şablon tablosu

### Faz 4 — UI: General + Rules listesi (2 gün)
- [ ] `RootView` (segment, pencere boyutu, başlık)
- [ ] `GeneralView` (2 satır + ipuçları + "varsayılan değil" uyarısı)
- [ ] `TargetPickerMenu` (native app'lar / webmail'ler / custom URL / clipboard)
- [ ] `RulesView` (liste, toggle, özet satırı, `+`, boş durum)
- [ ] Silme onayı, yeniden sıralama (sürükle-bırak veya ↑↓)
- **Çıktı:** Ekran görüntülerindeki UI birebir

### Faz 5 — UI: Edit Rule sheet (1.5 gün)
- [ ] Name + Open-in
- [ ] Recipient Matchers: `+`/trash, dropdown, **türe göre değişen açıklama satırı**
- [ ] Source Apps: `+`, uygulma seçici, "No source apps" durumu
- [ ] Cancel/Save, doğrulama (isim boş, hedef yok, matcher geçersiz domain)
- **Çızdı:** `Mailway` screenshot3'teki sheet ile eşleşik

### Faz 6 — Kaynak uygulama tespiti + Fn + kısayollar (1.5 gün)
- [ ] Faz 0 sonucuna göre `SourceAppResolver`'ı kalıcı hale getir (gerekirse izin UI'ı)
- [ ] `ModifierKeyReader` (Fn; gerekirse ayarlanabilir)
- [ ] App Intents: ComposeEmail, Get/SetPrimaryTarget, Get/SetAlternativeTarget, Enable/DisableRule
- [ ] `AppShortcutsProvider` + önerilen shortcut grupları
- **Çıktı:** Shortcuts.app'te 8 aksiyon görünüyor ve çalışıyor

### Faz 7 — Cilt, ikon, paketleme, dağıtım (1 gün)
- [ ] Kendi ikonumuz (1024 → tüm boyutlar, `iconutil`/asset catalog)
- [ ] Accent rengi, koyu/light modda kontrol
- [ ] `LSUIElement = true`, `applicationShouldTerminateAfterLastWindowClosed` ayarı
- [ ] Sandbox **kapalı** (kişisel kullanım) → Developer ID imzası + minimal entitlements
- [ ] `xcodebuild` script ile dağıtım, `install` script (LS re-register dahil)
- [ ] README (kurulum, varsayılan ayarı, geri dönüş)
- **Çızdı:** `open -a MacMail` çift tık → ayar penceresi; mailto → doğru hedef, sonra quit

### Faz 8 — Kalite turu (0.5 gün)
- [ ] 15 senaryoluk manuel test (aşağıdaki test matrisi)
- [ ] Edge case'ler: hedef uygulama yok, uygulama kaldırılmış, boş mailto, 5MB gövde, unicode, çoklu alıcı, kural döngüsü
- [ ] Ayar penceresi açıkken mailto gelmesi
- [ ] Mailway ile yarış durumu (Mailway default ise biz de açılıyor mu?)

---

## 7. Test matrisi (Faz 8)

| # | Senaryo | Beklenen |
|---|---|---|
| T1 | Safari'de `mailto:a@gmail.com` | Gmail webmail açılır, `to` dolu |
| T2 | Mail.app içinden mailto | Primary hedefte açılır |
| T3 | Terminal: `open "mailto:?to=x@outlook.com&subject=Hi&body=Body"` | Outlook'ta açılır, konu/gövde dolu |
| T4 | `work.com` domain kuralı + `x@sub.work.com` | Kural **tutmaz** (exact domain) |
| T5 | `work.com` "domain and subdomains" + `x@sub.work.com` | Kural **tutar** |
| T6 | İki kural eşleşiyor | **Listede üstteki** kazanır |
| T7 | Kural devre dışı | Atlanır, primary'ye düşer |
| T8 | Source-app kuralı, Slack'te tıklandı | Kural tutar |
| T9 | Aynı kural, Safari'de tıklandı | Kural tutmaz |
| T10 | **Fn** basılıyken | Alternative hedef, kurallar atlanır |
| T11 | Clipboard hedefi | Panoya yalnızca adres kopyalanır, hiçbir şey açılmaz |
| T12 | Custom URL + `{mailto}` | Şablon doğru genişler, tarayıcıda açılır |
| T13 | Çoklu alıcı + cc/bcc | Tümü aktarılır |
| T14 | Uygulama mailto sonrası | **Kapanmış** olmalı |
| T15 | Boş `mailto:` | Çökme yok, anlamlı davranış |
| T16 | Hedef uygulama uninstall edilmiş | Açık uyarı / graceful fallback |
| T17 | Ayar penceresi açıkken mailto | Route edilir, pencere **kalır** |
| T18 | 100KB gövde | Kırpılır veya uyarı verilir, URL patlamaz |
| T19 | Shortcuts: "Compose Email with X" | İlgili hedefte compose açılır |
| T20 | `⌘Q` / ayarı kapat | Temiz çıkış |

---

## 8. Yapı & dağıtım

```
# Geliştirme döngüsü
open MacMail.xcodeproj
xcodebuild -scheme MacMail -configuration Debug build

# LS'a kayıt (geliştirme)
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
  -f ./build/MacMail.app

# Kurulum
cp -R ./build/MacMail.app /Applications/

# Kayıt doğrulama
lsregister -dump | grep -A3 macmail
```

Dağıtım kararları:
| Konu | Karar | Gerekçe |
|---|---|---|
| Minimum macOS | **15.0 (Sequoia)** ile başla, istersen 26.0 | Daha geniş uyum; SwiftUI API'ler mevcut |
| Sandbox | **Kapalı** (ilk sürüm) | `/Applications` taraması + LS kayıt sorunları yok; kişisel kullanımda yasal risk yok. Sonra sandbox'a geçirmek istenirse `com.apple.security.files.user-selected.read-only` gerekir. |
| İmza | Ad-hoc (`codesign -s -`) | Yerel kullanım yeterli. Dağıtacaksan Developer ID + Notarization |
| Min macOS 26 olmalı mı? | Hayır | Mailway 26.4 istiyor çünkü yeni tasarım API'leri kullanıyor; işlevsel gerekçesi yok |

---

## 9. Bilinen sınırlar / kararlar

1. **İnteraktif seçici yok** — Mailway bunu bilinçli olarak yapmıyor, biz de yapmayacağız (bir mailto için her seferinde picker istemek sinir bozucu).
2. **Konu/gövde eşleştirme yok** — sadece alıcı + kaynak uygulama.
3. **Regex yok** — exact / domain / domain+subdomain.
4. **iOS yok** — iOS `mailto:` yakalamaya izin vermiyor.
5. **Launch at login yok** — gereksiz.
6. **Tarayıcı profili seçimi yok** — Velja'nın işi; biz sadece `NSWorkspace.open` ile varsayılan tarayıcıya bırakıyoruz.
7. **Proton Mail web compose yok** — masaüstü uygulaması native hedef olarak seçilebilir.
8. **Sekme/sayfa yenilemede state** — uygulama kapandığı için "hangi hedefe gittik" gibi bir geçmiş tutmuyoruz.

---

## 10. Tahmini süre

| Faz | Süre |
|---|---|
| Faz 0 – Spike | 0.5–1 gün |
| Faz 1 – Model + parser | 1 gün |
| Faz 2 – Router + dispatcher | 1–1.5 gün |
| Faz 3 – Webmail kataloğu | 0.5 gün |
| Faz 4 – UI (General + Rules) | 2 gün |
| Faz 5 – UI (Edit Rule sheet) | 1.5 gün |
| Faz 6 – Source app + Fn + Intents | 1.5 gün |
| Faz 7 – Cilt + paketleme | 1 gün |
| Faz 8 – Test turu | 0.5 gün |
| **Toplam** | **≈ 9–11 gün** |

---

## 11. Şimdi ne yapalım?

Önerilen sıra: **Faz 0'a başla.** Çünkü R1 (kaynak uygulama tespiti) ve R3 (varsayılan e-posta uygulaması) başarısız olursa geri kalan 10 günün tamamı boşa gider. PoC küçük olsun (tek pencere, tek `print`), 1 günde üç soruya da cevap verir.
