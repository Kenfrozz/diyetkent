# DiyetKent Mesajlaşma Uygulaması - Kronolojik Geliştirme Planı
Bu belge WhatsApp benzeri mesajlaşma uygulaması + diyetisyen paneli için kronolojik geliştirme sırasına göre düzenlenmiştir.

---

## 📅 FAZ 1: TEMEL ALTYAPI (2 Ağustos - 30 Ağustos 2025)

### 1. Hizmet Koşulları Onay Ekranı *(2-5 Ağustos 2025)*
**Amaç:** Uygulama ilk açıldığında kullanıcıdan Diyetkent Hizmet Koşulları onayı almak.

**İşlemler:**
- İlk açılışta hoşgeldin ekranı gösterme
- "Diyetkent Hizmet Koşullarını kabul etmek için Kabul Et ve Devam Et seçeneğine dokun" metni
- "Diyetkent Hizmet Koşulları" yazısı tıklanabilir link olarak gösterme
- Linke tıklandığında web sitesindeki hizmet koşulları sayfasına yönlendirme
- "Kabul Et ve Devam Et" butonuna tıklandığında telefon giriş ekranına geçiş
- Onay durumunu kalıcı olarak kaydetme (bir daha gösterilmez)

### 2. Telefon Numarası Giriş Sayfası *(5-10 Ağustos 2025)*
**Amaç:** Kullanıcıların telefon numarasıyla sisteme giriş yapmasını sağlamak ve hesap oluşturmak.

**İşlemler:**
- Kullanıcı ülke kodu seçer (248 farklı ülke desteği)
- Telefon numarasını girer (gerçek zamanlı format doğrulama)
- Sistem numarayı doğrular ve SMS gönderir
- Hatalı numara girişinde uyarı mesajı gösterir
- Numara doğruysa SMS doğrulama sayfasına yönlendirir

### 3. SMS Doğrulama Sayfası *(5-10 Ağustos 2025)*
**Amaç:** Telefon numarasının gerçekten kullanıcıya ait olduğunu doğrulamak ve güvenliği sağlamak.

**İşlemler:**
- SMS ile gelen 6 haneli kodu kullanıcı girer
- Kod otomatik algılanabilir (Android SMS Auto-Read)
- Yanlış kod girişinde hata gösterir ve tekrar girme imkanı verir
- 60 saniyelik zamanlayıcı sonrası kod yeniden gönderilebilir
- Doğru kod girişinde hesap aktivasyonu tamamlanır
- Numara değiştirme imkanı sunar

### 4. Ana Sohbet Listesi Sayfası *(10-15 Ağustos 2025)*
**Amaç:** Tüm sohbetleri merkezi bir yerde görmek ve hızlı erişim sağlamak.

**İşlemler:**
- Aktif sohbetleri son mesaj tarihine göre sıralama
- Sabitlenmiş sohbetleri üstte gösterme
- Her sohbet için son mesaj önizlemesi gösterme
- Okunmamış mesaj sayısını badge ile gösterme
- Mesaj durumunu gösterme (gönderildi, okundu, vs.)
- Çevrimiçi durumu gösterme
- Sohbetleri kaydırarak arşivleme/silme/sabitleme
- Uzun basarak çoklu seçim yapma
- Yeni sohbet başlatma

### 5. Sohbet Sayfası *(10-15 Ağustos 2025)*
**Amaç:** İki kullanıcı arasında gerçek zamanlı mesajlaşma deneyimi sunmak.

**İşlemler:**
- Mesajları kronolojik sırada gösterme
- Gönderilen ve alınan mesajları farklı taraflarda gösterme
- Mesaj durumunu gösterme (gönderiliyor, gönderildi, okundu)
- Karşı tarafın çevrimiçi durumunu gösterme
- Yazıyor göstergesini gösterme
- Mesajlara uzun basarak menü açma
- Mesaj gönderme, silme, kopyalama, yanıtlama, iletme
- Günlük tarih ayraçları gösterme

### 6. Profil Sayfası *(15-20 Ağustos 2025)*
**Amaç:** Kullanıcının kişisel bilgilerini yönetmesi ve diğer kullanıcılara kendini tanıtması.

**İşlemler:**
- Profil fotoğrafı ekleme/değiştirme/silme (kamera veya galeriden)
- Fotoğraf düzenleme (kırpma, boyutlandırma)
- Ad ve soyad bilgilerini güncelleme
- Hakkımda bölümünü düzenleme (durum mesajı)
- Telefon numarasını görüntüleme (değiştirilemez)
- Tüm değişiklikleri kaydetme
- Profil tamamlanma durumunu gösterme

### 7. Sohbet Arama ve Filtreleme *(15-20 Ağustos 2025)*
**Amaç:** Çok sayıda sohbet arasında hızlı arama yapabilmek ve kategorilere göre filtreleme.

**İşlemler:**
- Gerçek zamanlı arama (isim ve mesaj içeriği)
- Arama sonuçlarında eşleşen kısımları vurgulama
- Filtre uygulama (tüm sohbetler, okunmamış, gruplar, arşivlenen)
- Arama geçmişi tutma
- Arama sonuçlarını temizleme
- Favori aramalar kaydetme

### 8. Okundu/Yazıyor/Çevrimiçi Bilgisi *(15-20 Ağustos 2025)*
**Amaç:** Karşı tarafın durumunu bilmek ve mesajlaşma deneyimini iyileştirmek.

**İşlemler:**
- Kullanıcının çevrimiçi/çevrimdışı durumunu gösterme
- Son görülme zamanını gösterme
- "Yazıyor..." göstergesini gerçek zamanlı güncelleme
- Mesaj okundu bilgisini işaretleme
- Gizlilik ayarlarına göre bilgi paylaşımını kontrol etme
- Grup sohbetlerinde kim okudu bilgisini gösterme

