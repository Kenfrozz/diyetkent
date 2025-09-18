# 🤖 Multi-Agent Development Workflow Sistemi

Bu dokümantasyon, DiyetKent projesi için tasarlanan otomatik geliştirme workflow sistemini açıklar.

## 📋 Sistem Genel Bakış

4 farklı AI agent'ın koordineli çalışmasıyla tam otomatik software development lifecycle yönetimi:

1. **🎯 Proje Yöneticisi Agent (PM Agent)** - Task yönetimi ve koordinasyon
2. **💻 Developer Agent (DEV Agent)** - Kod geliştirme ve implementasyon
3. **🔍 Code Reviewer Agent (CR Agent)** - Kod kalitesi ve güvenlik kontrolü
4. **🧪 QA Tester Agent (QA Agent)** - Test ve kalite güvencesi

## 🔄 Workflow Döngüsü

```
📝 Task Master → 🎯 PM Agent → 💻 DEV Agent → 🔍 CR Agent → 🧪 QA Agent → 🔀 Merge → 🔄 Tekrar
```

### Detaylı Süreç:

1. **PM Agent**: Task Master backlog'undan en yüksek prioriteli task'ı seçer
2. **PM Agent**: GitHub'da issue açar ve task'ı in-progress yapar
3. **DEV Agent**: Issue'yu alır, feature branch oluşturur, kod geliştirir
4. **DEV Agent**: Testleri çalıştırır, commit yapar ve PR açar
5. **CR Agent**: PR'ı inceler, kod kalitesi/güvenlik/performans kontrolü yapar
6. **CR Agent**: Onay verir veya değişiklik talep eder
7. **QA Agent**: Fonksiyonel/widget/integration testlerini çalıştırır
8. **QA Agent**: Coverage kontrolü ve build testi yapar
9. **PM Agent**: Tüm onaylar alındıktan sonra PR'ı merge eder
10. **PM Agent**: Task'ı completed yapar ve döngü tekrarlanır

## 🛠️ Kullanım Komutları

### Manuel Agent Çalıştırma
```bash
/pm-agent start          # PM Agent başlat
/dev-agent <issue-id>    # DEV Agent başlat
/cr-agent <pr-id>        # CR Agent başlat
/qa-agent <pr-id>        # QA Agent başlat
```

### Otomatik Workflow
```bash
/start-auto-workflow     # Tam otomatik sürekli döngü
```

### Test ve Doğrulama
```bash
/test-workflow          # Sistem entegrasyonu test et
```

## 🔧 Teknik Entegrasyonlar

### Task Master Integration
- Task Master MCP server üzerinden task yönetimi
- Backlog'dan otomatik task seçimi
- Task durumu güncellemeleri (pending → in-progress → done)
- Priority ve dependency yönetimi

### GitHub MCP Integration
- Repository operasyonları (clone, branch, commit, push)
- Issue yönetimi (create, update, close)
- Pull Request yönetimi (create, review, merge)
- Comment ve review sistemi

### Flutter Development Integration
- CLAUDE.md kuralları otomatik uygulanması
- Make scripts kullanımı (setup, dev, test, build, lint)
- Code generation (build_runner) otomatik çalıştırılması
- Git user configuration kontrolü

## 📊 Kalite Kontrol Kriterleri

### Code Review (CR Agent)
- ✅ Clean Code principles
- ✅ Flutter/Dart best practices
- ✅ Security scan (input validation, SQL injection, XSS)
- ✅ Performance optimization
- ✅ Test coverage minimum %70

### QA Testing (QA Agent)
- ✅ Unit tests
- ✅ Widget tests
- ✅ Integration tests
- ✅ Build success
- ✅ Lint/analyze geçme

## 🔐 Güvenlik ve Best Practices

### Otomatik Kontroller
- API key ve sensitive data detection
- .gitignore kuralları uygulanması
- Commit message format kontrolü
- Branch naming convention

### Code Quality Gates
- Flutter analyze ✅
- Dart formatter ✅
- Test coverage ≥ 70% ✅
- Build success ✅
- No linting errors ✅

## 📈 İzleme ve Raporlama

### Agent Status Monitoring
- Real-time agent durumu görünürlüğü
- Workflow bottleneck analizi
- Error handling ve retry mekanizması

### Productivity Metrics
- Task completion rate
- Code review cycle time
- Bug detection rate
- Test coverage trends

## 🚀 Başlangıç

1. **Sistem Test**: `/test-workflow` komutu ile entegrasyonu doğrula
2. **Manual Test**: Tek task ile manuel agent'ları test et
3. **Auto Mode**: `/start-auto-workflow` ile tam otomatik moda geç

## 🤝 Agent İletişimi

Agent'lar arasında durum bilgisi GitHub PR/Issue comment'leri üzerinden paylaşılır:
- ✅ Success: Bir sonraki agent tetiklenir
- ❌ Failure: Önceki agent'e geri dönülür
- 🔄 Retry: Maksimum 3 deneme hakkı

## 🎯 Hedeflenen Faydalar

- **%90 Otomatik**: Manuel müdahale minimumu
- **Kalite Güvencesi**: Çok katmanlı kontrol sistemi
- **Hız**: Paralel işlem ve otomatik workflow
- **Standart**: Tutarlı kod kalitesi ve süreçler
- **İzlenebilirlik**: Tüm süreç GitHub'da kayıtlı

---

*Bu sistem Task Master AI ve GitHub MCP araçlarının güçlü entegrasyonu ile DiyetKent projesi için özel olarak tasarlanmıştır.*