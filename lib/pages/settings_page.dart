import 'package:flutter/material.dart';
import 'meal_reminder_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        children: [
          _buildProfileSection(),
          const Divider(),
          _buildSettingsSection(context),
          const Divider(),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.teal,
            child: Icon(Icons.person, size: 35, color: Colors.white),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profil ayarları yakında...',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                Text(
                  'Çevrimiçi',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.key),
          title: const Text('Hesap'),
          subtitle: const Text('Güvenlik bildirimleri, değiştirme numarası'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.lock),
          title: const Text('Gizlilik'),
          subtitle: const Text('Son görülme, profil fotoğrafı, durum'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.chat),
          title: const Text('Sohbetler'),
          subtitle: const Text('Tema, duvar kağıtları, sohbet geçmişi'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Bildirimler'),
          subtitle: const Text('Mesaj, grup ve arama tonları'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.restaurant),
          title: const Text('Öğün Hatırlatmaları'),
          subtitle: const Text('Kahvaltı, öğle, akşam yemeği hatırlatmaları'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MealReminderSettingsPage(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.data_usage),
          title: const Text('Depolama ve veri'),
          subtitle: const Text('Ağ kullanımı, otomatik indirme'),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.help),
          title: const Text('Yardım'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.group),
          title: const Text('Arkadaşlarını davet et'),
          onTap: () {},
        ),
        const ListTile(
          leading: Icon(Icons.info),
          title: Text('DiyetKent v1.0.0'),
          subtitle: Text('© 2025 DiyetKent'),
        ),
      ],
    );
  }
}