### 9. Mesaj Yanıtlama *(15-20 Ağustos 2025)*
**Amaç:** Belirli bir mesaja referans vererek yanıt verebilmek ve bağlamı korumak.

**İşlemler:**
- Mesaja uzun basarak yanıt seçeneği gösterme
- Yanıtlanacak mesajı vurgulama
- Yanıt yazma alanında referans mesajı gösterme
- Yanıt gönderme
- Referans mesaja tıklayarak orijinal mesaja gitme
- Yanıt zinciri oluşturma

### 10. Mesaj Silme/Kopyalama *(15-20 Ağustos 2025)*
**Amaç:** Mesaj yönetimi ve istenmeyen içerikleri kaldırabilmek.

**İşlemler:**
- Mesajı kopyalama (panoya)
- "Benden sil" seçeneği
- "Herkesten sil" seçeneği (7 dakika içinde)
- Çoklu mesaj seçimi
- Toplu silme işlemi
- Silinen mesaj yerine bilgi mesajı gösterme
- Silme işlemini onaylama

### 11. Günler Arası Tarih Ayracı *(15-20 Ağustos 2025)*
**Amaç:** Mesajları tarih bazında organize etmek ve geçmiş mesajlarda gezinmeyi kolaylaştırmak.

**İşlemler:**
- Günlük geçişlerde tarih ayracı ekleme
- "Bugün", "Dün" gibi göreli tarihler gösterme
- Eski tarihler için tam tarih gösterme
- Tarih ayracına tıklayarak o güne atlama
- Uzun sohbetlerde tarih bazlı navigasyon

### 12. Sohbet Arşivleme/Arşivden Çıkarma *(20-22 Ağustos 2025)*
**Amaç:** Eski veya az kullanılan sohbetleri ana listeden kaldırarak düzen sağlamak.

**İşlemler:**
- Sohbetleri arşivleme (kaydırma veya menü ile)
- Arşivlenmiş sohbetleri ayrı bölümde görüntüleme
- Arşivden tek tek veya toplu çıkarma
- Yeni mesaj geldiğinde otomatik arşivden çıkarma
- Arşiv bildirimi ayarları yönetme

### 13. Sohbet Silme *(20-22 Ağustos 2025)*
**Amaç:** İstenmeyen sohbetleri kalıcı olarak sistemden kaldırmak.

**İşlemler:**
- Sohbet silme için onay alma
- İki silme seçeneği sunma (sadece benden sil / herkesten sil)
- Silinen sohbetlerin geri alınamayacağı konusunda uyarı
- Grup sohbeti için ek seçenekler (gruptan ayrılma)
- Silme işlemi sonrası ana listeyi güncelleme

### 14. Sohbet Sabitleme *(20-22 Ağustos 2025)*
**Amaç:** Önemli sohbetleri her zaman üstte tutarak kolay erişim sağlamak.

**İşlemler:**
- En fazla 3 sohbeti sabitleme
- Sabitlenmiş sohbetleri özel simgeyle işaretleme
- Sabitleme sırası değiştirme
- Sabitleme limitine ulaşıldığında uyarı
- Sabitlemeyi kaldırma seçeneği

### 15. Arşivlenmiş Sohbetler Sayfası *(20-22 Ağustos 2025)*
**Amaç:** Kullanıcının arşivlediği sohbetleri yönetmek ve gerektiğinde geri getirmek.

**İşlemler:**
- Arşivlenmiş sohbetleri listeleme
- Arşiv tarihine göre sıralama
- Arşivden çıkarma işlemi
- Toplu arşiv yönetimi
- Arama ve filtreleme
- Arşiv boyutu bilgisi
- Otomatik arşivleme kuralları

### 16. Mesaj İletme *(20-25 Ağustos 2025)*
**Amaç:** Bir mesajı başka kişi veya gruplara hızlıca iletebilmek.

**İşlemler:**
- İletilecek mesajı seçme
- Alıcı listesi gösterme (kişiler ve gruplar)
- Çoklu alıcı seçimi yapma
- İletim onayı alma
- İletilen mesajda "İletildi" etiketini gösterme
- İletim başarısını bildirme

### 17. Mesaj İletme Sayfası *(20-25 Ağustos 2025)*
**Amaç:** Seçili mesajları birden fazla kişi ve gruba aynı anda iletebilmek.

**İşlemler:**
- İletilecek mesajların önizlemesini gösterme
- Kişi ve grup listesini gösterme
- Son sohbet edilen kişileri üstte gösterme
- Çoklu alıcı seçimi yapma
- Seçilen alıcı sayısını gösterme
- Arama yaparak alıcı bulma
- Toplu iletim işlemini başlatma

### 18. Link/Telefon/Email Algılama *(20-25 Ağustos 2025)*
**Amaç:** Mesajlardaki özel içerikleri otomatik algılayıp tıklanabilir hale getirmek.

**İşlemler:**
- URL linklerini otomatik algılama ve tıklanabilir yapma
- Telefon numaralarını algılayıp arama seçeneği sunma
- Email adreslerini algılayıp mail gönderme seçeneği sunma
- Web linkler için önizleme oluşturma
- Link güvenlik kontrolü yapma
- Kötü amaçlı linkler için uyarı

### 19. Rich Text Mesajları *(20-25 Ağustos 2025)*
**Amaç:** Mesajlarda format kullanarak daha etkili iletişim kurabilmek.

**İşlemler:**
- Kalın yazı formatı (**metin**)
- İtalik yazı formatı (*metin*)
- Üstü çizili yazı formatı (~metin~)
- Sabit genişlikli yazı formatı (```metin```)
- Format önizlemesi gösterme
- Format kısayolları öğretme

