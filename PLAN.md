# DiyetKent Mesajlaşma Uygulaması - Kronolojik Geliştirme Planı
Bu belge WhatsApp benzeri mesajlaşma uygulaması + diyetisyen paneli için kronolojik geliştirme sırasına göre düzenlenmiştir.

---

## 📅 FAZ 1: TEMEL ALTYAPI (2 Ağustos - 30 Ağustos 2025)

### 1. Hizmet Koşulları Onay Ekranı *(2-5 Ağustos 2025)*
**Amaç:** Uygulama ilk açıldığında kullanıcıdan Diyetkent Hizmet Koşulları onayı almak.

**Ayrıntılar:**
Bu sayfa uygulamaya ilk kez giriş yapan kullanıcılar için zorunlu bir adımdır. KVKK ve kullanıcı gizliliği açısından kritik öneme sahiptir. Sayfa, modern ve görsel olarak çekici bir tasarımla hizmet koşullarını özetler ve kullanıcıdan açık rıza ister. Onay verildikten sonra bu ekran bir daha görüntülenmez ve kullanıcı doğrudan giriş sayfasına yönlendirilir.

**İşlemler:**
- İlk açılışta hoşgeldin ekranı gösterme
- "Diyetkent Hizmet Koşullarını kabul etmek için Kabul Et ve Devam Et seçeneğine dokun" metni
- "Diyetkent Hizmet Koşulları" yazısı tıklanabilir link olarak gösterme
- Linke tıklandığında web sitesindeki hizmet koşulları sayfasına yönlendirme
- "Kabul Et ve Devam Et" butonuna tıklandığında telefon giriş ekranına geçiş
- Onay durumunu kalıcı olarak kaydetme (bir daha gösterilmez)

### 2. Telefon Numarası Giriş Sayfası *(5-10 Ağustos 2025)*
**Amaç:** Kullanıcıların telefon numarasıyla sisteme giriş yapmasını sağlamak ve hesap oluşturmak.

**Ayrıntılar:**
WhatsApp benzeri telefon numarası tabanlı kimlik doğrulama sistemi. 248 farklı ülke kodu desteği ile global kullanıcı erişimi sağlar. Numara formatı otomatik kontrol edilir ve geçersiz numaralar için anlık uyarı verilir. Firebase Auth entegrasyonu sayesinde güvenli SMS doğrulama işlemi başlatılır. Kullanıcı dostu arayüz ile hızlı ve kolay numara girişi mümkündür.

**İşlemler:**
- Kullanıcı ülke kodu seçer (248 farklı ülke desteği)
- Telefon numarasını girer (gerçek zamanlı format doğrulama)
- Sistem numarayı doğrular ve SMS gönderir
- Hatalı numara girişinde uyarı mesajı gösterir
- Numara doğruysa SMS doğrulama sayfasına yönlendirir

### 3. SMS Doğrulama Sayfası *(5-10 Ağustos 2025)*
**Amaç:** Telefon numarasının gerçekten kullanıcıya ait olduğunu doğrulamak ve güvenliği sağlamak.

**Ayrıntılar:**
Güvenlik odaklı 6 haneli doğrulama kodu giriş sayfası. Android cihazlarda SMS otomatik okuma özelliği ile kullanıcı deneyimi optimize edilmiştir. 60 saniyelik geri sayım timer'ı ile kod yeniden gönderme imkanı sunulur. Yanlış kod girişlerinde kullanıcı dostu hata mesajları gösterilir. Numara değiştirme seçeneği ile esneklik sağlanır. Firebase backend entegrasyonu ile yüksek güvenlik standartlarına uygun çalışır.

**İşlemler:**
- SMS ile gelen 6 haneli kodu kullanıcı girer
- Kod otomatik algılanabilir (Android SMS Auto-Read)
- Yanlış kod girişinde hata gösterir ve tekrar girme imkanı verir
- 60 saniyelik zamanlayıcı sonrası kod yeniden gönderilebilir
- Doğru kod girişinde hesap aktivasyonu tamamlanır
- Numara değiştirme imkanı sunar

