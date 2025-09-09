import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/meal_reminder_preference_service.dart';
import '../database/drift_service.dart';
import '../models/meal_reminder_preferences_model.dart';

class MealReminderSettingsPage extends StatefulWidget {
  const MealReminderSettingsPage({super.key});

  @override
  State<MealReminderSettingsPage> createState() => _MealReminderSettingsPageState();
}

class _MealReminderSettingsPageState extends State<MealReminderSettingsPage> {
  MealReminderPreferencesModel? _preferences;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final userId = AuthService.currentUserId;
      if (userId != null) {
        final preferences = await DriftService.getMealReminderPreferencesOrDefault(userId);
        if (mounted) {
          setState(() {
            _preferences = preferences;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Meal reminder preferences yükleme hatası: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _savePreferences() async {
    if (_preferences == null) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      await DriftService.saveMealReminderPreferences(_preferences);
      
      // Hatırlatmaları yenile
      final userId = AuthService.currentUserId;
      if (userId != null) {
        await MealReminderPreferenceService.scheduleAdaptiveReminders(userId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Öğün hatırlatma ayarları kaydedildi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Meal reminder preferences kaydetme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ayarlar kaydedilemedi. Lütfen tekrar deneyin.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
        title: const Text('Öğün Hatırlatmaları'),
        actions: [
          if (_preferences != null)
            TextButton(
              onPressed: _isSaving ? null : _savePreferences,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Kaydet',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _preferences == null
              ? const Center(
                  child: Text('Ayarlar yüklenirken hata oluştu'),
                )
              : _buildSettingsContent(),
    );
  }

  Widget _buildSettingsContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMainToggle(),
        const SizedBox(height: 16),
        if (_preferences!.isReminderEnabled) ...[
          _buildMealTimesSection(),
          const SizedBox(height: 24),
          _buildMealTogglesSection(),
          const SizedBox(height: 24),
          _buildReminderDaysSection(),
          const SizedBox(height: 24),
          _buildNotificationOptionsSection(),
          const SizedBox(height: 24),
          _buildAdvancedOptionsSection(),
          const SizedBox(height: 24),
          _buildStatsSection(),
        ],
      ],
    );
  }

  Widget _buildMainToggle() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.notifications_active,
              color: Color(0xFF075E54),
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Öğün Hatırlatmaları',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _preferences!.isReminderEnabled
                        ? 'Aktif - Günde ${_getActiveReminderCount()} hatırlatma'
                        : 'Devre dışı',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _preferences!.isReminderEnabled,
              onChanged: (value) {
                setState(() {
                  _preferences!.isReminderEnabled = value;
                  _preferences!.updatedAt = DateTime.now();
                });
              },
              activeColor: const Color(0xFF075E54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealTimesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Öğün Zamanları',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildMealTimeRow(
              'Kahvaltı',
              Icons.breakfast_dining,
              _preferences!.breakfastTime,
              _preferences!.isBreakfastReminderEnabled,
              (time) => _preferences!.setBreakfastTime(time),
            ),
            const Divider(),
            _buildMealTimeRow(
              'Öğle Yemeği',
              Icons.lunch_dining,
              _preferences!.lunchTime,
              _preferences!.isLunchReminderEnabled,
              (time) => _preferences!.setLunchTime(time),
            ),
            const Divider(),
            _buildMealTimeRow(
              'Akşam Yemeği',
              Icons.dinner_dining,
              _preferences!.dinnerTime,
              _preferences!.isDinnerReminderEnabled,
              (time) => _preferences!.setDinnerTime(time),
            ),
            const Divider(),
            _buildMealTimeRow(
              'Ara Öğün',
              Icons.coffee,
              _preferences!.snackTime,
              _preferences!.isSnackReminderEnabled,
              (time) => _preferences!.setSnackTime(time),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealTimeRow(
    String mealName,
    IconData icon,
    TimeOfDay currentTime,
    bool isEnabled,
    Function(TimeOfDay) onTimeChanged,
  ) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF075E54)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mealName,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          InkWell(
            onTap: isEnabled
                ? () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: currentTime,
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Color(0xFF075E54),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (time != null) {
                      setState(() {
                        onTimeChanged(time);
                        _preferences!.updatedAt = DateTime.now();
                      });
                    }
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealTogglesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hatırlatma Türleri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildMealToggle(
              'Kahvaltı Hatırlatması',
              Icons.breakfast_dining,
              _preferences!.isBreakfastReminderEnabled,
              (value) => setState(() {
                _preferences!.isBreakfastReminderEnabled = value;
                _preferences!.updatedAt = DateTime.now();
              }),
            ),
            _buildMealToggle(
              'Öğle Yemeği Hatırlatması',
              Icons.lunch_dining,
              _preferences!.isLunchReminderEnabled,
              (value) => setState(() {
                _preferences!.isLunchReminderEnabled = value;
                _preferences!.updatedAt = DateTime.now();
              }),
            ),
            _buildMealToggle(
              'Akşam Yemeği Hatırlatması',
              Icons.dinner_dining,
              _preferences!.isDinnerReminderEnabled,
              (value) => setState(() {
                _preferences!.isDinnerReminderEnabled = value;
                _preferences!.updatedAt = DateTime.now();
              }),
            ),
            _buildMealToggle(
              'Ara Öğün Hatırlatması',
              Icons.coffee,
              _preferences!.isSnackReminderEnabled,
              (value) => setState(() {
                _preferences!.isSnackReminderEnabled = value;
                _preferences!.updatedAt = DateTime.now();
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealToggle(
    String title,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      secondary: Icon(icon, color: const Color(0xFF075E54)),
      title: Text(title),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF075E54),
    );
  }

  Widget _buildReminderDaysSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hatırlatma Günleri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildDayToggles(),
          ],
        ),
      ),
    );
  }

  Widget _buildDayToggles() {
    const dayNames = ['Ptesi', 'Salı', 'Çarş', 'Perş', 'Cuma', 'Ctesi', 'Pazar'];
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (index) {
            final dayNumber = index + 1; // 1=Pazartesi, 7=Pazar
            final isSelected = _preferences!.reminderDays.contains(dayNumber);
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _preferences!.reminderDays.remove(dayNumber);
                  } else {
                    _preferences!.reminderDays.add(dayNumber);
                  }
                  _preferences!.reminderDays.sort();
                  _preferences!.updatedAt = DateTime.now();
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF075E54) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    dayNames[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _preferences!.reminderDays = [1, 2, 3, 4, 5]; // Hafta içi
                    _preferences!.updatedAt = DateTime.now();
                  });
                },
                icon: const Icon(Icons.business_center, size: 16),
                label: const Text('Hafta İçi', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _preferences!.reminderDays = [1, 2, 3, 4, 5, 6, 7]; // Her gün
                    _preferences!.updatedAt = DateTime.now();
                  });
                },
                icon: const Icon(Icons.calendar_month, size: 16),
                label: const Text('Her Gün', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF075E54),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotificationOptionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bildirim Seçenekleri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              secondary: const Icon(Icons.volume_up, color: Color(0xFF075E54)),
              title: const Text('Ses'),
              subtitle: const Text('Bildirim sesi çalar'),
              value: _preferences!.isSoundEnabled,
              onChanged: (value) {
                setState(() {
                  _preferences!.isSoundEnabled = value;
                  _preferences!.updatedAt = DateTime.now();
                });
              },
              activeColor: const Color(0xFF075E54),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.vibration, color: Color(0xFF075E54)),
              title: const Text('Titreşim'),
              subtitle: const Text('Telefon titreyecek'),
              value: _preferences!.isVibrationEnabled,
              onChanged: (value) {
                setState(() {
                  _preferences!.isVibrationEnabled = value;
                  _preferences!.updatedAt = DateTime.now();
                });
              },
              activeColor: const Color(0xFF075E54),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.psychology, color: Color(0xFF075E54)),
              title: const Text('Kişisel Mesajlar'),
              subtitle: const Text('Motivasyon mesajları göster'),
              value: _preferences!.usePersonalizedMessages,
              onChanged: (value) {
                setState(() {
                  _preferences!.usePersonalizedMessages = value;
                  _preferences!.updatedAt = DateTime.now();
                });
              },
              activeColor: const Color(0xFF075E54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedOptionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gelişmiş Seçenekler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.access_time, color: Color(0xFF075E54)),
              title: const Text('Erken Hatırlatma'),
              subtitle: Text('${_preferences!.beforeMealMinutes} dakika önce'),
              trailing: DropdownButton<int>(
                value: _preferences!.beforeMealMinutes,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Tam Zamanında')),
                  DropdownMenuItem(value: 5, child: Text('5 dakika önce')),
                  DropdownMenuItem(value: 10, child: Text('10 dakika önce')),
                  DropdownMenuItem(value: 15, child: Text('15 dakika önce')),
                  DropdownMenuItem(value: 30, child: Text('30 dakika önce')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _preferences!.beforeMealMinutes = value;
                      _preferences!.updatedAt = DateTime.now();
                    });
                  }
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.snooze, color: Color(0xFF075E54)),
              title: const Text('Erteleme Süresi'),
              subtitle: Text('${_preferences!.autoSnoozeMinutes} dakika'),
              trailing: DropdownButton<int>(
                value: _preferences!.autoSnoozeMinutes,
                items: const [
                  DropdownMenuItem(value: 5, child: Text('5 dakika')),
                  DropdownMenuItem(value: 10, child: Text('10 dakika')),
                  DropdownMenuItem(value: 15, child: Text('15 dakika')),
                  DropdownMenuItem(value: 20, child: Text('20 dakika')),
                  DropdownMenuItem(value: 30, child: Text('30 dakika')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _preferences!.autoSnoozeMinutes = value;
                      _preferences!.updatedAt = DateTime.now();
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'İstatistikler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatRow('Genel Başarı', '${(_preferences!.overallCompletionRate * 100).toInt()}%'),
            _buildStatRow('Kahvaltı', '${(_preferences!.breakfastCompletionRate * 100).toInt()}%'),
            _buildStatRow('Öğle Yemeği', '${(_preferences!.lunchCompletionRate * 100).toInt()}%'),
            _buildStatRow('Akşam Yemeği', '${(_preferences!.dinnerCompletionRate * 100).toInt()}%'),
            _buildStatRow('Ara Öğün', '${(_preferences!.snackCompletionRate * 100).toInt()}%'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF075E54).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _preferences!.getMotivationMessage(),
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF075E54),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF075E54),
            ),
          ),
        ],
      ),
    );
  }

  int _getActiveReminderCount() {
    int count = 0;
    if (_preferences!.isBreakfastReminderEnabled) count++;
    if (_preferences!.isLunchReminderEnabled) count++;
    if (_preferences!.isDinnerReminderEnabled) count++;
    if (_preferences!.isSnackReminderEnabled) count++;
    return count;
  }
}