### 20. Medya Gönderme (fotoğraf, video, doküman) *(25-30 Ağustos 2025)*
**Amaç:** Multimedya içeriklerini paylaşarak zengin iletişim kurabilmek.

**İşlemler:**
- Medya seçim menüsünü açma (kamera, galeri, doküman)
- Çoklu medya seçimi yapma
- Seçilen medyalara açıklama ekleme
- Medya önizlemesi gösterme
- Medya sıkıştırma seçenekleri
- Büyük dosyalar için uyarı verme
- Medya gönderim ilerlemesi gösterme

### 21. Konum Gönderme *(25-30 Ağustos 2025)*
**Amaç:** Bulunulan yeri veya belirli bir adresi karşı tarafa iletebilmek.

**İşlemler:**
- Mevcut konumu otomatik algılama
- Harita üzerinde konum seçme
- Konum arama yapma
- Canlı konum paylaşımı başlatma
- Canlı konum süresini belirleme (15dk, 1sa, 8sa)
- Statik konum gönderme
- Konum doğruluğunu gösterme

### 22. Kişi Kartı Gönderme *(25-30 Ağustos 2025)*
**Amaç:** Rehberdeki kişilerin bilgilerini paylaşabilmek.

**İşlemler:**
- Rehber listesinden kişi seçme
- Kişi bilgilerini önizleme
- Paylaşılacak bilgileri seçme
- Kişi kartını gönderme
- Alıcının kişiyi rehberine ekleme seçeneği
- Kişi kartı formatını standartlaştırma

### 23. Kamera Sayfası *(25-30 Ağustos 2025)*
**Amaç:** Uygulama içinden fotoğraf/video çekerek hızlı paylaşım yapmak.

**İşlemler:**
- Fotoğraf çekme modu
- Video kaydetme modu
- Ön/arka kamera değiştirme
- Flash açma/kapama
- Odaklama yapma
- Zoom işlevi
- Timer ayarlama
- Çekilen medyayı önizleme
- Doğrudan gönderme veya kaydetme

### 24. Kamera Sayfası (Extended Features) *(25-30 Ağustos 2025)*
**Amaç:** Profesyonel fotoğrafçılık özelliklerini sunarak kaliteli içerik üretimi sağlamak.

**İşlemler:**
- HDR modu kullanma
- Gece çekimi modu
- Portre modu (arka plan bulanıklığı)
- Panorama çekimi
- Zaman atlamalı video çekme
- Ağır çekim video çekme
- Manual odaklama kontrolü
- Pozlama ayarlama
- ISO değeri ayarlama

### 25. Medya Galerisi Sayfası *(25-30 Ağustos 2025)*
**Amaç:** Cihazda bulunan medya dosyalarını görüntülemek ve seçim yapmak.

**İşlemler:**
- Fotoğraf ve videoları grid görünümde listeleme
- Tarih bazında gruplandırma
- Çoklu seçim yapma
- Önizleme gösterme
- Filtreleme (fotoğraf, video, tümü)
- Arama yapma
- Paylaşılacak medyaları seçme
- Medya boyutlarını gösterme

### 26. Kişiler Sayfası *(25-30 Ağustos 2025)*
**Amaç:** Merkezi bir rehber sistemi ile tüm kişileri yönetmek.

**İşlemler:**
- Telefon rehberini senkronize etme
- DiyetKent kullanıcılarını üstte gösterme
- Alfabetik sıralama yapma
- Hızlı arama ve filtreleme
- Yeni kişi ekleme
- Kişi bilgilerini düzenleme
- Kişileri silme
- Toplu işlemler yapma

### 27. Merkezi Rehber Yönetimi *(25-30 Ağustos 2025)*
**Amaç:** Profesyonel düzeyde kişi yönetimi ve Firebase ile senkronizasyon sağlamak.

**İşlemler:**
- Gerçek zamanlı rehber senkronizasyonu
- Çapraz cihaz kişi erişimi
- Otomatik yedekleme
- Çakışma çözümleme (aynı kişi birden fazla kayıt)
- Akıllı kişi önerileri
- Duplicate kişi tespiti ve birleştirme
- Sosyal medya profili bağlama
- Kişi doğrulama sistemi

### 28. Emoji/Sticker Gönderme *(25-30 Ağustos 2025)*
**Amaç:** Duygusal ifade araçlarıyla mesajlaşmayı daha eğlenceli hale getirmek.

**İşlemler:**
- Emoji panelini açma ve seçim yapma
- Son kullanılan emojileri gösterme
- Emoji kategorilerine ayırma
- Ten rengi seçenekleri sunma
- Sticker paketleri gösterme
- Özel sticker yükleme
- Emoji/sticker arama yapma

---

## 🚀 FAZ 2: ANA ÖZELLİKLER (1 Eylül - 30 Eylül 2025)

### 29. Grup Oluşturma Sayfası *(1-5 Eylül 2025)*
**Amaç:** Yeni grup oluşturarak toplu mesajlaşma imkanı sağlamak.

**İşlemler:**
- Grup üyelerini seçme (minimum 2 kişi)
- Grup adı belirleme
- Grup açıklaması ekleme
- Grup fotoğrafı seçme/çekme
- Grup gizlilik ayarlarını belirleme
- Grup oluşturma işlemini tamamlama
- İlk grup mesajını atma
- Üyeleri bilgilendirme

### 30. Grup Detay Sayfası *(5-10 Eylül 2025)*
**Amaç:** Grup bilgilerini yönetmek ve üye işlemlerini gerçekleştirmek.