### 3.1. Yedek Kontrol ve Geri Yükleme Sayfası *(5-10 Ağustos 2025)*
**Amaç:** SMS doğrulaması sonrası kullanıcının daha önce yedekleme yapıp yapmadığını kontrol etmek.

**Ayrıntılar:**
SMS doğrulaması tamamlandıktan sonra kullanıcı bu sayfaya yönlendirilir. Sistem, kullanıcının daha önce Google Drive'da yedekleme yapıp yapmadığını otomatik kontrol eder. Eğer yedek varsa kullanıcıya "Daha önce mesajlarınızı yedeklemiş görünüyorsunuz. Yedeğinizi geri yüklemek istiyor musunuz?" sorusu sorulur. Kullanıcı isterse Google hesabıyla giriş yaparak yedeğini geri yükleyebilir. Yedekleme yoksa veya kullanıcı geri yükleme istemezse profil sayfasına yönlendirilir.

**İşlemler:**
- Google Drive'da yedek kontrolü yapma
- Yedek bulunursa kullanıcıya bilgi verme
- Google hesabı ile giriş seçeneği sunma
- Yedek geri yükleme işlemi başlatma
- Yedek yoksa profil sayfasına yönlendirme

### 4. Profil Sayfası *(15-20 Ağustos 2025)*
**Amaç:** Kullanıcının kişisel bilgilerini yönetmesi ve diğer kullanıcılara kendini tanıtması.

**Ayrıntılar:**
Yedek kontrol sayfasından sonra kullanıcının yönlendirildiği profil kurulum sayfası. Eğer kullanıcının daha önce profili varsa bilgiler önceden doldurulmuş halde gelir, sadece güncellemeler yapabilir. Yeni kullanıcılar için profil bilgileri zorunlu olarak doldurulmalıdır. Profil fotoğrafı ekleme/değiştirme için kamera ve galeri entegrasyonu mevcuttur. Fotoğraf düzenleme araçları (kırpma, boyutlandırma) ile kullanıcı istediği görünümü elde edebilir. Ad, soyad ve 'hakkımda' bilgileri kolaylıkla güncellenebilir. Profil tamamlandıktan sonra ana ekrana yönlendirilir ve arka planda rehber servisi çalışmaya başlar.

**İşlemler:**
- Önceki profil bilgilerini otomatik doldurma (varsa)
- Profil fotoğrafı ekleme/değiştirme/silme (kamera veya galeriden)
- Fotoğraf düzenleme (kırpma, boyutlandırma)
- Ad ve soyad bilgilerini güncelleme (zorunlu)
- Hakkımda bölümünü düzenleme (durum mesajı)
- Telefon numarasını görüntüleme (değiştirilemez)
- Profil tamamlandıktan sonra ana ekrana yönlendirme

### 5. Ana Sayfa (TabBar İskeleti) *(10-15 Ağustos 2025)*
**Amaç:** Uygulamanın merkezi navigasyon hub'ı olarak üç ana sekme arasında geçiş sağlamak.

**Ayrıntılar:**
Profil kurulumundan sonra kullanıcının yönlendirildiği ana uygulama iskeletidir. DiyetKent branding'li AppBar, sağlık göstergeleri (AppBarHealthIndicators), yedekleme durumu widget'ı (BackupStatusWidget) ve seçim modu için toplu işlem özellikleri içerir. TabController ile 3 ana sekme: "SOHBETLER" (ChatListPageNew), "DURUM" (StoriesPage), "ARAMALAR" (CallsPage). Her sekme için özel FloatingActionButton davranışı - sohbetlerde yeni chat, durumda story ekleme, aramalarda arama başlatma. RefreshIndicator ile manuel senkronizasyon ve optimized performance için Firebase listeners minimize edilmiş durumda.

**Ana Sekmeleri:**
- **📱 Sohbetler Tab'ı:** ChatListPageNew - optimize edilmiş sohbet listesi
- **📖 Durumlar Tab'ı:** StoriesPage - 24 saatlik hikayeler yönetimi
- **📞 Aramalar Tab'ı:** CallsPage - arama geçmişi ve yönetimi

