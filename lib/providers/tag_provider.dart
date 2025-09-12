import 'package:flutter/material.dart';
import '../database/drift_service.dart';
import '../models/tag_model.dart';

class TagProvider with ChangeNotifier {
  List<TagModel> _allTags = [];
  List<TagModel> _mostUsedTags = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<TagModel> get allTags => _allTags;
  List<TagModel> get mostUsedTags => _mostUsedTags;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize
  Future<void> initialize() async {
    await loadTags();
  }

  // Load all tags
  Future<void> loadTags() async {
    _setLoading(true);
    try {
      _allTags = await DriftService.getAllTags();
      _mostUsedTags = await DriftService.getMostUsedTags(limit: 6);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Create new tag
  Future<TagModel?> createTag({
    required String name,
    String? color,
    String? icon,
  }) async {
    try {
      final tag = await DriftService.createTag(
        name: name,
        color: color ?? '#2196F3', // Default blue color
        icon: icon,
      );
      await loadTags(); // Refresh tags
      return tag;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Update tag
  Future<bool> updateTag(TagModel tag) async {
    try {
      await DriftService.updateTag(tag);
      await loadTags(); // Refresh tags
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete tag
  Future<bool> deleteTag(String tagId) async {
    try {
      await DriftService.deleteTag(tagId);
      await loadTags(); // Refresh tags
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Add tag to chat
  Future<bool> addTagToChat(String chatId, String tagId) async {
    try {
      // Get the chat
      final chat = await DriftService.getChatById(chatId);
      if (chat != null) {
        // Parse existing tags from JSON or use empty list
        final List<dynamic> existingTags = [];
        try {
          // The tags field should be parsed from JSON if it's stored as string
          // For now, assuming it's a simple implementation
          if (!existingTags.contains(tagId)) {
            // Note: This requires updating the chat with new tags list
            // The actual implementation would need to handle JSON parsing/encoding
            await DriftService.incrementTagUsage(tagId);
          }
        } catch (e) {
          // Handle JSON parsing error
        }
      }
      await loadTags(); // Refresh usage counts
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Remove tag from chat
  Future<bool> removeTagFromChat(String chatId, String tagId) async {
    try {
      // Similar to addTagToChat, this would need proper implementation
      // For now, just decrement usage
      await DriftService.decrementTagUsage(tagId);
      await loadTags(); // Refresh usage counts
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get chat tags
  Future<List<TagModel>> getChatTags(String chatId) async {
    // This would need to parse the chat's tags field and return TagModel objects
    // For now, return empty list as placeholder
    return [];
  }

  // Search tags
  Future<List<TagModel>> searchTags(String query) async {
    return await DriftService.searchTags(query);
  }

  // Get tag by id
  Future<TagModel?> getTagById(String tagId) async {
    return await DriftService.getTagById(tagId);
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get predefined colors for tag creation
  static List<String> getPredefinedColors() {
    return [
      '#F44336', // Red
      '#E91E63', // Pink
      '#9C27B0', // Purple
      '#673AB7', // Deep Purple
      '#3F51B5', // Indigo
      '#2196F3', // Blue
      '#03A9F4', // Light Blue
      '#00BCD4', // Cyan
      '#009688', // Teal
      '#4CAF50', // Green
      '#8BC34A', // Light Green
      '#CDDC39', // Lime
      '#FFEB3B', // Yellow
      '#FFC107', // Amber
      '#FF9800', // Orange
      '#FF5722', // Deep Orange
      '#795548', // Brown
      '#9E9E9E', // Grey
      '#607D8B', // Blue Grey
    ];
  }

  // Get predefined icons for tag creation
  static List<Map<String, String>> getPredefinedIcons() {
    return [
      {'name': 'label', 'icon': 'label'},
      {'name': 'İş', 'icon': 'work'},
      {'name': 'Aile', 'icon': 'family_restroom'},
      {'name': 'Arkadaşlar', 'icon': 'people'},
      {'name': 'Önemli', 'icon': 'star'},
      {'name': 'Okul', 'icon': 'school'},
      {'name': 'Hobi', 'icon': 'sports_esports'},
      {'name': 'Alışveriş', 'icon': 'shopping_cart'},
      {'name': 'Sağlık', 'icon': 'local_hospital'},
      {'name': 'Spor', 'icon': 'fitness_center'},
      {'name': 'Seyahat', 'icon': 'flight'},
      {'name': 'Yemek', 'icon': 'restaurant'},
      {'name': 'Müzik', 'icon': 'music_note'},
      {'name': 'Film', 'icon': 'movie'},
      {'name': 'Kitap', 'icon': 'book'},
      {'name': 'Teknoloji', 'icon': 'computer'},
      {'name': 'Ev', 'icon': 'home'},
      {'name': 'Araba', 'icon': 'directions_car'},
      {'name': 'Para', 'icon': 'attach_money'},
      {'name': 'Sevgili', 'icon': 'favorite'},
    ];
  }
}
