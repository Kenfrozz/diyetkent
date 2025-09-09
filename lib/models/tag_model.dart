class TagModel {
  late String tagId;

  late String name;
  String? color; // Hex color code (örn: "#FF5722")
  String? icon; // Icon name (örn: "work", "family", "friends")
  String? description;

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  // Etiket kullanım sayısı
  int usageCount = 0;

  TagModel();

  TagModel.create({
    required this.tagId,
    required this.name,
    this.color,
    this.icon,
    this.usageCount = 0,
  }) {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  @override
  String toString() {
    return 'TagModel{tagId: $tagId, name: $name, color: $color, icon: $icon}';
  }
}
