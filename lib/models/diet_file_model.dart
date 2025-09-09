enum DietFileType {
  template, // Diyetisyen tarafından yüklenen şablon
  custom,   // Danışana özel oluşturulmuş dosya
}

class DietFileModel {
  late String fileId;
  late String userId; // diyet dosyasının sahibi
  late String dietitianId; // dosyayı oluşturan diyetisyen

  String title = '';
  String description = '';
  
  // Dosya bilgileri
  String? fileUrl; // Firebase Storage URL
  String? fileName;
  String? fileType; // pdf, doc, image, etc.
  int? fileSizeBytes;
  
  // Diyet planı detayları
  String? mealPlan; // öğün planı
  String? restrictions; // kısıtlamalar
  String? recommendations; // öneriler
  String? targetWeight; // hedef kilo
  String? duration; // süre
  
  // Diyetisyen notları
  String? dietitianNotes;
  
  // Etiketler ve kategoriler
  List<String> tags = <String>[];
  
  // Durum bilgileri
  bool isActive = true;
  bool isRead = false; // kullanıcı okudu mu
  DateTime? readAt;
  
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  DietFileModel();

  DietFileModel.create({
    required this.fileId,
    required this.userId,
    required this.dietitianId,
    required this.title,
    this.description = '',
    this.fileUrl,
    this.fileName,
    this.fileType,
    this.fileSizeBytes,
    this.mealPlan,
    this.restrictions,
    this.recommendations,
    this.targetWeight,
    this.duration,
    this.dietitianNotes,
    this.tags = const <String>[],
    this.isActive = true,
    this.isRead = false,
    this.readAt,
  }) {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  // Firebase'e çevirmek için Map
  Map<String, dynamic> toMap() {
    return {
      'fileId': fileId,
      'userId': userId,
      'dietitianId': dietitianId,
      'title': title,
      'description': description,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileType': fileType,
      'fileSizeBytes': fileSizeBytes,
      'mealPlan': mealPlan,
      'restrictions': restrictions,
      'recommendations': recommendations,
      'targetWeight': targetWeight,
      'duration': duration,
      'dietitianNotes': dietitianNotes,
      'tags': tags,
      'isActive': isActive,
      'isRead': isRead,
      'readAt': readAt?.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Firebase'den çevirmek için factory
  factory DietFileModel.fromMap(Map<String, dynamic> map) {
    return DietFileModel.create(
      fileId: map['fileId'] ?? '',
      userId: map['userId'] ?? '',
      dietitianId: map['dietitianId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      fileUrl: map['fileUrl'],
      fileName: map['fileName'],
      fileType: map['fileType'],
      fileSizeBytes: map['fileSizeBytes']?.toInt(),
      mealPlan: map['mealPlan'],
      restrictions: map['restrictions'],
      recommendations: map['recommendations'],
      targetWeight: map['targetWeight'],
      duration: map['duration'],
      dietitianNotes: map['dietitianNotes'],
      tags: List<String>.from(map['tags'] ?? []),
      isActive: map['isActive'] ?? true,
      isRead: map['isRead'] ?? false,
      readAt: map['readAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['readAt'])
          : null,
    );
  }

  // Dosya boyutu getter (backward compatibility)
  int? get fileSize => fileSizeBytes;

  // Dosya boyutu formatlanmış
  String get formattedFileSize {
    if (fileSizeBytes == null) return 'Bilinmiyor';
    
    double bytes = fileSizeBytes!.toDouble();
    if (bytes < 1024) return '${bytes.toInt()} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Dosya tipi ikonu
  String get fileIcon {
    switch (fileType?.toLowerCase()) {
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📝';
      case 'jpg':
      case 'jpeg':
      case 'png':
        return '🖼️';
      case 'xls':
      case 'xlsx':
        return '📊';
      default:
        return '📎';
    }
  }
}
