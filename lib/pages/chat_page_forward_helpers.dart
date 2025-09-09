import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../database/drift_service.dart';
import 'package:intl/intl.dart';

class ForwardSelectChatPage extends StatelessWidget {
  final void Function(ChatModel) onChatSelected;
  const ForwardSelectChatPage({super.key, required this.onChatSelected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yönlendirilecek sohbeti seç'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<ChatModel>>(
        future: DriftService.getAllChats(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final chats = snap.data!;
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, i) {
              final c = chats[i];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                      (c.displayName.isNotEmpty ? c.displayName[0] : '?')
                          .toUpperCase()),
                ),
                title: Text(c.displayName),
                subtitle: Text(c.lastMessage ?? ''),
                onTap: () {
                  Navigator.pop(context);
                  onChatSelected(c);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class DayDivider extends StatelessWidget {
  final DateTime date;
  const DayDivider({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String label;
    final d = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (d == today) {
      label = 'Bugün';
    } else if (d == yesterday) {
      label = 'Dün';
    } else {
      label = DateFormat('d MMMM yyyy', 'tr_TR').format(date);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Expanded(
            child: Divider(thickness: 1),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          const Expanded(
            child: Divider(thickness: 1),
          ),
        ],
      ),
    );
  }
}
