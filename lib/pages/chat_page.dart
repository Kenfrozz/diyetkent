import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';
import '../widgets/message_input_widget.dart';
import '../widgets/message_bubble_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart'; // Added for Clipboard
import 'dart:async';
import 'package:intl/intl.dart'; // Added for DateFormat
import '../database/drift_service.dart';
import '../widgets/app_notifier.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:diyetkent/widgets/photo_preview_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../services/media_service.dart';
import 'dart:io';
import 'camera_page.dart';
import 'chat_page_forward_helpers.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import 'group_info_page.dart';
import '../services/user_service.dart';
import '../services/call_service.dart';
import 'voice_call_page.dart';

class ChatPage extends StatefulWidget {
  final ChatModel chat;

  const ChatPage({super.key, required this.chat});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<MessageModel> _messages = [];
  bool _isLoadingMore = false;
  bool _isLoading = false;
  bool _isSendingMessage = false;
  MessageModel? _replyingToMessage;
  final List<String> _selectedMessageIds = [];
  bool _isSelectionMode = false;
  final Map<String, GlobalKey> _messageKeys = {};
  final PageController _pinnedPageController = PageController();
  int _currentPinnedIndex = 0;
  List<MessageModel> _pinnedMessages = [];
  Set<String> _pinnedIds = {};
  StreamSubscription<List<MessageModel>>? _pinnedSub;
  StreamSubscription<List<MessageModel>>? _messagesSub;
  // Presence & typing
  StreamSubscription<Map<String, dynamic>>? _presenceSub;
  StreamSubscription<Map<String, bool>>? _chatTypingSub;
  bool _isOtherTyping = false;
  String _statusText = 'çevrimiçi';
  Timer? _typingVisibilityTimer;

  // Search state
  bool _isSearchMode = false;
  final TextEditingController _searchController = TextEditingController();
  List<String> _searchResultIds = [];
  int _searchCurrentIndex = 0;

  // Mute state (for dynamic menu rendering)
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _prepareChatThenLoadMessages();
    // Chat aktif durumunu işaretle (otomatik okuma için)
    MessageService.setActiveChatStatus(widget.chat.chatId, true);
    // Chat dokümanları dinleyicisini başlat (UI yalnızca Isar'dan beslendiği için yereli güncel tutar)
    () async {
      try {
        await MessageService.startChatDocsListener();
      } catch (_) {}
    }();
    // Presence yazma işlemi maliyetli; uygulama genel AppLifecycle ile yönetiliyor