**İskelet Özellikleri:**
- **Optimize AppBar:** Sağlık göstergeleri, yedekleme durumu, seçim modu
- **TabController:** 3 sekme ile dinamik geçiş (length: 3, initialIndex: 0)
- **Smart FloatingActionButton:** Sekme bazlı farklı eylemler (chat/story/call)
- **Pull-to-Refresh:** Manuel sync tetikleme ile veri güncellemesi
- **Selection Mode:** Toplu sohbet işlemleri için çoklu seçim
- **Background Sync:** Firebase Background Sync Service entegrasyonu

**İşlemler:**
- DiyetKent ana navigasyon TabBar'ını görüntüleme
- TabBarView ile SOHBETLER, DURUM, ARAMALAR yönetimi
- AppBarHealthIndicators ile sistem durumu gösterimi
- Sekme bazlı FloatingActionButton eylem değişimi
- RefreshIndicator ile manuel senkronizasyon tetikleme
- Seçim modu etkinleştirme ve toplu işlemler

### 6. Ana Sohbet Listesi Sayfası *(10-15 Ağustos 2025)*
**Amaç:** Tüm sohbetleri merkezi bir yerde görmek ve hızlı erişim sağlamak.

**Ayrıntılar:**
Uygulamanın kalbi olan ana sohbet listesi. Gerçek zamanlı güncellemelerle canlı tutulan sohbet listesi, son mesaj tarihine göre otomatik sıralanır. Her sohbet için son mesaj önizlemesi, okunmamış mesaj sayısı rozeti ve mesaj durumu görüntülenir. Sabitleme, arşivleme ve silme işlemleri kaydırma hareketleriyle kolayca erişilebilir. Uzun basışla çoklu seçim modu etkinleştirilerek toplu işlemler yapılabilir.

**İşlemler:**
- Aktif sohbetleri son mesaj tarihine göre sıralama
- Sabitlenmiş sohbetleri üstte gösterme
- Her sohbet için son mesaj önizlemesi gösterme
- Okunmamış mesaj sayısını badge ile gösterme
- Mesaj durumunu gösterme (gönderildi, okundu, vs.)
- Sohbetleri kaydırarak arşivleme/silme/sabitleme
- Uzun basarak çoklu seçim yapma
- Yeni sohbet başlatma

### 7. Sohbet Sayfası *(10-15 Ağustos 2025)*
**Amaç:** İki kullanıcı arasında kapsamlı ve gerçek zamanlı mesajlaşma deneyimi sunmak.

**Ayrıntılar:**
WhatsApp kalitesinde gelişmiş mesajlaşma deneyimi sunan ana sohbet ekranı. Tüm modern mesajlaşma özelliklerini içeren kapsamlı bir iletişim merkezi.

**Ana Özellikler:**

**📱 Temel Mesajlaşma:**
- Mesajlar gerçek zamanlı olarak görüntülenir ve otomatik kaydırma ile son mesaja odaklanır
- Her mesaj için durum göstergesi (gönderiliyor, gönderildi, okundu) mevcuttur
- Günlük tarih ayraçları ile geçmiş mesajlarda gezinme kolaylaştırılır

**👤 Kullanıcı Durumu:**
- Karşı tarafın çevrimiçi/çevrimdışı durumu gerçek zamanlı gösterilir
- Son görülme zamanı bilgisi (gizlilik ayarlarına göre)
- 'Yazıyor...' göstergesi canlı olarak güncellenir
- Grup sohbetlerinde 'kim okudu' bilgisi

**💬 Gelişmiş Mesaj Özellikleri:**
- **Mesaj Yanıtlama:** Belirli mesajlara referans vererek yanıt verme
- **Mesaj Silme:** "Benden sil" ve "Herkesten sil" (24 saat içinde) seçenekleri
- **Mesaj Kopyalama:** Panoya kopyalama ve çoklu seçim desteği
- **Mesaj İletme:** Seçili mesajları diğer kişi/gruplara iletme

**🎨 Zengin İçerik Desteği:**
- **Rich Text:** Kalın (**metin**), italik (_metin_), üstü çizili (~metin~) formatlar
- **Link/Telefon/Email Algılama:** Otomatik algılama ve tıklanabilir linkler
- **Medya Paylaşımı:** Fotoğraf, video, doküman gönderme ve önizleme
- **Sesli Mesaj:** Mikrofona basılı tutarak ses kaydı, oynatma, hız kontrolü (1x, 1.5x, 2x)
- **Konum Paylaşımı:** Mevcut konum veya harita üzerinden seçilen konum
- **Kişi Kartı:** Rehberden kişi bilgilerini paylaşma

