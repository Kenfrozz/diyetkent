import 'package:flutter/material.dart';
// removed old UI-only call model usage
import '../services/call_service.dart';
import '../database/drift_service.dart';
import '../models/call_log_model.dart' as logm;
import '../services/people_service.dart';
import 'voice_call_page.dart';
import 'dart:async';

class CallsPage extends StatefulWidget {
  const CallsPage({super.key});

  @override
  State<CallsPage> createState() => _CallsPageState();
}

class _CallsPageState extends State<CallsPage> {
  List<logm.CallLogModel> _logs = [];
  StreamSubscription<List<logm.CallLogModel>>? _sub;

  @override
  void initState() {
    super.initState();
    _listenLogs();
  }

  // dispose en altta tanımlı

  void _listenLogs() {
    _sub?.cancel();
    _sub = DriftService.watchAllCallLogs().listen((logs) {
      setState(() {
        _logs = logs;
    });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aramalar')),
      body: Stack(
        children: [
          _buildBody(),
          Positioned(
            right: 16,
            bottom: 96,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('Geçmişi Temizle'),
              onPressed: _clearHistory,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showContactPicker,
        backgroundColor: const Color(0xFF25D366),
        child: const Icon(Icons.add_call, color: Colors.white),
      ),
    );
  }

  Future<void> _clearHistory() async {
    try {
      await DriftService.deleteAllCallLogs();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arama geçmişi temizlendi')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Widget _buildBody() {
    final list = _logs;
    if (list.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.call, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Henüz arama geçmişi yok',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final log = list[index];
        final name = log.otherDisplayName ??
            (log.otherUserId ?? log.otherUserPhone ?? 'Kişi');
        final time = log.createdAt;
        return ListTile(
          leading: CircleAvatar(
            radius: 25,
            backgroundColor: _getAvatarColor(name),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: log.status == logm.CallLogStatus.missed
                        ? Colors.red
                        : Colors.black,
                  ),
                ),
              ),
              Icon(
                _getCallDirectionIcon(log.direction),
                size: 16,
                color: log.status == logm.CallLogStatus.missed
                    ? Colors.red
                    : log.direction == logm.CallLogDirection.incoming
                        ? Colors.green
                        : Colors.blue,
              ),
            ],
          ),
          subtitle: Row(
            children: [
              const Icon(Icons.phone, size: 14),
              const SizedBox(width: 4),
              Text(
                _formatTime(time),
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
          trailing: IconButton(
            onPressed: () => _redial(log),
            icon: const Icon(Icons.phone, color: Color(0xFF25D366)),
          ),
          onTap: () => _redial(log),
        );
      },
    );
  }

  // filtre özelliği kaldırıldı

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF2E7D32),
      const Color(0xFF1976D2),
      const Color(0xFF7B1FA2),
      const Color(0xFFC62828),
      const Color(0xFFD84315),
      const Color(0xFF6A1B9A),
      const Color(0xFFE91D7C),
      const Color(0xFF5D4037),
    ];

