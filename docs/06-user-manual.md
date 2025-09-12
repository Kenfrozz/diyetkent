# 📱 DiyetKent - Son Kullanıcı Kılavuzu

## 📋 İçindekiler
- [Uygulamaya Giriş](#uygulamaya-giriş)
- [Profil Kurulumu](#profil-kurulumu)
- [Mesajlaşma Sistemi](#mesajlaşma-sistemi)
- [Diyet Programları](#diyet-programları)
- [Sağlık Takibi](#sağlık-takibi)
- [Story (Hikaye) Sistemi](#story-hikaye-sistemi)
- [Ayarlar ve Kişiselleştirme](#ayarlar-ve-kişiselleştirme)
- [Sorun Giderme](#sorun-giderme)

---

## 🚀 Uygulamaya Giriş

### 📱 **İlk Kurulum ve Kayıt**

#### **1. Uygulamayı İndirin ve Açın**
- Play Store veya App Store'dan "DiyetKent" uygulamasını indirin
- Uygulamayı açın ve karşınıza çıkan giriş ekranını görün

#### **2. Telefon Numarası ile Kayıt**

```
🔐 Güvenli Giriş Süreci
┌─────────────────────────────────────┐
│  1. Telefon numaranızı girin        │
│     Format: +90 5XX XXX XX XX       │
│                                     │
│  2. "SMS Gönder" butonuna tıklayın  │
│                                     │
│  3. SMS kodunu bekleyin (1-2 dk)    │
│                                     │
│  4. 6 haneli kodu girin             │
│                                     │
│  5. "Doğrula" butonuna tıklayın     │
└─────────────────────────────────────┘
```

**🕐 Önemli Notlar:**
- SMS kodu 3 dakika geçerlidir
- Kod gelmezse "Tekrar Gönder" seçeneğini kullanabilirsiniz
- Yanlış numara girdiysesek geri dönüp düzeltebilirsiniz

#### **3. İzinleri Onaylayın**
Uygulama aşağıdaki izinleri isteyecektir:

| İzin | Neden Gerekli | Zorunlu mu? |
|------|---------------|-------------|
| 📞 **Telefon** | SMS doğrulama için | ✅ Evet |
| 📇 **Rehber** | Kişilerinizi bulmak için | ❌ İsteğe bağlı |
| 📷 **Kamera** | Fotoğraf çekip göndermek için | ❌ İsteğe bağlı |
| 📁 **Depolama** | Medya dosyalarını kaydetmek için | ❌ İsteğe bağlı |
| 🔔 **Bildirimler** | Mesaj bildirimleri için | 🔄 Önerilen |

---

## 👤 Profil Kurulumu

### 🖼️ **Profil Fotoğrafı Ekleme**

#### **Seçenek 1: Kameradan Fotoğraf**
1. Profil fotoğrafı alanına tıklayın
2. "Fotoğraf Çek" seçeneğini seçin
3. Fotoğrafınızı çekin
4. Fotoğrafı kırpın ve onaylayın

#### **Seçenek 2: Galeriden Seçim**
1. "Galeriden Seç" seçeneğini tıklayın
2. Mevcut fotoğraflarınızdan birini seçin
3. Fotoğrafı kırpın ve onaylayın

**💡 İpuçları:**
- İyi aydınlatmalı, net fotoğraflar kullanın
- Yüzünüzü gösterir fotoğraf seçin
- Kare format en iyisidir
- Fotoğraf otomatik sıkıştırılır

### ✏️ **Temel Bilgileri Doldurma**

#### **📝 Zorunlu Bilgiler**
```
👤 Ad Soyad
├── En az 2 karakter
├── En fazla 30 karakter  
├── Sadece harf karakterleri
└── Türkçe karakter desteği

📞 Telefon Numarası
├── Otomatik doldurulur
├── SMS ile doğrulanmış
└── Değiştirilemez
```

#### **📋 İsteğe Bağlı Bilgiler**
```
💬 Hakkımda
├── En fazla 200 karakter
├── Emoji kullanabilirsiniz
├── Kişisel durum mesajı
└── Örnek: "Sağlıklı yaşam tutkunu 🌱"

🎂 Yaş Bilgisi
├── BMI hesaplamaları için önemli
├── Doğum yılı olarak girilir
└── Diyet önerileri için kullanılır
```

### 🏥 **Sağlık Bilgilerini Girme**

#### **📊 Fiziksel Ölçümler**
```
📏 Boy (cm)
├── 100-250 cm arası
├── BMI hesaplama için gerekli
└── Örnek: 170 cm

⚖️ Kilo (kg)
├── 30-300 kg arası
├── BMI hesaplama için gerekli
├── İlerleme takibi için kaydet
└── Örnek: 75.5 kg

🎯 Hedef Kilo (kg)
├── İsteğe bağlı
├── Motivasyon takibi için
└── Örnek: 68 kg
```

**✅ Profil Tamamlandı!**
Artık uygulamanın tüm özelliklerini kullanabilirsiniz.

---

## 💬 Mesajlaşma Sistemi

### 📱 **Ana Ekran - Sohbetler**

#### **🏠 Ana Ekran Bileşenleri**
```
DiyetKent Ana Ekran
┌─────────────────────────────────────┐
│  🏥 BMI: 23.4 (Normal) | 👟 6,245   │ ← AppBar (Sağlık göstergeleri)
├─────────────────────────────────────┤
│  📋 Tümü | 💬 Okunmamış | 👥 Gruplar │ ← Filtreler
├─────────────────────────────────────┤
│  👤 Dr. Ayşe Kaya      14:30 ✓✓    │ ← Sohbet listesi
│     Merhaba, nasılsın?              │
│                                     │
│  👥 Diyet Grubu        12:45       │
│     Fotoğraf                        │
│                                     │
│  👤 Mehmet Bey         09:15 ✓     │
│     Teşekkürler                     │
└─────────────────────────────────────┘
```

#### **🔍 Arama ve Filtreleme**
- **🔍 Arama çubuğu**: Üst kısmında arama yapabilirsiniz
- **📋 Tümü**: Tüm aktif sohbetler
- **💬 Okunmamış**: Sadece okunmamış mesajları olanlar
- **👥 Gruplar**: Grup sohbetleri
- **🏷️ Etiketler**: Diyetisyen tarafından atanmış etiketler (varsa)

### 💬 **Mesaj Gönderme ve Alma**

#### **📝 Metin Mesajı Gönderme**
1. Sohbet listesinden kişiye tıklayın
2. Alt kısımdaki metin kutusuna mesajınızı yazın
3. **Gönder** butonuna tıklayın (📤) veya Enter'a basın

**💡 Metin Mesajı İpuçları:**
- Emoji kullanabilirsiniz 😊
- Uzun mesajlarda otomatik satır bölünür
- Mesaj gönderildikten sonra düzenlenemez
- Link'ler otomatik tıklanabilir hale gelir

#### **📎 Medya Gönderme**

##### **📷 Fotoğraf Gönderme**
```
Fotoğraf Gönderme Seçenekleri
┌─────────────────────────────────────┐
│  📷 Fotoğraf Çek                    │
│  🖼️ Galeriden Seç                   │
│  📊 Belge Gönder                    │
│  📍 Konum Paylaş                    │
│  👤 Kişi Paylaş                     │
└─────────────────────────────────────┘
```

**Fotoğraf Çekme:**
1. 📎 butonuna tıklayın
2. "Fotoğraf Çek" seçin
3. Fotoğrafınızı çekin
4. İsteğe bağlı açıklama ekleyin
5. Gönder butonuna tıklayın

**Galeriden Seçme:**
1. "Galeriden Seç" seçeneğini tıklayın
2. Göndermek istediğiniz fotoğrafı seçin
3. Fotoğraf otomatik sıkıştırılır
4. Açıklama ekleyip gönderin

##### **🎥 Video Gönderme**
- Maksimum 2 dakika uzunluğunda videolar
- Otomatik video sıkıştırması
- Video önizlemesi mevcut
- WiFi bağlantısında daha hızlı yüklenir

##### **📄 Belge Gönderme**
- PDF, DOCX, TXT, XLS formatları desteklenir
- Maksimum dosya boyutu: 10 MB
- Belge adı ve boyutu gösterilir
- İndirme ve açma seçenekleri

##### **🎵 Ses Kaydı Gönderme**
1. Mikrofon butonuna basın ve basılı tutun
2. Konuşmanızı kaydettirin
3. Bıraktığınızda otomatik gönderilir
4. İptal etmek için yukarı kaydırın

#### **💬 Gelişmiş Mesaj Özellikleri**

##### **↩️ Mesajlara Yanıt Verme**
1. Yanıt vermek istediğiniz mesaja uzun basın
2. "Yanıtla" seçeneğini seçin
3. Yanıtınızı yazıp gönderin
4. Orijinal mesaj mini önizlemede gösterilir

##### **📤 Mesaj İletme**
1. İletmek istediğiniz mesaja uzun basın
2. "İlet" seçeneğini seçin
3. Göndermek istediğiniz kişi/grupları seçin
4. "Gönder" butonuna tıklayın

##### **🗑️ Mesaj Silme**
- **Sadece benden sil**: Mesaj sadece sizin telefonunuzdan silinir
- **Herkesten sil**: Mesaj tüm katılımcılardan silinir (5 dakika içinde)

### 📱 **Sohbet Ekranı Özellikleri**

#### **👀 Mesaj Durumları**
| Simge | Anlam |
|-------|-------|
| 🕐 | Gönderiliyor... |
| ✓ | Gönderildi |
| ✓✓ | Karşı tarafa ulaştı |
| ✓✓💙 | Okundu |
| ❌ | Gönderilemedi |

#### **⌨️ Yazıyor Göstergesi**
- Karşı taraf yazarken "yazıyor..." göstergesi
- 3 saniye boyunca gösterilir
- Gerçek zamanlı güncelleme

#### **👀 Son Görülme Bilgisi**
- Kişinin profil fotoğrafı altında
- "Çevrimiçi", "5 dakika önce görüldü" gibi
- Gizlilik ayarlarına bağlıdır

---

## 👥 Grup Sohbetleri

### 👥 **Grup Oluşturma**

#### **📝 Yeni Grup Oluşturma**
1. Ana ekranda ➕ butonuna tıklayın
2. "Yeni Grup" seçeneğini seçin
3. Grup üyelerini seçin (en az 2 kişi)
4. "İleri" butonuna tıklayın
5. Grup bilgilerini doldurun:

```
👥 Grup Bilgileri
┌─────────────────────────────────────┐
│  📷 Grup Fotoğrafı (isteğe bağlı)   │
│  📝 Grup Adı (zorunlu)              │
│  📋 Grup Açıklaması (isteğe bağlı)  │
│  👑 Admin Yetkilerini Ayarla        │
└─────────────────────────────────────┘
```

#### **⚙️ Grup Yönetimi**
**👑 Admin Yetkileri:**
- Üye ekleme/çıkarma
- Grup bilgilerini düzenleme
- Admin atama/kaldırma
- Grup ayarlarını değiştirme

**👤 Üye Yetkileri:**
- Mesaj gönderme
- Medya paylaşımı
- Gruptan ayrılma

#### **📋 Grup Ayarları**
1. Grup sohbetine girin
2. Grup adına tıklayın
3. Ayarlar menüsüne erişin

**Mevcut Ayarlar:**
- **🔒 Mesaj İzinleri**: Kim mesaj gönderebilir?
- **📎 Medya İzinleri**: Kim medya paylaşabilir?
- **👥 Üye Ekleme**: Üyeler başka kişi ekleyebilir mi?
- **📋 Grup Bilgisi**: Kim grup bilgilerini düzenleyebilir?

---

## 🍎 Diyet Programları

### 📊 **Diyet Programına Başlama**

#### **🔍 Size Uygun Diyet Bulma**
DiyetKent, BMI değerinize göre otomatik diyet önerir:

```
🏥 Otomatik Diyet Seçim Sistemi
┌─────────────────────────────────────┐
│  1. BMI Hesaplama                   │
│     Boy + Kilo + Yaş bilgileriniz   │
│                                     │
│  2. Kategori Belirleme              │
│     21-25: Normal kilo              │
│     26-29: Fazla kilo               │
│     30-33: Obez                     │
│     34+:   Morbid obez              │
│                                     │
│  3. Uygun Diyet Seçimi              │
│     Kategorinize özel diyet listesi │
└─────────────────────────────────────┘
```

#### **📋 Diyet Programı Alma Süreci**
1. **Diyetisyenle İletişim**: Diyetisyeninizle mesajlaşın
2. **Sağlık Bilgilerinizi Paylaşın**: Boy, kilo, yaş bilgilerini güncel tutun
3. **Diyet Paketi Atanır**: Diyetisyen size uygun paketi atar
4. **PDF Alın**: Kişiselleştirilmiş diyet listenizi PDF olarak alın
5. **Takip Edin**: İlerlemenizi sürekli kaydedin

#### **📄 Diyet PDF'i Özellikleri**
```
📄 Kişiselleştirilmiş Diyet PDF'i
┌─────────────────────────────────────┐
│  👤 Kişisel Bilgileriniz            │
│     Ad, yaş, boy, kilo, BMI         │
│                                     │
│  📊 Hedef Bilgileri                 │
│     İdeal kilo, hedef kilo          │
│                                     │
│  🍎 Diyet Programı                  │
│     Günlük öğün planları            │
│     Porsiyon önerileri              │
│     İçecek tavsiyeleri              │
│                                     │
│  ⏰ Tarih Bilgileri                 │
│     Başlangıç - Bitiş tarihleri     │
│     Kontrol tarihleri               │
└─────────────────────────────────────┘
```

### 📈 **İlerleme Takibi**

#### **⚖️ Günlük Kilo Girişi**
1. Ana ekranda BMI göstergesine tıklayın
2. "Kilo Girişi" seçeneğini seçin
3. Güncel kilonuzu girin
4. "Kaydet" butonuna tıklayın

**📊 Kilo Grafiği:**
- Son 30 günlük kilo değişimi
- Trend çizgileri (artış/azalış)
- Hedef kilo çizgisi
- BMI değişimi gösterimi

#### **🎯 Hedef Takibi**
```
🎯 Hedef İlerleme Göstergesi
┌─────────────────────────────────────┐
│  Mevcut: 75.2 kg                    │
│  Hedef:  68.0 kg                    │
│                                     │
│  [████████░░] 72% tamamlandı        │
│                                     │
│  Kalan: 7.2 kg                      │
│  Tahmini süre: 8 hafta             │
└─────────────────────────────────────┘
```

### 📅 **Diyet Takvimi**

#### **🗓️ Haftalık Program**
- Her gün için öğün planları
- Tamamlanan günleri işaretleme
- Sonraki diyet listesi bilgisi
- Önemli notlar ve hatırlatmalar

#### **⏰ Öğün Hatırlatıcıları**
Diyetisyeniniz size özel saatlerde hatırlatıcı gönderebilir:
- **☀️ Kahvaltı**: 08:00
- **🌞 Ara Öğün**: 10:30
- **🌅 Öğle**: 12:30
- **🌆 İkindi**: 15:30
- **🌙 Akşam**: 18:30
- **💧 Su İçme**: Her 2 saatte bir

---

## 📊 Sağlık Takibi

### 🏥 **BMI Hesaplama ve Takip**

#### **📐 BMI Hesaplama**
BMI (Beden Kitle İndeksi) otomatik olarak hesaplanır:

```
BMI = Kilo (kg) / Boy² (m²)

📊 BMI Kategorileri:
├── 18.5 altı    → Zayıf
├── 18.5 - 24.9  → Normal
├── 25.0 - 29.9  → Fazla Kilo
├── 30.0 - 34.9  → Obez (1. Derece)
└── 35.0 üstü    → Obez (2. Derece)
```

#### **🎯 Yaş Tabanlı İdeal Kilo**
DiyetKent yaşınızı dikkate alarak ideal kiloyu hesaplar:

| Yaş Grubu | İdeal BMI | Formül |
|-----------|-----------|--------|
| **<35 yaş** | 21 | Boy² × 21 |
| **35-45 yaş** | 22 | Boy² × 22 |
| **45+ yaş** | 23 | Boy² × 23 |

#### **⚠️ Maksimum Güvenli Kilo**
Sağlığınızı riske atmayacak maksimum kilo:

| Yaş Grubu | Max BMI | Formül |
|-----------|---------|--------|
| **<35 yaş** | 27 | Boy² × 27 |
| **35-45 yaş** | 28 | Boy² × 28 |
| **45+ yaş** | 30 | Boy² × 30 |

### 👟 **Adım Sayacı**

#### **📱 Adım Takibi**
- Telefonunuzun yerleşik sensörleri kullanılır
- 24/7 otomatik adım sayımı
- Günlük 10,000 adım hedefi

#### **📊 Adım İstatistikleri**
```
👟 Günlük Adım Raporu
┌─────────────────────────────────────┐
│  📊 6,245 / 10,000 adım             │
│  [████████░░] %62 tamamlandı        │
│                                     │
│  🔥 ~250 kalori yakıldı            │
│  📏 ~4.8 km yürüdünüz               │
│  ⏱️ ~45 dakika aktiflik             │
└─────────────────────────────────────┘
```

#### **🏆 Adım Başarıları**
- **🥉 Başlangıç**: 5,000 adım
- **🥈 İyi**: 7,500 adım  
- **🥇 Mükemmel**: 10,000+ adım
- **🔥 Süper**: 15,000+ adım

### 📈 **Sağlık Dashboard'u**

#### **🏥 Genel Sağlık Özeti**
Ana ekranda her zaman görünen kompakt bilgiler:

```
🏥 Sağlık Özeti (AppBar)
┌─────────────────────────────────────┐
│  BMI: 23.4 (Normal) | 👟 6,245     │
│     ↑ +0.2         |    ↑ +1,234   │
└─────────────────────────────────────┘
      ↑ Haftalık değişim
```

#### **📊 Detaylı Sağlık Raporu**
Sağlık göstergesine tıklayarak detaylı raporu görün:
- Son 30 günlük kilo grafiği
- BMI değişim trendi
- Adım sayımı istatistikleri
- Hedef ilerleme durumu
- Sağlık önerileri

### 🎯 **Motivasyon Sistemi**

#### **🏆 Başarı Rozetleri**
- **📉 Kilo Kaybı Rozetleri**: 1kg, 5kg, 10kg
- **📈 Hedef Yaklaşma**: %25, %50, %75, %100
- **👟 Adım Rozetleri**: 50K, 100K, 250K adım
- **📅 Süreklilik**: 7, 30, 90 gün

#### **💪 Motivasyon Mesajları**
Sisteminiz size özel mesajlar gönderir:
- "🎉 Tebrikler! Hedefinizin %50'sine ulaştınız!"
- "💪 Harika gidiyorsunuz! 2kg daha kaldı!"
- "🔥 Bugün 12,000 adım attınız - süpersiniz!"

---

## 📖 Story (Hikaye) Sistemi

### 📱 **Story'leri Görüntüleme**

#### **👀 Story Görüntüleme Arayüzü**
Ana ekranda üst kısımda story çemberleri görünür:

```
📖 Story Bölümü
┌─────────────────────────────────────┐
│ (👤) (👤+) (👥) (👤) (👤)           │
│  Sen  Dr.A  Grup Mehmet Ayşe       │
└─────────────────────────────────────┘
     ↑      ↑      ↑
  Senin  Yeni   Grup
  Story  Story  Story
```

#### **🎬 Story İzleme**
1. Bir story çemberine tıklayın
2. Story tam ekranda açılır
3. Dokunarak sonrakine geçin
4. Uzun basarak duraklatın
5. Kaydırarak diğer kişinin story'lerine geçin

**Story Kontrolleri:**
- **▶️ İleri**: Ekranın sağına dokunun
- **⏮️ Geri**: Ekranın soluna dokunun  
- **⏸️ Duraklat**: Uzun basın
- **💬 Yanıtla**: Yukarı kaydırın
- **❌ Çık**: Aşağı kaydırın

### 📸 **Story Paylaşma**

#### **📷 Fotoğraf Story'si**
1. Story bölümünde kendi profilinize tıklayın
2. "Fotoğraf Çek" veya "Galeriden Seç"
3. Fotoğrafınızı editörlerde düzenleyin:

```
🎨 Story Editörü
┌─────────────────────────────────────┐
│  📝 Metin Ekle                      │
│  🖍️ Çizim Yapma                     │
│  😊 Emoji Ekleme                    │
│  🎨 Filtre Uygulama                 │
│  📍 Konum Ekleme                    │
└─────────────────────────────────────┘
```

4. "Story'e Ekle" butonuna tıklayın

#### **📝 Metin Story'si**
1. "Metin" seçeneğini seçin
2. Mesajınızı yazın
3. Arka plan rengini seçin
4. Font stilini değiştirin
5. Story'e ekleyin

**Metin Story Özellikleri:**
- 280 karakter sınırı
- 15+ arka plan rengi seçeneği
- Bold, italic, underline destekli
- Emoji kullanabilirsiniz

#### **⏰ Story Süresi ve Görünürlük**
- **⏰ Süre**: 24 saat otomatik silinir
- **👁️ Görünürlük**: Rehberinizdeki herkesi görebilir
- **📊 Görüntüleme**: Kim baktığını görebilirsiniz
- **🗑️ Silme**: İstediğiniz zaman silebilirsiniz

### 💬 **Story'lere Yanıt Verme**

#### **👥 Story Etkileşimi**
Story izlerken:
1. Yukarı kaydırın
2. Yanıt mesajınızı yazın
3. Gönder butonuna tıklayın
4. Mesaj normal sohbete düşer

**Story Yanıt Formatı:**
```
💬 Story Yanıtı
┌─────────────────────────────────────┐
│  📖 Bu story'ye yanıt verdin:       │
│      [Story önizlemesi]             │
│                                     │
│  💬 Yanıtın: "Çok güzel! 👏"        │
└─────────────────────────────────────┘
```

---

## ⚙️ Ayarlar ve Kişiselleştirme

### 👤 **Profil Ayarları**

#### **📝 Profil Bilgilerini Düzenleme**
1. Ana ekranda sağ üst köşedeki ⚙️ simgesine tıklayın
2. "Profil" seçeneğini seçin
3. Düzenlemek istediğiniz bilgiyi tıklayın:

```
👤 Profil Ayarları
┌─────────────────────────────────────┐
│  📷 Profil Fotoğrafını Değiştir     │
│  📝 Ad Soyad                        │
│  💬 Hakkımda                        │
│  📞 Telefon Numarası (değiştirilemez)│
│  🎂 Doğum Tarihi                    │
│  📏 Boy Bilgisi                     │
│  ⚖️ Güncel Kilo                     │
│  🎯 Hedef Kilo                      │
└─────────────────────────────────────┘
```

#### **📷 Profil Fotoğrafı Yönetimi**
- **🔄 Değiştir**: Yeni fotoğraf yükle
- **🗑️ Kaldır**: Varsayılan avatar'a dön
- **👁️ Görüntüle**: Tam boyutunu gör
- **📤 Paylaş**: Story veya mesaj olarak paylaş

### 🔒 **Gizlilik Ayarları**

#### **👁️ Görünürlük Ayarları**
```
🔒 Gizlilik Kontrolü
┌─────────────────────────────────────┐
│  👁️ Son Görülme                     │
│     ○ Herkes  ○ Kişiler  ● Kimse   │
│                                     │
│  📷 Profil Fotoğrafı                │
│     ● Herkes  ○ Kişiler  ○ Kimse   │
│                                     │
│  💬 Hakkımda                        │
│     ● Herkes  ○ Kişiler  ○ Kimse   │
│                                     │
│  📖 Story'lerim                     │
│     ● Herkes  ○ Seçtiklerim        │
└─────────────────────────────────────┘
```

#### **🚫 Engelleme ve Bildirme**
- **🚫 Engelleme**: İstenmeyen kişileri engelleyin
- **📢 Şikayet**: Uygunsuz içeriki bildirin
- **🔇 Sessiz Bildirimleri**: Belirli kişilerden bildirim almayın

### 🔔 **Bildirim Ayarları**

#### **📱 Bildirim Türleri**
```
🔔 Bildirim Yönetimi
┌─────────────────────────────────────┐
│  💬 Mesaj Bildirimleri              │
│     ● Açık    ○ Kapalı              │
│                                     │
│  👥 Grup Mesajları                  │
│     ● Açık    ○ Sadece Etiketleme   │
│                                     │
│  📖 Story Bildirimleri              │
│     ○ Açık    ● Kapalı              │
│                                     │
│  🏥 Sağlık Hatırlatıcıları          │
│     ● Açık    ○ Kapalı              │
│                                     │
│  🍎 Öğün Hatırlatıcıları            │
│     ● Açık    ○ Kapalı              │
└─────────────────────────────────────┘
```

#### **⏰ Sessiz Saatler**
Belirli saatlerde bildirim almamak için:
1. "Sessiz Saatler" ayarını açın
2. Başlangıç saati: 22:00
3. Bitiş saati: 08:00  
4. Hafta sonu dahil et ☑️

### 💾 **Veri ve Depolama**

#### **📊 Depolama Kullanımı**
```
💾 Depolama Durumu
┌─────────────────────────────────────┐
│  📱 Toplam Alan: 2.1 GB             │
│                                     │
│  📷 Fotoğraflar: 890 MB            │
│  🎥 Videolar: 650 MB               │
│  📄 Belgeler: 125 MB               │
│  💬 Mesajlar: 435 MB               │
│                                     │
│  🗑️ Cache Temizle                   │
│  📤 Yedek Al                        │
└─────────────────────────────────────┘
```

#### **🔄 Otomatik Yedekleme**
- **☁️ Cloud Backup**: Firebase'de otomatik yedek
- **📅 Yedekleme Sıklığı**: Günlük/Haftalık/Aylık
- **📶 Sadece WiFi**: Veri tasarrufu için
- **🔐 Şifrelenmiş**: Güvenli yedekleme

### 🌙 **Görünüm ve Tema**

#### **🎨 Tema Seçimi**
```
🎨 Tema Ayarları
┌─────────────────────────────────────┐
│  ☀️ Açık Tema    (Varsayılan)       │
│  🌙 Koyu Tema                       │
│  🔄 Otomatik     (Sistem ayarı)     │
└─────────────────────────────────────┘
```

#### **📝 Font Ayarları**  
- **Küçük**: Kompakt görünüm
- **Normal**: Standart boyut
- **Büyük**: Kolay okuma
- **Çok Büyük**: Erişilebilirlik için

### 🔧 **Gelişmiş Ayarlar**

#### **📶 Bağlantı Ayarları**
- **📶 Ağ Kullanımı**: WiFi önceliği
- **🔋 Batarya Optimizasyonu**: Arka plan sınırlaması
- **📊 Veri Tasarrufu**: Düşük kalite medya
- **🔄 Otomatik İndirme**: Fotoğraf/video ayarları

#### **🔐 Güvenlik**
- **🔒 Uygulama Kilidi**: Parmak izi/PIN
- **👁️ Ekran Görüntüsü**: Engelleme seçeneği  
- **🔄 İki Faktörlü Doğrulama**: Ekstra güvenlik
- **📱 Aktif Oturumlar**: Diğer cihazları görün

---

## ❓ Sorun Giderme

### 📱 **Yaygın Sorunlar ve Çözümler**

#### **🔐 Giriş Sorunları**

**❌ Problem**: SMS kodu gelmiyor
**✅ Çözüm**: 
1. Telefon numaranızı kontrol edin
2. Ağ bağlantınızı kontrol edin
3. 3 dakika bekleyip "Tekrar Gönder" deneyin
4. Telefonunuzu yeniden başlatın

**❌ Problem**: SMS kodu yanlış diyor
**✅ Çözüm**:
1. Kodu dikkatli girin (boşluk bırakmayın)
2. Kodun son kullanma süresini kontrol edin
3. Yeni kod talep edin

#### **💬 Mesajlaşma Sorunları**

**❌ Problem**: Mesajlar gönderilmiyor
**✅ Çözüm**:
```
🔧 Mesaj Gönderme Sorun Giderme
┌─────────────────────────────────────┐
│  1. İnternet bağlantısını kontrol et│
│  2. Uygulamayı yeniden başlat        │
│  3. Telefonu yeniden başlat          │
│  4. Uygulamayı güncelle              │
│  5. Cache'i temizle                  │
└─────────────────────────────────────┘
```

**❌ Problem**: Fotoğraflar yüklenmiyor
**✅ Çözüm**:
1. WiFi/4G bağlantısını kontrol edin
2. Depolama alanınızı kontrol edin
3. Kamera/galeri izinlerini kontrol edin
4. Fotoğraf boyutunu küçültün

#### **📊 Sağlık Takibi Sorunları**

**❌ Problem**: Adım sayacı çalışmıyor
**✅ Çözüm**:
1. Konum/sensör izinlerini kontrol edin
2. Batarya optimizasyonunu kapatın
3. Telefon sensörlerini kalibre edin
4. Uygulamayı arka planda çalıştığından emin olun

**❌ Problem**: BMI yanlış hesaplanıyor
**✅ Çözüm**:
1. Boy ve kilo bilgilerinizi kontrol edin
2. Yaş bilginizi güncelleyin
3. Metric/Imperial birim ayarını kontrol edin

### 🔧 **Performans Optimizasyonu**

#### **⚡ Hız Artırma İpuçları**
```
⚡ Performans İyileştirme
┌─────────────────────────────────────┐
│  🗑️ Cache'i düzenli temizle         │
│  📱 Uygulamayı güncel tut            │
│  💾 Depolama alanı boşalt            │
│  🔋 Batarya optimizasyonunu kapat    │
│  📶 Güçlü WiFi kullan               │
│  🌙 Koyu tema kullan (batarya)      │
└─────────────────────────────────────┘
```

#### **💾 Bellek Yönetimi**
- **Otomatik Cache Temizleme**: Haftada bir
- **Eski Medyaları Sil**: 3 aydan eski
- **Yedek Al**: Önemli verileri kaydet
- **Gereksiz İndirmeleri Durdur**: Ayarlardan kontrol et

### 📞 **Destek ve İletişim**

#### **🆘 Yardım Alma**
1. **Uygulama İçi Yardım**: Ayarlar → Yardım
2. **SSS Bölümü**: Sık sorulan sorular
3. **Destek Talebi**: Doğrudan mesaj gönder
4. **Community Forum**: Diğer kullanıcılarla etkileş

#### **📧 İletişim Bilgileri**
- **📧 E-posta**: support@diyetkent.com
- **💬 Canlı Destek**: Uygulama içi chat
- **🌐 Web Site**: www.diyetkent.com
- **📱 Sosyal Medya**: @diyetkent

#### **🐛 Hata Bildirme**
Hata ile karşılaştığınızda:
1. Ekran görüntüsü alın
2. Hatanın adımlarını yazın
3. Telefon/uygulama versiyonu belirtin
4. Destek ekibine gönderin

### 🔄 **Güncellemeler ve Yenilikler**

#### **📱 Uygulama Güncellemeleri**
- **Otomatik Güncelleme**: Play Store/App Store'da açın
- **Manuel Kontrol**: Haftada bir kontrol edin
- **Beta Programı**: Erken erişim için katılın
- **Güncelleme Notları**: Yenilikleri öğrenin

---

## 🎯 **Sonuç ve İpuçları**

### 💡 **Başarılı Kullanım İpuçları**

#### **🏥 Sağlık Takibi İçin**
- Kiloyu her gün aynı saatte ölçün
- Adım sayacınızı aktif tutun
- Hedeflerinizi gerçekçi belirleyin
- İlerlemenizi düzenli kaydedin

#### **💬 Mesajlaşma İçin**
- Profil bilgilerinizi güncel tutun
- Grup kurallarına uyun
- Medya paylaşırken boyuta dikkat edin
- Yedeklemeyi unutmayın

#### **🍎 Diyet Takibi İçin**
- Diyetisyeninizle düzenli iletişim kurun
- Öğün hatırlatıcılarını aktif tutun
- İlerlemenizi paylaşın
- Sabırlı olun ve hedefinizden şaşmayın

### 🏆 **Başarı Stratejileri**

```
🎯 DiyetKent Başarı Formülü
┌─────────────────────────────────────┐
│  📊 Düzenli Takip                   │
│  +  💬 Aktif İletişim               │
│  +  🎯 Net Hedefler                 │
│  +  💪 Sabır ve Motivasyon          │
│  =  🏆 BAŞARI!                      │
└─────────────────────────────────────┘
```

**🎉 DiyetKent ile sağlıklı yaşamınız başlıyor!**

---

## 📚 **Ek Kaynaklar**

### 📖 **Daha Fazla Bilgi**
- **📘 Admin Rehberi**: Diyetisyen özellikleri için
- **🛠️ Developer Dökümanları**: Teknik detaylar
- **📊 API Referansı**: Geliştiriciler için
- **🔐 Güvenlik Rehberi**: Güvenlik en iyi uygulamaları

### 🌐 **Yararlı Linkler**
- **Web Sitesi**: www.diyetkent.com
- **GitHub**: github.com/Kenfrozz/diyetkent
- **Dokümantasyon**: docs.diyetkent.com
- **Community**: community.diyetkent.com

---

**Son Güncelleme**: 2024-01-11  
**Doküman Versiyonu**: 1.0.0  
**Uygulama Versiyonu**: 1.0.0+1  

**🌟 DiyetKent kullandığınız için teşekkürler!**