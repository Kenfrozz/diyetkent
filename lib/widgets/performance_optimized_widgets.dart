import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Performans optimize edilmiş widget'lar koleksiyonu
/// 
/// Bu widget'lar şunları sağlar:
/// ✅ Efficient rendering
/// ✅ Memory optimization
/// ✅ Lazy loading
/// ✅ Caching strategies
/// ✅ Const constructors

/// Optimize edilmiş profil avatarı widget'ı
class OptimizedProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? userName;
  final double radius;
  final VoidCallback? onTap;

  const OptimizedProfileAvatar({
    super.key,
    this.imageUrl,
    this.userName,
    this.radius = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatar;

    if (imageUrl?.isNotEmpty == true) {
      // Resim varsa cached network image kullan
      avatar = CachedNetworkImage(
        imageUrl: imageUrl!,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: radius,
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => CircleAvatar(
          radius: radius,
          backgroundColor: const Color(0xFF00796B),
          child: const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        ),
        errorWidget: (context, url, error) => _buildInitialsAvatar(),
        // Memory cache optimizasyonu
        memCacheWidth: (radius * 2 * MediaQuery.of(context).devicePixelRatio).round(),
        memCacheHeight: (radius * 2 * MediaQuery.of(context).devicePixelRatio).round(),
      );
    } else {
      // Resim yoksa initials avatar
      avatar = _buildInitialsAvatar();
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildInitialsAvatar() {
    final initials = _getInitials(userName);
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF00796B),
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.6,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else {
      return words[0][0].toUpperCase();
    }
  }
}

/// Optimize edilmiş mesaj bubble widget'ı
class OptimizedMessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final DateTime timestamp;
  final MessageStatus status;
  final String? senderName;
  
  const OptimizedMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.senderName,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF00796B) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMe && senderName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  senderName!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF00796B),
                  ),
                ),
              ),
            Text(
              message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: isMe ? Colors.white70 : Colors.grey[600],
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _buildStatusIcon(),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (status) {
      case MessageStatus.sending:
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1,
            color: Colors.white70,
          ),
        );
      case MessageStatus.sent:
        return const Icon(
          Icons.check,
          size: 12,
          color: Colors.white70,
        );
      case MessageStatus.delivered:
        return const Icon(
          Icons.done_all,
          size: 12,
          color: Colors.white70,
        );
      case MessageStatus.read:
        return const Icon(
          Icons.done_all,
          size: 12,
          color: Colors.blue,
        );
      case MessageStatus.failed:
        return const Icon(
          Icons.error_outline,
          size: 12,
          color: Colors.red,
        );
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}';
    } else {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

/// Optimize edilmiş lista tile widget'ı
class OptimizedChatTile extends StatelessWidget {
  final String chatId;
  final String chatName;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isPinned;
  final bool isMuted;
  final String? avatarUrl;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const OptimizedChatTile({
    super.key,
    required this.chatId,
    required this.chatName,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isMuted = false,
    this.avatarUrl,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      leading: OptimizedProfileAvatar(
        imageUrl: avatarUrl,
        userName: chatName,
        radius: 24,
      ),
      title: Row(
        children: [
          if (isPinned)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(
                Icons.push_pin,
                size: 14,
                color: Color(0xFF00796B),
              ),
            ),
          if (isMuted)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(
                Icons.volume_off,
                size: 14,
                color: Colors.grey,
              ),
            ),
          Expanded(
            child: Text(
              chatName,
              style: TextStyle(
                fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      subtitle: lastMessage != null
          ? Text(
              lastMessage!,
              style: TextStyle(
                color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (lastMessageTime != null)
            Text(
              _formatTime(lastMessageTime!),
              style: TextStyle(
                fontSize: 12,
                color: unreadCount > 0 ? const Color(0xFF00796B) : Colors.grey[600],
                fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          if (unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(
                color: Color(0xFF00796B),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 6) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}g';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}s';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}dk';
    } else {
      return 'şimdi';
    }
  }
}

/// Optimize edilmiş shimmer loading widget'ı
class OptimizedShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  
  const OptimizedShimmerLoading({
    super.key,
    required this.child,
    this.isLoading = true,
  });

  @override
  State<OptimizedShimmerLoading> createState() => _OptimizedShimmerLoadingState();
}

class _OptimizedShimmerLoadingState extends State<OptimizedShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutSine),
    );
    
    if (widget.isLoading) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(OptimizedShimmerLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _animationController.repeat();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _animationController.stop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Colors.transparent,
                Colors.white54,
                Colors.transparent,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Lazy loading ListView optimize edilmiş versiyonu
class OptimizedLazyListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final VoidCallback? onEndReached;
  final EdgeInsets? padding;
  final ScrollController? controller;
  
  const OptimizedLazyListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.loadingBuilder,
    this.onEndReached,
    this.padding,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      itemCount: itemCount,
      // Performans optimizasyonu: Viewport dışındaki widget'ları cache'e al
      cacheExtent: MediaQuery.of(context).size.height,
      itemBuilder: (context, index) {
        // Son element yaklaştığında onEndReached callback'i çağır
        if (index == itemCount - 3 && onEndReached != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onEndReached!();
          });
        }
        
        return itemBuilder(context, index);
      },
    );
  }
}

/// Memory efficient image widget
class OptimizedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  
  const OptimizedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF00796B),
          ),
        ),
      ),
      errorWidget: (context, url, error) => errorWidget ?? Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Icon(Icons.error_outline),
      ),
      // Memory optimization - boyutları device pixel ratio'ya göre ayarla
      memCacheWidth: width != null ? (width! * devicePixelRatio).round() : null,
      memCacheHeight: height != null ? (height! * devicePixelRatio).round() : null,
      // Disk cache optimizasyonu
      maxWidthDiskCache: width != null ? (width! * devicePixelRatio * 1.5).round() : null,
      maxHeightDiskCache: height != null ? (height! * devicePixelRatio * 1.5).round() : null,
    );
  }
}