**İşlemler:**
- Grup bilgilerini görüntüleme (isim, açıklama, fotoğraf)
- Grup bilgilerini düzenleme (sadece adminler)
- Üye listesini gösterme
- Üye ekleme/çıkarma işlemleri
- Admin yetkisi verme/alma
- Paylaşılan medyaları görüntüleme
- Grup ayarlarını yönetme
- Gruptan ayrılma

### 31. Sesli Mesaj Gönderme *(7-10 Eylül 2025)*
**Amaç:** Metinden daha hızlı ve kişisel ses mesajları gönderebilmek.

**İşlemler:**
- Mikrofon butonuna basılı tutarak kayıt başlatma
- Kayıt süresini gerçek zamanlı gösterme
- Kaydı iptal etme (sola kaydırma)
- Kaydı gönderme (butonu bırakma)
- Kayıt kalitesi ayarlama
- Sesli mesajları oynatma/duraklatma
- Oynatma hızı değiştirme (1x, 1.5x, 2x)
- Sesli mesaj süresini gösterme

### 32. Durumlar Sayfası *(14-18 Eylül 2025)*
**Amaç:** 24 saat içinde kaybolacak hikayeler paylaşmak ve görmek.

**İşlemler:**
- Kendi durumunu görüntüleme/yönetme
- Yeni durum ekleme
- Kişilerin durumlarını izleme
- Durum görüntüleme sayılarını gösterme
- Durumları izleyici listesi ile görme
- Durum gizlilik ayarlarını yönetme
- Eski durumları silme
- Durum tepkileri gönderme

### 33. Durum Gizlilik Ayarları *(14-18 Eylül 2025)*
**Amaç:** Durumların kimler tarafından görülebileceğini kontrol etmek.

**İşlemler:**
- "Herkes" seçeneği
- "Rehbimdekiler" seçeneği
- "Seçtiğim kişiler" seçeneği
- "Hariç tutulanlar" listesi oluşturma
- Gizlilik ayarlarını kaydetme
- Mevcut durumlar için geçmişe dönük uygulama

### 34. Durum Görüntüleme Sayfası *(14-18 Eylül 2025)*
**Amaç:** Durumları tam ekran görüntülemek ve etkileşim kurmak.

**İşlemler:**
- Durumu tam ekranda gösterme
- Otomatik ilerleme (15 saniye)
- Manuel ileri/geri gitme
- Durum sahibi bilgilerini gösterme
- Durum süresini gösterme
- Tepki gönderme
- Duruma yanıt yazma
- Paylaşım yapma

### 35. Aramalar Sayfası *(18-22 Eylül 2025)*
**Amaç:** Arama geçmişini yönetmek ve yeni aramalar başlatmak.

**İşlemler:**
- Gelen/giden/cevapsız aramaları listeleme
- Arama türünü gösterme (sesli/görüntülü)
- Arama süresini gösterme
- Tarih/saat bilgisini gösterme
- Yeniden arama yapma
- Arama geçmişini silme
- Arama kayıtlarını filtreleme
- İstatistik görüntüleme

### 36. Gelen/Giden Çağrı Sayfası *(18-22 Eylül 2025)*
**Amaç:** Aktif arama sırasında gerekli kontrolleri sağlamak.

**İşlemler:**
- Gelen aramayı yanıtlama/reddetme
- Mikrofonu açma/kapama
- Hoparlörü açma/kapama
- Kamerayı açma/kapama (görüntülü aramalar)
- Aramayı sonlandırma
- Tuş takımını açma
- Çağrı beklemeye alma
- Çağrı transferi yapma

### 37. Gelen/Giden Çağrı Yönetim Sayfası *(18-22 Eylül 2025)*
**Amaç:** WebRTC tabanlı sesli ve görüntülü arama sistemi yönetmek.

**İşlemler:**
- Gelen arama bildirimi yönetimi
- Arama kalitesi ayarları
- Ağ bağlantısı optimizasyonu
- Arama geçmişi kaydetme
- Arama süresi takibi
- Arama kayıtları filtreleme
- ICE server konfigürasyonu
- Bandwidth optimizasyonu

### 38. Ana Ayarlar Sayfası *(22-26 Eylül 2025)*
**Amaç:** Tüm uygulama ayarlarına merkezi erişim sağlamak.

**İşlemler:**
- Kullanıcı profilini özetleme
- Ayar kategorilerini listeleme
- Hızlı ayarlara erişim
- Ayarlarda arama yapma
- Ayar önizlemeleri gösterme
- Alt sayfalara yönlendirme

### 39. Hakkında/Yardım Sayfası *(22-26 Eylül 2025)*
**Amaç:** Uygulama hakkında bilgi vermek ve kullanıcı desteği sağlamak.

**İşlemler:**
- Uygulama versiyonu gösterme
- Geliştirici bilgileri gösterme
- Lisans bilgilerini gösterme
- SSS bölümü sunma
- Destek iletişim seçenekleri
- Özellik talebi gönderme
- Hata raporu oluşturma
- Kullanım kılavuzu gösterme

### 40. Dil Ayarları Sayfası *(22-26 Eylül 2025)*
**Amaç:** Uygulama dilini değiştirmek ve yerelleştirme yapmak.

**İşlemler:**
- Mevcut dili gösterme
- Desteklenen dilleri listeleme
- Dil değişimi yapma
- Değişiklik onayı alma
- Uygulamayı yeniden başlatma
- Dil paketlerini güncelleme

### 41. Gizlilik Ayarları Sayfası *(22-26 Eylül 2025)*
**Amaç:** Kişisel verilerin gizliliğini korumak ve paylaşım kontrolü sağlamak.

