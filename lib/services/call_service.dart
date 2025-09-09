import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../database/drift_service.dart';
import '../models/call_log_model.dart' as logm;
import '../services/people_service.dart';

enum CallStatus { ringing, connected, ended, declined, missed }

class CallSession {
  final String callId;
  final String callerId;
  final String calleeId;
  final bool isVideo;
  CallStatus status;

  CallSession({
    required this.callId,
    required this.callerId,
    required this.calleeId,
    required this.isVideo,
    required this.status,
  });
}

class CallService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _callDocSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _calleeCandidatesSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _callerCandidatesSub;
  bool _isEnding = false;
  bool _remoteAnswerApplied = false;

  final _onRemoteStreamController = StreamController<MediaStream?>.broadcast();
  final _onCallStatusController = StreamController<CallStatus>.broadcast();

  Stream<MediaStream?> get onRemoteStream => _onRemoteStreamController.stream;
  Stream<CallStatus> get onCallStatus => _onCallStatusController.stream;

  Future<void> setMuted(bool muted) async {
    try {
      final tracks =
          _localStream?.getAudioTracks() ?? const <MediaStreamTrack>[];
      for (final t in tracks) {
        t.enabled = !muted;
      }
    } catch (_) {}
  }

  Future<void> setSpeakerphoneOn(bool on) async {
    try {
      await Helper.setSpeakerphoneOn(on);
    } catch (_) {}
  }

  Future<void> _initPeer() async {
    try {
      _peerConnection?.close();
      final config = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
          {'urls': 'stun:stun1.l.google.com:19302'},
        ]
      };
      _peerConnection = await createPeerConnection(config);
      _remoteAnswerApplied = false;
      _isEnding = false;
    } catch (e) {
      throw Exception('WebRTC bağlantısı başlatılamadı: $e');
    }

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) async {
      // ICE adaylarını Firestore'a ekle (calleeCandidates / callerCandidates)
      // Adaylar, aktif çağrı dökümanında tutulur
      try {
        final userId = _auth.currentUser?.uid;
        if (userId == null) return;
        final currentCallId = _activeCallId;
        if (currentCallId == null || _isEnding) return;
        final role = (userId == _activeCallerId)
            ? 'callerCandidates'
            : 'calleeCandidates';
        await _firestore
            .collection('calls')
            .doc(currentCallId)
            .collection(role)
            .add(candidate.toMap());
      } catch (_) {}
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
        _onRemoteStreamController.add(_remoteStream);
      }
    };

    _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
      if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
          state == RTCIceConnectionState.RTCIceConnectionStateClosed) {
        if (!_isEnding) {
          endCall(remote: true);
        }
      }
    };
  }

  String? _activeCallId;
  String? _activeCallerId;

  // Kişi bilgilerini al
  Future<String> _getPersonDisplayName(String userId) async {
    try {
      final people = await PeopleService.searchDirectoryQuick(
        query: userId,
        includeUnregistered: true,
        limit: 1,
      );
      if (people.isNotEmpty) {
        return people.first['displayName'] ?? 
               people.first['contactName'] ?? 
               userId;
      }
    } catch (_) {
      // Hata durumunda userId'yi döndür
    }
    return userId;
  }

  Future<MediaStream> _getUserAudio() async {
    try {
      final mediaConstraints = {
        'audio': true,
        'video': false,
      };
      final stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      return stream;
    } catch (e) {
      throw Exception('Mikrofon erişimi reddedildi: $e');
    }
  }

  Future<String> startVoiceCall({
    required String calleeId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Kullanıcı oturumu yok');

    await _initPeer();
    _localStream = await _getUserAudio();
    for (final track in _localStream!.getTracks()) {
      await _peerConnection!.addTrack(track, _localStream!);
    }

    final callDoc = _firestore.collection('calls').doc();
    _activeCallId = callDoc.id;
    _activeCallerId = user.uid;

    // Offer oluştur
    final offer =
        await _peerConnection!.createOffer({'offerToReceiveAudio': 1});
    await _peerConnection!.setLocalDescription(offer);

    final callData = {
      'callId': callDoc.id,
      'callerId': user.uid,
      'calleeId': calleeId,
      'isVideo': false,
      'status': 'ringing',
      'createdAt': FieldValue.serverTimestamp(),
      'offer': offer.toMap(),
    };
    await callDoc.set(callData);

    // Isar call log: outgoing ringing
    try {
      final displayName = await _getPersonDisplayName(calleeId);
      await DriftService.saveCallLog(logm.CallLogModel()
        ..callId = callDoc.id
        ..otherUserId = calleeId
        ..otherDisplayName = displayName
        ..isVideo = false
        ..direction = logm.CallLogDirection.outgoing
        ..status = logm.CallLogStatus.ringing
        ..createdAt = DateTime.now());
    } catch (_) {}

    // Dökümanı dinle (answer/status değişimleri için)
    _callDocSubscription?.cancel();
    _callDocSubscription = callDoc.snapshots().listen((snap) async {
      final data = snap.data();
      if (data == null) return;
      final status = (data['status'] as String?) ?? 'ringing';
      _onCallStatusController.add(_statusFromString(status));

      if (data['answer'] != null) {
        if (!_remoteAnswerApplied) {
          try {
            final answer = RTCSessionDescription(
              data['answer']['sdp'],
              data['answer']['type'],
            );
            if (_peerConnection != null) {
              await _peerConnection!.setRemoteDescription(answer);
              _remoteAnswerApplied = true;
            }
          } catch (_) {
            // Tekrarlı snapshot veya yanlış state durumunda yut
          }
        }
      }
      if ((status == 'connected')) {
        try {
          final displayName = await _getPersonDisplayName(calleeId);
          await DriftService.saveCallLog(logm.CallLogModel()
            ..callId = callDoc.id
            ..otherUserId = calleeId
            ..otherDisplayName = displayName
            ..isVideo = false
            ..direction = logm.CallLogDirection.outgoing
            ..status = logm.CallLogStatus.connected
            ..createdAt = DateTime.now()
            ..connectedAt = DateTime.now());
        } catch (_) {}
      }
      if ((status == 'ended' || status == 'declined') && !_isEnding) {
        try {
          final displayName = await _getPersonDisplayName(calleeId);
          await DriftService.saveCallLog(logm.CallLogModel()
            ..callId = callDoc.id
            ..otherUserId = calleeId
            ..otherDisplayName = displayName
            ..isVideo = false
            ..direction = logm.CallLogDirection.outgoing
            ..status = status == 'declined'
                ? logm.CallLogStatus.declined
                : logm.CallLogStatus.ended
            ..endedAt = DateTime.now());
        } catch (_) {}
        await endCall(remote: true);
      }
    });

    // Callee ICE adaylarını dinle
    _calleeCandidatesSub?.cancel();
    _calleeCandidatesSub = _firestore
        .collection('calls')
        .doc(callDoc.id)
        .collection('calleeCandidates')
        .snapshots()
        .listen((snapshot) {
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final candidate = RTCIceCandidate(
          data['candidate'],
          data['sdpMid'],
          data['sdpMLineIndex'],
        );
        _peerConnection?.addCandidate(candidate);
      }
    });

    return callDoc.id;
  }

  Future<void> acceptCall(String callId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _initPeer();
    _localStream = await _getUserAudio();
    for (final track in _localStream!.getTracks()) {
      await _peerConnection!.addTrack(track, _localStream!);
    }

    final callRef = _firestore.collection('calls').doc(callId);
    final callSnap = await callRef.get();
    final call = callSnap.data();
    if (call == null) return;

    _activeCallId = callId;
    _activeCallerId = call['callerId'];

    final offer = call['offer'];
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(offer['sdp'], offer['type']),
    );

    final answer =
        await _peerConnection!.createAnswer({'offerToReceiveAudio': 1});
    await _peerConnection!.setLocalDescription(answer);

    await callRef.update({
      'answer': answer.toMap(),
      'status': 'connected',
      'connectedAt': FieldValue.serverTimestamp(),
    });

    // Isar call log: incoming connected
    try {
      final callerId = call['callerId'] as String?;
      if (callerId != null) {
        final displayName = await _getPersonDisplayName(callerId);
        await DriftService.saveCallLog(logm.CallLogModel()
          ..callId = callId
          ..otherUserId = callerId
          ..otherDisplayName = displayName
          ..isVideo = false
          ..direction = logm.CallLogDirection.incoming
          ..status = logm.CallLogStatus.connected
          ..createdAt = DateTime.now()
          ..connectedAt = DateTime.now());
      }
    } catch (_) {}

    // Caller ICE adaylarını dinle
    _callerCandidatesSub?.cancel();
    _callerCandidatesSub = _firestore
        .collection('calls')
        .doc(callId)
        .collection('callerCandidates')
        .snapshots()
        .listen((snapshot) {
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final candidate = RTCIceCandidate(
          data['candidate'],
          data['sdpMid'],
          data['sdpMLineIndex'],
        );
        _peerConnection?.addCandidate(candidate);
      }
    });

    // Dökümanı dinle (status değişimleri için)
    _callDocSubscription?.cancel();
    _callDocSubscription = callRef.snapshots().listen((snap) async {
      final data = snap.data();
      if (data == null) return;
      final status = (data['status'] as String?) ?? 'ringing';
      _onCallStatusController.add(_statusFromString(status));
      if ((status == 'ended' || status == 'declined') && !_isEnding) {
        try {
          final callerId = data['callerId'] as String?;
          if (callerId != null) {
            final displayName = await _getPersonDisplayName(callerId);
            await DriftService.saveCallLog(logm.CallLogModel()
              ..callId = callId
              ..otherUserId = callerId
              ..otherDisplayName = displayName
              ..isVideo = false
              ..direction = logm.CallLogDirection.incoming
              ..status = status == 'declined'
                  ? logm.CallLogStatus.declined
                  : logm.CallLogStatus.ended
              ..endedAt = DateTime.now());
          }
        } catch (_) {}
        await endCall(remote: true);
      }
    });
  }

  Future<void> declineCall(String callId) async {
    await _firestore.collection('calls').doc(callId).update({
      'status': 'declined',
      'endedAt': FieldValue.serverTimestamp(),
    });
    await endCall();
  }

  Future<void> endCall({bool remote = false}) async {
    try {
      _isEnding = true;
      final callId = _activeCallId;
      if (callId != null && !remote) {
        await _firestore.collection('calls').doc(callId).update({
          'status': 'ended',
          'endedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
    try {
      _callDocSubscription?.cancel();
      _callerCandidatesSub?.cancel();
      _calleeCandidatesSub?.cancel();
      _callDocSubscription = null;
      _callerCandidatesSub = null;
      _calleeCandidatesSub = null;
      if (_peerConnection != null) {
        _peerConnection!.onIceCandidate = null;
        _peerConnection!.onTrack = null;
      }
      await _peerConnection?.close();
      await _cleanupMedia();
      try {
        await Helper.setSpeakerphoneOn(false);
      } catch (_) {}
      final callId = _activeCallId;
      if (callId != null && !remote) {
        await _deleteIceCandidates(callId);
      }
      _peerConnection = null;
      _localStream = null;
      _remoteStream = null;
      _activeCallId = null;
      _activeCallerId = null;
    } catch (_) {}
    _onRemoteStreamController.add(null);
    _onCallStatusController.add(CallStatus.ended);
  }

  Future<void> _cleanupMedia() async {
    try {
      for (final t
          in _localStream?.getAudioTracks() ?? const <MediaStreamTrack>[]) {
        try {
          t.stop();
        } catch (_) {}
      }
      for (final t
          in _localStream?.getVideoTracks() ?? const <MediaStreamTrack>[]) {
        try {
          t.stop();
        } catch (_) {}
      }
      await _localStream?.dispose();
    } catch (_) {}
    try {
      for (final t
          in _remoteStream?.getAudioTracks() ?? const <MediaStreamTrack>[]) {
        try {
          t.stop();
        } catch (_) {}
      }
      for (final t
          in _remoteStream?.getVideoTracks() ?? const <MediaStreamTrack>[]) {
        try {
          t.stop();
        } catch (_) {}
      }
      await _remoteStream?.dispose();
    } catch (_) {}
  }

  Future<void> _deleteIceCandidates(String callId) async {
    try {
      final callerRef = _firestore
          .collection('calls')
          .doc(callId)
          .collection('callerCandidates');
      final calleeRef = _firestore
          .collection('calls')
          .doc(callId)
          .collection('calleeCandidates');
      final callerSnap = await callerRef.get();
      final calleeSnap = await calleeRef.get();
      final batch = _firestore.batch();
      for (final d in callerSnap.docs) {
        batch.delete(d.reference);
      }
      for (final d in calleeSnap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    } catch (_) {}
  }

  CallStatus _statusFromString(String s) {
    switch (s) {
      case 'ringing':
        return CallStatus.ringing;
      case 'connected':
        return CallStatus.connected;
      case 'declined':
        return CallStatus.declined;
      case 'missed':
        return CallStatus.missed;
      case 'ended':
      default:
        return CallStatus.ended;
    }
  }

  void dispose() {
    _callDocSubscription?.cancel();
    _callerCandidatesSub?.cancel();
    _calleeCandidatesSub?.cancel();
    _onRemoteStreamController.close();
    _onCallStatusController.close();
  }
}
