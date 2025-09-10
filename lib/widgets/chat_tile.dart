import 'package:flutter/material.dart';
import '../models/chat_model.dart';

import '../widgets/tag_chips_widget.dart';
import 'package:intl/intl.dart';

class ChatTile extends StatelessWidget {
  final ChatModel chat;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isSelected;
  final bool isSelectionMode;

  const ChatTile({
    super.key,
    required this.chat,
    required this.onTap,
    required this.onLongPress,
    this.isSelected = false,
    this.isSelectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withValues(alpha: 0.1) : null,
        ),
        child: Row(
          children: [
            // Seçim modu checkbox'ı veya profil resmi
            if (isSelectionMode)
              Container(
                margin: const EdgeInsets.only(right: 12),
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) => onTap(),
                  activeColor: const Color(0xFFE91D7C),
                ),
              )
            else
              // Profil resmi + (varsa) okunmamış göstergesi
              _buildProfileImageWithStatus(),

            const SizedBox(width: 12),

            // Sohbet bilgileri
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // İsim ve zaman
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                _getDisplayName(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Etiketler
                            if (chat.tags.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              TagChipsWidget(
                                tagIds: chat.tags,
                                maxVisible: 2,
                                fontSize: 10,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(),
                            style: TextStyle(
                              fontSize: 12,
                              color: chat.unreadCount > 0
                                  ? const Color(0xFF25D366)
                                  : Colors.grey[600],
                              fontWeight: chat.unreadCount > 0
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                          if (chat.isPinned) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.push_pin,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                          ],
                          if (chat.isArchived) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.archive,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Son mesaj ve durum simgeleri
                  Row(
                    children: [
                      // Son mesaj içeriği
                      Expanded(child: _buildLastMessage()),

                      // Durum simgeleri ve sayaç
                      _buildStatusIcons(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImageWithStatus() {
    final avatar = _buildProfileImageBase();
    // Okunmamış mesaj varsa küçük bir gösterge ekle (avatarı değiştirme)
    if (chat.unreadCount > 0) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF25D366),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      );
    }
    return avatar;
  }

  Widget _buildProfileImageBase() {
    // Grup ise grup avatarı ve isimlendirme önceliği
    if (chat.isGroup) {
      final display =
          chat.groupName?.isNotEmpty == true ? chat.groupName! : 'Grup';
      final letter = display[0].toUpperCase();
      return CircleAvatar(
        radius: 25,
        backgroundColor: Colors.blueGrey,
        backgroundImage:
            (chat.groupImage != null && chat.groupImage!.isNotEmpty)
                ? NetworkImage(chat.groupImage!)
                : null,
        child: (chat.groupImage == null || chat.groupImage!.isEmpty)
            ? Text(
                letter,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              )
            : null,
      );
    }
    if (chat.otherUserProfileImage != null &&
        chat.otherUserProfileImage!.isNotEmpty) {
      return CircleAvatar(
        radius: 25,
        backgroundImage: NetworkImage(chat.otherUserProfileImage!),
        backgroundColor: Colors.grey[300],
      );
    }

    // Profil resmi yoksa baş harfi göster
    final firstLetter =
        _getDisplayName().isNotEmpty ? _getDisplayName()[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: 25,
      backgroundColor: _getAvatarColor(),
      child: Text(
        firstLetter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildLastMessage() {
    if (chat.lastMessage == null || chat.lastMessage!.isEmpty) {
      return const Text(
        'Henüz mesaj yok',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Row(
      children: [
        // Son mesaj gönderen kim kontrol edilir
        if (chat.isLastMessageFromMe) ...[
          Icon(
            chat.isLastMessageRead ? Icons.done_all : Icons.done,
            size: 16,
            color: chat.isLastMessageRead
                ? const Color(0xFF4FC3F7)
                : Colors.grey[600],
          ),
          const SizedBox(width: 4),
        ],

        // Mesaj içeriği
        Expanded(
          child: Text(
            chat.lastMessage!,
            style: TextStyle(
              fontSize: 14,
              color: chat.unreadCount > 0 && !chat.isLastMessageFromMe
                  ? Colors.black87
                  : Colors.grey[600],
              fontWeight: chat.unreadCount > 0 && !chat.isLastMessageFromMe
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIcons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sessize alınmış simgesi
        if (chat.isMuted) ...[
          Icon(Icons.volume_off, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
        ],

        // Okunmamış mesaj sayısı
        if (chat.unreadCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF25D366),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              chat.unreadCount > 99 ? '99+' : chat.unreadCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  String _getDisplayName() {
    if (chat.isGroup) {
      return chat.groupName ?? 'Grup';
    }
    // Eğer rehber ismi varsa onu göster
    if (chat.otherUserContactName != null &&
        chat.otherUserContactName!.isNotEmpty) {
      return chat.otherUserContactName!;
    }

    // Rehber ismi yoksa telefon numarasını göster
    if (chat.otherUserPhoneNumber != null &&
        chat.otherUserPhoneNumber!.isNotEmpty) {
      return chat.otherUserPhoneNumber!;
    }

    // Son çare olarak Firebase ismini göster
    return chat.otherUserName ?? 'Bilinmeyen';
  }

  String _formatTime() {
    if (chat.lastMessageTime == null) return '';

    final now = DateTime.now();
    final messageTime = chat.lastMessageTime!;
    final difference = now.difference(messageTime);

    if (difference.inDays == 0) {
      // Bugün - sadece saat:dakika
      return DateFormat('HH:mm').format(messageTime);
    } else if (difference.inDays == 1) {
      // Dün
      return 'Dün';
    } else if (difference.inDays < 7) {
      // Bu hafta - gün adı
      return DateFormat('EEEE', 'tr_TR').format(messageTime);
    } else {
      // Daha eski - tarih
      return DateFormat('dd.MM.yyyy').format(messageTime);
    }
  }

  Color _getAvatarColor() {
    // Kullanıcı ID'sine göre sabit renk üret
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.pink,
      Colors.indigo,
      Colors.pink,
    ];

    final hash = chat.otherUserId.hashCode;
    return colors[hash.abs() % colors.length];
  }
}