**İşlemler:**
- Son görülme ayarları (herkes/rehberim/kimse)
- Profil fotoğrafı gizliliği
- Hakkımda bilgisi gizliliği
- Durum gizlilik kontrolleri
- Engellenen kişiler yönetimi
- İki adımlı doğrulama kurulumu
- Okundu bilgisi kontrolü
- Grup ekleme izinleri

### 42. Hesap Ayarları Sayfası *(22-26 Eylül 2025)*
**Amaç:** Temel hesap işlemlerini yönetmek ve güvenlik sağlamak.

**İşlemler:**
- Telefon numarası değiştirme
- İki adımlı doğrulama ayarlama
- Şifre oluşturma/değiştirme
- Kurtarma e-postası ekleme
- Güvenlik kodları oluşturma
- Hesap silme işlemi
- Veri indirme talebi
- Hesap dondurma

### 43. Bildirim Ayarları Sayfası *(22-26 Eylül 2025)*
**Amaç:** Bildirim tercihleri yönetmek ve rahatsız edici bildirimleri engellemek.

**İşlemler:**
- Ana bildirim anahtarını açma/kapama
- Sesli bildirim ayarları
- Titreşim ayarları
- Ekran açık bildirimler
- Grup bildirim ayarları
- Sessiz saatler belirleme
- Bildirim önizleme ayarları
- Özel kişiler için özel sesler

### 44. Etiketler Sayfası *(26-30 Eylül 2025)*
**Amaç:** Diyetisyenlerin danışanlarını kategorilere ayırarak organize etmesini sağlamak.

**İşlemler:**
- Tüm etiketleri renk kodlu olarak listeleme
- Her etiketin kaç sohbette kullanıldığını gösterme
- Etikete tıklayarak o kategorideki sohbetleri listeleme
- Etiket ekleme, düzenleme, silme işlemleri
- Etiketleri renk ve isme göre sıralama
- Etiket bazlı istatistikler gösterme

### 45. Etiket Ekleme *(26-30 Eylül 2025)*
**Amaç:** Yeni müşteri kategorileri oluşturarak sınıflandırma sistemi geliştirmek.

**İşlemler:**
- Etiket adı belirleme
- Renk seçimi (10 farklı seçenek)
- İkon seçimi (20+ seçenek)
- Etiket açıklaması ekleme
- Aynı isimde etiket kontrolü
- Etiket önizlemesi gösterme
- Oluşturma işlemini onaylama

### 46. Etiket Düzenleme/Silme *(26-30 Eylül 2025)*
**Amaç:** Mevcut etiket sistemini güncel tutmak ve gereksiz etiketleri temizlemek.

**İşlemler:**
- Etiket bilgilerini güncelleme (isim, renk, ikon)
- Etiket silme işleminde onay alma
- Silinecek etiketteki sohbetler için alternatif etiket sunma
- Etiket kullanım istatistikleri gösterme
- Silme sonrası sohbetleri "Etiketiesiz" kategorisine taşıma

---

## 💊 FAZ 3: SAĞLIK ÖZELLİKLERİ (1 Ekim - 25 Ekim 2025)

### 47. Sağlık Bilgilerim Sayfası *(1-5 Ekim 2025)*
**Amaç:** Kullanıcının sağlık profilini oluşturmak ve diyetisyen için temel verileri sağlamak.

**İşlemler:**
- Boy bilgisi girme/güncelleme
- Kilo bilgisi girme/güncelleme (geçmiş kayıt)
- Yaş bilgisi girme
- BMI otomatik hesaplama ve kategori belirleme
- Hedef kilo belirleme
- Sağlık hedefleri seçme
- Hastalık geçmişi kaydetme
- Alerji bilgileri ekleme
- İlaç kullanım bilgileri
- İlerleme grafikleri görüntüleme (FL Chart entegrasyonu)

### 48. Form Doldurma Sayfası *(1-5 Ekim 2025)*
**Amaç:** Diyetisyen tarafından oluşturulan formları doldurmak ve değerlendirme sağlamak.

**İşlemler:**
- Dinamik form alanlarını görüntüleme
- Farklı input tiplerini destekleme (metin, çoktan seçmeli, tarih, vs.)
- Form doğrulama kurallarını uygulama
- Ara kayıt yapma (taslak)
- Form ilerlemesini gösterme
- Zorunlu alanları işaretleme
- Form gönderim onayı
- Gönderilen formları görüntüleme

### 49. Adım Sayar ve Aktivite Takibi Sayfası *(10-15 Ekim 2025)*
**Amaç:** Günlük fiziksel aktiviteyi izlemek ve sağlık hedeflerini desteklemek.

**İşlemler:**
- Günlük adım sayısı takibi
- Yakılan kalori hesaplaması
- Aktif mesafe ölçümü
- Haftalık/aylık aktivite trendleri
- Hedef adım sayısı belirleme
- Aktivite hatırlatıcıları
- Sağlık verileri ile entegrasyon
- İstatistik grafikleri gösterme
- Export ve paylaşım seçenekleri

### 50. Beslenme Hatırlatıcısı Ayarları Sayfası *(15-20 Ekim 2025)*
**Amaç:** Kişiselleştirilmiş öğün hatırlatıcısı sistemi kurarak beslenme düzenini desteklemek.

**İşlemler:**
- Öğün saatleri belirleme (kahvaltı, öğle, akşam, ara öğünler)
- Hatırlatıcı sıklığı ayarlama
- Özel bildirim mesajları oluşturma
- Hafta sonu/tatil günleri için ayrı ayarlar
- Hatırlatıcı davranış analizi
- Kullanıcı tepki süresi takibi
- Adaptif hatırlatıcı zamanlaması
- Sessiz saatler belirleme

