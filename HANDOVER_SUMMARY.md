# mailto: Geliştirme Özeti & Devir Teslim Dokümanı (Handover)

**Tarih:** 4 Ekim 2026  
**Aktif Sürüm:** v1.3.1 (Build 14)  
**Proje Konumu:** `/Users/atalayhuryasar/Desktop/mailto`  
**GitHub Reposu:** `git@github.com:atalayhuryasar/mailto.git`  
**Homebrew Tap:** `atalayhuryasar/homebrew-tap` (`atalayhuryasar/tap/mailto`)  
**Web Sitesi:** `https://mailto.huryasar.com`

---

## 1. Bugün Tamamlanan Başarılar & Çözümler

### A. "Copy to Clipboard" ve Sıfır Kaynak Kapanma Hatası (v1.3.1 Çözüldü)
* **Kök Neden:** macOS LaunchServices üzerinden gelen `mailto:` AppleEvent'leri SwiftUI lifecycle tarafından bazen atlanıyordu. Ayrıca `TargetDispatcher`'da panoya kopyalama yapıldıktan hemen sonra `NSApp.terminate(nil)` çağrıldığında, `pboard` daemon'ı IPC işlemini tamamlayamadan süreç ölüyordu.
* **Çözüm:**
  - `AppDelegate.swift` içine yerel `NSAppleEventManager.kAEGetURL` dinleyicisi ve `MailtoApp.swift` içine `.onOpenURL` eklendi.
  - Panoya yazım (`NSPasteboard.general`) sonrası hafif bir sistem sesi (`Tink`) eklendi ve IPC senkronizasyonu için 150 ms mikro bekleme konuldu.
  - Alıcı yoksa fallback mekanizması kuruldu (`cc`, `bcc` veya ham bağlantı).
  - Canlı testle (`open "mailto:..."`) panoya kopyalama ve anında kapanma başarıyla doğrulandı.
  - `v1.3.1` olarak GitHub Releases ve Homebrew Tap'te yayımlandı.

### B. Proje Klasörü & Masaüstü Temizliği
* Masaüstündeki eski `MacMail` adı tamamen kaldırıldı; proje tek bir gerçek dizin olarak doğrudan **`/Users/atalayhuryasar/Desktop/mailto`** yapıldı.
* Kod tabanındaki ve scriptlerdeki eski bundle/klasör referansları temizlendi.

### C. Mac App Store (MAS) Çift Dağıtım Mimarisi (Dual-Distribution)
* Tek kod tabanından hem **GitHub/Homebrew** hem de **Mac App Store** sürümlerini derleyen altyapı kuruldu:
  - **`#if !APPSTORE` İzolasyonu:** `UpdateChecker`, `AppUpdater` ve ilk açılıştaki `/Applications` klasörüne taşıma prompt'u MAS derlemesinde derleme seviyesinde tamamen çıkarıldı (Apple Review Guideline 2.5.2 uyumu).
  - **Sandbox Entitlements:** MAS için `Resources/mailto-sandbox.entitlements` oluşturuldu (`com.apple.security.app-sandbox = true`).
  - **MAS Derleme Scripti:** `scripts/build-mas.sh` eklendi (`-DAPPSTORE` ile derleyip `build/mas/mailto.pkg` üretir).
  - Doğrudan dağıtım scripti `scripts/build-app.sh` bağımsız güncelleyicisiyle `build/mailto.zip` üretmeye devam ediyor.

### D. Homebrew Tap CI/CD Hatasının Giderilmesi
* `Casks/mailto.rb` içindeki Homebrew RuboCop linter hataları giderildi (`desc` içindeki platform adı silindi, `zap trash` dizinleri alfabetik sıralandı).
* `brew style` ve `brew audit` 0 hatayla geçti; GitHub Actions `brew test-bot` çalışması **yeşil (Success ✓)** oldu.

---

## 2. Mevcut Proje Durumu

* **Birim Testleri:** 65/65 test geçiyor (`swift test`).
* **Git Durumu:** `main` branch güncel ve GitHub ile senkronize.
* **Kurulu Uygulama:** `/Applications/mailto.app` (v1.3.1) aktif ve test edilmiş durumda.

---

## 3. Yarın / Sonraki Oturumda Yapılacaklar (Roadmap)

### Öncelik: Mac App Store Yayınına Hazırlık
1. **Gizlilik Politikası Sayfası:**
   - `mailto.huryasar.com/privacy` adresine veya web sitesine uygulamanın hiçbir veri toplamadığını (Zero Data Collection / Zero Analytics) açıklayan basit bir gizlilik sayfası eklemek.
2. **Apple Developer & App Store Connect Ayarları:**
   - Apple Developer Hesabı ($99/yıl) üzerinde `com.atalayhuryasar.mailto` App ID'sini açıp Sandbox yetkisini tanımlamak.
   - Dağıtım sertifikaları (*Apple Distribution* ve *Mac Installer Distribution*) ve provisioning profile oluşturmak.
   - App Store Connect üzerinde yeni macOS uygulaması kaydetmek (`mailto:`).
3. **Mağaza Varlıkları (Assets):**
   - 1024x1024 px saydamlıksız App Store uygulama ikonu.
   - 3-4 adet yüksek çözünürlüklü Retina ekran görüntüsü (Yönlendirme yeteneği, Temiz ayarlar ekranı, Akıllı kurallar sekmesi, Pano kopyalama özelliği).
   - Apple Review ekibi için test notu metni.
4. **Paketleme & Yükleme:**
   - `./scripts/build-mas.sh` çalıştırılarak imzalı `mailto.pkg` üretilecek.
   - Transporter uygulaması veya `xcrun altool` ile App Store Connect'e gönderim yapılacak.

---
*İyi dinlenmeler! Yarın kaldığımız yerden hızla devam edebiliriz.*