**🎤 Sesli Mesaj Özellikleri:**
- Mikrofon butonuna basılı tutarak kayıt başlatma
- Kayıt süresini gerçek zamanlı gösterme
- Kaydı iptal etme (sola kaydırma)
- Kaydı gönderme (butonu bırakma)
- Kayıt kalitesi ayarlama
- Sesli mesajları oynatma/duraklatma
- Oynatma hızı değiştirme (1x, 1.5x, 2x)
- Sesli mesaj süresini gösterme

### 8. Sohbet Arama ve Filtreleme *(15-20 Ağustos 2025)*
**Amaç:** Çok sayıda sohbet arasında hızlı arama yapabilmek ve kategorilere göre filtreleme.

**Ayrıntılar:**
Akıllı arama motoru ile çok boyutlu arama imkanı sunar. İsim, telefon numarası, mesaj içeriği ve medya dosyaları içinde arama yapılabilir. Arama sonuçlarında eşleşen kısımlar vurgulanır. Filtre seçenekleri: tüm sohbetler, okunmamış mesajlar, gruplar, arşivlenen sohbetler ve etiket bazında kategorizasyon. Gerçek zamanlı arama sonuçları ile anlık geri bildirim verilir. Canlı öneriler ve geçmiş arama geçmişi kaydedilir.

**İşlemler:**
- Gerçek zamanlı arama (isim, telefon no, medya, ve mesaj içeriği)
- Arama sonuçlarında eşleşen kısımları vurgulama
- Filtre uygulama (tüm sohbetler, okunmamış, gruplar, arşivlenen, etiketler)

### 9. Sohbet Arşivleme/Arşivden Çıkarma *(20-22 Ağustos 2025)*
**Amaç:** Eski veya az kullanılan sohbetleri ana listeden kaldırarak düzen sağlamak.

**İşlemler:**
- Sohbetleri arşivleme (kaydırma veya menü ile)
- Arşivlenmiş sohbetleri ayrı bölümde görüntüleme
- Arşivden tek tek veya toplu çıkarma
- Yeni mesaj geldiğinde otomatik arşivden çıkarma
- Arşiv bildirimi ayarları yönetme

### 10. Sohbet Silme *(20-22 Ağustos 2025)*
**Amaç:** İstenmeyen sohbetleri kalıcı olarak sistemden kaldırmak.

**İşlemler:**
- Sohbet silme için onay alma
- İki silme seçeneği sunma (sadece benden sil / herkesten sil)
- Silinen sohbetlerin geri alınamayacağı konusunda uyarı
- Grup sohbeti için ek seçenekler (gruptan ayrılma)
- Silme işlemi sonrası ana listeyi güncelleme

### 11. Sohbet Sabitleme *(20-22 Ağustos 2025)*
**Amaç:** Önemli sohbetleri her zaman üstte tutarak kolay erişim sağlamak.

**İşlemler:**
- En fazla 3 sohbeti sabitleme
- Sabitlenmiş sohbetleri özel simgeyle işaretleme
- Sabitleme sırası değiştirme
- Sabitleme limitine ulaşıldığında uyarı
- Sabitlemeyi kaldırma seçeneği

### 12. Arşivlenmiş Sohbetler Sayfası *(20-22 Ağustos 2025)*
**Amaç:** Kullanıcının arşivlediği sohbetleri yönetmek ve gerektiğinde geri getirmek.

**İşlemler:**
- Arşivlenmiş sohbetleri listeleme
- Arşiv tarihine göre sıralama
- Arşivden çıkarma işlemi
- Toplu arşiv yönetimi
- Arama ve filtreleme
- Arşiv boyutu bilgisi
- Otomatik arşivleme kuralları

### 13. Kamera Sayfası *(25-30 Ağustos 2025)*
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

### 14. Kamera Sayfası (Extended Features) *(25-30 Ağustos 2025)*
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

### 15. Medya Galerisi Sayfası *(25-30 Ağustos 2025)*
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