### 51. Sağlık Verileri Export Sayfası *(20-25 Ekim 2025)*
**Amaç:** Sağlık verilerini farklı formatlarda dışa aktararak paylaşım ve analiz imkanı sağlamak.

**İşlemler:**
- CSV formatında veri export
- Grafik tabanlı rapor oluşturma
- Belirli tarih aralığı seçme
- Özelleştirilebilir veri setleri
- E-posta ile paylaşım
- Cloud storage entegrasyonu
- Otomatik backup oluşturma
- Veri gizlilik kontrolü

### 52. PDF Görüntüleme Sayfası *(20-25 Ekim 2025)*
**Amaç:** Diyet planları, raporlar ve belgeler için kapsamlı PDF görüntüleyici sunmak.

**İşlemler:**
- PDF belgelerini yüksek kalitede görüntüleme
- Zoom yapma ve kaydırma
- Sayfa navigasyonu
- PDF içinde arama yapma
- Yer imleri kullanma
- Metin vurgulama
- Not ekleme
- Çizim yapma
- PDF'i kaydetme ve paylaşma

---

## 🔧 FAZ 4: OPTİMİZASYON VE TEST (26 Ekim - 20 Kasım 2025)

### 53. Depolama Yönetimi Sayfası *(1-5 Kasım 2025)*
**Amaç:** Uygulama ve medya verilerinin disk kullanımını optimize etmek.

**İşlemler:**
- Toplam depolama kullanımı gösterme
- Kategori bazında kullanım detayları
- Önbellek temizleme
- Eski medyaları silme
- Otomatik indirme ayarları
- Medya kalitesi ayarları
- Depolama uyarıları ayarlama
- Toplu temizlik önerileri

### 54. Yedekleme Sayfası *(1-5 Kasım 2025)*
**Amaç:** Sohbet verilerini güvenli bir şekilde yedeklemek ve geri yüklemek.

**İşlemler:**
- Google Drive/iCloud bağlantısı
- Otomatik yedekleme ayarlama
- Manuel yedek alma
- Yedekleme sıklığı belirleme
- Yedek boyutu gösterme
- Yedek geri yükleme
- Yedekleme şifreleme
- Yedek geçmişi görüntüleme

### 55. Directory Parser ve Otomatik Sistem Sayfası *(5-10 Kasım 2025)*
**Amaç:** Sistem dosyalarını otomatik olarak işlemek ve organize etmek.

**İşlemler:**
- Dosya yapısı analizi
- Otomatik kategorizasyon
- Batch dosya işlemleri
- Klasör hiyerarşi yönetimi
- Dosya meta veri çıkarma
- Duplicate dosya tespiti
- Otomatik backup oluşturma
- Sistem temizlik işlemleri

### 56. Test Data Yönetim Sayfası *(10-15 Kasım 2025)*
**Amaç:** Geliştirme ve test süreçleri için sample veri oluşturma ve yönetme.

**İşlemler:**
- Rastgele kullanıcı profilleri oluşturma
- Sample sohbet verisi üretme
- Test mesajları ekleme
- Sahte sağlık verileri oluşturma
- Demo senaryoları hazırlama
- Test verisi temizleme
- Performance test veri setleri
- A/B test veri yönetimi

### 57. Performans Optimizasyon Sayfası *(26 Ekim - 5 Kasım 2025)*
**Amaç:** Uygulama performansını izlemek ve optimize etmek için geliştirici araçları sunmak.

**İşlemler:**
- Medya cache yönetimi
- Veritabanı performans analizi
- Bellek kullanım istatistikleri
- Ağ trafiği optimizasyonu
- Batarya kullanım optimizasyonu
- Background sync yönetimi
- App lifecycle izleme
- Connection-aware sync
- Firebase kullanım takibi

### 58. Toplu Mesaj Gönderme Sayfası *(15 Kasım 2025)*
**Amaç:** Diyetisyenlerin tüm danışanlarına veya belirli gruplara toplu mesaj göndermesini sağlamak.

**İşlemler:**
- Alıcı grubu seçimi (tüm kullanıcılar, etiket bazlı gruplar)
- Mesaj türü belirleme (metin, medya, doküman)
- Mesaj şablonları kullanma
- Kişiselleştirilebilir değişkenler
- Zamanlanmış gönderim
- Teslimat durumu takibi
- Gönderim başarı raporları
- Batch işlemi optimizasyonu
- Kullanıcı yetkilendirme kontrolü

---

## 🏥 FAZ 5: DİYETİSYEN YÖNETİM PANELİ (21 Kasım - 15 Aralık 2025)

### 59. Danışan Yönetim Sayfası *(21-25 Kasım 2025)*
**Amaç:** Diyetisyenlerin tüm müşteri ilişkilerini merkezi olarak yönetmesini sağlamak.

**İşlemler:**
- Danışan profilleri oluşturma ve güncelleme
- Rol atama (Aktif Danışan, Eski Müşteri, VIP, vs.)
- Danışan durumu takibi (aktif, pasif, bloklu)
- Paket atama işlemleri
- İlerleme takibi yapma
- İletişim geçmişi görüntüleme
- Faturalama entegrasyonu
- Toplu mesaj gönderme
- Danışan arama ve filtreleme
- Randevu planlama

### 60. Diyet Paketleri Yönetim Sayfası *(25 Kasım - 1 Aralık 2025)*
**Amaç:** Diyet içeriklerini düzenlemek ve otomatik dağıtım sistemi kurmak.