    // hashCode negatif dönebileceği için mutlak değeri al
    int colorIndex = name.hashCode.abs() % colors.length;
    return colors[colorIndex];
  }

  IconData _getCallDirectionIcon(logm.CallLogDirection direction) {
    switch (direction) {
      case logm.CallLogDirection.incoming:
        return Icons.call_received;
      case logm.CallLogDirection.outgoing:
        return Icons.call_made;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Şimdi';
    }
  }

  Future<void> _redial(logm.CallLogModel log) async {
    final service = CallService();
    try {
      final calleeId = log.otherUserId ?? log.otherUserPhone ?? '';
      if (calleeId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kişi bilgisi bulunamadı')),
        );
        return;
      }
      final callId = await service.startVoiceCall(calleeId: calleeId);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VoiceCallPage(
            otherUserName:
                log.otherDisplayName ?? (log.otherUserId ?? 'Kişi'),
            callId: callId,
            isIncoming: false,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Arama başlatılamadı: $e')),
      );
    }
  }

  /*
  void _showCallOptions(CallModel call) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.phone, color: Color(0xFF25D366)),
                title: const Text('Sesli arama'),
                onTap: () {
                  Navigator.pop(context);
                  _makeCall(call);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Color(0xFF25D366)),
                title: const Text('Görüntülü arama'),
                onTap: () {
                  Navigator.pop(context);
                  _makeCall(call);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Arama geçmişinden sil'),
                onTap: () {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(context);
                  setState(() {
                    _calls.remove(call);
                    // Aktif filtreyi korumak için yeniden uygula
                    _filterCalls();
                  });
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Arama geçmişinden silindi')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
  */

  // removed: replaced with _showContactPicker via FAB

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _showContactPicker() {
    final rootContext = context; // parent scaffold context
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final TextEditingController controller = TextEditingController();
        List<Map<String, dynamic>> filtered = [];
        bool initialized = false;
        bool loading = true;
        Timer? debounce;
        // load fonksiyonu StatefulBuilder'ın setState'ini kullanacak şekilde
        // builder içinde tanımlanacak

        return StatefulBuilder(
          builder: (context, modalSetState) {
            Future<void> load() async {
              // Başlangıçta ağır yükleme yapma; kullanıcı aradıkça getirilecek
              modalSetState(() {
                filtered = [];
                loading = false;
              });
            }

            if (!initialized) {
              initialized = true;
              Future.microtask(load);
            }
            void applyFilter() {
              final q = controller.text.trim().toLowerCase();
              if (debounce?.isActive == true) debounce!.cancel();
              debounce = Timer(const Duration(milliseconds: 300), () async {
                if (q.isEmpty) {
                  modalSetState(() {
                    filtered = [];
                  });
                  return;
                }
                modalSetState(() {
                  loading = true;
                });
                try {
                  final data = await PeopleService.searchDirectoryQuick(
                    query: q,
                    includeUnregistered: true,
                    limit: 200,
                  ).timeout(const Duration(seconds: 20),
                      onTimeout: () => <Map<String, dynamic>>[]);
                  if (!(context as Element).mounted) return;
                  modalSetState(() {
                    filtered = data;
                    loading = false;
                  });
                } catch (e) {
                  if (!(context as Element).mounted) return;
                  modalSetState(() {
                    filtered = [];
                    loading = false;
                  });
                }
              });
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      height: 4,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: 'Kişilerde ara',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        onChanged: (_) => applyFilter(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final c = filtered[index];
                            final name =
                                (c['contactName'] ?? c['displayName'] ?? 'Kişi')
                                    .toString();
                            final phone = (c['phoneNumber'] ??
                                    c['normalizedPhoneNumber'] ??
                                    '')
                                .toString();
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getAvatarColor(name),
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(name),
                              subtitle: Text(phone),
                              trailing: const Icon(Icons.call,
                                  color: Color(0xFF25D366)),
                              onTap: () async {
                                Navigator.pop(context);
                                final uidOrPhone =
                                    (c['uid'] as String?) ?? phone;
                                final service = CallService();
                                try {
                                  final callId = await service.startVoiceCall(
                                      calleeId: uidOrPhone);
                                  if (!mounted) return;
                                  if (rootContext.mounted) {
                                    Navigator.of(rootContext).push(
                                      MaterialPageRoute(
                                        builder: (_) => VoiceCallPage(
                                          otherUserName: name,
                                          callId: callId,
                                          isIncoming: false,
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (!mounted) return;
                                  // BottomSheet context kapanmış olabilir; parent context kullan
                                  if (rootContext.mounted) {
                                    final messenger =
                                        ScaffoldMessenger.of(rootContext);
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text('Arama başlatılamadı: $e'),
                                      ),
                                    );
                                  }
                                }
                              },
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
