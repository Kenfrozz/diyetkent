import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/chat_model.dart';
import '../widgets/chat_tile.dart';
import 'chat_page.dart';

class ArchivedChatsPage extends StatelessWidget {
  const ArchivedChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arşivlenmiş Sohbetler'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value, context),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'unarchive_all',
                child: ListTile(
                  leading: Icon(Icons.unarchive),
                  title: Text('Tümünü Arşivden Çıkar'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete_all',
                child: ListTile(
                  leading: Icon(Icons.delete_forever, color: Colors.red),
                  title: Text(
                    'Tümünü Sil',
                    style: TextStyle(color: Colors.red),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          final archivedChats = chatProvider.archivedChats;

          if (archivedChats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.archive_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Arşivlenmiş sohbet yok',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sohbetleri arşivleyerek ana listeden gizleyebilirsiniz',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Info banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.blue.shade50,
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Arşivlenmiş sohbetler ana listede görünmez. Yeni mesaj geldiğinde otomatik olarak arşivden çıkar.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Archived chats list
              Expanded(
                child: ListView.builder(
                  itemCount: archivedChats.length,
                  itemBuilder: (context, index) {
                    final chat = archivedChats[index];
                    return _buildArchivedChatTile(context, chat, chatProvider);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildArchivedChatTile(
    BuildContext context,
    ChatModel chat,
    ChatProvider chatProvider,
  ) {
    return Dismissible(
      key: Key(chat.chatId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.green,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.unarchive, color: Colors.white),
            Text(
              'Arşivden Çıkar',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        await chatProvider.toggleArchive(chat.chatId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_getDisplayName(chat)} arşivden çıkarıldı'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'Geri Al',
                textColor: Colors.white,
                onPressed: () => chatProvider.toggleArchive(chat.chatId),
              ),
            ),
          );
        }
        return true;
      },
      child: ChatTile(
        chat: chat,
        onTap: () => _openChat(context, chat),
        onLongPress: () => _showChatOptions(context, chat, chatProvider),
        isSelected: false,
        isSelectionMode: false,
      ),
    );
  }

  void _openChat(BuildContext context, ChatModel chat) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatPage(chat: chat)),
    );
  }

  void _showChatOptions(
    BuildContext context,
    ChatModel chat,
    ChatProvider chatProvider,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.unarchive),
            title: const Text('Arşivden Çıkar'),
            onTap: () {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              chatProvider.toggleArchive(chat.chatId);
              messenger.showSnackBar(
                SnackBar(
                  content: Text('${_getDisplayName(chat)} arşivden çıkarıldı'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(chat.isMuted ? Icons.volume_up : Icons.volume_off),
            title: Text(chat.isMuted ? 'Sessize Almayı Kaldır' : 'Sessize Al'),
            onTap: () {
              Navigator.pop(context);
              chatProvider.toggleMute(chat.chatId);
            },
          ),
          ListTile(
            leading: Icon(
              chat.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
            ),
            title: Text(chat.isPinned ? 'Sabitlemeyi Kaldır' : 'Sabitle'),
            onTap: () {
              Navigator.pop(context);
              chatProvider.togglePin(chat.chatId);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Sil', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(context, chat, chatProvider);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    ChatModel chat,
    ChatProvider chatProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sohbeti Sil'),
        content: Text(
          '${_getDisplayName(chat)} ile olan sohbeti silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              chatProvider.deleteChat(chat.chatId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_getDisplayName(chat)} silindi'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    switch (action) {
      case 'unarchive_all':
        _showUnarchiveAllConfirmation(context, chatProvider);
        break;
      case 'delete_all':
        _showDeleteAllConfirmation(context, chatProvider);
        break;
    }
  }

  void _showUnarchiveAllConfirmation(
    BuildContext context,
    ChatProvider chatProvider,
  ) {
    final archivedChats = chatProvider.archivedChats;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tümünü Arşivden Çıkar'),
        content: Text(
          '${archivedChats.length} arşivlenmiş sohbeti arşivden çıkarmak istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              for (final chat in archivedChats) {
                await chatProvider.toggleArchive(chat.chatId);
              }

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${archivedChats.length} sohbet arşivden çıkarıldı',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Arşivden Çıkar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllConfirmation(
    BuildContext context,
    ChatProvider chatProvider,
  ) {
    final archivedChats = chatProvider.archivedChats;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tümünü Sil'),
        content: Text(
          '${archivedChats.length} arşivlenmiş sohbeti silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              for (final chat in archivedChats) {
                await chatProvider.deleteChat(chat.chatId);
              }

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${archivedChats.length} sohbet silindi'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  String _getDisplayName(ChatModel chat) {
    if (chat.otherUserContactName != null &&
        chat.otherUserContactName!.isNotEmpty) {
      return chat.otherUserContactName!;
    }

    if (chat.otherUserPhoneNumber != null &&
        chat.otherUserPhoneNumber!.isNotEmpty) {
      return chat.otherUserPhoneNumber!;
    }

    if (chat.otherUserName != null && chat.otherUserName!.isNotEmpty) {
      return chat.otherUserName!;
    }

    return 'Bilinmeyen Kullanıcı';
  }
}
