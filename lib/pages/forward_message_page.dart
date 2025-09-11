import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';
import '../database/drift_service.dart';
import '../services/ui_contacts_service.dart';
import '../services/message_service.dart';

/// 📤 MESAJ İLETME SAYFASI
///
/// Bu sayfa ContactsManager sistemi kullanarak:
/// ✅ Kişi ve grup listesi
/// ✅ Çoklu seçim
/// ✅ Hızlı arama
/// ✅ Mesaj iletme
class ForwardMessagePage extends StatefulWidget {
  final MessageModel message;
  final String chatId;

  const ForwardMessagePage({
    super.key,
    required this.message,
    required this.chatId,
  });

  @override
  State<ForwardMessagePage> createState() => _ForwardMessagePageState();
}

class _ForwardMessagePageState extends State<ForwardMessagePage> {
  final TextEditingController _searchController = TextEditingController();

  List<ContactViewModel> _contacts = [];
  List<ContactViewModel> _filteredContacts = [];
  final Set<String> _selectedUids = <String>{};
  bool _isLoading = true;
  bool _isForwarding = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _filteredContacts = _contacts;
      });
    } else {
      _performSearch(query);
    }
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);

    try {
      final contacts = await UIContactsService.getContactsForForward();

      if (mounted) {
        setState(() {
          _contacts = contacts;
          _filteredContacts = contacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kişiler yüklenirken hata: $e')),
        );
      }
    }
  }

  Future<void> _performSearch(String query) async {
    try {
      final results = await UIContactsService.getContactsForForward(
        searchQuery: query,
      );

      if (mounted) {
        setState(() {
          _filteredContacts = results;
        });
      }
    } catch (e) {
      debugPrint('❌ İletme arama hatası: $e');
    }
  }

  void _toggleSelection(ContactViewModel contact) {
    if (contact.uid == null) return;

    setState(() {
      if (_selectedUids.contains(contact.uid)) {
        _selectedUids.remove(contact.uid);
      } else {
        _selectedUids.add(contact.uid!);
      }
    });
  }

  Future<void> _forwardMessage() async {
    if (_selectedUids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir kişi seçmelisiniz')),
      );
      return;
    }

    setState(() => _isForwarding = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('Kullanıcı oturumu bulunamadı');

      int forwardedCount = 0;

      for (final uid in _selectedUids) {
        try {
          // Hedef chat'i bul veya oluştur
          final targetContact = _contacts.where((c) => c.uid == uid).isNotEmpty
              ? _contacts.where((c) => c.uid == uid).first
              : null;
          if (targetContact == null) continue;

          // Mevcut chat'i kontrol et
          final existingChats = await DriftService.getAllChats();
          String? targetChatId;

          for (final chat in existingChats) {
            if (chat.isGroup == false && chat.participants.contains(uid)) {
              targetChatId = chat.chatId;
              break;
            }
          }

          // Chat yoksa oluştur
          if (targetChatId == null) {
            final newChat = ChatModel.createPrivateChat(
              otherUserId: uid,
              otherUserName: targetContact.displayName,
              otherUserPhone: targetContact.phoneNumber,
              otherUserContactName: targetContact.displayName, // Rehber ismi eklendi
              otherUserProfileImage: targetContact.profileImageUrl,
            );
            await DriftService.saveChat(newChat);
            targetChatId = newChat.chatId;
          }

          // Mesajı ilet
          await _forwardMessageToChat(targetChatId, targetContact);
          forwardedCount++;
        } catch (e) {
          debugPrint('❌ $uid için iletme hatası: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mesaj $forwardedCount kişiye iletildi'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isForwarding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İletme hatası: $e')),
        );
      }
    }
  }

  Future<void> _forwardMessageToChat(
      String chatId, ContactViewModel contact) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // İletilen mesajı oluştur
    MessageModel forwardedMessage;

    switch (widget.message.type) {
      case MessageType.text:
        forwardedMessage = MessageModel.create(
          messageId: DateTime.now().millisecondsSinceEpoch.toString(),
          chatId: chatId,
          senderId: currentUser.uid,
          content: '📤 İletilen mesaj:\n${widget.message.content}',
          type: MessageType.text,
        );
        break;

      case MessageType.image:
        forwardedMessage = MessageModel.create(
          messageId: DateTime.now().millisecondsSinceEpoch.toString(),
          chatId: chatId,
          senderId: currentUser.uid,
          content: widget.message.content.isNotEmpty
              ? '📤 İletilen: ${widget.message.content}'
              : '📤 İletilen resim',
          type: MessageType.image,
          mediaUrl: widget.message.mediaUrl,
          mediaWidth: widget.message.mediaWidth,
          mediaHeight: widget.message.mediaHeight,
          thumbnailUrl: widget.message.thumbnailUrl,
        );
        break;

      case MessageType.video:
        forwardedMessage = MessageModel.create(
          messageId: DateTime.now().millisecondsSinceEpoch.toString(),
          chatId: chatId,
          senderId: currentUser.uid,
          content: widget.message.content.isNotEmpty
              ? '📤 İletilen: ${widget.message.content}'
              : '📤 İletilen video',
          type: MessageType.video,
          mediaUrl: widget.message.mediaUrl,
          mediaWidth: widget.message.mediaWidth,
          mediaHeight: widget.message.mediaHeight,
          mediaDuration: widget.message.mediaDuration,
          thumbnailUrl: widget.message.thumbnailUrl,
        );
        break;

      case MessageType.audio:
        forwardedMessage = MessageModel.create(
          messageId: DateTime.now().millisecondsSinceEpoch.toString(),
          chatId: chatId,
          senderId: currentUser.uid,
          content: '📤 İletilen ses mesajı',
          type: MessageType.audio,
          mediaUrl: widget.message.mediaUrl,
          mediaDuration: widget.message.mediaDuration ?? 0,
        );
        break;

      case MessageType.document:
        forwardedMessage = MessageModel.create(
          messageId: DateTime.now().millisecondsSinceEpoch.toString(),
          chatId: chatId,
          senderId: currentUser.uid,
          content: '📤 İletilen dosya',
          type: MessageType.document,
          mediaUrl: widget.message.mediaUrl,
        );
        break;

      default:
        // Desteklenmeyen mesaj türü
        forwardedMessage = MessageModel.create(
          messageId: DateTime.now().millisecondsSinceEpoch.toString(),
          chatId: chatId,
          senderId: currentUser.uid,
          content: '📤 İletilen mesaj (${widget.message.type.name})',
          type: MessageType.text,
        );
    }

    // Mesajı gönder
    await MessageService.sendMessage(
      chatId: chatId,
      text: forwardedMessage.content,
      type: forwardedMessage.type.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesaj İlet'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed:
                _isForwarding || _selectedUids.isEmpty ? null : _forwardMessage,
            child: _isForwarding
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'İLET',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Mesaj önizleme
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'İletilecek mesaj:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildMessagePreview(),
              ],
            ),
          ),

          // Seçilen kişiler
          if (_selectedUids.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.people, color: Colors.teal),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedUids.length} kişi seçildi',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

          // Arama çubuğu
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Kişi ara...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),

          // Kişi listesi
          Expanded(
            child: _buildContactsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagePreview() {
    switch (widget.message.type) {
      case MessageType.text:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.teal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.message.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        );

      case MessageType.image:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.teal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.image, color: Colors.teal),
              const SizedBox(width: 8),
              const Text('Resim'),
              if (widget.message.content.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.message.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        );

      case MessageType.video:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.teal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.videocam, color: Colors.teal),
              SizedBox(width: 8),
              Text('Video'),
            ],
          ),
        );

      case MessageType.audio:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.teal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.mic, color: Colors.teal),
              SizedBox(width: 8),
              Text('Ses kaydı'),
            ],
          ),
        );

      default:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.teal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.message, color: Colors.teal),
              SizedBox(width: 8),
              Text('Mesaj'),
            ],
          ),
        );
    }
  }

  Widget _buildContactsList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Kişiler yükleniyor...'),
          ],
        ),
      );
    }

    if (_filteredContacts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.contacts, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Kişi bulunamadı'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredContacts.length,
      itemBuilder: (context, index) {
        return _buildContactTile(_filteredContacts[index]);
      },
    );
  }

  Widget _buildContactTile(ContactViewModel contact) {
    final isSelected = _selectedUids.contains(contact.uid);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isSelected ? Colors.teal : Colors.grey,
        backgroundImage: contact.profileImageUrl != null
            ? NetworkImage(contact.profileImageUrl!)
            : null,
        child: contact.profileImageUrl == null
            ? Text(
                contact.avatarText,
                style: const TextStyle(color: Colors.white),
              )
            : null,
      ),
      title: Text(contact.displayName),
      subtitle: Text(contact.phoneNumber),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.teal)
          : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
      onTap: () => _toggleSelection(contact),
      selected: isSelected,
      selectedTileColor: Colors.teal.withValues(alpha: 0.1),
    );
  }
}