### 16. Kişiler Sayfası ve Merkezi Rehber Yönetimi *(25-30 Ağustos 2025)*
**Amaç:** Merkezi bir rehber sistemi ile tüm kişileri yönetmek ve uygulama genelinde kişi seçimlerinde kullanmak.

**Ayrıntılar:**
Kullanıcı profili tamamlandıktan sonra ana ekrana geldiğinde rehber servisi arka planda çalışmaya başlar. Telefon rehberindeki numaralar ve isimler yerel veritabanına çekilir. Uygulamayı kullananları hızlıca ayırt etmek ve büyük rehberleri taramayı beklememek için bu işlem arka planda yavaş yavaş yapılır. Rehber sayfası özel bir sayfa olarak tasarlanır ve kullanıcı arama, yeni mesaj gibi tüm işlemlerde bu sayfayı kullanarak kişi veya kişileri seçer.

**İşlemler:**
- **Arka Plan Senkronizasyonu:** Profil tamamlandıktan sonra otomatik başlama
- **Telefon Rehberi Entegrasyonu:** Numara ve isimleri yerel veritabanına çekme
- **DiyetKent Kullanıcı Tespiti:** Uygulamayı kullananları otomatik ayırt etme
- **Akıllı Sıralama:** DiyetKent kullanıcılarını üstte gösterme
- **Hızlı Arama:** Alfabetik sıralama ve gerçek zamanlı filtreleme
- **Çoklu Seçim:** Grup oluşturma ve toplu mesaj için
- **Duplicate Yönetimi:** Aynı kişi birden fazla kayıt tespiti ve birleştirme
- **Çapraz Platform:** Firebase ile çoklu cihaz senkronizasyonu
---

## 🚀 FAZ 2: ANA ÖZELLİKLER (1 Eylül - 30 Eylül 2025)

### 28. Grup Oluşturma Sayfası *(1-5 Eylül 2025)*
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

### 29. Grup Detay Sayfası *(5-10 Eylül 2025)*
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

### 30. Durumlar Sayfası *(14-18 Eylül 2025)*
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

### 31. Durum Gizlilik Ayarları *(14-18 Eylül 2025)*
**Amaç:** Durumların kimler tarafından görülebileceğini kontrol etmek.

**İşlemler:**
- "Herkes" seçeneği
- "Rehbimdekiler" seçeneği
- "Seçtiğim kişiler" seçeneği
- "Hariç tutulanlar" listesi oluşturma
- Gizlilik ayarlarını kaydetme
- Mevcut durumlar için geçmişe dönük uygulama

### 32. Durum Görüntüleme Sayfası *(14-18 Eylül 2025)*
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

### 33. Aramalar Sayfası *(18-22 Eylül 2025)*
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

### 34. Gelen/Giden Çağrı Sayfası *(18-22 Eylül 2025)*
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

### 35. Gelen/Giden Çağrı Yönetim Sayfası *(18-22 Eylül 2025)*
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

### 36. Ana Ayarlar Sayfası *(22-26 Eylül 2025)*
**Amaç:** Tüm uygulama ayarlarına merkezi erişim sağlamak.

**İşlemler:**
- Kullanıcı profilini özetleme
- Ayar kategorilerini listeleme
- Hızlı ayarlara erişim
- Ayarlarda arama yapma
- Ayar önizlemeleri gösterme
- Alt sayfalara yönlendirme

### 37. Hakkında/Yardım Sayfası *(22-26 Eylül 2025)*
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


### 38. Gizlilik Ayarları Sayfası *(22-26 Eylül 2025)*
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

### 39. Hesap Ayarları Sayfası *(22-26 Eylül 2025)*
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

### 40. Bildirim Ayarları Sayfası *(22-26 Eylül 2025)*
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

### 41. Etiketler Sayfası *(26-30 Eylül 2025)*
**Amaç:** Diyetisyenlerin danışanlarını kategorilere ayırarak organize etmesini sağlamak.

**İşlemler:**
- Tüm etiketleri renk kodlu olarak listeleme
- Her etiketin kaç sohbette kullanıldığını gösterme
- Etikete tıklayarak o kategorideki sohbetleri listeleme
- Etiket ekleme, düzenleme, silme işlemleri
- Etiketleri renk ve isme göre sıralama
- Etiket bazlı istatistikler gösterme

