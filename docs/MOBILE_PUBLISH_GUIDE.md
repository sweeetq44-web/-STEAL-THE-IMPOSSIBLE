# 📱 Bilgisayarsız (Sadece Telefondan) Roblox'a Yayınlama Rehberi

Bilgisayarın olmadan **GitHub Actions + Roblox Open Cloud** kullanarak `StealTheImpossible.rbxlx` dosyasını doğrudan telefonundan kendi Roblox hesabına yayınlayabilirsin.

---

## Adım 1 — Telefondan Roblox Universe ID, Place ID ve API Key Alma
Telefonunun tarayıcısından (Chrome/Safari) **Masaüstü Sitesi (Desktop Site)** modunu açman butonları çok daha rahat görmeni sağlar:

1. **`https://create.roblox.com`** adresine gir ve Roblox hesabınla giriş yap.
2. **Creations** bölümüne gir → mevcut başlangıç oyununa (veya yeni bir Experience oluşturduysan ona) tıkla.
3. Sayfanın üst veya sol menüsünden ID'leri not al:
   - **Universe ID**: URL'de `/creations/experiences/<UNIVERSE_ID>/overview` kısmındaki sayı veya Overview → Configure Experience içindeki **Universe ID**.
   - **Place ID**: Sol menüden **Places** → Başlangıç Place'ine tıkla; URL'de `/places/<PLACE_ID>/configure` kısmındaki sayı.
   - *(Önemli Ayarlar)*: Aynı yerden **Configure Experience → Max Players = 8** ve **Access → Public** (oynamak istediğin kişilere göre Public veya Friends) ile **Security → Enable Studio Access to API Services** ayarlarını aç.
4. Şimdi sol menüde **Open Cloud → API Keys** sayfasına git → **Create API Key** de:
   - **Name**: `GitHubPublish`
   - **Access Permissions → Add API System**: **`universe-places`** seç.
   - **Experience**: Kendi oyununun adını ekle ve **Operation**: **`Write`** (`universe-places:write`) yetkisini seç.
   - **Security → Accepted IP Addresses**: GitHub sunucularının bağlanabilmesi için `0.0.0.0/0` gir.
   - **Save & Generate Key** butonuna bas ve çıkan uzun anahtarı kopyala! *(Güvenliğin için bu anahtarı kimseyle paylaşma.)*

---

## Adım 2 — GitHub Deposuna 3 Gizli Anahtar (Secret) Ekleme
1. Telefon tarayıcısından GitHub'daki **`sweeetq44-web/-STEAL-THE-IMPOSSIBLE`** depona git.
2. **Settings** → **Secrets and variables** → **Actions** → **New repository secret** yolunu izle ve şu **3** kaydı sırayla ekle:
   - Name: `ROBLOX_API_KEY` → Value: Az önce kopyaladığın API anahtarı
   - Name: `ROBLOX_UNIVERSE_ID` → Value: Sadece rakamlardan oluşan Universe ID
   - Name: `ROBLOX_PLACE_ID` → Value: Sadece rakamlardan oluşan Place ID

---

## Adım 3 — Telefondan Tek Tuşla Yayınla!
1. GitHub'da deponun **Actions** sekmesine gir (eğer GitHub bu proje için workflow'ları ilk kez sorarsa *I understand my workflows, go ahead and enable them* butonuna bas).
2. Sol listeden **`Publish to Roblox (No PC Needed)`** akışını seç.
3. **Run workflow** butonuna tıkla:
   - **Use workflow from**: kodun bulunduğu güncel dalı (`main` veya `arena/2e8bd490-steal-the-impossible`) seç.
   - **version_type**: **`Published`** kalsın.
   - Yeşil **Run workflow** butonuna bas!
4. ~30–45 saniye içinde GitHub önce **47 `.luau` dosyasını derleyip 131 testi geçirecek**, ardından `StealTheImpossible.rbxlx` dosyasını otomatik olarak **senin Roblox Place'ine yükleyecek**!

---

## Adım 4 — Telefonundan Oyna!
- İşlem yeşil tik (✅) aldıktan sonra telefonundaki resmi **Roblox** uygulamasını aç → Profilin → **Creations** bölümünden oyununa gir ve oyna!
- *(Not: İnternetteki resmi olmayan "Roblox Lite" APK'larını kullanma; hesap güvenliği için daima Google Play / App Store'daki resmi Roblox uygulamasını kullan.)*
