import 'package:flutter/material.dart';
import '../services/people_service.dart';
import '../services/progressive_contacts_loader.dart';

/// 🚀 Progressive Contacts Widget
/// Büyük rehberler için optimize edilmiş kişi listesi widget'ı
class ProgressiveContactsWidget extends StatefulWidget {
  final bool includeUnregistered;
  final int? maxContacts;
  final Widget Function(Map<String, dynamic> contact)? itemBuilder;
  final Widget? emptyWidget;
  final Widget? errorWidget;
  
  const ProgressiveContactsWidget({
    super.key,
    this.includeUnregistered = false,
    this.maxContacts,
    this.itemBuilder,
    this.emptyWidget,
    this.errorWidget,
  });

  @override
  State<ProgressiveContactsWidget> createState() => _ProgressiveContactsWidgetState();
}

class _ProgressiveContactsWidgetState extends State<ProgressiveContactsWidget> {
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;
  String? _error;
  ContactsLoadingProgress? _currentProgress;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _listenToProgress();
  }

  void _loadContacts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final contacts = await PeopleService.getDirectoryProgressive(
        includeUnregistered: widget.includeUnregistered,
        maxContacts: widget.maxContacts,
      );

      if (mounted) {
        setState(() {
          _contacts = contacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _listenToProgress() {
    PeopleService.loadingProgressStream.listen((progress) {
      if (!mounted) return;

      setState(() {
        _currentProgress = progress;
        
        if (progress.hasError) {
          _error = progress.error;
          _isLoading = false;
        } else if (progress.isCompleted) {
          if (progress.data != null) {
            _contacts = progress.data!;
          }
          _isLoading = false;
        } else if (progress.data != null) {
          // Partial data available
          _contacts = progress.data!;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorWidget ?? _buildErrorWidget();
    }

    if (_contacts.isEmpty && _isLoading) {
      return _buildLoadingWidget();
    }

    if (_contacts.isEmpty) {
      return widget.emptyWidget ?? _buildEmptyWidget();
    }

    return Column(
      children: [
        // Progress indicator (if loading)
        if (_isLoading && _currentProgress != null)
          _buildProgressIndicator(),
        
        // Contacts list
        Expanded(
          child: ListView.builder(
            itemCount: _contacts.length,
            itemBuilder: (context, index) {
              final contact = _contacts[index];
              return widget.itemBuilder?.call(contact) ?? 
                     _buildDefaultContactTile(contact);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    final progress = _currentProgress!;
    
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  progress.message ?? 'Yükleniyor...',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              if (progress.currentCount != null)
                Text(
                  '${progress.currentCount}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          if (progress.phase != null)
            const SizedBox(height: 4),
          if (progress.phase != null)
            LinearProgressIndicator(
              value: _getProgressValue(progress.phase!),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
        ],
      ),
    );
  }

  double _getProgressValue(LoadingPhase phase) {
    switch (phase) {
      case LoadingPhase.localData:
        return 0.25;
      case LoadingPhase.contactsReading:
        return 0.5;
      case LoadingPhase.firebaseSync:
        return 0.75;
      case LoadingPhase.finalizing:
        return 0.9;
    }
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Rehber yükleniyor...'),
          SizedBox(height: 8),
          Text(
            'Büyük rehberlerde bu işlem biraz zaman alabilir',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Rehber yüklenirken hata oluştu'),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadContacts,
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.contacts_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Henüz kişi bulunamadı'),
          SizedBox(height: 8),
          Text(
            'Rehber izni verdiğinizden emin olun',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultContactTile(Map<String, dynamic> contact) {
    final isRegistered = contact['isRegistered'] == true;
    final displayName = contact['displayName'] as String? ?? 'İsimsiz';
    final phoneNumber = contact['phoneNumber'] as String? ?? '';
    final isOnline = contact['isOnline'] == true;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isRegistered ? Colors.teal : Colors.grey,
        child: contact['profileImageUrl'] != null
            ? ClipOval(
                child: Image.network(
                  contact['profileImageUrl'],
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
            : Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white),
              ),
      ),
      title: Row(
        children: [
          Expanded(child: Text(displayName)),
          if (isRegistered && isOnline)
            const Icon(
              Icons.circle,
              size: 8,
              color: Colors.green,
            ),
        ],
      ),
      subtitle: Text(phoneNumber),
      trailing: isRegistered
          ? const Icon(Icons.check_circle, color: Colors.teal, size: 20)
          : const Icon(Icons.person_add, color: Colors.grey, size: 20),
      onTap: () {
        // Handle contact tap
      },
    );
  }
}