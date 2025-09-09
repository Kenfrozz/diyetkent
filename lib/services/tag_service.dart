// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
// import '../database/drift_service.dart'; // Unused
import '../models/tag_model.dart';
import '../models/chat_model.dart';
// import 'firebase_usage_tracker.dart'; // Unused

class TagService {
  static final TagService _instance = TagService._internal();
  factory TagService() => _instance;
  TagService._internal();

  // Unused fields commented out
  // final DriftService _driftService = DriftService();
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> init() async {
    // TODO: Implement Drift-based tag service
    debugPrint('TagService: Drift migration needed - service temporarily stubbed');
  }

  // Stubbed methods to prevent compilation errors
  Future<List<TagModel>> getAllTags() async {
    debugPrint('TagService.getAllTags: Not yet implemented with Drift');
    return <TagModel>[];
  }

  Future<TagModel?> getTagById(String tagId) async {
    debugPrint('TagService.getTagById: Not yet implemented with Drift');
    return null;
  }

  Future<TagModel> createTag({
    required String name,
    String? color,
    String? icon,
  }) async {
    debugPrint('TagService.createTag: Not yet implemented with Drift');
    final tagId = DateTime.now().millisecondsSinceEpoch.toString();
    return TagModel.create(
      tagId: tagId,
      name: name,
      color: color ?? '#2196F3',
      icon: icon ?? 'label',
    );
  }

  Future<void> updateTag(TagModel tag) async {
    debugPrint('TagService.updateTag: Not yet implemented with Drift');
  }

  Future<void> deleteTag(String tagId) async {
    debugPrint('TagService.deleteTag: Not yet implemented with Drift');
  }

  Future<void> addTagToChat(String chatId, String tagId) async {
    debugPrint('TagService.addTagToChat: Not yet implemented with Drift');
  }

  Future<void> removeTagFromChat(String chatId, String tagId) async {
    debugPrint('TagService.removeTagFromChat: Not yet implemented with Drift');
  }

  Future<void> removeAllTagsFromChat(String chatId) async {
    debugPrint('TagService.removeAllTagsFromChat: Not yet implemented with Drift');
  }

  Future<void> removeTagFromAllChats(String tagId) async {
    debugPrint('TagService.removeTagFromAllChats: Not yet implemented with Drift');
  }

  Future<List<ChatModel>> getChatsByTag(String tagId) async {
    debugPrint('TagService.getChatsByTag: Not yet implemented with Drift');
    return <ChatModel>[];
  }

  Future<List<TagModel>> getChatTags(String chatId) async {
    debugPrint('TagService.getChatTags: Not yet implemented with Drift');
    return <TagModel>[];
  }

  Future<List<TagModel>> getMostUsedTags({int limit = 10}) async {
    debugPrint('TagService.getMostUsedTags: Not yet implemented with Drift');
    return <TagModel>[];
  }

  Future<List<TagModel>> searchTags(String query) async {
    debugPrint('TagService.searchTags: Not yet implemented with Drift');
    return <TagModel>[];
  }
}