**İşlemler:**
- Diyet dosyalarını yükleme (.docx, .pdf formatları)
- Paket kategorileme (BMI aralıkları, hedefler, kısıtlamalar)
- Template kütüphanesi yönetimi
- Paket versiyon kontrolü
- Paket etkinlik analizleri
- Otomatik paket seçim kuralları oluşturma
- Kişiselleştirilmiş paket düzenlemeleri
- Teslimat programlama
- Paket güncellemeleri yapma

#### 📦 Paket Yönetimi Detayları

##### 🎯 Paket Tanımlama Sistemi
Her paket için:
- **Paket Adı**: Her paket için benzersiz isim ("1 Aylık Zayıflama", "21 Günlük Detoks" vb.)
- **Toplam Süre**: Kaç gün süreceği
- **Liste Sayısı**: Pakette kaç adet diyet listesi olduğu
- **Kilo Değişim Hedefi**: Her diyet dosyasının ortalama ne kadar kilo değişimi sağlayacağı

##### 🌿 Mevsimsel Paket Yönetimi
- **Bahar Paketleri**: Mart-Mayıs dönemi için özel diyetler
- **Yaz Paketleri**: Haziran-Ağustos detoks ve zayıflama programları
- **Sonbahar Paketleri**: Eylül-Kasım bağışıklık güçlendirme
- **Kış Paketleri**: Aralık-Şubat enerji destekli beslenme
- **Tüm Yıl**: Mevsim bağımsız kullanılabilir paketler

##### 📁 Toplu Paket Yükleme Sistemi
```
Ana klasör adı → Paketin adı (örnek: Detoks Paketi)
├── AkdenizDiyeti/
│   ├── 21_25bmi/
│   │   └── akdeniz_normal.docx
│   ├── 26_29bmi/
│   │   └── akdeniz_fazla_kilo.docx
│   └── 30_33bmi/
│       └── akdeniz_obez.docx
```

### 61. Oto-Diyetler Botu Sayfası *(1-5 Aralık 2025)*
**Amaç:** Danışan rolündeki kullanıcıların paket bazlı diyet programlarını otomatik olarak almasını sağlamak.

**İşlemler:**
- Paket ve kombinasyon atama
- Sağlık bilgileri hesaplama (BMI, hedef kilo, kontrol tarihi)
- Uygun diyet seçimi (BMI bazlı)
- Kişiselleştirilmiş PDF oluşturma
- Otomatik mesaj gönderimi
- Dosya isimlendirme: [Ad Soyad] - [Başlangıç Tarihi] - [Bitiş Tarihi].pdf

#### 📊 Hesaplama Formülleri
- **Yaş**: Güncel Yıl - Doğum Yılı
- **BMI**: Kilo / (Boy²)
- **İdeal Kilo**:
  - 35 yaş altı: Boy² × 21
  - 35-45 yaş: Boy² × 22
  - 45 yaş üstü: Boy² × 23

### 62. Spor Seansları Yönetim Sayfası *(5-8 Aralık 2025)*
**Amaç:** Egzersiz programları oluşturmak ve danışanlara atamak.

**İşlemler:**
- Egzersiz kütüphanesi oluşturma
- Antrenman planları hazırlama
- Video talimat yükleme/bağlama
- Süre ve yoğunluk belirleme
- Dinlenme günleri planlama
- Danışanlara toplu atama
- Kişiselleştirilmiş değişiklikler
- İlerleme takip entegrasyonu
- Tamamlanma bildirimleri
- Performans analizleri

### 63. Randevu Yönetim Sayfası *(8-10 Aralık 2025)*
**Amaç:** Profesyonel randevu sistemini otomatize etmek ve müşteri deneyimini iyileştirmek.

**İşlemler:**
- Takvim bazlı randevu oluşturma
- Danışan seçimi ve ataması
- Randevu türü belirleme (konsültasyon, takip, vs.)
- Süre ve konum belirleme
- Platform seçimi (yüz yüze, görüntülü arama)
- Otomatik onay bildirimi
- Hatırlatma sistemi (1 gün, 1 saat öncesi)
- Randevu değişiklik bildirimleri
- İptal işlemleri
- Randevu geçmişi

### 64. Form Oluşturma Sayfası *(10-12 Aralık 2025)*
**Amaç:** Danışan değerlendirmesi için özelleştirilmiş formlar tasarlamak.

**İşlemler:**
- Sürükle-bırak form editörü kullanma
- Farklı soru türleri ekleme (açık uçlu, çoktan seçmeli, değerlendirme, vs.)
- Koşullu soru mantığı kurma
- Form doğrulama kuralları belirleme
- Dallanma mantığı oluşturma
- Form template'leri kaydetme
- Form önizleme ve test etme
- Form dağıtım seçenekleri
- Cevap analizi araçları
- Form performans metrikleri

### 65. Danışan Analiz Sayfası *(12-14 Aralık 2025)*
**Amaç:** Veri odaklı yaklaşımla danışan ilerlemesini analiz etmek ve raporlamak.

**İşlemler:**
- İlerleme görselleştirme grafikleri
- Hedef başarım oranları
- Karşılaştırmalı analizler
- Sağlık metrik trendleri
- Rapor oluşturma ve otomasyonu
- Kilo kaybı/artış takibi
- BMI trend analizi
- İletişim sıklığı analizi
- Paket etkinlik metrikleri
- Özelleştirilebilir rapor şablonları
- Excel/PDF export işlemleri

### 66. Oto-Mesajlar Botu Sayfası (Geliştirilmiş) *(14-15 Aralık 2025)*
**Amaç:** Toplu mesajlaşma sistemini otomatize etmek ve hedefli iletişim sağlamak.

