import 'package:flutter/material.dart';
import '../services/call_service.dart';
import 'package:flutter/scheduler.dart';

class VoiceCallPage extends StatefulWidget {
  final String otherUserName;
  final String callId; // active call id
  final bool isIncoming;

  const VoiceCallPage({
    super.key,
    required this.otherUserName,
    required this.callId,
    this.isIncoming = false,
  });

  @override
  State<VoiceCallPage> createState() => _VoiceCallPageState();
}

class _VoiceCallPageState extends State<VoiceCallPage> {
  final CallService _callService = CallService();
  bool _muted = false;
  bool _speakerOn = false;
  CallStatus _status = CallStatus.ringing;
  bool _hasAnswered = false;
  DateTime? _connectedAt;
  late final Ticker _ticker;
  final Stopwatch _stopwatch = Stopwatch();
  String _elapsed = '00:00';

  @override
  void initState() {
    super.initState();
    _ticker = Ticker(_onTick);
    _callService.onRemoteStream.listen((_) => setState(() {}));
    _callService.onCallStatus.listen((st) async {
      setState(() {
        _status = st;
        if (_status == CallStatus.connected && !_stopwatch.isRunning) {
          _connectedAt ??= DateTime.now();
          _stopwatch.start();
          _ticker.start();
        }
      });
      if (_status == CallStatus.ended || _status == CallStatus.declined) {
        _ticker.stop();
        _stopwatch.stop();
        if (mounted) {
          Navigator.maybePop(context);
        }
      }
    });
    // Gelen aramada otomatik kabul ETME
  }

  Widget _buildProfileAvatar() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF128C7E), Color(0xFF25D366)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: CircleAvatar(
        radius: 64,
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        child: Text(
          widget.otherUserName.isNotEmpty
              ? widget.otherUserName[0].toUpperCase()
              : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusText() {
    String text;
    switch (_status) {
      case CallStatus.connected:
        text = 'Süre: $_elapsed';
        break;
      case CallStatus.declined:
        text = 'Reddedildi';
        break;
      case CallStatus.ended:
        text = 'Bitti';
        break;
      case CallStatus.ringing:
      default:
        text = widget.isIncoming && !_hasAnswered ? 'Gelen arama…' : 'Çalıyor…';
        break;
    }
    return Text(text, style: const TextStyle(color: Colors.white70));
  }

  Widget _buildIncomingActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _roundButton(
          icon: Icons.call_end,
          label: 'Reddet',
          color: Colors.red,
          onTap: _end,
        ),
        _roundButton(
          icon: Icons.call,
          label: 'Yanıtla',
          color: const Color(0xFF25D366),
          onTap: _accept,
        ),
      ],
    );
  }

  Widget _buildOngoingActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _roundButton(
          icon: _muted ? Icons.mic_off : Icons.mic,
          label: _muted ? 'Mik Kapalı' : 'Mik Açık',
          onTap: _toggleMute,
        ),
        _roundButton(
          icon: Icons.call_end,
          label: 'Bitir',
          color: Colors.red,
          onTap: _end,
        ),
        _roundButton(
          icon: _speakerOn ? Icons.volume_up : Icons.volume_down,
          label: _speakerOn ? 'Hoparlör' : 'Kulaklık',
          onTap: _toggleSpeaker,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    // Sayfa kapanırken aramayı güvenli şekilde sonlandır
    () async {
      try {
        await _callService.endCall();
      } catch (_) {}
      _callService.dispose();
    }();
    super.dispose();
  }

  Future<void> _end() async {
    try {
      // Gelen aramada henüz cevaplanmadıysa sonlandırma = reddet
      if (widget.isIncoming && !_hasAnswered && _status == CallStatus.ringing) {
        await _callService.declineCall(widget.callId);
      } else {
        await _callService.endCall();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Arama sonlandırılamadı: $e')),
        );
      }
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _accept() async {
    if (_hasAnswered) return;
    try {
      setState(() => _hasAnswered = true);
      await _callService.acceptCall(widget.callId);
    } catch (e) {
      if (mounted) {
        setState(() => _hasAnswered = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Arama kabul edilemedi: $e')),
        );
      }
    }
  }

  Future<void> _toggleMute() async {
    try {
      final next = !_muted;
      await _callService.setMuted(next);
      if (mounted) setState(() => _muted = next);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mikrofon ayarı değiştirilemedi: $e')),
        );
      }
    }
  }

  Future<void> _toggleSpeaker() async {
    try {
      final next = !_speakerOn;
      await _callService.setSpeakerphoneOn(next);
      if (mounted) setState(() => _speakerOn = next);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hoparlör ayarı değiştirilemedi: $e')),
        );
      }
    }
  }

  void _onTick(Duration _) {
    if (!_stopwatch.isRunning) return;
    final d = Duration(seconds: _stopwatch.elapsed.inSeconds);
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    setState(() {
      _elapsed =
          h > 0 ? '${two(h)}:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B141A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B141A),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _status == CallStatus.connected ? _elapsed : 'Sesli Arama',
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            _buildProfileAvatar(),
            const SizedBox(height: 16),
            Text(
              widget.otherUserName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildStatusText(),
            const SizedBox(height: 40),
            if (widget.isIncoming &&
                !_hasAnswered &&
                _status == CallStatus.ringing)
              _buildIncomingActions()
            else
              _buildOngoingActions(),
          ],
        ),
      ),
    );
  }

  Widget _roundButton({
    required IconData icon,
    required String label,
    Color color = const Color(0xFF128C7E),
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}