### 42. Etiket Ekleme *(26-30 Eylül 2025)*
**Amaç:** Yeni müşteri kategorileri oluşturarak sınıflandırma sistemi geliştirmek.

**İşlemler:**
- Etiket adı belirleme
- Renk seçimi (10 farklı seçenek)
- İkon seçimi (20+ seçenek)
- Etiket açıklaması ekleme
- Aynı isimde etiket kontrolü
- Etiket önizlemesi gösterme
- Oluşturma işlemini onaylama

### 43. Etiket Düzenleme/Silme *(26-30 Eylül 2025)*
**Amaç:** Mevcut etiket sistemini güncel tutmak ve gereksiz etiketleri temizlemek.

**İşlemler:**
- Etiket bilgilerini güncelleme (isim, renk, ikon)
- Etiket silme işleminde onay alma
- Silinecek etiketteki sohbetler için alternatif etiket sunma
- Etiket kullanım istatistikleri gösterme
- Silme sonrası sohbetleri "Etiketiesiz" kategorisine taşıma

---

## 💊 FAZ 3: SAĞLIK ÖZELLİKLERİ (1 Ekim - 25 Ekim 2025)

### 44. Sağlık Bilgilerim Sayfası *(1-5 Ekim 2025)*
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

### 45. Form Doldurma Sayfası *(1-5 Ekim 2025)*
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

### 46. Adım Sayar ve Aktivite Takibi Sayfası *(10-15 Ekim 2025)*
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

### 47. PDF Görüntüleme Sayfası *(20-25 Ekim 2025)*
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

## 🏥 FAZ 4: DİYETİSYEN YÖNETİM PANELİ (26 Ekim - 20 Kasım 2025)

### 48. Danışan Yönetim Sayfası *(26 Ekim - 1 Kasım 2025)*
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

### 49. Diyet Paketleri Yönetim Sayfası *(1-5 Kasım 2025)*
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

### 50. Oto-Diyetler Botu Sayfası *(5-8 Kasım 2025)*
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

### 51. Spor Seansları Yönetim Sayfası *(8-10 Kasım 2025)*
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

### 52. Randevu Yönetim Sayfası *(10-12 Kasım 2025)*
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

### 53. Form Oluşturma Sayfası *(12-15 Kasım 2025)*
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

## 🔧 FAZ 5: OPTİMİZASYON VE TEST (21 Kasım - 15 Aralık 2025)

### 54. Danışan Analiz Sayfası *(15-18 Kasım 2025)*
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

### 55. Oto-Mesajlar Botu Sayfası (Geliştirilmiş) *(18-20 Kasım 2025)*
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

### 56. Oto-Yanıtlar Botu Sayfası *(20 Kasım 2025)*
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

### 57. Depolama Yönetimi Sayfası *(21-25 Kasım 2025)*
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

### 58. Yedekleme Sayfası *(25-28 Kasım 2025)*
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

### 59. Directory Parser ve Otomatik Sistem Sayfası *(28 Kasım - 5 Aralık 2025)*
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

### 60. Test Data Yönetim Sayfası *(5-10 Aralık 2025)*
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

### 61. Performans Optimizasyon Sayfası *(10-12 Aralık 2025)*
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

### 62. Toplu Mesaj Gönderme Sayfası *(12-15 Aralık 2025)*
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
# Teknik Stack Özeti:
- **Frontend**: Flutter 3.3.0+ (Dart)
- **Backend**: Firebase (Auth, Firestore, Storage, Messaging)
- **Database**: Drift ORM (SQLite) + Cloud Firestore
- **Real-time**: WebRTC, Firebase Real-time Database
- **Charts**: FL Chart
- **State Management**: Provider Pattern
- **Testing**: Mockito, Golden Toolkit, Coverage 70%+
---


### 👨‍💻 Geliştirici Bilgileri:
- **Lead Developer**: Kenan Kanat (kenankanat93@gmail.com)
- **Repository**: https://github.com/Kenfrozz/diyetkent.git
- **Branch Strategy**: Main branch (production-ready)