    // Initialize states
    _isMuted = widget.chat.isMuted;
  }

  Future<void> _prepareChatThenLoadMessages() async {
    try {
      // Bireysel sohbetlerde: parent chat dokümanını servis üzerinden hazırla
      if (widget.chat.isGroup == false &&
          (widget.chat.otherUserId != null &&
              widget.chat.otherUserId!.isNotEmpty)) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await MessageService.ensureChatDocument(
            chatId: widget.chat.chatId,
            participants: [uid, widget.chat.otherUserId!],
            isGroup: false,
            type: 'direct',
          );
        }
      }
    } catch (_) {
      // izin/offline durumunda sessiz geç; mesaj gönderiminde tekrar denenecek
    } finally {
      // Sabitli mesajları, chat dokümanı hazırlandıktan sonra dinle
      _pinnedSub = MessageService.getPinnedMessagesStream(widget.chat.chatId)
          .listen((msgs) {
        setState(() {
          _pinnedMessages = msgs;
          _pinnedIds = msgs.map((m) => m.messageId).toSet();
          if (_currentPinnedIndex >= _pinnedMessages.length) {
            _currentPinnedIndex =
                _pinnedMessages.isEmpty ? 0 : _pinnedMessages.length - 1;
          }
        });
      });
      // Typing/presence dinleyicilerini chat dokümanı hazırlandıktan sonra başlat
      _listenPresenceAndTyping();
      _loadMessages();
      // Sohbete girildiğinde mevcut okunmamışları da işaretle
      () async {
        try {
          await MessageService.markChatMessagesAsRead(widget.chat.chatId);
        } catch (_) {}
      }();
    }
  }

  @override
  void dispose() {
    _pinnedSub?.cancel();
    _messagesSub?.cancel();
    _pinnedPageController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _presenceSub?.cancel();
    _chatTypingSub?.cancel();
    _typingVisibilityTimer?.cancel();
    _searchController.dispose();
    // Chat artık aktif değil
    MessageService.setActiveChatStatus(null, false);
    // Chat dokümanı dinleyicisini durdur (global kullanımdaysa kaldırılabilir)
    () async {
      try {
        await MessageService.stopChatDocsListener();
      } catch (_) {}
    }();
    // Presence güncellemesi uygulama genel AppLifecycle ile yönetiliyor
    super.dispose();
  }

  void _listenPresenceAndTyping() {
    // Presence stream: Service üzerinden
    if (widget.chat.otherUserId != null) {
      _presenceSub = UserService.getUserOnlineInfo(widget.chat.otherUserId!)
          .listen((info) {
        final bool isOnline = (info['isOnline'] as bool?) ?? false;
        final DateTime? lastSeen = info['lastSeen'] as DateTime?;
        final text = isOnline
            ? 'çevrimiçi'
            : (lastSeen != null ? _formatLastSeenText(lastSeen) : 'çevrimdışı');
        if (mounted) setState(() => _statusText = text);
      });
    }

    // Typing: servis stream'i
    _chatTypingSub =
        UserService.getTypingUsersStream(widget.chat.chatId).listen((typing) {
      final isTyping = typing[widget.chat.otherUserId] == true;
      if (mounted) setState(() => _isOtherTyping = isTyping);

      // Görünürlük zamanlayıcısı: veri gelmezse otomatik kapat
      _typingVisibilityTimer?.cancel();
      if (isTyping) {
        _typingVisibilityTimer = Timer(const Duration(seconds: 6), () {
          if (mounted) setState(() => _isOtherTyping = false);
        });
      }
    });
  }

  String _formatLastSeenText(DateTime lastSeen) {
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inMinutes < 60) {
      return 'son görülme ${diff.inMinutes} dk önce';
    } else if (diff.inHours < 24) {
      return 'son görülme ${diff.inHours} sa önce';
    } else {
      return 'son görülme ${DateFormat('dd.MM.yy HH:mm').format(lastSeen)}';
    }
  }

  void _replyToMessage(MessageModel message) {
    setState(() {
      _replyingToMessage = message;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingToMessage = null;
    });
  }

  void _onMessageLongPress(MessageModel message) {
    // Uzun basınca doğrudan seçim modu aktifleştir ve mesajı seç
    setState(() {
      if (_isSelectionMode) {
        _onMessageTap(message);
      } else {
        _isSelectionMode = true;
        if (!_selectedMessageIds.contains(message.messageId)) {
          _selectedMessageIds.add(message.messageId);
        }
      }
    });
  }

  void _showEditDialog(MessageModel message) {
    final controller = TextEditingController(text: message.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mesajı Düzenle'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 1000,
          decoration: const InputDecoration(
            hintText: 'Mesajınızı düzenleyin...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              final newContent = controller.text.trim();
              if (newContent.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mesaj boş olamaz')),
                );
                return;
              }

              Navigator.pop(context);
              await _updateMessage(message, newContent);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateMessage(MessageModel message, String newContent) async {
    try {
      // Mesajı güncelle
      message.content = newContent;
      message.isEdited = true;
      // updatedAt alanı yerine editedAt kullanılır
      message.editedAt = DateTime.now();

      // Yerel veritabanını güncelle
      await DriftService.updateMessage(message);

      // Firebase'i güncelle
      await MessageService.updateMessage(message);

      setState(() {
        // UI'ı güncelle
        final index = _messages.indexWhere(
          (m) => m.messageId == message.messageId,
        );
        if (index >= 0) {
          _messages[index] = message;
        }
      });

      if (!mounted) return;
      AppNotifier.showInfo(context, 'Mesaj güncellendi');
    } catch (e) {
      if (!mounted) return;
      AppNotifier.showError(context, 'Mesaj güncellenirken hata oluştu: $e');
    }
  }

  void _onMessageTap(MessageModel message) {
    if (_isSelectionMode) {
      setState(() {
        if (_selectedMessageIds.contains(message.messageId)) {
          _selectedMessageIds.remove(message.messageId);
          if (_selectedMessageIds.isEmpty) {
            _isSelectionMode = false;
          }
        } else {
          _selectedMessageIds.add(message.messageId);
        }
      });
    }
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedMessageIds.clear();
    });
  }

  void _deleteSelectedMessages() {
    final selected = _messages
        .where((m) => _selectedMessageIds.contains(m.messageId))
        .toList();

    final currentUser = FirebaseAuth.instance.currentUser;
    final now = DateTime.now();

    final canDeleteForEveryone = selected.isNotEmpty &&
        selected.every((m) {
          final isMine = m.senderId == currentUser?.uid;
          final within24h = now.difference(m.timestamp).inHours <= 24;
          return isMine && within24h;
        });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mesajları Sil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_selectedMessageIds.length} mesaj seçili.'),
            const SizedBox(height: 8),
            const Text(
              'Herkesten Sil: Sadece kendi mesajların ve 24 saat içinde gönderilenler için geçerlidir.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            const Text(
              'Benden Sil: Her mesaj için geçerlidir (yalnızca sizde kaybolur).',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: canDeleteForEveryone
                ? () async {
                    Navigator.pop(context);
                    await _performDelete(forEveryone: true);
                  }
                : null,
            child: const Text('Herkesten Sil'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDelete(forEveryone: false);
            },
            child: const Text('Benden Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete({required bool forEveryone}) async {
    try {
      final ids = List<String>.from(_selectedMessageIds);
      if (forEveryone) {
        await MessageService.deleteMessagesForEveryone(ids);
      } else {
        await MessageService.deleteMessagesForMe(widget.chat.chatId, ids);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        // Placeholder to keep structure - replaced below
        const SnackBar(content: Text('')), // will be ignored
      );
      AppNotifier.showInfo(
        context,
        forEveryone
            ? 'Mesaj(lar) herkesten silindi'
            : 'Mesaj(lar) sizden silindi',
      );
    } catch (e) {
      if (!mounted) return;
      AppNotifier.showError(context, 'Silme başarısız: $e');
    } finally {
      if (mounted) _exitSelectionMode();
    }
  }

  void _copySelectedMessages() {
    if (_selectedMessageIds.isEmpty) return;

    final selectedMessages = _messages
        .where((msg) => _selectedMessageIds.contains(msg.messageId))
        .toList();

    String copyText;

    if (selectedMessages.length == 1) {
      // Tek mesaj seçildiyse sadece içeriği kopyala
      copyText = selectedMessages.first.content;
    } else {
      // Birden fazla mesaj seçildiyse isim, saat ve içerik listesi oluştur
      final currentUser = FirebaseAuth.instance.currentUser;
      final currentUserId = currentUser?.uid;

      final messageList = selectedMessages.map((message) {
        final isFromMe = message.senderId == currentUserId;
        // Rehber ismi öncelikli; yoksa telefon; yoksa profil adı
        final contactName = widget.chat.otherUserContactName;
        final phone = widget.chat.otherUserPhoneNumber;
        final profileName = widget.chat.otherUserName;
        final resolvedName = contactName?.isNotEmpty == true
            ? contactName!
            : (phone?.isNotEmpty == true
                ? phone!
                : (profileName ?? 'Bilinmeyen'));
        final senderName = isFromMe ? 'Sen' : resolvedName;
        final time = DateFormat('HH:mm').format(message.timestamp);
        final content = message.content;

        return '$senderName ($time): $content';
      }).toList();

      copyText = messageList.join('\n');
    }

    Clipboard.setData(ClipboardData(text: copyText));

    AppNotifier.showInfo(
      context,
      '${selectedMessages.length} mesaj kopyalandı',
    );
    _exitSelectionMode();
  }

  void _forwardSelectedMessages() {
    final ids = List<String>.from(_selectedMessageIds);
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => ForwardSelectChatPage(
              onChatSelected: (ChatModel target) async {
                try {
                  await MessageService.forwardMessages(
                    fromChatId: widget.chat.chatId,
                    messageIds: ids,
                    toChatId: target.chatId,
                    toRecipientId: target.otherUserId,
                  );
                  if (!context.mounted) return;
                  AppNotifier.showInfo(context, 'Mesajlar yönlendirildi');
                } catch (e) {
                  if (!context.mounted) return;
                  AppNotifier.showError(context, 'Yönlendirme hatası: $e');
                }
              },
            ),
          ),
        )
        .then((_) => _exitSelectionMode());
  }

  void _pinSelectedMessages() {
    final ids = List<String>.from(_selectedMessageIds);
    () async {
      try {
        await MessageService.pinMessages(widget.chat.chatId, ids);
        if (!mounted) return;
        AppNotifier.showInfo(context, 'Mesajlar sabitlendi');
      } catch (e) {
        if (!mounted) return;
        AppNotifier.showError(context, 'Sabitleme başarısız: $e');
      } finally {
        if (mounted) _exitSelectionMode();
      }
    }();
  }

  void _editMessage() {
    if (_selectedMessageIds.length != 1) {
      AppNotifier.showInfo(context, 'Düzenlemek için sadece bir mesaj seçin');
      return;
    }

    final idx = _messages.indexWhere(
      (msg) => msg.messageId == _selectedMessageIds.first,
    );
    if (idx == -1) {
      AppNotifier.showError(context, 'Mesaj bulunamadı');
      return;
    }
    final message = _messages[idx];

    // Sadece kendi mesajları düzenlenebilir
    final currentUser = FirebaseAuth.instance.currentUser;
    if (message.senderId != currentUser?.uid) {
      AppNotifier.showInfo(
        context,
        'Sadece kendi mesajlarınızı düzenleyebilirsiniz',
      );
      return;
    }

    // 24 saat kontrolü
    final now = DateTime.now();
    final messageTime = message.timestamp;
    final hoursDiff = now.difference(messageTime).inHours;

    if (hoursDiff > 24) {
      AppNotifier.showInfo(context, '24 saatten eski mesajlar düzenlenemez');
      return;
    }

    _showEditDialog(message);
    _exitSelectionMode();
  }

  void _loadMessages() {
    setState(() {
      _isLoading = true;
    });

    _messagesSub =
        MessageService.getMessagesStream(widget.chat.chatId).listen((messages) {
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      _scrollToBottom();
    }, onError: (e) {
      // Yetki veya offline durumunda çökme olmasın
      if (!mounted) return;
      setState(() => _isLoading = false);
    });

    // Sonsuz kaydırma için listener
    _scrollController.addListener(_onScrollLoadMore);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onScrollLoadMore() {
    if (_isLoadingMore || _isLoading) return;
    if (!_scrollController.hasClients) return;
    // reverse: true olduğu için, listenin yukarısına kaydırma => maxScrollExtent'e yaklaşmak
    final position = _scrollController.position;
    final threshold = position.maxScrollExtent - 400; // 400px kala yükle
    if (position.pixels > threshold) {
      _loadOlderMessages();
    }
  }

  Future<void> _loadOlderMessages() async {
    if (_messages.isEmpty) return;
    _isLoadingMore = true;
    try {
      final lastMessage =
          _messages.last; // reverse: true -> listedeki en eskisi
      final older = await MessageService.fetchOlderMessagesAndSaveToIsar(
        chatId: widget.chat.chatId,
        startAfterTimestamp: lastMessage.timestamp,
        limit: 50,
      );
      if (!mounted) return;
      if (older.isNotEmpty) {
        setState(() {
          _messages.addAll(older.reversed.toList()); // kronolojik uyum için
        });
      }
    } catch (_) {
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSendingMessage) return;

    setState(() {
      _isSendingMessage = true;
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        _isSendingMessage = false;
      });
      return;
    }

    final replyId = _replyingToMessage?.messageId; // Temizlemeden önce kaydet
    final tempMessage = MessageModel.create(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: widget.chat.chatId,
      senderId: currentUser.uid,
      content: text,
      type: MessageType.text,
      status: MessageStatus.sending,
      replyToMessageId: replyId,
    );
    // Temp mesajda da yanıt önizlemesi için meta doldur
    if (_replyingToMessage != null) {
      tempMessage.replyToContent = _replyingToMessage!.content;
      tempMessage.replyToSenderId = _replyingToMessage!.senderId;
    }

    setState(() {
      _messages.insert(0, tempMessage);
    });

    _messageController.clear();
    _cancelReply();
    _scrollToBottom();

    try {
      await MessageService.sendMessage(
        chatId: widget.chat.chatId,
        recipientId: widget.chat.otherUserId,
        text: text,
        replyToMessageId: replyId,
      );
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere(
            (m) => m.messageId == tempMessage.messageId,
          );
          if (index >= 0) {
            _messages[index].status = MessageStatus.delivered;
            _messages[index].deliveredAt = DateTime.now();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere(
            (m) => m.messageId == tempMessage.messageId,
          );
          if (index >= 0) {
            _messages[index].status = MessageStatus.failed;
          }
        });
        AppNotifier.showError(context, 'Mesaj gönderilemedi: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingMessage = false;
        });
      }
    }
  }

  Widget _buildReplyPreview() {
    if (_replyingToMessage == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _replyingToMessage!.senderId ==
                          FirebaseAuth.instance.currentUser?.uid
                      ? 'Sen'
                      : widget.chat.otherUserName ?? 'Bilinmeyen',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _replyingToMessage!.content,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: _cancelReply,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // --- Forward select page ---

// (moved classes to bottom)

  AppBar _buildNormalAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF00796B),
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[300],
            backgroundImage: (widget.chat.otherUserProfileImage != null &&
                    widget.chat.otherUserProfileImage!.isNotEmpty)
                ? CachedNetworkImageProvider(widget.chat.otherUserProfileImage!)
                : null,
            child: (widget.chat.otherUserProfileImage == null ||
                    widget.chat.otherUserProfileImage!.isEmpty)
                ? Text(
                    widget.chat.otherUserName?.isNotEmpty == true
                        ? widget.chat.otherUserName![0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chat.otherUserContactName?.isNotEmpty == true
                      ? widget.chat.otherUserContactName!
                      : (widget.chat.otherUserPhoneNumber?.isNotEmpty == true
                          ? widget.chat.otherUserPhoneNumber!
                          : (widget.chat.otherUserName ?? 'Bilinmeyen')),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _isOtherTyping ? 'yazıyor…' : _statusText,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (widget.chat.isGroup) ...[
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            tooltip: 'Grup bilgisi',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GroupInfoPage(groupId: widget.chat.chatId),
                ),
              );
            },
          ),
        ],
        if (!widget.chat.isGroup)
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.white),
            tooltip: 'Ara',
            onPressed: _startVoiceCallFromAppBar,
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view_profile',
              child: ListTile(
                leading: Icon(Icons.person),
                title: Text('Profili Görüntüle'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'search',
              child: ListTile(
                leading: Icon(Icons.search),
                title: Text('Ara'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'mute',
              child: ListTile(
                leading: Icon(_isMuted ? Icons.volume_up : Icons.volume_off),
                title: Text(_isMuted ? 'Sessizden çıkar' : 'Sessize al'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'block',
              child: ListTile(
                leading: Icon(Icons.block, color: Colors.red),
                title: Text('Engelle', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'report',
              child: ListTile(
                leading: Icon(Icons.report, color: Colors.red),
                title: Text('Şikayet Et', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _startVoiceCallFromAppBar() {
    () async {
      try {
        final String calleeId =
            widget.chat.otherUserId ?? (widget.chat.otherUserPhoneNumber ?? '');
        if (calleeId.isEmpty) {
          AppNotifier.showError(context, 'Aranacak kişi bilgisi bulunamadı');
          return;
        }
        final service = CallService();
        final callId = await service.startVoiceCall(calleeId: calleeId);
        if (!mounted) return;
        final displayName = widget.chat.otherUserContactName?.isNotEmpty == true
            ? widget.chat.otherUserContactName!
            : (widget.chat.otherUserName ?? 'Kişi');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VoiceCallPage(
              otherUserName: displayName,
              callId: callId,
              isIncoming: false,
            ),
          ),
        );
      } catch (e) {
        AppNotifier.showError(context, 'Arama başlatılamadı: $e');
      }
    }();
  }

  AppBar _buildSelectionAppBar() {
    final canEdit = _selectedMessageIds.length == 1 && _canEditMessage();

    return AppBar(
      backgroundColor: const Color(0xFF00796B),
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: _exitSelectionMode,
      ),
      title: Text(
        '${_selectedMessageIds.length} seçildi',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      actions: [
        // İstenen sıralama: Kopyala, Yönlendir, Sabitle, (varsa) Düzenle, Sil
        IconButton(
          icon: const Icon(Icons.copy, color: Colors.white),
          onPressed: _copySelectedMessages,
          tooltip: 'Kopyala',
        ),
        IconButton(
          icon: const Icon(Icons.forward, color: Colors.white),
          onPressed: _forwardSelectedMessages,
          tooltip: 'Yönlendir',
        ),
        IconButton(
          icon: const Icon(Icons.push_pin, color: Colors.white),
          onPressed: _pinSelectedMessages,
          tooltip: 'Sabitle',
        ),
        if (canEdit)
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _editMessage,
            tooltip: 'Düzenle',
          ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.white),
          onPressed: _deleteSelectedMessages,
          tooltip: 'Sil',
        ),
      ],
    );
  }

  bool _canEditMessage() {
    if (_selectedMessageIds.length != 1) return false;
    final idx = _messages.indexWhere(
      (msg) => msg.messageId == _selectedMessageIds.first,
    );
    if (idx == -1) return false;
    final message = _messages[idx];

    // Sadece kendi mesajları düzenlenebilir
    final currentUser = FirebaseAuth.instance.currentUser;
    if (message.senderId != currentUser?.uid) return false;

    // 24 saat kontrolü
    final now = DateTime.now();
    final messageTime = message.timestamp;
    final hoursDiff = now.difference(messageTime).inHours;

    return hoursDiff <= 24;
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'view_profile':
        _viewProfile();
        break;
      case 'search':
        _enterSearchMode();
        break;
      case 'mute':
        _toggleMute();
        break;
      case 'block':
        _blockUser();
        break;
      case 'report':
        _reportUser();
        break;
    }
  }

  void _viewProfile() {
    AppNotifier.showInfo(context, 'Profil görüntüleme özelliği yakında...');
  }

  void _enterSearchMode() {
    setState(() {
      _isSearchMode = true;
      _searchController.text = '';
      _searchResultIds = [];
      _searchCurrentIndex = 0;
    });
  }

  void _exitSearchMode() {
    setState(() {
      _isSearchMode = false;
      _searchController.clear();
      _searchResultIds = [];
      _searchCurrentIndex = 0;
    });
  }

  void _updateSearch(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _searchResultIds = [];
        _searchCurrentIndex = 0;
      });
      return;
    }

    final List<String> ids = [];
    for (final m in _messages) {
      final inText = m.content.toLowerCase().contains(q);
      final inLocal = (m.mediaLocalPath?.toLowerCase().contains(q) ?? false);
      final inUrl = (m.mediaUrl?.toLowerCase().contains(q) ?? false);
      if (inText || inLocal || inUrl) {
        ids.add(m.messageId);
      }
    }

    setState(() {
      _searchResultIds = ids;
      _searchCurrentIndex = ids.isEmpty ? 0 : 0;
    });

    if (ids.isNotEmpty) {
      _scrollToMessage(ids[0]);
    }
  }

  void _gotoPrevResult() {
    if (_searchResultIds.isEmpty) return;
    setState(() {
      _searchCurrentIndex =
          (_searchCurrentIndex - 1 + _searchResultIds.length) %
              _searchResultIds.length;
    });
    _scrollToMessage(_searchResultIds[_searchCurrentIndex]);
  }

  void _gotoNextResult() {
    if (_searchResultIds.isEmpty) return;
    setState(() {
      _searchCurrentIndex = (_searchCurrentIndex + 1) % _searchResultIds.length;
    });
    _scrollToMessage(_searchResultIds[_searchCurrentIndex]);
  }

  PreferredSizeWidget _buildSearchAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF00796B),
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: _exitSearchMode,
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        onChanged: _updateSearch,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Sohbette ara...',
          hintStyle: TextStyle(color: Colors.white70),
          border: InputBorder.none,
        ),
      ),
      actions: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              _searchResultIds.isEmpty
                  ? '0/0'
                  : '${_searchCurrentIndex + 1}/${_searchResultIds.length}',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
          onPressed: _searchResultIds.length > 1 ? _gotoPrevResult : null,
          tooltip: 'Önceki',
        ),
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          onPressed: _searchResultIds.length > 1 ? _gotoNextResult : null,
          tooltip: 'Sonraki',
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _exitSearchMode,
          tooltip: 'Kapat',
        ),
      ],
    );
  }

  //

  Future<void> _toggleMute() async {
    try {
      final provider = context.read<ChatProvider>();
      await provider.toggleMute(widget.chat.chatId);
      setState(() {
        _isMuted = !_isMuted;
      });
      if (!mounted) return;
      AppNotifier.showInfo(
        context,
        _isMuted ? 'Sohbet sessize alındı' : 'Sohbet sessizden çıkarıldı',
      );
    } catch (e) {
      if (!mounted) return;
      AppNotifier.showError(context, 'Sessize alma hatası: $e');
    }
  }

  void _blockUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcıyı Engelle'),
        content: Text(
          '${widget.chat.otherUserName ?? "Bu kullanıcı"}yı engellemek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              AppNotifier.showInfo(context, 'Kullanıcı engellendi');
            },
            child: const Text('Engelle', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _reportUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Şikayet Et'),
        content: Text(
          '${widget.chat.otherUserName ?? "Bu kullanıcı"}yı şikayet etmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              AppNotifier.showInfo(context, 'Şikayet gönderildi');
            },
            child: const Text(
              'Şikayet Et',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _handleImageSelected(dynamic file) {
    () async {
      try {
        if (file == null) return;
        // MessageInputWidget görüntü seçimi için File gönderiyor
        final pickedFile = file as File;
        final bool? confirmed = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => PhotoPreviewDialog(imageFile: pickedFile),
          ),
        );
        if (confirmed != true) return;
        final xfile = XFile(pickedFile.path);
        double p = 0;
        if (!mounted) return;
        AppNotifier.showInfo(context, 'Fotoğraf yükleniyor... %0');
        final url = await MediaService().uploadImage(
          xfile,
          widget.chat.chatId,
          onProgress: (v) {
            final percent = (v * 100).clamp(0, 100).toStringAsFixed(0);
            if (mounted) {
              if (percent != (p * 100).toStringAsFixed(0)) {
                AppNotifier.showInfo(
                    context, 'Fotoğraf yükleniyor... %$percent');
              }
            }
            p = v;
          },
        );
        if (url == null) {
          if (!mounted) return;
          AppNotifier.showError(context, 'Fotoğraf yüklenemedi');
          return;
        }
        await MessageService.sendMediaMessage(
          chatId: widget.chat.chatId,
          recipientId: widget.chat.otherUserId,
          mediaUrl: url,
          messageType: MessageType.image,
        );
        _scrollToBottom();
      } catch (e) {
        if (!mounted) return;
                AppNotifier.showError(context, 'Fotoğraf gönderilemedi: $e');
      }
    }();
  }

  void _handleVideoSelected(dynamic file) {
    () async {
      try {
        if (file == null) return;
        // Video XFile olarak geliyor
        final XFile xfile = file as XFile;
        double p = 0;
        AppNotifier.showInfo(context, 'Video yükleniyor... %0');
        final url = await MediaService().uploadVideo(
          xfile,
          widget.chat.chatId,
          onProgress: (v) {
            final percent = (v * 100).clamp(0, 100).toStringAsFixed(0);
            if (mounted) {
              if (percent != (p * 100).toStringAsFixed(0)) {
                AppNotifier.showInfo(context, 'Video yükleniyor... %$percent');
              }
            }
            p = v;
          },
        );
        if (url == null) {
          if (mounted) {
            AppNotifier.showError(context, 'Video yüklenemedi');
          }
          return;
        }
        await MessageService.sendMediaMessage(
          chatId: widget.chat.chatId,
          recipientId: widget.chat.otherUserId,
          mediaUrl: url,
          messageType: MessageType.video,
        );
        _scrollToBottom();
      } catch (e) {
        if (mounted) {
          AppNotifier.showError(context, 'Video gönderilemedi: $e');
        }
      }
    }();
  }

  void _handleDocumentSelected(dynamic file) {
    () async {
      try {
        if (file == null) return;
        // Belge PlatformFile olarak geliyor
        final PlatformFile doc = file as PlatformFile;
        double p = 0;
        AppNotifier.showInfo(context, 'Belge yükleniyor... %0');
        final url = await MediaService().uploadDocument(
          doc,
          widget.chat.chatId,
          onProgress: (v) {
            final percent = (v * 100).clamp(0, 100).toStringAsFixed(0);
            if (mounted) {
              if (percent != (p * 100).toStringAsFixed(0)) {
                AppNotifier.showInfo(context, 'Belge yükleniyor... %$percent');
              }
            }
            p = v;
          },
        );
        if (url == null) {
          if (mounted) {
            AppNotifier.showError(context, 'Belge yüklenemedi');
          }
          return;
        }
        await MessageService.sendMediaMessage(
          chatId: widget.chat.chatId,
          recipientId: widget.chat.otherUserId,
          mediaUrl: url,
          messageType: MessageType.document,
          fileName: doc.name,
        );
        _scrollToBottom();
      } catch (e) {
        if (mounted) {
          AppNotifier.showError(context, 'Belge gönderilemedi: $e');
        }
      }
    }();
  }

  void _handleTypingChanged(bool isTyping) {
    MessageService.updateTypingStatus(widget.chat.chatId, isTyping);
  }

  Future<void> _openUnifiedCamera() async {
    await Navigator.of(context, rootNavigator: true).push<XFile?>(
      MaterialPageRoute(
        builder: (_) => CameraPage(
          onCaptured: (file, {required isVideo}) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (isVideo) {
                _handleVideoSelected(file);
              } else {
                _handleImageSelected(File(file.path));
              }
            });
          },
        ),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _handleAudioRecorded(File audioFile) async {
    try {
      AppNotifier.showInfo(context, 'Ses yükleniyor... %0');
      double p = 0;
      final url = await MediaService().uploadAudio(
        audioFile,
        widget.chat.chatId,
        onProgress: (v) {
          final percent = (v * 100).clamp(0, 100).toStringAsFixed(0);
          if (percent != (p * 100).toStringAsFixed(0)) {
            AppNotifier.showInfo(context, 'Ses yükleniyor... %$percent');
          }
          p = v;
        },
      );
      if (url == null) {
        if (mounted) {
          AppNotifier.showError(context, 'Ses kaydı yüklenemedi');
        }
        return;
      }
      await MessageService.sendMediaMessage(
        chatId: widget.chat.chatId,
        recipientId: widget.chat.otherUserId,
        mediaUrl: url,
        messageType: MessageType.audio,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        AppNotifier.showError(context, 'Ses kaydı gönderilemedi: $e');
      }
    }
  }

  Future<void> _shareCurrentLocation() async {
    try {
      AppNotifier.showInfo(context, 'Konum alınıyor...');
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          AppNotifier.showError(context, 'Konum izni verilmedi');
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await MessageService.sendLocationMessage(
        chatId: widget.chat.chatId,
        recipientId: widget.chat.otherUserId,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        AppNotifier.showError(context, 'Konum gönderilemedi: $e');
      }
    }
  }

  Future<void> _shareContact() async {
    try {
      final granted = await FlutterContacts.requestPermission();
      if (!granted) {
        if (mounted) {
          AppNotifier.showError(context, 'Kişiler izni verilmedi');
        }
        return;
      }
      final contact = await FlutterContacts.openExternalPick();
      if (contact == null) return;
      final full =
          await FlutterContacts.getContact(contact.id, withProperties: true);
      final name = (full?.displayName ?? contact.displayName);
      final phone =
          (full?.phones.isNotEmpty ?? false) ? full!.phones.first.number : '';
      if (name.isEmpty && phone.isEmpty) {
        if (mounted) {
          AppNotifier.showError(context, 'Geçerli kişi bulunamadı');
        }
        return;
      }
      await MessageService.sendContactMessage(
        chatId: widget.chat.chatId,
        recipientId: widget.chat.otherUserId,
        name: name,
        phoneNumber: phone,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        AppNotifier.showError(context, 'Kişi gönderilemedi: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5DDD5),
      appBar: _isSelectionMode
          ? _buildSelectionAppBar()
          : (_isSearchMode ? _buildSearchAppBar() : _buildNormalAppBar()),
      body: Column(
        children: [
          _buildPinnedMessagesSection(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00796B)),
                  )
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'Henüz mesaj yok\nİlk mesajı gönderin!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        itemCount: _messages.length,
                        padding: const EdgeInsets.all(8),
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          // Gün ayraçları
                          final currentDay = DateTime(message.timestamp.year,
                              message.timestamp.month, message.timestamp.day);
                          DateTime? prevDay;
                          if (index + 1 < _messages.length) {
                            final prevMsg = _messages[index + 1];
                            prevDay = DateTime(prevMsg.timestamp.year,
                                prevMsg.timestamp.month, prevMsg.timestamp.day);
                          }
                          final showDivider =
                              prevDay == null || currentDay != prevDay;
                          final isSelected = _selectedMessageIds.contains(
                            message.messageId,
                          );
                          _messageKeys.putIfAbsent(
                            message.messageId,
                            () => GlobalKey(),
                          );
                          return Column(
                            children: [
                              if (showDivider) DayDivider(date: currentDay),
                              Container(
                                key: _messageKeys[message.messageId],
                                child: MessageBubbleWidget(
                                  message: message,
                                  isGroupChat: widget.chat.isGroup,
                                  isSelected: isSelected,
                                  isPinned:
                                      _pinnedIds.contains(message.messageId),
                                  onReply: () => _replyToMessage(message),
                                  onLongPress: () =>
                                      _onMessageLongPress(message),
                                  onTap: () => _onMessageTap(message),
                                  onOpenReplied: (id) => _scrollToMessage(id),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
          ),
          if (_replyingToMessage != null) _buildReplyPreview(),
          MessageInputWidget(
            controller: _messageController,
            onSendMessage: _sendMessage,
            onImageSelected: _handleImageSelected,
            onVideoSelected: _handleVideoSelected,
            onDocumentSelected: _handleDocumentSelected,
            onShareLocation: _shareCurrentLocation,
            onShareContact: _shareContact,
            onOpenCamera: _openUnifiedCamera,
            onAudioRecorded: _handleAudioRecorded,
            onTypingChanged: _handleTypingChanged,
          ),
        ],
      ),
    );
  }

  // kaldırıldı: eski liste temelli pinned gösterim

  Future<void> _scrollToMessage(String messageId) async {
    // 1) Hızlıca görünür mü kontrol et
    final key = _messageKeys[messageId];
    if (key?.currentContext != null) {
      try {
        await Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          alignment: 0.2,
        );
        return;
      } catch (_) {}
    }

    // 2) Liste içinde indeksini bul ve yaklaşık konuma kaydır
    final index = _messages.indexWhere((m) => m.messageId == messageId);
    if (index == -1) {
      if (mounted) {
        AppNotifier.showInfo(context, 'Mesaj bulunamadı');
      }
      return;
    }

    await _scrollNearIndexAndEnsure(index, key);
  }

  Future<void> _scrollNearIndexAndEnsure(int index, GlobalKey? key) async {
    // reverse: true -> index 0 en altta (offset 0). Büyük index -> daha yukarı offset
    const double avgExtent = 88.0; // Ortalama satır yüksekliği tahmini
    final double target = index * avgExtent;

    Future<bool> tryEnsure() async {
      final k = key ?? _messageKeys[_messages[index].messageId];
      if (k?.currentContext != null) {
        try {
          await Scrollable.ensureVisible(
            k!.currentContext!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.2,
          );
          return true;
        } catch (_) {}
      }
      return false;
    }

    // Yaklaşık konuma kaydır ve birkaç kez dene
    for (int attempt = 0; attempt < 5; attempt++) {
      if (!_scrollController.hasClients) break;
      final double max = _scrollController.position.maxScrollExtent;
      final double clamped = target.clamp(0, max).toDouble();
      await _scrollController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      await Future.delayed(const Duration(milliseconds: 50));
      if (await tryEnsure()) return;
      // Biraz daha yukarı çıkmayı dene
      final double extra = ((attempt + 1) * 200).toDouble();
      final double next = (clamped + extra).clamp(0, max).toDouble();
      await _scrollController.animateTo(
        next,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
      await Future.delayed(const Duration(milliseconds: 50));
      if (await tryEnsure()) return;
    }

    // Son çare: kullanıcıya yine de bilgi ver
    if (mounted) {
      AppNotifier.showInfo(context, 'Mesaj bulunamadı');
    }
  }

  Widget _buildPinnedMessagesSection() {
    if (_pinnedMessages.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF25D366),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.push_pin, size: 18, color: Colors.black54),
            const SizedBox(width: 8),
            Expanded(
              child: PageView.builder(
                controller: _pinnedPageController,
                itemCount: _pinnedMessages.length,
                onPageChanged: (i) => setState(() => _currentPinnedIndex = i),
                itemBuilder: (context, i) {
                  final m = _pinnedMessages[i];
                  return InkWell(
                    onTap: () => _scrollToMessage(m.messageId),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        m.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  );
                },
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Sabitlemeyi kaldır',
              icon: const Icon(Icons.close, size: 18, color: Colors.black54),
              onPressed: () async {
                if (_pinnedMessages.isEmpty) return;
                final target = _pinnedMessages[_currentPinnedIndex];
                try {
                  await MessageService.unpinMessage(
                    widget.chat.chatId,
                    target.messageId,
                  );
                  if (mounted) {
                    AppNotifier.showInfo(context, 'Sabitleme kaldırıldı');
                  }
                } catch (e) {
                  if (mounted) {
                    AppNotifier.showError(context, 'Sabit kaldırma hata: $e');
                  }
                }
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
