import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/media_service.dart';
import '../widgets/app_notifier.dart';
import '../services/user_service.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _aboutController = TextEditingController();
  String? _phoneNumber;
  String? _photoUrl;
  File? _localPhoto;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      // Önce yerel kullanıcıyı getir, yoksa Firestore'dan çekip yerel kaydet
      final localUser = await UserService.getOrFetchLocalUser(user.uid);
      final data = localUser?.toMap() ?? {};
      setState(() {
        _nameController.text = (data['name'] as String?)?.trim() ?? '';
        _aboutController.text = (data['about'] as String?)?.trim() ?? '';
        _phoneNumber = (data['phoneNumber'] as String?) ?? user.phoneNumber;
        _photoUrl = (data['profileImageUrl'] as String?) ?? '';
      });
    } catch (e) {
      if (mounted) {
        AppNotifier.showError(context, 'Profil yüklenemedi: $e');
      }
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1024, imageQuality: 70);
    if (xfile == null) return;
    setState(() => _localPhoto = File(xfile.path));
  }

  String? _validateName(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'İsim gerekli';
    if (value.length < 2) return 'İsim en az 2 karakter olmalı';
    if (value.length > 30) return 'İsim en fazla 30 karakter olabilir';
    final valid = RegExp(r"^[A-Za-zÇĞİÖŞÜçğıöşü0-9 .'-]{2,30}").hasMatch(value);
    if (!valid) return 'Geçersiz karakter içeriyor';
    return null;
  }

  String? _validateAbout(String? v) {
    final value = (v ?? '').trim();
    if (value.length > 160) return 'Hakkımda en fazla 160 karakter olabilir';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      String? uploadedUrl = _photoUrl;
      if (_localPhoto != null) {
        final xfile = XFile(_localPhoto!.path);
        final url =
            await MediaService().uploadImage(xfile, 'profiles_${user.uid}');
        if (url != null) uploadedUrl = url;
      }

      await UserService.updateUserProfile(
        name: _nameController.text.trim(),
        about: _aboutController.text.trim(),
        profileImageUrl: uploadedUrl,
      );

      if (!mounted) return;
      AppNotifier.showInfo(context, 'Profil güncellendi');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) AppNotifier.showError(context, 'Kayıt başarısız: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Ayarları'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Kaydet', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: _localPhoto != null
                        ? FileImage(_localPhoto!)
                        : (_photoUrl != null && _photoUrl!.isNotEmpty)
                            ? NetworkImage(_photoUrl!) as ImageProvider
                            : null,
                    child: (_photoUrl == null && _localPhoto == null)
                        ? const Icon(Icons.person,
                            size: 48, color: Colors.white70)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Material(
                      color: Colors.teal,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _saving ? null : _pickPhoto,
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.camera_alt, color: Colors.white),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              maxLength: 30,
              validator: _validateName,
              decoration: const InputDecoration(
                labelText: 'İsim',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              enabled: false,
              initialValue: _phoneNumber ?? '',
              decoration: const InputDecoration(
                labelText: 'Telefon Numarası',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _aboutController,
              maxLines: 3,
              maxLength: 160,
              validator: _validateAbout,
              decoration: const InputDecoration(
                labelText: 'Hakkımda',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info_outline),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