**İşlemler:**
- Mesaj editörü ile içerik hazırlama
- Alıcı seçimi (etiketler, roller, tüm kullanıcılar)
- Zengin medya içeriği ekleme
- Mesaj şablonları kullanma
- Kişiselleştirilebilir değişkenler
- Anında gönderim
- Zamanlanmış gönderim
- Tekrarlayan mesajlar
- Etkinlik bazlı tetikleme
- Zaman dilimi farkında teslimat
- Teslimat analitikleri

### 67. Oto-Yanıtlar Botu Sayfası *(15 Aralık 2025)*
**Amaç:** Akıllı otomatik yanıt sistemi ile müşteri hizmetlerini iyileştirmek.

**İşlemler:**
- Yanıt kuralları oluşturma
- Anahtar kelime eşleştirmesi
- AI destekli yanıt üretimi
- Bağlam farkında yanıtlama
- Öncelik bazlı kural sıralaması
- Template kütüphanesi yönetimi
- Dinamik değişken kullanma
- Çok dilli yanıt desteği
- Yanıt etkinlik takibi
- OpenAI/ChatGPT entegrasyonu
- Diyetisyen düzeltmelerinden öğrenme
- Belirsizlik durumunda insana yönlendirme

**Not:** Bu sayfa yukarıda Sayfa 58 olarak eklendi.
**Amaç:** Diyetisyenlerin tüm danışanlarına veya belirli gruplara toplu mesaj göndermesini sağlamak.

**İşlemler:**
- Alıcı grubu seçimi (tüm kullanıcılar, etiket bazlı gruplar)
- Mesaj türü belirleme (metin, medya, doküman)
- Mesaj şablonları kullanma
- Kişiselleştirilebilir değişkenler
- Zamanlanmış gönderim
- Teslimat durumu takibi
- Gönderim başarı raporları
- Batch işlemi optimizasyonu
- Kullanıcı yetkilendirme kontrolü

---

## 📊 SÜRÜM PLANLARI VE ÖNCELIKLER

### 🎯 **v1.0 (15 Aralık 2025)** - Tam Platform
- ✅ Core messaging sistemi (Sayfa 1-57)
- ✅ Sağlık takibi özellikleri
- ✅ Diyetisyen yönetim paneli (Sayfa 58-67)
- ✅ Toplu mesaj gönderme
- ✅ Performance optimizasyonu

### 🚀 **v1.1 (Q1 2026)** - Optimizasyon
- 🔧 Performance iyileştirmeleri
- 🐛 Bug fixes ve stabilizasyon
- 📱 UI/UX geliştirmeleri
- 🔒 Güvenlik güncellemeleri

### 💪 **v2.0 (Q2 2026)** - AI & Analytics
- ⌚ Wearable cihaz entegrasyonları
- 🔗 Fitness tracker bağlantıları
- 🤖 Gelişmiş AI öneriler
- 📊 İleri analytics

### 🏥 **v2.5 (Q3 2026)** - Telemedicine
- 🎥 Video konsültasyon sistemi
- 💊 Telemedicine özellikleri
- 🩺 Uzaktan sağlık monitörü
- 📋 Elektronik reçete sistemi

### 🌍 **v3.0 (Q4 2026)** - Global Expansion
- 🌐 Multi-language support
- 🌎 International nutritionist standards
- 📱 Platform expansion (Web, Desktop)
- 🌐 Global compliance

---

## 📅 PROJE ROADMAP VE GELECEK PLANLAR

### 🎯 2025 Yılı Hedefleri:
- **Q3 2025**: Core messaging ve sağlık özelliklerinin tamamlanması (Sayfa 1-57)
- **Q4 2025**: Diyetisyen panel eklenmesi (Sayfa 58-67)
- **15 Aralık 2025**: Tam platform ile App Store ve Google Play'de yayın

### 🚀 Gelecek Sürümler (2026+):
- **v1.1 (Q1 2026)**: Optimizasyon ve stabilizasyon
- **v2.0 (Q2 2026)**: AI & wearable entegrasyonları
- **v2.5 (Q3 2026)**: Telemedicine özellikleri
- **v3.0 (Q4 2026)**: Global expansion

### 📊 Başarı Metrikleri:
- **Kullanıcı Hedefi**: 10,000+ aktif kullanıcı (2025 sonu)
- **Performance**: <2 saniye açılma süresi
- **Reliability**: %99.5 uptime hedefi
- **User Satisfaction**: 4.5+ App Store rating

### Teknik Stack Özeti:
- **Frontend**: Flutter 3.3.0+ (Dart)
- **Backend**: Firebase (Auth, Firestore, Storage, Messaging)
- **Database**: Drift ORM (SQLite) + Cloud Firestore
- **Real-time**: WebRTC, Firebase Real-time Database
- **Charts**: FL Chart
- **State Management**: Provider Pattern
- **Testing**: Mockito, Golden Toolkit, Coverage 70%+

---

**Son Güncelleme:** 2025-01-15

**Geliştirme Başlangıcı:** 2 Ağustos 2025 \
**v1.0 Release:** 15 Aralık 2025 \
**Toplam Sayfa Sayısı:** 67 (v1.0: 57 sayfa, v2.0+: 10 sayfa) \
**v1.0 Geliştirme Süresi:** ~4.5 ay (135 gün) \
**Platform:** Flutter (Android/iOS) \
**v1.0 Özellikler:** Sağlık Takibi + WhatsApp-benzeri Mesajlaşma + Performance Optimizations \
**Gelecek Sürümler:** Diyetisyen Panel + AI + Telemedicine (2026+)

### 👨‍💻 Geliştirici Bilgileri:
- **Lead Developer**: Kenan Kanat (kenankanat93@gmail.com)
- **Repository**: https://github.com/Kenfrozz/diyetkent.git
- **Branch Strategy**: Main branch (production-ready)
- **Development Methodology**: Agile, 5-faz iterative development