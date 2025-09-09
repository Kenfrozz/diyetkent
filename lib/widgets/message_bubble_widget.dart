import 'package:flutter/material.dart';
import '../models/message_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'media_message_widget.dart';
import 'package:intl/intl.dart';

class MessageBubbleWidget extends StatelessWidget {
  final MessageModel message;
  final VoidCallback? onLongPress;
  final VoidCallback? onImageTap;
  final VoidCallback? onReply;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool isPinned;
  final ValueChanged<String>? onOpenReplied;
  // Sadece grup sohbetlerinde gönderen etiketini göstermek için
  final bool isGroupChat;

  const MessageBubbleWidget({
    super.key,
    required this.message,
    this.onLongPress,
    this.onImageTap,
    this.onReply,
    this.isSelected = false,
    this.onTap,
    this.isPinned = false,
    this.onOpenReplied,
    this.isGroupChat = false,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isMe = message.senderId == currentUser?.uid;

    return Dismissible(
      key: Key(message.messageId),
      direction: DismissDirection.startToEnd,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: Colors.transparent,
        child: const Icon(Icons.reply, color: Colors.grey, size: 28),
      ),
      confirmDismiss: (direction) async {
        // Yanıtlama işlemini tetikle ve dismiss'i iptal et
        if (onReply != null) {
          onReply!();
        }
        return false; // Mesajı silme, sadece yanıtla
      },
      child: GestureDetector(
        onLongPress: onLongPress,
        onTap: onTap,
        child: Container(
          decoration: isSelected
              ? BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: _isMediaMessage()
                  ? _buildMediaContent(isMe)
                  : _buildTextContent(isMe),
            ),
          ),
        ),
      ),
    );
  }

  bool _isMediaMessage() {
    return message.type == MessageType.image ||
        message.type == MessageType.video ||
        message.type == MessageType.document ||
        message.type == MessageType.audio ||
        message.type == MessageType.location ||
        message.type == MessageType.contact;
  }

  Widget _buildMediaContent(bool isMe) {
    final timeString = DateFormat('HH:mm').format(message.timestamp);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.replyToMessageId != null) _buildReplyPreview(isMe),
        MediaMessageWidget(
          imageUrl: message.type == MessageType.image ? message.mediaUrl : null,
          videoUrl: message.type == MessageType.video ? message.mediaUrl : null,
          documentUrl:
              message.type == MessageType.document ? message.mediaUrl : null,
          documentName:
              message.type == MessageType.document ? message.content : null,
          audioUrl: message.type == MessageType.audio ? message.mediaUrl : null,
          audioDurationSec: message.mediaDuration,
          latitude:
              message.type == MessageType.location ? message.latitude : null,
          longitude:
              message.type == MessageType.location ? message.longitude : null,
          locationName: message.type == MessageType.location
              ? message.locationName
              : null,
          contactName: message.type == MessageType.contact
              ? _extractContactName(message.content)
              : null,
          contactPhone: message.type == MessageType.contact
              ? _extractContactPhone(message.content)
              : null,
          localPath: message.mediaLocalPath,
          messageId: message.messageId,
          isFromMe: isMe,
          messageTime: timeString,
          isRead: message.status == MessageStatus.read,
        ),
      ],
    );
  }

  String? _extractContactName(String content) {
    final lines = content.split('\n');
    if (lines.isEmpty) return null;
    return lines.first.replaceAll('👤 ', '').trim();
  }

  String? _extractContactPhone(String content) {
    final lines = content.split('\n');
    if (lines.length < 2) return null;
    return lines[1].replaceAll('📞 ', '').trim();
  }

  Widget _buildTextContent(bool isMe) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF00796B) : Colors.grey[200],
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grup sohbeti: gönderen etiketini göster
          if (isGroupChat) ...[
            _SenderNameLabel(message: message, isFromMe: isMe),
            const SizedBox(height: 4),
          ],
          // Yanıtlanan mesaj varsa göster
          if (message.replyToMessageId != null) _buildReplyPreview(isMe),
          // Mesaj içeriği
          _buildMessageContent(isMe),
          const SizedBox(height: 4),
          // Zaman ve durum
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isPinned) ...[
                const Icon(Icons.push_pin, size: 12, color: Colors.white70),
                const SizedBox(width: 4),
              ],
              if (message.isEdited) ...[
                Text(
                  'Düzenlendi',
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.grey[600],
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              // Grup sohbetinde: kendi mesajımda durum simgesi solda
              // Bireysel sohbette: kendi mesajımda durum simgesi sağda (eski davranış)
              if (isGroupChat && isMe) ...[
                Icon(
                  _getStatusIcon(message.status),
                  size: 16,
                  color: _getStatusColor(message.status),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                "${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}",
                style: TextStyle(
                  color: isMe ? Colors.white70 : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              if (!isGroupChat && isMe) ...[
                const SizedBox(width: 4),
                Icon(
                  _getStatusIcon(message.status),
                  size: 16,
                  color: _getStatusColor(message.status),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Yanıtlanan mesaj önizlemesi
  Widget _buildReplyPreview(bool isMe) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final repliedSenderId = message.replyToSenderId;
    final repliedLabel = repliedSenderId == null
        ? 'Yanıtlandı'
        : (repliedSenderId == currentUser?.uid ? 'Sen' : 'Yanıtlandı');
    final repliedText = (message.replyToContent?.isNotEmpty == true)
        ? message.replyToContent!
        : 'Mesaj';
    final preview = Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe ? Colors.white.withValues(alpha: 0.2) : Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMe ? Colors.white.withValues(alpha: 0.3) : Colors.grey[400]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 30,
            decoration: BoxDecoration(
              color: isMe ? Colors.white : Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      repliedLabel,
                      style: TextStyle(
                        color: isMe ? Colors.white70 : Colors.grey[600],
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.reply,
                      size: 12,
                      color: isMe ? Colors.white70 : Colors.grey[600],
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  repliedText.length > 50
                      ? '${repliedText.substring(0, 50)}...'
                      : repliedText,
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.grey[700],
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (message.replyToMessageId != null && onOpenReplied != null) {
      return InkWell(
        onTap: () => onOpenReplied!(message.replyToMessageId!),
        child: preview,
      );
    }
    return preview;
  }

  Widget _buildMessageContent(bool isMe) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        );

      case MessageType.audio:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe ? Colors.white24 : Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_arrow,
                color: isMe ? Colors.white : Colors.black87,
              ),
              const SizedBox(width: 8),
              Text(
                'Ses mesajı',
                style: TextStyle(color: isMe ? Colors.white : Colors.black87),
              ),
            ],
          ),
        );

      default:
        return Text(
          message.content,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        );
    }
  }

  IconData _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error_outline;
    }
  }

  Color _getStatusColor(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Colors.grey;
      case MessageStatus.sent:
        return Colors.grey;
      case MessageStatus.delivered:
        return Colors.grey;
      case MessageStatus.read:
        return Colors.blue;
      case MessageStatus.failed:
        return Colors.red;
    }
  }
}

class _SenderNameLabel extends StatelessWidget {
  final MessageModel message;
  final bool isFromMe;
  const _SenderNameLabel({required this.message, required this.isFromMe});

  @override
  Widget build(BuildContext context) {
    // Grup sohbeti gönderen adını tespit etme için basit stil: "Sen" ya da karşı taraf adı
    // İdeal: GroupMemberModel'den effectiveDisplayName. Bu hızlı çözümde sadece mevcut chat'teki "Sen"/"Karşı taraf" ayrımı yapılır.
    // Geliştirme: ChatPage grupsa ve senderId != currentUser ise ContactsService üzerinden ad bulunabilir.
    final currentUser = FirebaseAuth.instance.currentUser;
    final isMeSender = message.senderId == currentUser?.uid;
    final label = isMeSender ? 'Sen' : 'Üye';
    return Text(
      label,
      style: TextStyle(
        color: isFromMe ? Colors.white70 : Colors.teal[700],
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
