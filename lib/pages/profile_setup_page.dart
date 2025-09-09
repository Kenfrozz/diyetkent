import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
// Firestore/Storage doğrudan kullanılmıyor; servisler üzerinden
import 'dart:io';
import 'home_page.dart';
import '../services/media_service.dart';
import '../services/user_service.dart';

class ProfileSetupPage extends StatefulWidget {
  final String userId;
  final String phoneNumber;
  final Map<String, dynamic>? existingData;

  const ProfileSetupPage({
    super.key,
    required this.userId,
    required this.phoneNumber,
    this.existingData,
  });

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _nameController = TextEditingController();
  final _aboutController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _profileImageUrl;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    if (widget.existingData != null) {
      final data = widget.existingData!;
      _nameController.text = data['name'] ?? '';
      _aboutController.text = data['about'] ?? '';
      _profileImageUrl = data['profileImageUrl'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Profil Bilgileri'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Geri butonunu kaldır
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              const Text(
                'Profil bilgilerinizi tamamlayın',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bu bilgiler diğer kullanıcılara gösterilecektir',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // Profil fotoğrafı
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _getProfileImage(),
                      child: _getProfileImage() == null
                          ? Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey[600],
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF00796B),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // İsim
              TextFormField(
                controller: _nameController,
                maxLength: 40,
                inputFormatters: [LengthLimitingTextInputFormatter(40)],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'İsim gerekli';
                  }
                  if (value.trim().length < 2) {
                    return 'İsim en az 2 karakter olmalı';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'İsim*',
                  hintText: 'Adınızı ve soyadınızı girin',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Color(0xFF00796B), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Hakkımda
              TextFormField(
                controller: _aboutController,
                maxLines: 3,
                maxLength: 250,
                inputFormatters: [LengthLimitingTextInputFormatter(250)],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Hakkımda bilgisi gerekli';
                  }
                  if (value.trim().length < 5) {
                    return 'Hakkımda en az 5 karakter olmalı';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Hakkımda*',
                  hintText: 'Kendinizi kısaca tanıtın...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Color(0xFF00796B), width: 2),
                  ),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 40),

              // Kaydet butonu
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00796B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Kaydet ve Devam Et',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                '* Zorunlu alanlar',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider? _getProfileImage() {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      return NetworkImage(_profileImageUrl!);
    }
    return null;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return _profileImageUrl;
    try {
      return await MediaService().uploadImage(
          XFile(_selectedImage!.path), 'profiles_${widget.userId}');
    } catch (e) {
      debugPrint('Resim yükleme hatası: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Resmi yükle
      String? imageUrl = await _uploadImage();

      // Kullanıcı verilerini servis ile kaydet (Firestore + Isar senkron)
      await UserService.updateUserProfile(
        name: _nameController.text.trim(),
        about: _aboutController.text.trim(),
        profileImageUrl: imageUrl,
      );

      if (mounted) {
        // Ana sayfaya yönlendir
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil kaydedilirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
