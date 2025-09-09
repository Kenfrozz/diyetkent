import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../pages/incoming_call_page.dart';
import '../database/drift_service.dart';
import '../models/call_log_model.dart' as logm;
import '../services/people_service.dart';

class IncomingCallService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static StreamSubscription<QuerySnapshot>? _incomingCallSubscription;
  static BuildContext? _currentContext;
  
  // Gelen çağrıları dinlemeye başla
  static void startListening(BuildContext context) {
    _currentContext = context;
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    _incomingCallSubscription?.cancel();
    _incomingCallSubscription = _firestore
        .collection('calls')
        .where('calleeId', isEqualTo: userId)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .listen(_handleIncomingCall);
  }
  
  // Dinlemeyi durdur
  static void stopListening() {
    _incomingCallSubscription?.cancel();
    _incomingCallSubscription = null;
    _currentContext = null;
  }
  
  static Future<void> _handleIncomingCall(QuerySnapshot snapshot) async {
    final context = _currentContext;
    if (context == null) return;
    
    for (final doc in snapshot.docChanges) {
      if (doc.type == DocumentChangeType.added) {
        final data = doc.doc.data() as Map<String, dynamic>;
        final callId = doc.doc.id;
        final callerId = data['callerId'] as String;
        
        // Arayan kişinin bilgilerini al
        String callerName = 'Bilinmeyen Kişi';
        try {
          final people = await PeopleService.searchDirectoryQuick(
            query: callerId,
            includeUnregistered: false,
            limit: 1,
          );
          if (people.isNotEmpty) {
            callerName = people.first['displayName'] ?? 
                        people.first['contactName'] ?? 
                        'Bilinmeyen Kişi';
          }
        } catch (_) {
          // Hata durumunda default isim kullan
        }
        
        // Call log'a kaydet (incoming ringing)
        try {
          await DriftService.saveCallLog(logm.CallLogModel()
            ..callId = callId
            ..otherUserId = callerId
            ..otherDisplayName = callerName
            ..isVideo = data['isVideo'] ?? false
            ..direction = logm.CallLogDirection.incoming
            ..status = logm.CallLogStatus.ringing
            ..createdAt = DateTime.now());
        } catch (_) {}
        
        // Gelen arama ekranını göster
        if (context.mounted) {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  IncomingCallPage(
                callId: callId,
                callerName: callerName,
                callerId: callerId,
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(0.0, 1.0);
                const end = Offset.zero;
                const curve = Curves.ease;
                
                final tween = Tween(begin: begin, end: end);
                final curvedAnimation = CurvedAnimation(
                  parent: animation,
                  curve: curve,
                );
                
                return SlideTransition(
                  position: tween.animate(curvedAnimation),
                  child: child,
                );
              },
              fullscreenDialog: true,
            ),
          );
        }
      }
    }
  }
  
  // Missed call'ları işle
  static void handleMissedCalls() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    _firestore
        .collection('calls')
        .where('calleeId', isEqualTo: userId)
        .where('status', isEqualTo: 'ringing')
        .get()
        .then((snapshot) async {
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        if (createdAt != null) {
          // 30 saniyeden eski ringing çağrıları missed olarak işaretle
          final now = DateTime.now();
          if (now.difference(createdAt).inSeconds > 30) {
            await doc.reference.update({'status': 'missed'});
            
            // Call log'a missed olarak kaydet
            try {
              await DriftService.saveCallLog(logm.CallLogModel()
                ..callId = doc.id
                ..otherUserId = data['callerId']
                ..isVideo = data['isVideo'] ?? false
                ..direction = logm.CallLogDirection.incoming
                ..status = logm.CallLogStatus.missed
                ..createdAt = createdAt
                ..endedAt = now);
            } catch (_) {}
          }
        }
      }
    });
  }
}