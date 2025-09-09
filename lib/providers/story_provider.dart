import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/drift_service.dart';
import '../models/story_model.dart';

class StoryProvider extends ChangeNotifier {
  List<StoryModel> _stories = [];
  bool _isLoading = false;
  String _error = '';
  StreamSubscription<List<StoryModel>>? _driftStoriesSub;

  List<StoryModel> get stories => _stories;
  bool get isLoading => _isLoading;
  String get error => _error;

  StoryProvider() {
    loadStories();
  }

  Future<void> loadStories() async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      // Load initial stories
      _stories = await DriftService.getAllActiveStories();

      // Set up stream listener if not already active
      if (_driftStoriesSub == null) {
        _driftStoriesSub = DriftService.watchAllActiveStories().listen((data) {
          _stories = data;
          notifyListeners();
        });
      }
    } catch (e) {
      _error = 'Story\'ler yüklenemedi: $e';
      debugPrint('❌ Story yükleme hatası: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createStory({
    required String type, // Using string instead of StoryType
    required String content,
    String? mediaUrl,
    String backgroundColor = '#000000',
  }) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      // Convert string type to StoryType enum
      StoryType storyType = StoryType.text;
      switch (type.toLowerCase()) {
        case 'image':
          storyType = StoryType.image;
          break;
        case 'video':
          storyType = StoryType.video;
          break;
        default:
          storyType = StoryType.text;
      }

      final storyId = await DriftService.createStory(
        type: storyType,
        content: content,
        mediaUrl: mediaUrl,
        backgroundColor: backgroundColor,
      );

      // Story başarıyla oluşturuldu
      debugPrint('✅ Story oluşturuldu: $storyId');
    } catch (e) {
      _error = 'Story oluşturulamadı: $e';
      debugPrint('❌ Story oluşturma hatası: $e');
      throw Exception('Story oluşturulamadı: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> viewStory(String storyId) async {
    try {
      await DriftService.markStoryAsViewed(storyId);
      debugPrint('✅ Story görüntülendi: $storyId');
    } catch (e) {
      debugPrint('❌ Story görüntüleme hatası: $e');
    }
  }

  Future<void> replyToStory(String storyId, String message) async {
    try {
      // For now, this is a placeholder since story replies would need message creation
      // In a full implementation, this would create a message to the story owner
      debugPrint('Story reply placeholder: $storyId -> $message');
    } catch (e) {
      debugPrint('❌ Story yanıtlama hatası: $e');
      throw Exception('Story\'e yanıt verilemedi: $e');
    }
  }

  Future<void> deleteStory(String storyId) async {
    try {
      await DriftService.deleteStory(storyId);
      debugPrint('✅ Story silindi: $storyId');
    } catch (e) {
      debugPrint('❌ Story silme hatası: $e');
      throw Exception('Story silinemedi: $e');
    }
  }

  List<StoryModel> getMyStories() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    return _stories
        .where((story) => story.userId == user.uid && story.isActive)
        .toList();
  }

  List<StoryModel> getUserStories(String userId) {
    return _stories
        .where((story) => story.userId == userId && story.isActive)
        .toList();
  }

  int getUnviewedStoryCount(String userId) {
    return _stories
        .where(
          (story) =>
              story.userId == userId && story.isActive && !story.isViewed,
        )
        .length;
  }

  bool hasUnviewedStories(String userId) {
    return getUnviewedStoryCount(userId) > 0;
  }

  StoryModel? getLatestStory(String userId) {
    final userStories = getUserStories(userId);
    if (userStories.isEmpty) return null;

    userStories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return userStories.first;
  }

  @override
  void dispose() {
    _driftStoriesSub?.cancel();
    super.dispose();
  }
}
