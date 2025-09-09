import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class AttachmentBottomSheet extends StatelessWidget {
  final Function(PlatformFile) onDocumentSelected;
  final VoidCallback onShareLocation;
  final VoidCallback onShareContact;

  const AttachmentBottomSheet({
    super.key,
    required this.onDocumentSelected,
    required this.onShareLocation,
    required this.onShareContact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Başlık
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Dosya Ekle',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Seçenekler (Belge / Konum / Kişi)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _AttachmentOption(
                        icon: Icons.description,
                        label: 'Belge',
                        color: Colors.blue,
                        onTap: () async {
                          Navigator.pop(context);
                          final PlatformFile? document =
                              await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx'],
                            allowMultiple: false,
                          ).then((r) => r?.files.first);
                          if (document != null) {
                            onDocumentSelected(document);
                          }
                        },
                      ),
                      _AttachmentOption(
                        icon: Icons.location_on,
                        label: 'Konum',
                        color: Colors.green,
                        onTap: () {
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(context);
                          onShareLocation();
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Konum gönderiliyor...')),
                          );
                        },
                      ),
                      _AttachmentOption(
                        icon: Icons.contact_phone,
                        label: 'Kişi',
                        color: Colors.orange,
                        onTap: () {
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(context);
                          onShareContact();
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Kişi gönderiliyor...')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Video seçenekleri kaldırıldı; medya birleşik kamera ekranında
}

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }
}
